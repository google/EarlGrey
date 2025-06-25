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
#import "EarlGrey.h"
#import "BaseIntegrationTest.h"

@interface SystemAlertHandlingTest_Standalone_API_IOS13OrLater : BaseIntegrationTest
@end

@implementation SystemAlertHandlingTest_Standalone_API_IOS13OrLater

/**
 * Custom setup to set up an XCUIApplication and move to the System Alerts screen.
 */
- (void)setUp {
  [super setUp];
  [self openTestViewNamed:@"System Alerts"];
}

/**
 * Custom teardown method returns the UI to the starting table view controller.
 */
- (void)tearDown {
  [[EarlGrey selectElementWithMatcher:GREYButtonTitle(@"EarlGrey TestApp")]
      performAction:GREYTap()];
  [super tearDown];
}

/**
 * Automates the accepting of a system alert.
 */
- (void)testAcceptingSystemAlert {
  CFTimeInterval interactionTimeout = GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration);
  [[EarlGrey selectElementWithMatcher:GREYButtonTitle(@"Locations Alert")]
      performAction:GREYTap()];
  XCTAssertTrue([EarlGrey WaitForAlertVisibility:YES withTimeout:interactionTimeout]);
  XCTAssertEqual([EarlGrey SystemAlertType], GREYSystemAlertTypeLocation);
  XCTAssertTrue([EarlGrey AcceptSystemDialogWithError:nil]);
  XCTAssertTrue([EarlGrey WaitForAlertVisibility:NO withTimeout:interactionTimeout]);
  [[EarlGrey selectElementWithMatcher:GREYButtonTitle(@"Alert Handled?")]
      performAction:GREYTap()];
}

/**
 * Tests validity of system alert text helper.
 */
- (void)testSystemAlertLabelText {
  [[EarlGrey selectElementWithMatcher:GREYButtonTitle(@"Notifications Alert")]
      performAction:GREYTap()];
  XCTAssertTrue([EarlGrey WaitForAlertVisibility:YES withTimeout:1]);
  NSError *error;
  NSString *alertString = [EarlGrey SystemAlertTextWithError:&error];
  NSString *expectedString = @"“FunctionalTestRig” Would Like to Send You Notifications";
  XCTAssertTrue([alertString isEqualToString:expectedString]);
  XCTAssertTrue([EarlGrey AcceptSystemDialogWithError:nil]);
  XCTAssertTrue([EarlGrey WaitForAlertVisibility:NO withTimeout:1]);
  [[EarlGrey selectElementWithMatcher:GREYButtonTitle(@"Alert Handled?")]
      performAction:GREYTap()];
}

/**
 * Automates the checking of a System Alert's text when no alert exists.
 */
- (void)testSystemAlertTextCheckingWithoutAnyAlertPresent {
  XCTAssertTrue([EarlGrey WaitForAlertVisibility:NO withTimeout:3]);
  NSString *string = [EarlGrey SystemAlertTextWithError:nil];
  XCTAssertNil(string);
  NSError *error;
  string = [EarlGrey SystemAlertTextWithError:&error];
  XCTAssertNil(string);
  XCTAssertNotNil(error);
  XCTAssertEqualObjects(error.domain, kGREYSystemAlertDismissalErrorDomain);
  XCTAssertEqual(error.code, GREYSystemAlertNotPresent);
}

/**
 * Automates the denying of a system alert.
 */
- (void)testDenyingSystemAlert {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Contacts Alert")] performAction:GREYTap()];
  XCTAssertTrue([EarlGrey WaitForAlertVisibility:YES withTimeout:5]);
  XCTAssertEqual([EarlGrey SystemAlertType], GREYSystemAlertTypeContacts);
  XCTAssertTrue([EarlGrey DenySystemDialogWithError:nil]);
  XCTAssertTrue([EarlGrey WaitForAlertVisibility:NO withTimeout:5]);
  [[EarlGrey selectElementWithMatcher:GREYText(@"Denied")]
      assertWithMatcher:GREYSufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:GREYButtonTitle(@"Alert Handled?")]
      performAction:GREYTap()];
}

/**
 * Checks the case when a non-system alert is displayed along with system alerts, with the
 * expected behavior for the system alerts to be handled as the user wishes.
 */
- (void)testCustomHandlingMultipleAlerts {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Reminders & Camera Alert")]
      performAction:GREYTap()];
  XCTAssertTrue([EarlGrey WaitForAlertVisibility:YES withTimeout:1]);
  XCTAssertTrue([EarlGrey AcceptSystemDialogWithError:nil]);
  XCTAssertTrue([EarlGrey DenySystemDialogWithError:nil]);
  XCTAssertTrue([EarlGrey WaitForAlertVisibility:NO withTimeout:1]);
  // The App Alert will be dismissed by the default UIInterruption Handler. However, the
  // direct calls for dismissal guarantee the order in which the dismissal is done.
  [[EarlGrey selectElementWithMatcher:GREYText(@"OK")] performAction:GREYTap()];
}

/**
 * Checks tapping on a System Alert by hitting the OK button.
 */
- (void)testCustomButtonTapping {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Motion Activity Alert")]
      performAction:GREYTap()];
  XCTAssertTrue([EarlGrey WaitForAlertVisibility:YES withTimeout:1]);
  XCTAssertEqual([EarlGrey SystemAlertType], GREYSystemAlertTypeMotionActivity);
  XCTAssertTrue([EarlGrey TapSystemDialogButtonWithText:@"OK" error:nil]);
  XCTAssertTrue([EarlGrey WaitForAlertVisibility:NO withTimeout:1]);
}

/**
 * Checks tapping on a System Alert by hitting the Don’t Allow button. Also checks the error
 * value.
 */
- (void)testCustomButtonTappingWithError {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Calendar Alert")] performAction:GREYTap()];
  XCTAssertTrue([EarlGrey WaitForAlertVisibility:YES withTimeout:1]);
  XCTAssertEqual([EarlGrey SystemAlertType], GREYSystemAlertTypeCalendar);
  NSError *error;
  XCTAssertFalse([EarlGrey TapSystemDialogButtonWithText:@"Garbage Value" error:&error]);
  XCTAssertEqualObjects(error.domain, kGREYSystemAlertDismissalErrorDomain);
  XCTAssertEqual(error.code, GREYSystemAlertCustomButtonNotFound);
  XCTAssertTrue([EarlGrey TapSystemDialogButtonWithText:@"Don’t Allow" error:nil]);
  XCTAssertTrue([EarlGrey WaitForAlertVisibility:NO withTimeout:1]);
  [[EarlGrey selectElementWithMatcher:GREYText(@"Alert Handled?")] performAction:GREYTap()];
}

/**
 * Checks the typing of text and password values into System Alerts.
 */
- (void)DISABLED_testTypingInSystemAlertTextFields {
  // TODO: This test requires network access for the iTunes Prompt. Re-enable once we // NOLINT
  // have network access.
  [[EarlGrey selectElementWithMatcher:GREYText(@"iTunes Restore Purchases Button")]
      performAction:GREYTap()];
  XCTAssertTrue([EarlGrey WaitForAlertVisibility:YES withTimeout:1]);
  XCTAssertTrue([EarlGrey TapSystemDialogButtonWithText:@"Use Existing Apple ID" error:nil]);
  XCTAssertTrue([EarlGrey TypeSystemAlertText:@"foo@bar.com"
                           forPlaceholderText:@"Apple ID"
                                        error:nil]);
  XCTAssertTrue([EarlGrey TypeSystemAlertText:@"foobarbaz"
                           forPlaceholderText:@"Password"
                                        error:nil]);
  XCTAssertTrue([EarlGrey TapSystemDialogButtonWithText:@"Cancel" error:nil]);
}

/**
 * Checks the return value from the system alert handling methods when no error is passed and no
 * alert is to be accepted.
 */
- (void)testAcceptFailureWhenAlertIsNotPresent {
  XCTAssertTrue([EarlGrey WaitForAlertVisibility:NO withTimeout:kSystemAlertVisibilityTimeout]);
  XCTAssertFalse([EarlGrey AcceptSystemDialogWithError:nil]);
}

/**
 * Checks the return value from the system alert handling methods when no error is passed and no
 * alert is to be denied.
 */
- (void)testDeniedFailureWhenAlertIsNotPresent {
  XCTAssertTrue([EarlGrey WaitForAlertVisibility:NO withTimeout:kSystemAlertVisibilityTimeout]);
  XCTAssertFalse([EarlGrey DenySystemDialogWithError:nil]);
}

/**
 * Checks the value of a passed-in error when no alert is brought up to be accepted.
 */
- (void)testPassedErrorForAcceptFailure {
  NSError *error = nil;
  XCTAssertFalse([EarlGrey AcceptSystemDialogWithError:&error]);
  XCTAssertEqualObjects(error.domain, kGREYSystemAlertDismissalErrorDomain);
  XCTAssertEqual(error.code, GREYSystemAlertAcceptButtonNotFound);
}

/**
 * Checks the value of a passed-in error when no alert is brought up to be denied.
 */
- (void)testPassedErrorForDenialFailure {
  NSError *error = nil;
  XCTAssertFalse([EarlGrey DenySystemDialogWithError:&error]);
  XCTAssertEqualObjects(error.domain, kGREYSystemAlertDismissalErrorDomain);
  XCTAssertEqual(error.code, GREYSystemAlertDenialButtonNotFound);
}

/**
 * Checks the value of a passed-in error when no alert is brought up to be handled with a custom
 * tap.
 */
- (void)testPassedErrorForCustomButtonTapFailure {
  NSError *error = nil;
  XCTAssertFalse([EarlGrey TapSystemDialogButtonWithText:@"Foo" error:&error]);
  XCTAssertEqualObjects(error.domain, kGREYSystemAlertDismissalErrorDomain);
  XCTAssertEqual(error.code, GREYSystemAlertCustomButtonNotFound);
}

/**
 * Checks error handling with and without any error passed in for typing in a System Alert Text
 * Field.
 */
- (void)testErrorsForTypingFailure {
  XCTAssertThrows([EarlGrey TypeSystemAlertText:@"foo" forPlaceholderText:@"" error:nil]);
  XCTAssertThrows([EarlGrey TypeSystemAlertText:nil forPlaceholderText:@"Foo" error:nil]);
  XCTAssertThrows([EarlGrey TypeSystemAlertText:@"Foo" forPlaceholderText:nil error:nil]);
  NSError *error = nil;
  XCTAssertFalse([EarlGrey TypeSystemAlertText:@"Foo" forPlaceholderText:@"Foo" error:&error]);
  XCTAssertEqualObjects(error.domain, kGREYSystemAlertDismissalErrorDomain);
  XCTAssertEqual(error.code, GREYSystemAlertTextNotTypedCorrectly);
}

@end
