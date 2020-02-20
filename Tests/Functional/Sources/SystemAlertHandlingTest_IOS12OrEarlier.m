//
// Copyright 2020 Google Inc.
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

#import "BaseIntegrationTest.h"

@interface SystemAlertHandlingTest_IOS12OrEarlier : BaseIntegrationTest
@end

@implementation SystemAlertHandlingTest_IOS12OrEarlier

/**
 *  Custom setup to set up an XCUIApplication and move to the System Alerts screen.
 */
- (void)setUp {
  [super setUp];
  [self openTestViewNamed:@"System Alerts"];
}

/**
 *  Custom teardown method returns the UI to the starting table view controller.
 */
- (void)tearDown {
  [[EarlGrey selectElementWithMatcher:grey_buttonTitle(@"EarlGrey TestApp")]
      performAction:grey_tap()];
  [super tearDown];
}

/**
 *  Automates the accepting of a system alert & checking it's text.
 */
- (void)testAcceptingSystemAlertAndCheckingItsText {
  [[EarlGrey selectElementWithMatcher:grey_buttonTitle(@"Locations Alert")]
      performAction:grey_tap()];
  XCTAssertTrue([self grey_waitForAlertVisibility:YES withTimeout:1]);
  NSString *string = [self grey_systemAlertTextWithError:nil];
  NSString *alertString =
      @"Allow “FunctionalTestRig” to access your location while you are using the app?";
  XCTAssertEqualObjects(string, alertString);
  NSError *error;
  string = [self grey_systemAlertTextWithError:&error];
  XCTAssertEqualObjects(string, alertString);
  XCTAssertNil(error);
  XCTAssertEqual([self grey_systemAlertType], GREYSystemAlertTypeLocation);
  XCTAssertTrue([self grey_acceptSystemDialogWithError:nil]);
  XCTAssertTrue([self grey_waitForAlertVisibility:NO withTimeout:1]);
  [[EarlGrey selectElementWithMatcher:grey_buttonTitle(@"Alert Handled?")]
      performAction:grey_tap()];
}

/**
 *  Automates the acceptance of a system alert with buttons that each have their own row.
 */
- (void)testAcceptingSystemAlertWithButtonsInEachRow {
  [[EarlGrey selectElementWithMatcher:grey_buttonTitle(@"Background Locations Alert")]
      performAction:grey_tap()];
  XCTAssertTrue([self grey_waitForAlertVisibility:YES withTimeout:1]);
  XCTAssertEqual([self grey_systemAlertType], GREYSystemAlertTypeBackgroundLocation);
  XCTAssertTrue([self grey_acceptSystemDialogWithError:nil]);
  XCTAssertTrue([self grey_waitForAlertVisibility:NO withTimeout:1]);
  [[EarlGrey selectElementWithMatcher:grey_buttonTitle(@"Alert Handled?")]
      performAction:grey_tap()];
}

@end
