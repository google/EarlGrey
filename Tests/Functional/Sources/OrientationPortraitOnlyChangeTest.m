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
  // Tear down before undoing swizzling.
  [super tearDown];
  GREYAssert([[GREYHostApplicationDistantObject sharedInstance] unblockNonPortraitOrientations],
             @"Failed to undo the blocking of non-portrait orientations.");
}

- (void)testRotateToUnsupportedOrientation {
  UIApplication *sharedApp = [GREY_REMOTE_CLASS_IN_APP(UIApplication) sharedApplication];
  if (@available(iOS 16, *)) {
    NSError *error;
    [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeLeft error:&error];
    XCTAssertNotNil(error, @"Unsupported orientations should error out in iOS 16+.");
    GREYAssertEqual(sharedApp.statusBarOrientation, UIInterfaceOrientationPortrait,
                    @"Interface orientation should remain portrait");
  } else {
    [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeLeft error:nil];
    UIDeviceOrientation appOrientation =
        [GREY_REMOTE_CLASS_IN_APP(UIDevice) currentDevice].orientation;
    GREYAssertEqual(appOrientation, UIDeviceOrientationLandscapeLeft,
                    @"Device orientation should now be landscape left");
    GREYAssertEqual(sharedApp.statusBarOrientation, UIInterfaceOrientationPortrait,
                    @"Interface orientation should remain portrait");
  }
}

- (void)testDeviceChangeWithoutInterfaceChange {
  UIApplication *sharedApp = [GREY_REMOTE_CLASS_IN_APP(UIApplication) sharedApplication];
  if (@available(iOS 16, *)) {
    NSError *error;
    [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeLeft error:&error];
    XCTAssertNotNil(error, @"Unsupported orientations should error out in iOS 16+.");
    GREYAssertEqual(sharedApp.statusBarOrientation, UIInterfaceOrientationPortrait,
                    @"Interface orientation should remain portrait");
  } else {
    [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeLeft error:nil];
    GREYAssertEqual(sharedApp.statusBarOrientation, UIInterfaceOrientationPortrait,
                    @"Interface orientation should be portrait.");

    [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationPortrait error:nil];
    UIDeviceOrientation appOrientation =
        [GREY_REMOTE_CLASS_IN_APP(UIDevice) currentDevice].orientation;
    GREYAssertEqual(appOrientation, UIDeviceOrientationPortrait,
                    @"Device orientation should now be portrait");
    GREYAssertEqual(sharedApp.statusBarOrientation, UIInterfaceOrientationPortrait,
                    @"Interface orientation should remain portrait");
  }
}

@end
