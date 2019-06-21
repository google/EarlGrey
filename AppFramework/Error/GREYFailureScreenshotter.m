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

#import "GREYFailureScreenshotter.h"

#import "GREYSyncAPI.h"
#import "GREYConfiguration.h"
#import "GREYError.h"
#import "GREYScreenshotter+Private.h"
#import "GREYScreenshotter.h"
#import "GREYVisibilityChecker+Private.h"

@implementation GREYFailureScreenshotter

+ (NSDictionary *)screenshots {
  NSMutableDictionary *appScreenshots = [[NSMutableDictionary alloc] init];
  __block UIImage *screenshot;
  grey_dispatch_sync_on_main_thread(^{
    screenshot = [GREYScreenshotter grey_takeScreenshotAfterScreenUpdates:NO withStatusBar:NO];
  });

  if (screenshot) {
    appScreenshots[kGREYScreenshotAtFailure] = screenshot;
  }

  screenshot = [GREYVisibilityChecker grey_lastActualBeforeImage];
  if (screenshot) {
    appScreenshots[kGREYScreenshotBeforeImage] = screenshot;
  }

  screenshot = [GREYVisibilityChecker grey_lastExpectedAfterImage];
  if (screenshot) {
    appScreenshots[kGREYScreenshotExpectedAfterImage] = screenshot;
  }

  screenshot = [GREYVisibilityChecker grey_lastActualAfterImage];
  if (screenshot) {
    appScreenshots[kGREYScreenshotActualAfterImage] = screenshot;
  }

  return appScreenshots;
}

@end
