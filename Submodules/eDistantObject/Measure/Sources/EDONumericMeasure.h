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

NS_ASSUME_NONNULL_BEGIN

/**
 *  The numerical measurement to record the minimum, maximum, and average values from a streaming
 *  input.
 *
 *  The measurement continues to read values in a streaming manner and the statistics are available
 *  after the measurement completes by calling -complete. Any reads of @c average, @c minimum,
 *  and @c maximum will throw an exception if the measurement has not yet completed. The write is
 *  thread-safe.
 */
@interface EDONumericMeasure : NSObject
/** The average value, the default is 0.0. */
@property(readonly, nonatomic) double average;
/** The minimum value, the default is DBL_MAX. */
@property(readonly, nonatomic) double minimum;
/** The maximum value, the default is DBL_MIN. */
@property(readonly, nonatomic) double maximum;
/** The number of measures that have been added so far. */
@property(readonly, nonatomic) size_t measureCount;

/** Creates a new measure. */
+ (instancetype)measure;

/**
 *  Adds a new value to calculate the measurement.
 *
 *  @note If the measurement is completed, this becomes a no-op.
 *
 *  @param value The measurement value to be added.
 */
- (void)addSingleValue:(double)value;

/**
 *  Completes the current measurement. After invoking this method, all future writes will be
 *  discarded.
 *
 *  @return @c NO if the measurement has already completed, @c YES otherwise.
 */
- (BOOL)complete;

@end

NS_ASSUME_NONNULL_END
