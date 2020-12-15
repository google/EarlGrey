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
#import "GREYFailureScreenshotSaver.h"

#import "NSFileManager+GREYCommon.h"
#import "GREYConfigKey.h"
#import "GREYConfiguration.h"
#import "GREYError.h"
#import "GREYFrameworkException.h"

typedef NSDictionary<NSString *, UIImage *> *GREYScreenshotImages;

@implementation GREYFailureScreenshotSaver

+ (GREYFailureScreenshots *)saveFailureScreenshotsInDictionary:(GREYScreenshotImages)screenshotsDict
                                                   toDirectory:(NSString *)screenshotDir {
  NSMutableDictionary<NSString *, NSString *> *screenshotPaths = [[NSMutableDictionary alloc] init];

  // Save and log screenshot, before and after images (if available).
  UIImage *screenshot = screenshotsDict[kGREYAppScreenshotAtFailure];
  if (screenshot) {
    NSString *screenshotSuffix = @"app_screenshot.png";
    screenshotPaths[kGREYAppScreenshotAtFailure] =
        [NSFileManager grey_saveImageAsPNG:screenshot
                                    toFile:screenshotSuffix
                               inDirectory:screenshotDir];
  }

  screenshot = screenshotsDict[kGREYTestScreenshotAtFailure];
  if (screenshot) {
    NSString *screenshotSuffix = @"test_screenshot.png";
    screenshotPaths[kGREYTestScreenshotAtFailure] =
        [NSFileManager grey_saveImageAsPNG:screenshot
                                    toFile:screenshotSuffix
                               inDirectory:screenshotDir];
  }

  screenshot = screenshotsDict[kGREYScreenshotBeforeImage];
  if (screenshot) {
    NSString *beforeScreenshotSuffix = @"visibility_before.png";
    screenshotPaths[kGREYScreenshotBeforeImage] =
        [NSFileManager grey_saveImageAsPNG:screenshot
                                    toFile:beforeScreenshotSuffix
                               inDirectory:screenshotDir];
  }

  screenshot = screenshotsDict[kGREYScreenshotExpectedAfterImage];
  if (screenshot) {
    NSString *afterExpectedScreenshotSuffix = @"visibility_after_expected.png";
    screenshotPaths[kGREYScreenshotExpectedAfterImage] =
        [NSFileManager grey_saveImageAsPNG:screenshot
                                    toFile:afterExpectedScreenshotSuffix
                               inDirectory:screenshotDir];
  }

  screenshot = screenshotsDict[kGREYScreenshotActualAfterImage];
  if (screenshot) {
    NSString *afterActualScreenshotSuffix = @"visibility_after_actual.png";
    screenshotPaths[kGREYScreenshotActualAfterImage] =
        [NSFileManager grey_saveImageAsPNG:screenshot
                                    toFile:afterActualScreenshotSuffix
                               inDirectory:screenshotDir];
  }
  return [screenshotPaths copy];
}

+ (NSString *)failureScreenshotPathForException:(nullable GREYFrameworkException *)exception {
  NSString *uniqueSubDirName =
      [NSString stringWithFormat:@"%@-%@", exception.name, [[NSUUID UUID] UUIDString]];
  return [GREY_CONFIG_STRING(kGREYConfigKeyArtifactsDirLocation)
      stringByAppendingPathComponent:uniqueSubDirName];
}

@end
