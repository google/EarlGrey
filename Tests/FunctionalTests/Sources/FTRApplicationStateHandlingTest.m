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
#import "TestLib/EarlGreyImpl/EarlGreyImpl+XCUIApplication.h"

@interface FTRApplicationStateHandlingTest : XCTestCase
@end

@implementation FTRApplicationStateHandlingTest {
  XCUIApplication *_application;
}

- (void)setUp {
  [super setUp];
  _application = [[XCUIApplication alloc] init];
  [_application launch];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Picker Views")] performAction:grey_tap()];
}

- (void)testBackgroundingAndForegrounding {
  BOOL success = [EarlGrey backgroundApplication];
  XCTAssertTrue(success);
  NSString *applicationBundleID = @"com.google.earlgreyftr.dev";
  XCUIApplication *application =
      [EarlGrey foregroundApplicationWithBundleID:applicationBundleID error:nil];
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

@end
