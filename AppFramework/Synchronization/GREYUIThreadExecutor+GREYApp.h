//
// Copyright 2020 Google Inc.
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

/**
 * @file  GREYUIThreadExecutor+Internal.h
 * @brief Exposes GREYUIThreadExecutor methods that are to be used only in the application-process
 *        or for testing purposes.
 *
 * @remark DO NOT call these methods in the test side as they can lead to deadlocks. Use the wait
 *         methods in GREYAssertionDefines.h or GREYWaitFunctions.h instead.
 */

#import "GREYUIThreadExecutor.h"

@protocol GREYIdlingResource;

@interface GREYUIThreadExecutor (GREYApp)

/**
 * Blocking call that drains the main runloop enough times to make each source gets a fair chance
 * of service. No guarantee is made on whether the app is in kGREYIdle state after this method
 * returns.
 */
- (void)drainOnce;

/**
 * Blocking call that drains the UI thread for the specified number of @c seconds.
 * This method can block for longer than the specified time if any of the signalled sources take
 * longer than that to execute.
 *
 * @param seconds Amount of time that the UI thread should be drained for, in seconds.
 */
- (void)drainForTime:(CFTimeInterval)seconds;

/**
 * Blocking call that drains the UI thread until both the UI and registered GREYIdlingResources
 * are in idle.
 *
 * @remark Be very careful while calling this as you could end up in state where the caller expects
 *         the callee to mark the thread as idle and callee inadvertently calls
 *         GREYUIThreadExecutor::drainUntilIdle:, in which case it will go into an infinite loop
 *         and the test will have to be force-exited by the test-runner.
 */
- (void)drainUntilIdle;

/**
 * Drains the UI thread and waits for both the UI and idling resources to idle until the given
 * amount of @c seconds have passed, at which point, a timeout occurs and the method returns @c NO.
 * Returns @c YES if idled within @c seconds, @c NO otherwise.
 *
 * @param seconds Amount of time to wait for the UI and idling resources to idle.
 *
 * @return @c YES if idled within @c seconds, @c NO otherwise.
 */
- (BOOL)drainUntilIdleWithTimeout:(CFTimeInterval)seconds;

@end
