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
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NSDictionary<NSString *, NSString *> GREYFailureScreenshots;

/**
 *  Saves screenshot images in a provided dictionary to disk.
 */
@interface GREYFailureScreenshotSaver : NSObject

/**
 *  Saves the screenshots in the @c screenshotsDict to the path specified in @c screenshotDir.
 *
 *  @param screenshotsDict A NSDictionary containing the image type and the screenshots
 *                         themselves.
 *  @param screenshotDir   The directory path to save the screenshots in.
 *
 *  @return A NSDictionary containing the paths of the images saved to disk with the keys as the
 *          titles of the images.
 */
+ (GREYFailureScreenshots *)saveFailureScreenshotsInDictionary:
                                (NSDictionary<NSString *, UIImage *> *)screenshotsDict
                                                   toDirectory:(NSString *)screenshotDir;
@end

NS_ASSUME_NONNULL_END
