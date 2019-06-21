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

#import "GREYHostApplicationDistantObject+GREYTestHelper.h"
#import "BaseIntegrationTest.h"

@interface OrientationChangeTest : BaseIntegrationTest

@end

@implementation OrientationChangeTest

- (void)setUp {
  [super setUp];
  [self openTestViewNamed:@"Rotated Views"];
}

- (void)tearDown {
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationPortrait error:nil];
  XCTAssertEqual([GREY_REMOTE_CLASS_IN_APP(UIDevice) currentDevice].orientation,
                 UIInterfaceOrientationPortrait, @"Interface orientation should now be portrait");
  [[EarlGrey selectElementWithMatcher:grey_text(@"EarlGrey TestApp")] performAction:grey_tap()];
  [super tearDown];
}

- (void)testBasicOrientationChange {
  // Test rotating to landscape.
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeLeft error:nil];
  UIDeviceOrientation orientation = [GREY_REMOTE_CLASS_IN_APP(UIDevice) currentDevice].orientation;
  XCTAssertEqual(orientation, UIDeviceOrientationLandscapeLeft,
                 @"Device orientation should now be left landscape");
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeRight error:nil];
  orientation = [GREY_REMOTE_CLASS_IN_APP(UIDevice) currentDevice].orientation;
  XCTAssertEqual(orientation, UIDeviceOrientationLandscapeRight,
                 @"Interface orientation should now be right landscape");

  // Test rotating to portrait.
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationPortrait error:nil];
  orientation = [GREY_REMOTE_CLASS_IN_APP(UIDevice) currentDevice].orientation;
  XCTAssertEqual(orientation, UIDeviceOrientationPortrait,
                 @"Interface orientation should now be portrait");
}

- (void)testInteractingWithElementsAfterRotation {
  NSArray *buttonNames = @[ @"Top Left", @"Top Right", @"Bottom Right", @"Bottom Left", @"Center" ];
  NSArray *orientations = @[
    @(UIDeviceOrientationLandscapeLeft), @(UIDeviceOrientationPortraitUpsideDown),
    @(UIDeviceOrientationLandscapeRight), @(UIDeviceOrientationPortrait),
    @(UIDeviceOrientationFaceUp), @(UIDeviceOrientationFaceDown)
  ];

  for (NSUInteger i = 0; i < [orientations count]; i++) {
    UIDeviceOrientation orientation = [orientations[i] integerValue];
    [EarlGrey rotateDeviceToOrientation:orientation error:nil];
    UIDeviceOrientation deviceOrientation =
        [[GREY_REMOTE_CLASS_IN_APP(UIDevice) currentDevice] orientation];
    GREYAssertEqual(deviceOrientation, orientation, @"Device orientation should match");
    // Tap clear, check if label was reset
    [[EarlGrey selectElementWithMatcher:grey_buttonTitle(@"Clear")] performAction:grey_tap()];
    [[EarlGrey selectElementWithMatcher:grey_text(@"Last tapped: None")]
        assertWithMatcher:grey_sufficientlyVisible()];
    // Each of the buttons, when tapped, execute an action that changes the |lastTapped| UILabel
    // to contain their locations. We tap each button then check if the label actually changed.
    for (NSString *buttonName in buttonNames) {
      [[EarlGrey selectElementWithMatcher:grey_buttonTitle(buttonName)] performAction:grey_tap()];
      NSString *tappedString = [NSString stringWithFormat:@"Last tapped: %@", buttonName];
      [[EarlGrey selectElementWithMatcher:grey_text(tappedString)]
          assertWithMatcher:grey_sufficientlyVisible()];
    }
  }
}

- (void)testOrientationChangeWithInvalidOrientation {
  UIInterfaceOrientation orientation =
      [[GREYHostApplicationDistantObject sharedInstance] appOrientation];
  XCTAssertEqual(orientation, UIInterfaceOrientationPortrait,
                 @"Invalid orientation doesn't change the actual orientation of the app");
  BOOL orientationChange = [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationFaceDown
                                                         error:nil];
  XCTAssertTrue(orientationChange);
  orientation = [[GREYHostApplicationDistantObject sharedInstance] appOrientation];
  XCTAssertEqual(orientation, UIInterfaceOrientationPortrait,
                 @"Invalid orientation doesn't change the actual orientation of the app");
}

@end
