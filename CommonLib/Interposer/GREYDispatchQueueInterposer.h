//
// Copyright 2020 Google LLC.
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
 * A class to track dispatch_queues without using fishhook. Must be inside a dylib which is inserted
 * into an application binary for tracking purposes.
 */
@interface GREYDispatchQueueInterposer : NSObject

/**
 * Pass in a queue to the interposer so it can be interposed. This form of interposing will only
 * work if it is part of a dylib.
 *
 * @return An instance of GREYDispatchQueueInterposer which can be used by looking at isIdleNow to
 * check if it tracks any queues.
 */
+ (instancetype)interposeDispatchQueue:(dispatch_queue_t)queue;

- (instancetype)init NS_UNAVAILABLE;

/**
 * Methods that are similar to GREYDispatchQueueTracker which are in turn used by
 * idling resources.
 */

/** @see GREYDispatchQueueTracker::isIdleNow. */
- (BOOL)isIdleNow;

/** @see GREYDispatchQueueTracker::isTrackingALiveQueue. */
- (BOOL)isTrackingALiveQueue;

@end

NS_ASSUME_NONNULL_END
