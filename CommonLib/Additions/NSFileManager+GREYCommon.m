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

#import "NSFileManager+GREYCommon.h"

#import "GREYDefines.h"

@implementation NSFileManager (GREYCommon)

+ (NSString *)grey_saveImageAsPNG:(UIImage *)image
                           toFile:(NSString *)filename
                      inDirectory:(NSString *)directoryPath {
  NSParameterAssert(image);
  NSParameterAssert(filename);
  NSParameterAssert(directoryPath);

  // Create screenshot dir and its parent directories if any of them don't exist
  NSError *error;
  if (![[NSFileManager defaultManager] createDirectoryAtPath:directoryPath
                                 withIntermediateDirectories:YES
                                                  attributes:nil
                                                       error:&error]) {
    NSLog(@"Could not create screenshot directory \"%@\": %@", directoryPath,
          [error localizedDescription]);
    return nil;
  }

  NSString *filePath = [directoryPath stringByAppendingPathComponent:filename];
  // UIImagePNGRepresentation will not store imageOrientation metadata nor rotate the image;
  // we must redraw pixels in the correct orientation before saving it.
  UIImage *orientedImage = [self grey_imageAfterApplyingOrientation:image];

  if ([UIImagePNGRepresentation(orientedImage) writeToFile:filePath atomically:YES]) {
    return filePath;
  } else {
    NSLog(@"Could not write image to file '%@'", filePath);
    return nil;
  }
}

#pragma mark - Private

/**
 *  @return An image with the given @c image redrawn in the orientation defined by its
 *          imageOrientation property.
 */
+ (UIImage *)grey_imageAfterApplyingOrientation:(UIImage *)image {
  if (image.imageOrientation == UIImageOrientationUp) {
    return image;
  }

  UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
  CGRect imageRect = CGRectMake(0, 0, image.size.width, image.size.height);
  [image drawInRect:imageRect];
  UIImage *rotatedImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return rotatedImage;
}

@end
