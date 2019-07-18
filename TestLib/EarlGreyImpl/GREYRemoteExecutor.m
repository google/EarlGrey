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

#import "GREYRemoteExecutor.h"

#import "GREYFatalAsserts.h"

void GREYExecuteSyncBlockInBackgroundQueue(void (^block)(void)) {
  GREYFatalAssertMainThread();
  // This dispatches the EarlGrey call onto another thread so that the test's main thread
  // is freed up for handling any more events. Without this, deadlocks will be seen.
  // The timeout for the interaction is set to be forever since EarlGrey's interaction
  // should handle the interaction timeout.

  // The dispatch queue where the queries will be tunnelled to. Will be initialized only once.
  static dispatch_queue_t appProxyQueue;
  static dispatch_once_t token = 0;
  dispatch_once(&token, ^{
    appProxyQueue = dispatch_queue_create("com.google.earlgrey.egappproxyqueue",
                                         DISPATCH_QUEUE_SERIAL);
  });

  __block BOOL blockProcessed = NO;
  dispatch_block_t blockToStopMainRunloopSpinning =
      dispatch_block_create(DISPATCH_BLOCK_ASSIGN_CURRENT, ^{
        blockProcessed = YES;
        CFRunLoopStop(CFRunLoopGetCurrent());
      });
  __block NSException *blockException;
  dispatch_async(appProxyQueue, ^{
    @try {
      block();
    } @catch (NSException *exception) {
      blockException = exception;
    }
    dispatch_async(dispatch_get_main_queue(), blockToStopMainRunloopSpinning);
  });

  while (!blockProcessed) {
    CFRunLoopRun();
  }
  GREYFatalAssertWithMessage(
      !blockException,
      @"Exception occurred when processing background queue request in EarlGrey: %@",
      blockException.description);
  // Cancel any future executions of the CFRunLoopStop block.
  dispatch_block_cancel(blockToStopMainRunloopSpinning);
}
