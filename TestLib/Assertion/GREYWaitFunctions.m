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

#import "GREYWaitFunctions.h"

#import "GREYUIThreadExecutor.h"
#import "GREYConfigKey.h"
#import "GREYConfiguration.h"
#import "GREYRemoteExecutor.h"

BOOL GREYWaitForAppToIdleWithError(NSError **waitError) {
  CFTimeInterval interactionTimeout = GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration);
  return GREYWaitForAppToIdleWithTimeoutAndError(interactionTimeout, waitError);
}

BOOL GREYWaitForAppToIdleWithTimeoutAndError(CFTimeInterval timeoutInSeconds, NSError **waitError) {
  __block BOOL success = NO;
  __block NSError *error;
  GREYExecuteSyncBlockInBackgroundQueue(^{
    success = [[GREYUIThreadExecutor sharedInstance] executeSyncWithTimeout:timeoutInSeconds
                                                                      block:nil
                                                                      error:&error];
  });
  if (!success) {
    if (waitError) {
      *waitError = error;
    }
  }
  return success;
}

void GREYWaitForTime(CFTimeInterval time) {
  __block BOOL timer_fired = NO;

  // Interpret a wait for 0 time as a request to only drain existing items from
  // the background queue.
  if (time > 0) {
    CFRunLoopTimerRef wake_timer = CFRunLoopTimerCreateWithHandler(
        NULL, time + CFAbsoluteTimeGetCurrent(), 0, 0, 0, ^(CFRunLoopTimerRef ignored) {
          timer_fired = YES;
          CFRunLoopStop(CFRunLoopGetCurrent());
        });
    CFRunLoopAddTimer(CFRunLoopGetCurrent(), wake_timer, kCFRunLoopCommonModes);

    while (!timer_fired) {
      CFRunLoopRun();
    }

    // wake_timer is one-shot (interval == 0), so it removes itself from the runloop after it fires.
    // We don't need to use CFRunLoopRemoveTimer for it, but we do need to return the memory.
    CFRelease(wake_timer);
  }

  // A previous implementation waited by sleeping on the background queue, blocking it from making
  // progress. Blocking it was undesirable, but waiting for existing queued tasks to complete
  // might be an important side effect. Now that the background queue can keep working, it makes
  // more sense to wait for a block on it at the end of the wait period rather than the beginning
  // so any new work enqueued ruing the wait period can resolve.
  if ([NSThread isMainThread]) {
    GREYExecuteSyncBlockInBackgroundQueue(^{
    });
  }
}
