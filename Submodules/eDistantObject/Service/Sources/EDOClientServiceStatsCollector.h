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

#import <Foundation/Foundation.h>

@class EDONumericMeasure;

NS_ASSUME_NONNULL_BEGIN

/** The status for one type of request. */
@interface EDORequestMeasurement : NSObject

/**
 *  The measure for the request excluding the time spent for handling the response, that is,
 *  the time spent only for eDO to send the request and receive the response.
 */
@property(readonly, nonatomic) EDONumericMeasure *requestMeasure;
/** The measure measurement for the response. */
@property(readonly, nonatomic) EDONumericMeasure *responseMeasure;
/** The performance ratio of the request average to the total average (request + response). */
@property(readonly, nonatomic) double requestRatio;

/**
 *  Completes the request and response measure so it can be read.
 *
 *  @note You don't need to call this directly but EDOClientServiceStatsCollector will take care of
 *        this.
 */
- (void)complete;

@end

/** The statistics for the client service. */
@interface EDOClientServiceStatsCollector : NSObject

/** The number of errors ocurred. */
@property(readonly, nonatomic) uint64_t errorCount;
/** The number of remote releases ocurred. */
@property(readonly, nonatomic) uint64_t releaseCount;
/** The measurement for the connection. */
@property(readonly, nonatomic) EDONumericMeasure *connectionMeasure;
/** The measurement matrix for the requests by the request name. */
@property(readonly, nonatomic)
    NSMutableDictionary<NSString *, EDORequestMeasurement *> *allRequestMeasurements;

/** The singleton of EDOClientServiceStatsCollector. */
@property(readonly, nonatomic, class) EDOClientServiceStatsCollector *sharedServiceStats;

/** Reports that a release request is sent. */
- (void)reportReleaseObject;

/** Reports that an error has ocurred. */
- (void)reportError;

/** Reports that a request is sent and a response is received. */
- (void)reportRequestType:(Class)requestType
          requestDuration:(double)requestDuration
         responseDuration:(double)responseDuration;

/** Reports that the connection is established. */
- (void)reportConnectionDuration:(double)duration;

/** Starts collecting the statistics. This is automatically invoked once initialized. */
- (void)start;

/** Completes the collection and readies for reads. */
- (void)complete;

@end

NS_ASSUME_NONNULL_END
