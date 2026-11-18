//
// Copyright 2017 Google Inc.
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

/**
 * A class for creating BOOL conditions that can be waited on until the condition is satisfied
 * or a timeout elapses.
 *
 * Conditions are specified in the form of a block that returns a @c BOOL value indicating whether
 * the condition is met.
 */
@interface GREYCondition : NSObject

/**
 * Creates a condition with a block that should return @c YES when the condition is met.
 *
 * @param name           A descriptive name for the condition
 * @param conditionBlock The block that will be used to evaluate the condition.
 *
 * @return A new initialized GREYCondition instance.
 */
+ (instancetype)conditionWithName:(NSString *)name block:(BOOL (^)(void))conditionBlock;

/**
 * @remark init is not an available initializer. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 * Initializes a condition with a block that should return @c YES when the condition is met.
 *
 * @param name           A descriptive name for the condition
 * @param conditionBlock The block that will be used to evaluate the condition.
 *
 * @return The initialized instance.
 */
- (instancetype)initWithName:(NSString *)name
                       block:(BOOL (^)(void))conditionBlock NS_DESIGNATED_INITIALIZER;

/**
 * Waits for the condition to be met until the specified @c seconds have elapsed.
 *
 * Evaluates the condition immediately, and if not met, polls every 0.5 seconds until the condition
 * is met or the timeout elapses.
 *
 * @remark To poll at a shorter or longer interval than the 0.5-second default, use
 *         GREYCondition::waitWithTimeout:pollInterval: with a positive poll interval.
 *
 * @param seconds Amount of time to wait for the condition to be met, in seconds.
 *
 * @return @c YES if the condition was met before the timeout, @c NO otherwise.
 */
- (BOOL)waitWithTimeout:(CFTimeInterval)seconds
    __attribute__((warn_unused_result)) NS_SWIFT_DISABLE_ASYNC;

/**
 * Waits for the condition to be met until the specified @c seconds have elapsed. Will poll the
 * condition immediately and then no more than once every @c interval seconds. Will attempt to poll
 * the condition as close as possible to every @c interval seconds.
 *
 * @remark Will allow the main thread to sleep instead of busily checking the condition.
 *
 * @param seconds  Amount of time to wait for the condition to be met, in seconds.
 * @param interval The minimum time that should elapse between checking the condition, or 0 to use
 *                 the default 0.5-second poll interval.
 *
 * @return @c YES if the condition was met before the timeout, @c NO otherwise.
 */
- (BOOL)waitWithTimeout:(CFTimeInterval)seconds
           pollInterval:(CFTimeInterval)interval
    __attribute__((warn_unused_result)) NS_SWIFT_DISABLE_ASYNC;
/**
 * @return Name of the condition.
 */
- (NSString *)name;

@end
