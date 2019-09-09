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
#import "GREYConfiguration.h"
#import "GREYRemoteExecutor.h"

BOOL GREYWaitForAppToIdleWithError(NSError **waitError) {
  CFTimeInterval interactionTimeout = GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration);
  return GREYWaitForAppToIdleWithTimeout(interactionTimeout, waitError);
}

BOOL GREYWaitForAppToIdleWithTimeout(CFTimeInterval timeoutInSeconds, NSError **waitError) {
  __block BOOL success = NO;
  __block NSError *error;
  GREYExecuteSyncBlockInBackgroundQueue(^{
    success = [[GREYUIThreadExecutor sharedInstance] executeSyncWithTimeout:timeoutInSeconds
                                                                      block:nil
                                                                      error:&error];
  });
  if (!success) {
    *waitError = error;
  }
  return success;
}
