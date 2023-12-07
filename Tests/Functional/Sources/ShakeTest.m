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
#import "BaseIntegrationTest.h"

@interface ShakeTest : BaseIntegrationTest

@end

@implementation ShakeTest

- (void)setUp {
  [super setUp];
  [self openTestViewNamed:@"Rotated Views"];
}

/**
 * Shake the device using EarlGrey API and verify that the device is shaked using standard motion
 * detection.
 */
- (void)testDeviceShake {
  // Test device shake.
  [EarlGrey shakeDeviceWithError:nil];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"lastTapped")]
      assertWithMatcher:GREYText([NSString stringWithFormat:@"Device Was Shaken"])];
}

@end
