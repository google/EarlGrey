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

NS_ASSUME_NONNULL_BEGIN

/**
 *  Saves screenshot images in a provided dictionary to disk.
 */
@interface GREYFailureScreenshotSaver : NSObject

/**
 *  Saves the screenshots in the @c screenshotsDict to the path specified in @c screenshotDir.
 *
 *  @param screenshotsDict  An NSDictionary containing the image type and the screenshots
 *                          themselves.
 *  @param screenshotPrefix A prefix to add to the screenshots as they are saved.
 *  @param screenshotDir    The directory path to save the screenshots in.
 *
 *  @return An NSArray containing the paths of the images saved to disk.
 */
+ (NSArray *)saveFailureScreenshotsInDictionary:(NSDictionary *)screenshotsDict
                           withScreenshotPrefix:(NSString *)screenshotPrefix
                                    toDirectory:(NSString *)screenshotDir;
@end

NS_ASSUME_NONNULL_END
