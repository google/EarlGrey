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

#import "GREYDefines.h"

/**
 * @file
 * @brief Header file for GREYUIThreadExecutor.
 */

@protocol GREYIdlingResource;

/**
 * Typedef for blocks that can be executed by the GREYUIThreadExecutor.
 */
typedef void (^GREYExecBlock)(void);

/**
 * The executor that syncs execution with the UI events on the main thread.
 *
 * The executor will need to be invoked from a non-main thread; before
 * executing a block, it waits for any pending UI events to complete and the
 * block will be dispatched to the main queue.
 */
@interface GREYUIThreadExecutor : NSObject

/**
 * @return The unique shared instance of the GREYUIThreadExecutor.
 * @note This will initialize idling resources for the main dispatch queue, operations queue and the
 *       app state tracker. The first call to @c sharedInstance is not in any constructor but from
 *       swizzled methods such as timers.
 */
+ (instancetype)sharedInstance;

/**
 * @remark init is not an available initializer. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 * Executes @c execBlock on the main thread, synchronizing with all registered GREYIdlingResources
 * and UI events. If the UI thread or idling resources are not idle until @c seconds have elapsed,
 * @c execBlock is not executed and error (if provided) is populated.
 *
 * @param seconds   The timeout for waiting for the resources to idle, in seconds. A value of @c
 *                  kGREYInfiniteTimeout indicates an infinite timeout.
 * @param execBlock The block to be executed in the main queue.
 * @param error     Reference to the error that will store the failure cause, if any.
 *
 * @return @c YES if the block was executed, @c NO otherwise, in which case @c
 *         error will be set to the failure cause.
 *
 * @remark Blocks are executed in the order in which they were submitted.
 * @remark This selector must be invoked on the main thread.
 */
- (BOOL)executeSyncWithTimeout:(CFTimeInterval)seconds
                         block:(GREYExecBlock)execBlock
                         error:(__autoreleasing NSError **)error;

/**
 * Drains the UI thread and waits for both the UI and idling resources to idle, for up to
 * @c kDrainTimeoutSecondsBeforeForcedStateTrackerCleanup seconds, before forcefully clearing
 * the state of GREYAppStateTracker.
 */
- (void)grey_forcedStateTrackerCleanUp;

@end
