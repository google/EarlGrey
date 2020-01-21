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
#import "EarlGreyImpl+XCUIApplication.h"

@interface ApplicationStateHandlingTest : XCTestCase
@end

@implementation ApplicationStateHandlingTest {
  XCUIApplication *_application;
}

- (void)setUp {
  [super setUp];
  _application = [[XCUIApplication alloc] init];
  [_application launch];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Picker Views")] performAction:grey_tap()];
}

- (void)tearDown {
  NSError *rotateError;
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationPortrait error:&rotateError];
  XCTAssertNil(rotateError);
  [super tearDown];
}

- (void)testBottomDockInIPadInPortrait {
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
    [self openBottomDockInLandscape:NO];
    [self closeBottomDockInLandscape:NO];
  }
}

- (void)testBottomDockInIPadInLandscape {
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
    // Rotate to Landscape Left orientation.
    NSError *rotateError;
    [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeLeft error:&rotateError];
    XCTAssertNil(rotateError);

    [self openBottomDockInLandscape:YES];
    [self closeBottomDockInLandscape:YES];
  }
}

- (void)testBackgroundingAndForegrounding {
  BOOL success = [EarlGrey backgroundApplication];
  XCTAssertTrue(success);
  NSString *applicationBundleID = @"com.google.earlgreyftr.dev";
  XCUIApplication *application = [EarlGrey foregroundApplicationWithBundleID:applicationBundleID
                                                                       error:nil];
  XCTAssertNotNil(application);
  [[EarlGrey selectElementWithMatcher:grey_keyWindow()]
      assertWithMatcher:grey_sufficientlyVisible()];
  XCTAssertNoThrow([EarlGrey foregroundApplicationWithBundleID:applicationBundleID error:nil]);
}

// Flakiness will be seen in these tests since the wait times for launching an app were too small
// (10 seconds). On filing an applebug for this, the timeout has been extended to 30 seconds.
- (void)testOpenSettingsApplicationAndReturning_flaky {
  XCUIApplication *settingsApp =
      [EarlGrey foregroundApplicationWithBundleID:@"com.apple.Preferences" error:nil];
  XCTAssertTrue([settingsApp.staticTexts[@"General"] waitForExistenceWithTimeout:30]);
  [_application activate];
  [[EarlGrey selectElementWithMatcher:grey_keyWindow()]
      assertWithMatcher:grey_sufficientlyVisible()];
}

#pragma mark - Test app relaunch

/**
 *  Test launching app post termination without causing issues in loading
 *  the `AppFramework` library injected using DYLD_INSERT_LIBRARIES.
 */
- (void)testApplicationRestartOnce {
  [_application terminate];
  [_application launch];
  [[EarlGrey selectElementWithMatcher:grey_keyWindow()]
      assertWithMatcher:grey_sufficientlyVisible()];
}

/**
 *  Test by relaunching twice.
 */
- (void)testApplicationRestartTwice {
  [_application terminate];
  [_application launch];
  [[EarlGrey selectElementWithMatcher:grey_keyWindow()]
      assertWithMatcher:grey_sufficientlyVisible()];
    
  [_application terminate];
  [_application launch];
  [[EarlGrey selectElementWithMatcher:grey_keyWindow()]
      assertWithMatcher:grey_sufficientlyVisible()];
}

#pragma mark - End Test app relaunch

- (void)openBottomDockInLandscape:(BOOL)isLandscape {
  XCUIApplication *springboardApplication =
      [[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.springboard"];
  CGVector startVector = isLandscape ? CGVectorMake(0.0, 0.5) : CGVectorMake(0.5, 1.0);
  XCUICoordinate *startCoordinate =
      [[springboardApplication.windows firstMatch] coordinateWithNormalizedOffset:startVector];
  CGVector endVector = isLandscape ? CGVectorMake(200.0f, 0.5f) : CGVectorMake(0.5f, -200.0f);
  XCUICoordinate *endCoordinate = [startCoordinate coordinateWithOffset:endVector];
  [startCoordinate pressForDuration:0 thenDragToCoordinate:endCoordinate];

  XCTAssertTrue([springboardApplication.otherElements[@"Dock"] isHittable]);
  [[EarlGrey selectElementWithMatcher:grey_keyWindow()] performAction:grey_tap()];
}

- (void)closeBottomDockInLandscape:(BOOL)isLandscape {
  XCUIApplication *springboardApplication =
      [[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.springboard"];
  CGVector startReverseVector = isLandscape ? CGVectorMake(0.20, 0.5) : CGVectorMake(0.5, 0.85);
  XCUICoordinate *startReverseCoordinate = [[springboardApplication.windows firstMatch]
      coordinateWithNormalizedOffset:startReverseVector];
  CGVector endReverseVector =
      isLandscape ? CGVectorMake(-200.0f, 0.5f) : CGVectorMake(0.5f, 200.0f);
  XCUICoordinate *endReverseCoordinate =
      [startReverseCoordinate coordinateWithOffset:endReverseVector];
  [startReverseCoordinate pressForDuration:0 thenDragToCoordinate:endReverseCoordinate];
  XCTAssertFalse([springboardApplication.otherElements[@"Dock"] exists]);
}

@end
