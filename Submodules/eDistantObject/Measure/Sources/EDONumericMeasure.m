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

#import "Measure/Sources/EDONumericMeasure.h"

@implementation EDONumericMeasure {
  /** The isolation queue to access the measure values. */
  dispatch_queue_t _measureIsolation;
  /** Whether the measurement is completed. */
  BOOL _completed;
}

@synthesize maximum = _maximum, minimum = _minimum, average = _average,
            measureCount = _measureCount;

+ (instancetype)measure {
  return [[self alloc] init];
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _maximum = DBL_MIN;
    _minimum = DBL_MAX;
    _measureIsolation = dispatch_queue_create("com.google.edo.measure", DISPATCH_QUEUE_SERIAL);
  }
  return self;
}

- (double)maximum {
  [self edo_checkCompletion];
  return _maximum;
}

- (double)minimum {
  [self edo_checkCompletion];
  return _minimum;
}

- (double)average {
  [self edo_checkCompletion];
  return _average;
}

- (size_t)measureCount {
  __block size_t measureCount = 0;
  dispatch_sync(_measureIsolation, ^{
    measureCount = self->_measureCount;
  });
  return measureCount;
}

- (void)addSingleValue:(double)value {
  dispatch_sync(_measureIsolation, ^{
    if (self->_completed) {
      return;
    }

    self->_maximum = MAX(self->_maximum, value);
    self->_minimum = MIN(self->_minimum, value);

    double countOfMeasures = (double)self->_measureCount;
    // TODO(haowoo): Reduce the aggregated loss over time if needed in the future.
    // The average is computed as: new_avg = avg * n/(n+1) + newValue / (n+1)
    self->_average = self->_average * (countOfMeasures / (countOfMeasures + 1.0));
    self->_average += value / (countOfMeasures + 1.0);
    ++self->_measureCount;
  });
}

- (BOOL)complete {
  __block BOOL alreadyCompleted = NO;
  dispatch_sync(_measureIsolation, ^{
    alreadyCompleted = self->_completed;
    self->_completed = YES;
  });
  return !alreadyCompleted;
}

- (NSString *)description {
  __block BOOL alreadyCompleted;
  __block size_t measureCount;
  dispatch_sync(_measureIsolation, ^{
    alreadyCompleted = self->_completed;
    measureCount = self->_measureCount;
  });
  if (alreadyCompleted) {
    return [NSString stringWithFormat:@"Numeric measure (%zd) in milliseconds: minimum (%lf), "
                                      @"maximum (%lf), and average (%lf).",
                                      measureCount, self.minimum, self.maximum, self.average];
  } else {
    return [NSString stringWithFormat:@"Incomplete numeric measure (%zd).", measureCount];
  }
}

#pragma mark - Private methods

- (void)edo_checkCompletion {
  __block BOOL completed = NO;
  dispatch_sync(_measureIsolation, ^{
    completed = self->_completed;
  });
  if (!completed) {
    [[NSException exceptionWithName:NSInternalInconsistencyException
                             reason:@"The measurement hasn't been completed."
                           userInfo:nil] raise];
  }
}

@end
