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

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Categpry on NSFileManager Provides interfaces for saving screenshots.
 */
@interface NSFileManager (GREYCommon)

/**
 *  Saves the provided @c image as a PNG to the given @c filename under the given @c directoryPath.
 *  If the given directory path doesn't exist, it will be created.
 *
 *  @param image         The source image.
 *  @param filename      The target file name.
 *  @param directoryPath The path to the directory where the image must be saved.
 *
 *  @return The complete filepath and name of the saved image or @c nil on failure.
 */
+ (NSString *)grey_saveImageAsPNG:(UIImage *)image
                           toFile:(NSString *)filename
                      inDirectory:(NSString *)directoryPath;

@end

NS_ASSUME_NONNULL_END
