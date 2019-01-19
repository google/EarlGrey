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
#import "FTRBaseIntegrationTest.h"

#import "CommonLib/GREYDefines.h"

@interface FTRSystemAlertHandlingTest : FTRBaseIntegrationTest
@end

@implementation FTRSystemAlertHandlingTest

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
  [[EarlGrey selectElementWithMatcher:grey_text(@"EarlGrey TestApp")] performAction:grey_tap()];
  [super tearDown];
}

/**
 *  Automates the accepting of a system alert & checking it's text.
 */
- (void)testAcceptingSystemAlertAndCheckingItsText {
  [[EarlGrey selectElementWithMatcher:grey_buttonTitle(@"Locations Alert")]
      performAction:grey_tap()];
  NSString *string = [self grey_systemAlertTextWithError:nil];
  NSString *alertString = @"Allow “FunctionalTestRig” to access your location while you are "
                          @"using the app?";
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
 *  Automates the checking of a System Alert's text when no alert exists.
 */
- (void)testSystemAlertTextCheckingWithoutAnyAlertPresent {
  XCTAssertTrue([self grey_waitForAlertVisibility:NO withTimeout:3]);
  NSString *string = [self grey_systemAlertTextWithError:nil];
  XCTAssertNil(string);
  NSError *error;
  string = [self grey_systemAlertTextWithError:&error];
  XCTAssertNil(string);
  XCTAssertNotNil(error);
  XCTAssertEqualObjects(error.domain, kGREYSystemAlertDismissalErrorDomain);
  XCTAssertEqual(error.code, GREYSystemAlertNotPresent);
}

/**
 *  Automates the acceptance of a system alert with buttons that each have their own row.
 */
- (void)testAcceptingSystemAlertWithButtonsInEachRow {
  if (iOS11_OR_ABOVE()) {
    [[EarlGrey selectElementWithMatcher:grey_buttonTitle(@"Background Locations Alert")]
        performAction:grey_tap()];
    XCTAssertEqual([self grey_systemAlertType], GREYSystemAlertTypeBackgroundLocation);
    XCTAssertTrue([self grey_acceptSystemDialogWithError:nil]);
    XCTAssertTrue([self grey_waitForAlertVisibility:NO withTimeout:1]);
    [[EarlGrey selectElementWithMatcher:grey_buttonTitle(@"Alert Handled?")]
        performAction:grey_tap()];
  }
}

/**
 *  Automates the denying of a system alert.
 */
- (void)testDenyingSystemAlert {
  [[EarlGrey selectElementWithMatcher:grey_text(@"Contacts Alert")] performAction:grey_tap()];
  XCTAssertEqual([self grey_systemAlertType], GREYSystemAlertTypeContacts);
  XCTAssertTrue([self grey_denySystemDialogWithError:nil]);
  XCTAssertTrue([self grey_waitForAlertVisibility:NO withTimeout:1]);
  [[EarlGrey selectElementWithMatcher:grey_text(@"Denied")]
      assertWithMatcher:grey_sufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:grey_buttonTitle(@"Alert Handled?")]
      performAction:grey_tap()];
}

/**
 *  Checks the case when a non-system alert is displayed along with system alerts, with the
 *  expected behavior for the system alerts to be handled as the user wishes.
 */
- (void)testCustomHandlingMultipleAlerts {
  [[EarlGrey selectElementWithMatcher:grey_text(@"Reminders & Camera Alert")]
      performAction:grey_tap()];
  XCTAssertTrue([self grey_acceptSystemDialogWithError:nil]);
  XCTAssertTrue([self grey_denySystemDialogWithError:nil]);
  XCTAssertTrue([self grey_waitForAlertVisibility:NO withTimeout:1]);
  // The App Alert will be dismissed by the default UIInterruption Handler. However, the
  // direct calls for dismissal guarantee the order in which the dismissal is done.
  [[EarlGrey selectElementWithMatcher:grey_text(@"OK")] performAction:grey_tap()];
}

/**
 *  Checks tapping on a System Alert by hitting the OK button.
 */
- (void)testCustomButtonTapping {
  [[EarlGrey selectElementWithMatcher:grey_text(@"Motion Activity Alert")]
      performAction:grey_tap()];
  XCTAssertEqual([self grey_systemAlertType], GREYSystemAlertTypeMotionActivity);
  XCTAssertTrue([self grey_tapSystemDialogButtonWithText:@"OK" error:nil]);
  XCTAssertTrue([self grey_waitForAlertVisibility:NO withTimeout:1]);
}

/**
 *  Checks tapping on a System Alert by hitting the Don’t Allow button. Also checks the error
 *  value.
 */
- (void)testCustomButtonTappingWithError {
  [[EarlGrey selectElementWithMatcher:grey_text(@"Calendar Alert")] performAction:grey_tap()];
  XCTAssertEqual([self grey_systemAlertType], GREYSystemAlertTypeCalendar);
  NSError *error;
  XCTAssertFalse([self grey_tapSystemDialogButtonWithText:@"Garbage Value" error:&error]);
  XCTAssertEqualObjects(error.domain, kGREYSystemAlertDismissalErrorDomain);
  XCTAssertEqual(error.code, GREYSystemAlertCustomButtonNotFound);
  XCTAssertTrue([self grey_tapSystemDialogButtonWithText:@"Don’t Allow" error:nil]);
  XCTAssertTrue([self grey_waitForAlertVisibility:NO withTimeout:1]);
  [[EarlGrey selectElementWithMatcher:grey_text(@"Alert Handled?")] performAction:grey_tap()];
}

/**
 *  Checks the typing of text and password values into System Alerts.
 */
- (void)DISABLED_testTypingInSystemAlertTextFields {
  // TODO: This test requires network access for the iTunes Prompt. Re-enable once we // NOLINT
  // have network access.
  [[EarlGrey selectElementWithMatcher:grey_text(@"iTunes Restore Purchases Button")]
      performAction:grey_tap()];
  XCTAssertTrue([self grey_tapSystemDialogButtonWithText:@"Use Existing Apple ID" error:nil]);
  if (iOS11_OR_ABOVE()) {
    XCTAssertTrue(
        [self grey_typeSystemAlertText:@"foo@bar.com" forPlaceholderText:@"Apple ID" error:nil]);
  } else {
    XCTAssertTrue([self grey_typeSystemAlertText:@"foo@bar.com"
                              forPlaceholderText:@"example@icloud.com"
                                           error:nil]);
  }
  XCTAssertTrue(
      [self grey_typeSystemAlertText:@"foobarbaz" forPlaceholderText:@"Password" error:nil]);
  XCTAssertTrue([self grey_tapSystemDialogButtonWithText:@"Cancel" error:nil]);
}

/**
 *  Checks the return value from the system alert handling methods when no error is passed and no
 *  alert is to be accepted.
 */
- (void)testAcceptFailureWhenAlertIsNotPresent {
  XCTAssertTrue([self grey_waitForAlertVisibility:NO withTimeout:kSystemAlertVisibilityTimeout]);
  XCTAssertFalse([self grey_acceptSystemDialogWithError:nil]);
}

/**
 *  Checks the return value from the system alert handling methods when no error is passed and no
 *  alert is to be denied.
 */
- (void)testDeniedFailureWhenAlertIsNotPresent {
  XCTAssertTrue([self grey_waitForAlertVisibility:NO withTimeout:kSystemAlertVisibilityTimeout]);
  XCTAssertFalse([self grey_denySystemDialogWithError:nil]);
}

/**
 *  Checks the value of a passed-in error when no alert is brought up to be accepted.
 */
- (void)testPassedErrorForAcceptFailure {
  NSError *error = nil;
  XCTAssertFalse([self grey_acceptSystemDialogWithError:&error]);
  XCTAssertEqualObjects(error.domain, kGREYSystemAlertDismissalErrorDomain);
  XCTAssertEqual(error.code, GREYSystemAlertNotPresent);
}

/**
 *  Checks the value of a passed-in error when no alert is brought up to be denied.
 */
- (void)testPassedErrorForDenialFailure {
  NSError *error = nil;
  XCTAssertFalse([self grey_denySystemDialogWithError:&error]);
  XCTAssertEqualObjects(error.domain, kGREYSystemAlertDismissalErrorDomain);
  XCTAssertEqual(error.code, GREYSystemAlertNotPresent);
}

/**
 *  Checks the value of a passed-in error when no alert is brought up to be handled with a custom
 *  tap.
 */
- (void)testPassedErrorForCustomButtonTapFailure {
  NSError *error = nil;
  XCTAssertFalse([self grey_tapSystemDialogButtonWithText:@"Foo" error:&error]);
  XCTAssertEqualObjects(error.domain, kGREYSystemAlertDismissalErrorDomain);
  XCTAssertEqual(error.code, GREYSystemAlertNotPresent);
}

/**
 *  Checks error handling with and without any error passed in for typing in a System Alert Text
 *  Field.
 */
- (void)testErrorsForTypingFailure {
  XCTAssertThrows([self grey_typeSystemAlertText:@"foo" forPlaceholderText:@"" error:nil]);
  XCTAssertThrows([self grey_typeSystemAlertText:nil forPlaceholderText:@"Foo" error:nil]);
  XCTAssertThrows([self grey_typeSystemAlertText:@"Foo" forPlaceholderText:nil error:nil]);
  NSError *error = nil;
  XCTAssertFalse([self grey_typeSystemAlertText:@"Foo" forPlaceholderText:@"Foo" error:&error]);
  XCTAssertEqualObjects(error.domain, kGREYSystemAlertDismissalErrorDomain);
  XCTAssertEqual(error.code, GREYSystemAlertNotPresent);
}

@end
