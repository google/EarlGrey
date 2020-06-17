//
// Copyright 2018 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "Service/Sources/EDOClientServiceStatsCollector.h"

#import "Measure/Sources/EDONumericMeasure.h"

@implementation EDORequestMeasurement

- (instancetype)init {
  self = [super init];
  if (self) {
    _requestMeasure = [EDONumericMeasure measure];
    _responseMeasure = [EDONumericMeasure measure];
  }
  return self;
}

- (void)complete {
  [self.requestMeasure complete];
  [self.responseMeasure complete];
}

- (double)requestRatio {
  double requestAverage = self.requestMeasure.average;
  double responseAverage = self.responseMeasure.average;
  return requestAverage / (responseAverage + requestAverage);
}

- (NSString *)description {
  return [NSString stringWithFormat:@"Ratio: %lf\n  Request:%@\n  Response:%@", self.requestRatio,
                                    self.requestMeasure, self.responseMeasure];
}

@end

@implementation EDOClientServiceStatsCollector {
  /** The isolation queue to access the stats data. */
  dispatch_queue_t _statsIsolation;
}

+ (EDOClientServiceStatsCollector *)sharedServiceStats {
  static dispatch_once_t onceToken;
  static EDOClientServiceStatsCollector *clientServiceStats;
  dispatch_once(&onceToken, ^{
    clientServiceStats = [[self alloc] init];
  });
  return clientServiceStats;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _statsIsolation = dispatch_queue_create("com.google.edo.stats", DISPATCH_QUEUE_SERIAL);
    [self start];
  }
  return self;
}

- (void)reportConnectionDuration:(double)duration {
  dispatch_async(_statsIsolation, ^{
    [self->_connectionMeasure addSingleValue:duration];
  });
}

- (void)reportRequestType:(Class)requestType
          requestDuration:(double)requestDuration
         responseDuration:(double)responseDuration {
  dispatch_async(_statsIsolation, ^{
    NSString *requestName = NSStringFromClass(requestType);
    EDORequestMeasurement *status = [self->_allRequestMeasurements objectForKey:requestName];
    if (!status) {
      status = [[EDORequestMeasurement alloc] init];
      self->_allRequestMeasurements[requestName] = status;
    }
    [status.requestMeasure addSingleValue:requestDuration - responseDuration];
    [status.responseMeasure addSingleValue:responseDuration];
  });
}

- (void)reportError {
  dispatch_async(_statsIsolation, ^{
    ++self->_errorCount;
  });
}

- (void)reportReleaseObject {
  dispatch_async(_statsIsolation, ^{
    ++self->_releaseCount;
  });
}

- (void)start {
  dispatch_async(_statsIsolation, ^{
    self->_errorCount = 0;
    self->_releaseCount = 0;
    self->_connectionMeasure = [EDONumericMeasure measure];
    self->_allRequestMeasurements = [[NSMutableDictionary alloc] init];
  });
}

- (void)complete {
  dispatch_async(_statsIsolation, ^{
    for (NSString *request in self.allRequestMeasurements) {
      [self.allRequestMeasurements[request] complete];
    }
    [self.connectionMeasure complete];
  });
}

- (NSString *)description {
  NSMutableString *requestDescription = [[NSMutableString alloc] init];
  dispatch_sync(_statsIsolation, ^{
    for (NSString *requestName in self.allRequestMeasurements) {
      [requestDescription appendFormat:@"Request: (%@)\n%@\n---\n", requestName,
                                       self.allRequestMeasurements[requestName]];
    }
  });
  NSString *desc =
      [NSString stringWithFormat:@"Client service: # of releases (%" PRIu64 "), # of errors"
                                 @"(%" PRIu64 ")\n Connections: %@\nRequests:\n%@",
                                 self.releaseCount, self.errorCount, self.connectionMeasure,
                                 requestDescription];
  return desc;
}

@end
