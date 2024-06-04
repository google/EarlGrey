//
// Copyright 2018 Google Inc.
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
#import "EarlGrey.h"
#import "BaseIntegrationTest.h"

@interface ScreenshotTest : BaseIntegrationTest
@end

@implementation ScreenshotTest {
  UIInterfaceOrientation _originalOrientation;
}

- (void)setUp {
  [super setUp];
  UIApplication *sharedApp = [GREY_REMOTE_CLASS_IN_APP(UIApplication) sharedApplication];
  _originalOrientation = sharedApp.windows.firstObject.windowScene.interfaceOrientation;
}

- (void)tearDown {
  // Undo orientation changes after test is finished.
  [EarlGrey rotateDeviceToOrientation:(UIDeviceOrientation)_originalOrientation error:nil];
  [super tearDown];
}

- (void)testSnapshotComparison {
  [self openTestViewNamed:@"Accessibility Views"];

  // Snapshot Accessibility Element.
  UIImage *snapshot =
      [self snapshotElementWithMatcher:GREYAccessibilityLabel(@"OnScreenRectangleElementLabel")];
  UIImage *snapshotCopy =
      [self snapshotElementWithMatcher:GREYAccessibilityLabel(@"OnScreenRectangleElementLabel")];

  NSData *snapshotData = UIImagePNGRepresentation(snapshot);
  NSData *snapshotCopyData = UIImagePNGRepresentation(snapshotCopy);
  GREYAssertEqualObjects(snapshotData, snapshotCopyData, @"should be equal");
}

- (void)testSnapshotAXElementInPortraitMode {
  [self openTestViewNamed:@"Accessibility Views"];

  // Snapshot Accessibility Element.
  UIImage *snapshot =
      [self snapshotElementWithMatcher:GREYAccessibilityLabel(@"OnScreenRectangleElementLabel")];

  // TODO: Verify the content of the image as well. // NOLINT
  CGSize expectedSize = CGSizeMake(64, 128);
  UIScreen *mainScreen = (UIScreen *)[GREY_REMOTE_CLASS_IN_APP(GREYUILibUtils) screen];
  CGFloat expectedScale = mainScreen.scale;
  GREYAssertEqual(expectedSize.width, snapshot.size.width, @"should be equal");
  GREYAssertEqual(expectedSize.height, snapshot.size.height, @"should be equal");
  GREYAssertEqual(expectedScale, snapshot.scale, @"should be equal");

  NSError *error = nil;
  // Snapshot Accessibility Element with zero height should be an error.
  snapshot =
      [self snapshotElementWithMatcher:grey_accessibilityID(@"ElementWithZeroHeightIdentifier")
                                 error:&error];
  GREYAssertEqualObjects(kGREYInteractionErrorDomain, error.domain, @"should be equal");
}

- (void)testSnapshotAXElementInLandscapeMode {
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeLeft error:nil];
  [self openTestViewNamed:@"Accessibility Views"];

  // Snapshot Accessibility Element.
  UIImage *snapshot =
      [self snapshotElementWithMatcher:GREYAccessibilityLabel(@"OnScreenRectangleElementLabel")];

  // TODO: Verify the content of the image as well. // NOLINT
  CGSize expectedSize = CGSizeMake(64, 128);

  UIScreen *mainScreen = (UIScreen *)[GREY_REMOTE_CLASS_IN_APP(GREYUILibUtils) screen];
  CGFloat expectedScale = mainScreen.scale;
  GREYAssertEqual(expectedSize.width, snapshot.size.width, @"should be equal");
  GREYAssertEqual(expectedSize.height, snapshot.size.height, @"should be equal");
  GREYAssertEqual(expectedScale, snapshot.scale, @"should be equal");

  NSError *error = nil;
  // Snapshot Accessibility Element with zero height should be an error.
  snapshot =
      [self snapshotElementWithMatcher:grey_accessibilityID(@"ElementWithZeroHeightIdentifier")
                                 error:&error];
  GREYAssertEqualObjects(kGREYInteractionErrorDomain, error.domain, @"should be equal");
}

- (void)testTakeScreenShotInPortraitMode {
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationPortrait error:nil];
  UIImage *screenshot = [self snapshotElementWithMatcher:GREYKeyWindow()];
  GREYAssert(screenshot, @"Failed to take screenshot");

  CGRect actualRect = CGRectMake(0, 0, screenshot.size.width, screenshot.size.height);
  GREYAssertTrue(CGRectEqualToRect(actualRect, [self expectedImageRect]),
                 @"Screenshot isn't correct dimension");
}

- (void)testTakeScreenShotInPortraitUpsideDownMode {
  if (@available(iOS 16.0, *)) {
    // PortraitUpsideDown mode is unavailable in iOS16
    return;
  }
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationPortraitUpsideDown error:nil];
  UIImage *screenshot = [self snapshotElementWithMatcher:GREYKeyWindow()];
  GREYAssert(screenshot, @"Failed to take screenshot");

  CGRect actualRect = CGRectMake(0, 0, screenshot.size.width, screenshot.size.height);
  GREYAssertTrue(CGRectEqualToRect(actualRect, [self expectedImageRect]),
                 @"Screenshot isn't correct dimension");
}

- (void)testTakeScreenShotInLandscapeLeftMode {
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeLeft error:nil];

  UIImage *screenshot = [self snapshotElementWithMatcher:GREYKeyWindow()];
  GREYAssert(screenshot, @"Failed to take screenshot");

  CGRect actualRect = CGRectMake(0, 0, screenshot.size.width, screenshot.size.height);
  GREYAssertTrue(CGRectEqualToRect(actualRect, [self expectedImageRect]),
                 @"Screenshot isn't correct dimension");
}

- (void)testTakeScreenShotInLandscapeRightMode {
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeRight error:nil];

  UIImage *screenshot = [self snapshotElementWithMatcher:GREYKeyWindow()];
  GREYAssert(screenshot, @"Failed to take screenshot");

  CGRect actualRect = CGRectMake(0, 0, screenshot.size.width, screenshot.size.height);
  GREYAssertTrue(CGRectEqualToRect(actualRect, [self expectedImageRect]),
                 @"Screenshot isn't correct dimension");
}

- (void)testUIStatusBarWindowNotPresentOnIOS13 {
  if (iOS13_OR_ABOVE()) {
    GREYElementInteraction *interaction =
        [EarlGrey selectElementWithMatcher:GREYKindOfClassName(@"UIStatusBarWindow")];
    [[interaction includeStatusBar] assertWithMatcher:GREYNil()];
  }
}


#pragma mark - Private

- (UIImage *)snapshotElementWithMatcher:(id<GREYMatcher>)matcher {
  return [self snapshotElementWithMatcher:matcher error:nil];
}

- (UIImage *)snapshotElementWithMatcher:(id<GREYMatcher>)matcher error:(NSError **)error {
  EDORemoteVariable<UIImage *> *snapshot = [[EDORemoteVariable alloc] init];
  [[EarlGrey selectElementWithMatcher:matcher] performAction:GREYSnapshot(snapshot) error:error];
  return snapshot.object;
}

/** The screenshot rect for the application under test. */
- (CGRect)expectedImageRect {
  UIScreen *mainScreen = (UIScreen *)[GREY_REMOTE_CLASS_IN_APP(GREYUILibUtils) screen];
  CGRect screenRect = mainScreen.bounds;
  return screenRect;
}

@end
