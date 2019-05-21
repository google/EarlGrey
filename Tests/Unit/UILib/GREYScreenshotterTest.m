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

#import <XCTest/XCTest.h>

#import "CommonLib/GREYSwizzler.h"
#import "Tests/Unit/UILib/GREYBaseTest.h"
#import "UILib/GREYScreenshotter.h"

// Constant for a dummy screenshot directory.
static NSString *const kDummyScreenshotDir = @"dummyScreenshotDir";

@interface GREYScreenshotterTest : GREYBaseTest
@end

@implementation GREYScreenshotterTest

- (void)testNoExceptionOnValidImageDir {
  NSArray *searchPaths =
      NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *screenshotDir = searchPaths.firstObject;
  NSString *filename = @"dummyFileName";
  // The original saveImageAsPNG was swizzled by GREYBaseTest, so check the original version.
  XCTAssertThrowsSpecificNamed([GREYScreenshotter greyswizzled_fakeSaveImageAsPNG:nil
                                                                           toFile:filename
                                                                      inDirectory:screenshotDir],
                               NSException, NSInternalInconsistencyException);
}

- (void)testNoExceptionOnValidImageDirAndImage {
  NSArray *searchPaths =
      NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *filename = @"dummyFileName";
  UIImage *image1 = [UIImage imageNamed:@"image.png"];

  CGSize newSize = CGSizeMake(1, 1);
  UIGraphicsBeginImageContext(newSize);

  [image1 drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
  UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();

  UIGraphicsEndImageContext();
  XCTAssertNoThrow([GREYScreenshotter greyswizzled_fakeSaveImageAsPNG:finalImage
                                                               toFile:filename
                                                          inDirectory:searchPaths.firstObject]);
}

- (void)testExceptionOnNilImage {
  NSString *filename = @"dummyFileName";
  // The original saveImageAsPNG was swizzled by GREYBaseTest, so check the original version.
  XCTAssertThrowsSpecificNamed(
      [GREYScreenshotter greyswizzled_fakeSaveImageAsPNG:nil
                                                  toFile:filename
                                             inDirectory:kDummyScreenshotDir],
      NSException, NSInternalInconsistencyException);
}

- (void)testExceptionOnNilFileName {
  UIImage *image = [[UIImage alloc] init];
  // The original saveImageAsPNG was swizzled by GREYBaseTest, so check the original version.
  XCTAssertThrowsSpecificNamed(
      [GREYScreenshotter greyswizzled_fakeSaveImageAsPNG:image
                                                  toFile:nil
                                             inDirectory:kDummyScreenshotDir],
      NSException, NSInternalInconsistencyException);
}

- (void)testExceptionOnNilScreenshotDir {
  UIImage *image = [[UIImage alloc] init];
  NSString *filename = @"dummyFileName";

  // The original saveImageAsPNG was swizzled by GREYBaseTest, so check the original version.
  XCTAssertThrowsSpecificNamed([GREYScreenshotter greyswizzled_fakeSaveImageAsPNG:image
                                                                           toFile:filename
                                                                      inDirectory:nil],
                               NSException, NSInternalInconsistencyException);
}

- (void)testScreenshotSucceedsOnCorrectValues {
  UIImage *image = [[UIImage alloc] init];
  NSString *filename = @"dummyFileName";
  // The original saveImageAsPNG was swizzled by GREYBaseTest, so check the original version.
  XCTAssertNoThrow([GREYScreenshotter greyswizzled_fakeSaveImageAsPNG:image
                                                               toFile:filename
                                                          inDirectory:kDummyScreenshotDir]);
}

- (void)testSnapshotInvalidUIView {
  UIView *element = [[UIView alloc] initWithFrame:CGRectMake(1, 1, 0, 5)];
  UIImage *image = [GREYScreenshotter snapshotElement:element];
  XCTAssertNil(image);

  element = [[UIView alloc] initWithFrame:CGRectMake(2, 2, 5, 0)];
  image = [GREYScreenshotter snapshotElement:element];
  XCTAssertNil(image);

  image = [GREYScreenshotter snapshotElement:nil];
  XCTAssertNil(image);
}

- (void)testSnapshotInvalidAccessibilityElement {
  UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  UIAccessibilityElement *element =
      [[UIAccessibilityElement alloc] initWithAccessibilityContainer:container];
  element.accessibilityFrame = CGRectMake(1, 1, 0, 5);
  UIImage *image = [GREYScreenshotter snapshotElement:element];
  XCTAssertNil(image);

  element.accessibilityFrame = CGRectMake(2, 2, 5, 0);
  image = [GREYScreenshotter snapshotElement:element];
  XCTAssertNil(image);

  image = [GREYScreenshotter snapshotElement:nil];
  XCTAssertNil(image);
}

@end
