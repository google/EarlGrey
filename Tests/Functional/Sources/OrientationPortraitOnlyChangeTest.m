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

#import "EarlGrey.h"
#import "GREYHostApplicationDistantObject+PortraitOnlyOrientationTest.h"
#import "BaseIntegrationTest.h"

@interface OrientationPortraitOnlyChangeTest : BaseIntegrationTest
@end

@implementation OrientationPortraitOnlyChangeTest

- (void)setUp {
  [super setUp];
  GREYAssert([[GREYHostApplicationDistantObject sharedInstance] blockNonPortraitOrientations],
             @"Could not block non-portrait orientations.");
}

- (void)tearDown {
  // Run BaseIntegrationTest teardown (restoring the failure handler and resetting the navigation
  // stack) before unswizzling the portrait lock, which otherwise triggers an immediate rotation to
  // the current XCUIDevice orientation.
  [super tearDown];
  GREYAssert([[GREYHostApplicationDistantObject sharedInstance] unblockNonPortraitOrientations],
             @"Failed to undo the blocking of non-portrait orientations.");
  [EarlGrey rotateInterfaceToOrientation:UIInterfaceOrientationPortrait error:nil];
}

- (void)testRotateToUnsupportedOrientation {
  UIWindowScene *scene = [GREY_REMOTE_CLASS_IN_APP(GREYUILibUtils) activeWindowScene];
  if (@available(iOS 16, *)) {
    NSError *error;
    BOOL success = [EarlGrey rotateInterfaceToOrientation:UIInterfaceOrientationLandscapeLeft
                                                    error:&error];
    XCTAssertFalse(success, @"Rotation to unsupported orientation should return NO.");
    XCTAssertNotNil(error, @"Unsupported orientations should error out in iOS 16+.");
    XCTAssertTrue(
        [error.userInfo[@"Recovery Suggestion"] containsString:@"Verify if orientation is locked"]);
    XCTAssertNotNil(error.userInfo[@"Description"],
                    @"Error should include underlying geometry update error details.");

    GREYAssertTrue(UIInterfaceOrientationIsPortrait(scene.effectiveGeometry.interfaceOrientation),
                   @"Interface orientation should remain portrait");
  } else {
    [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeLeft error:nil];
    UIDeviceOrientation appOrientation =
        [GREY_REMOTE_CLASS_IN_APP(UIDevice) currentDevice].orientation;
    GREYAssertEqual(appOrientation, UIDeviceOrientationLandscapeLeft,
                    @"Device orientation should now be landscape left");
    GREYAssertTrue(UIInterfaceOrientationIsPortrait(scene.interfaceOrientation),
                   @"Interface orientation should remain portrait");
  }
}

- (void)testDeviceChangeWithoutInterfaceChange {
  UIWindowScene *scene = [GREY_REMOTE_CLASS_IN_APP(GREYUILibUtils) activeWindowScene];
  if (@available(iOS 16, *)) {
    NSError *error;
    BOOL success = [EarlGrey rotateInterfaceToOrientation:UIInterfaceOrientationLandscapeLeft
                                                    error:&error];
    XCTAssertFalse(success, @"Rotation to unsupported orientation should return NO.");
    XCTAssertNotNil(error, @"Unsupported orientations should error out in iOS 16+.");
    XCTAssertTrue(
        [error.userInfo[@"Recovery Suggestion"] containsString:@"Verify if orientation is locked"]);
    XCTAssertNotNil(error.userInfo[@"Description"],
                    @"Error should include underlying geometry update error details.");
    GREYAssertEqual([XCUIDevice sharedDevice].orientation, UIDeviceOrientationLandscapeRight,
                    @"Device orientation should now be landscape right");
    GREYAssertEqual(scene.effectiveGeometry.interfaceOrientation, UIInterfaceOrientationPortrait,
                    @"Interface orientation should remain portrait");

    error = nil;
    success = [EarlGrey rotateInterfaceToOrientation:UIInterfaceOrientationPortrait error:&error];
    XCTAssertTrue(success, @"Rotation back to supported portrait orientation should succeed.");
    XCTAssertNil(error);
    GREYAssertEqual([XCUIDevice sharedDevice].orientation, UIDeviceOrientationPortrait,
                    @"Device orientation should now be portrait");
    GREYAssertEqual(scene.effectiveGeometry.interfaceOrientation, UIInterfaceOrientationPortrait,
                    @"Interface orientation should remain portrait");
  } else {
    [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeLeft error:nil];
    GREYAssertTrue(UIInterfaceOrientationIsPortrait(scene.interfaceOrientation),
                   @"Interface orientation should be portrait.");

    [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationPortrait error:nil];
    UIDeviceOrientation appOrientation =
        [GREY_REMOTE_CLASS_IN_APP(UIDevice) currentDevice].orientation;
    GREYAssertEqual(appOrientation, UIDeviceOrientationPortrait,
                    @"Device orientation should now be portrait");
    GREYAssertTrue(UIInterfaceOrientationIsPortrait(scene.interfaceOrientation),
                   @"Interface orientation should remain portrait");
  }
}

@end
