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

#import "FTRBaseIntegrationTest.h"

@interface FTRScreenshotTest : FTRBaseIntegrationTest
@end

@implementation FTRScreenshotTest {
  UIInterfaceOrientation _originalOrientation;
}

- (void)setUp {
  [super setUp];
  _originalOrientation =
      [[GREY_REMOTE_CLASS_IN_APP(UIApplication) sharedApplication] statusBarOrientation];
}

- (void)tearDown {
  // Undo orientation changes after test is finished.
  [EarlGrey rotateDeviceToOrientation:(UIDeviceOrientation)_originalOrientation error:nil];
  [super tearDown];
}

- (void)testSnapshotComparison {
  [self openTestViewNamed:@"Accessibility Views"];

  EDORemoteVariable<UIImage *> *snapshot = [[EDORemoteVariable alloc] init];
  EDORemoteVariable<UIImage *> *snapshotCopy = [[EDORemoteVariable alloc] init];
  // Snapshot Accessibility Element.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"OnScreenRectangleElementLabel")]
      performAction:grey_snapshot(snapshot)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"OnScreenRectangleElementLabel")]
      performAction:grey_snapshot(snapshotCopy)];

  NSData *snapshotData = UIImagePNGRepresentation(snapshot.object);
  NSData *snapshotCopyData = UIImagePNGRepresentation(snapshotCopy.object);
  GREYAssertEqualObjects(snapshotData, snapshotCopyData, @"should be equal");
}

- (void)testSnapshotAXElementInPortraitMode {
  [self openTestViewNamed:@"Accessibility Views"];

  EDORemoteVariable<UIImage *> *snapshot = [[EDORemoteVariable alloc] init];
  // Snapshot Accessibility Element.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"OnScreenRectangleElementLabel")]
      performAction:grey_snapshot(snapshot)];

  // TODO: Verify the content of the image as well. // NOLINT
  CGSize expectedSize = CGSizeMake(64, 128);
  CGFloat expectedScale = [GREY_REMOTE_CLASS_IN_APP(UIScreen) mainScreen].scale;
  GREYAssertEqual(expectedSize.width, snapshot.object.size.width, @"should be equal");
  GREYAssertEqual(expectedSize.height, snapshot.object.size.height, @"should be equal");
  GREYAssertEqual(expectedScale, snapshot.object.scale, @"should be equal");

  NSError *error = nil;
  // Snapshot Accessibility Element with zero height should be an error.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"ElementWithZeroHeight")]
      performAction:grey_snapshot(snapshot)
              error:&error];
  GREYAssertEqualObjects(kGREYInteractionErrorDomain, error.domain, @"should be equal");
}

- (void)testSnapshotAXElementInLandscapeMode {
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeLeft error:nil];
  [self openTestViewNamed:@"Accessibility Views"];

  EDORemoteVariable<UIImage *> *snapshot = [[EDORemoteVariable alloc] init];
  // Snapshot Accessibility Element.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"OnScreenRectangleElementLabel")]
      performAction:grey_snapshot(snapshot)];

  // TODO: Verify the content of the image as well. // NOLINT
  CGSize expectedSize = CGSizeMake(64, 128);
  if (!iOS8_0_OR_ABOVE()) {
    // Width and height are interchanged on versions before iOS 8.0
    expectedSize = CGSizeMake(expectedSize.height, expectedSize.width);
  }
  CGFloat expectedScale = [GREY_REMOTE_CLASS_IN_APP(UIScreen) mainScreen].scale;
  GREYAssertEqual(expectedSize.width, snapshot.object.size.width, @"should be equal");
  GREYAssertEqual(expectedSize.height, snapshot.object.size.height, @"should be equal");
  GREYAssertEqual(expectedScale, snapshot.object.scale, @"should be equal");

  NSError *error = nil;
  // Snapshot Accessibility Element with zero height should be an error.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"ElementWithZeroHeight")]
      performAction:grey_snapshot(snapshot)
              error:&error];
  GREYAssertEqualObjects(kGREYInteractionErrorDomain, error.domain, @"should be equal");
}

// Tests to be run only on iOS 11 since we need the new XCUIScreen API.
#if defined(__IPHONE_11_0)

- (void)testTakeScreenShotForAppStoreInPortraitMode {
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationPortrait error:nil];
  UIImage *screenshot = [XCUIScreen mainScreen].screenshot.image;
  GREYAssert(screenshot, @"Failed to take screenshot");

  CGRect actualRect = CGRectMake(0, 0, screenshot.size.width, screenshot.size.height);
  GREYAssertTrue(CGRectEqualToRect(actualRect, [self ftr_expectedImageRectForAppStore]),
                 @"Screenshot isn't correct dimension");
}

- (void)testTakeScreenShotForAppStoreInPortraitUpsideDownMode {
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationPortraitUpsideDown error:nil];
  UIImage *screenshot = [XCUIScreen mainScreen].screenshot.image;
  GREYAssert(screenshot, @"Failed to take screenshot");

  CGRect actualRect = CGRectMake(0, 0, screenshot.size.width, screenshot.size.height);
  GREYAssertTrue(CGRectEqualToRect(actualRect, [self ftr_expectedImageRectForAppStore]),
                 @"Screenshot isn't correct dimension");
}

- (void)testTakeScreenShotForAppStoreInLandscapeLeftMode {
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeLeft error:nil];

  UIImage *screenshot = [XCUIScreen mainScreen].screenshot.image;
  GREYAssert(screenshot, @"Failed to take screenshot");

  CGRect actualRect = CGRectMake(0, 0, screenshot.size.width, screenshot.size.height);
  GREYAssertTrue(CGRectEqualToRect(actualRect, [self ftr_expectedImageRectForAppStore]),
                 @"Screenshot isn't correct dimension");
}

- (void)testTakeScreenShotForAppStoreInLandscapeRightMode {
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeRight error:nil];

  UIImage *screenshot = [XCUIScreen mainScreen].screenshot.image;
  GREYAssert(screenshot, @"Failed to take screenshot");

  CGRect actualRect = CGRectMake(0, 0, screenshot.size.width, screenshot.size.height);
  GREYAssertTrue(CGRectEqualToRect(actualRect, [self ftr_expectedImageRectForAppStore]),
                 @"Screenshot isn't correct dimension");
}

- (void)testAddingTheStatusBarToTheInteraction {
  GREYElementInteraction *interaction =
      [EarlGrey selectElementWithMatcher:grey_kindOfClassName(@"UIStatusBarWindow")];
  [[interaction includeStatusBar] assertWithMatcher:grey_notNil()];
}

#endif

#pragma mark - Private

- (CGRect)ftr_expectedImageRectForAppStore {
  CGRect screenRect = [GREY_REMOTE_CLASS_IN_APP(UIScreen) mainScreen].bounds;
  UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;

  BOOL isLandscape = (orientation == UIInterfaceOrientationLandscapeLeft ||
                      orientation == UIInterfaceOrientationLandscapeRight);
  // Pre-iOS 8, interface is in fixed screen coordinates. We need to rotate it.
  if ([UIDevice currentDevice].systemVersion.intValue < 8 && isLandscape) {
    screenRect = CGRectMake(0, 0, screenRect.size.height, screenRect.size.width);
  }
  return screenRect;
}

@end
