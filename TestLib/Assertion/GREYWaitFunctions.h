//
// Copyright 2019 Google Inc.
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
 * Utilities for waiting for the app to synchronize. Used only from within
 * existing assertion defines. Should be used instead of GREYUIThreadExecutor
 * calls in the test as this synchronizes correctly using a background
 * execution queue in the test.
 */

/**
 * Waits for the application under test to idle. Similar to
 * GREYUIThreadExecutor:drainUntilIdleWithTimeout if the timeout was the
 * default interaction duration.
 *
 * @param[out] waitError An error populated if the application has idled.
 *
 * @return @c YES if the application idled successfully. @c NO otherwise.
 */
GREY_EXTERN BOOL GREYWaitForAppToIdleWithError(NSError **waitError);

/**
 * Waits for the application under test to idle before the specified timeout.
 *
 * @param      timeoutInSeconds A CFTimeInterval in seconds specifying by when
 *                              the application should idle.
 * @param[out] waitError        An error populated if the application has
 *                              idled.
 *
 * @return @c YES if the application idled successfully before the timeout.
 *         @c NO otherwise.
 */
GREY_EXTERN BOOL GREYWaitForAppToIdleWithTimeoutAndError(
    CFTimeInterval timeoutInSeconds, NSError **waitError);

/**
 * Processes other requests in the current thread's runloop for @c time, then
 * resumes execution. This is most commonly used on the main thread.
 *
 * When called from the main thread, the wait duration does not start counting
 * until previous operations on EarlGrey's background queue have completed, but
 * it has no synchronization relationship with any items added to the
 * background queue during the wait period. It does not synchronize with the
 * background queue at all if called from any other thread.
 *
 * @remark Please do not use this as a catch-all instead of an idling resource
 *         or GREYCondition.
 *
 * @param time A CFTimeInterval in seconds for which the test process will
 * sleep.
 */
GREY_EXTERN void GREYWaitForTime(CFTimeInterval time);
