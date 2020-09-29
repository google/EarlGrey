//
// Copyright 2016 Google Inc.
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

#import "GREYSyncAPI.h"

#import "GREYFatalAsserts.h"

void grey_dispatch_sync_on_main_thread(void (^block)(void)) {
  if ([NSThread isMainThread]) {
    block();
  } else {
    dispatch_semaphore_t waitForBlock = dispatch_semaphore_create(0);
    CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopDefaultMode, ^{
      block();
      dispatch_semaphore_signal(waitForBlock);
    });
    // CFRunLoopPerformBlock does not wake up the main queue.
    CFRunLoopWakeUp(CFRunLoopGetMain());
    // Waits until block is executed and semaphore is signalled.
    dispatch_semaphore_wait(waitForBlock, DISPATCH_TIME_FOREVER);
  }
}

BOOL grey_check_condition_until_timeout(BOOL (^checkConditionBlock)(void), double timeout) {
  GREYFatalAssertWithMessage(checkConditionBlock != nil, @"Condition Block must not be nil.");
  GREYFatalAssertWithMessage(timeout > 0, @"Timeout has to be greater than zero.");
  CFTimeInterval startTime = CACurrentMediaTime();
  BOOL success = NO;
  while (!success && (CACurrentMediaTime() - startTime) < timeout) {
    // TODO(b/169537945): Drain the runloop in the EarlGrey active mode.
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, NO);
    success = checkConditionBlock();
  }
  return success;
}
