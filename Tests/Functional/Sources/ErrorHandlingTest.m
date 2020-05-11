//
// Copyright 2019 Google Inc.
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

#import "BaseIntegrationTest.h"

#import "GREYError.h"
#import "GREYObjectFormatter.h"
#import "EarlGrey.h"
#import "GREYHostApplicationDistantObject+ErrorHandlingTest.h"
#import "FailureHandler.h"

@interface ErrorHandlingTest : BaseIntegrationTest
@end

@implementation ErrorHandlingTest

/**
 * Checks the error information for a timeout when a search action fails.
 */
- (void)testDescriptionForSearchActionTimeout {
  [self openTestViewNamed:@"Scroll Views"];
  id<GREYMatcher> matcher = grey_allOf(grey_accessibilityLabel(@"Label 2"), grey_interactable(),
                                       grey_sufficientlyVisible(), nil);
  CFTimeInterval interactionTimeout = GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration);
  [[GREYConfiguration sharedConfiguration] setValue:@(1)
                                       forConfigKey:kGREYConfigKeyInteractionTimeoutDuration];
  NSError *error;
  [[[EarlGrey selectElementWithMatcher:matcher]
         usingSearchAction:grey_scrollInDirection(kGREYDirectionDown, 50)
      onElementWithMatcher:grey_accessibilityLabel(@"Upper Scroll View")]
      assertWithMatcher:grey_sufficientlyVisible()
                  error:&error];
  [[GREYConfiguration sharedConfiguration] setValue:@(interactionTimeout)
                                       forConfigKey:kGREYConfigKeyInteractionTimeoutDuration];
  XCTAssertNotNil(error);
  NSString *timeoutText = @"Interaction timed out after 1 seconds while searching for element.";
  XCTAssertTrue(
      [error.description containsString:timeoutText],
      @"Error's description: %@ for a search action timing out did not contain timeout info: %@.",
      error.description, timeoutText);
}

/**
 * Check error for multiple matchers.
 */
- (void)testMultipleMatcherError {
  NSError *error;
  [[EarlGrey selectElementWithMatcher:grey_kindOfClass([UITableViewCell class])]
      performAction:grey_tap()
              error:&error];
  XCTAssertNotNil(error, @"Multiple Matchers error for the main VC is nil.");
  NSString *suggestion =
      @"Create a more specific matcher to uniquely match an element.\n\nIn general, prefer "
      @"using accessibility ID before accessibility label or other attributes. If you are "
      @"matching on a UIButton, please use grey_buttonTitle() with the accessibility label "
      @"instead. For UITextField, please use grey_textFieldValue().\n\nIf that's not "
      @"possible then use atIndex: to select from one of the matched elements. Keep "
      @"in mind when using atIndex: that the order in which elements are "
      @"arranged may change, making your test brittle.";
  XCTAssertTrue([error.description containsString:suggestion],
                @"Multiple Matcher Error: %@ doesn't contain the fixing-suggestion: %@",
                error.description, suggestion);
}

/**
 * Check that the correct error description is printed when an error is returned from a custom
 * action.
 */
- (void)testCustomNSErrorInAction {
  id<GREYAction> failingAction = [[GREYHostApplicationDistantObject sharedInstance] failingAction];
  NSError *error;
  [[EarlGrey selectElementWithMatcher:grey_keyWindow()] performAction:failingAction error:&error];
  NSString *errorDescription = @"The operation couldn’t be completed. (Generic Error error 1.)";
  XCTAssertTrue([error.description containsString:errorDescription]);
}

/**
 * Check that the correct error description is printed when an error is returned from a custom
 * assertion.
 */
- (void)testCustomNSErrorInAssertion {
  id<GREYAssertion> failingAssertion =
      [[GREYHostApplicationDistantObject sharedInstance] failingAssertion];
  NSError *error;
  [[EarlGrey selectElementWithMatcher:grey_keyWindow()] assert:failingAssertion error:&error];
  NSString *errorDescription = @"The operation couldn’t be completed. (Generic Error error 1.)";
  XCTAssertTrue([error.description containsString:errorDescription]);
}

- (void)testDescriptionForSearchAction {
  [self openTestViewNamed:@"Scroll Views"];
  id<GREYMatcher> matcher = grey_allOf(grey_accessibilityLabel(@"Label 2"), grey_interactable(),
                                       grey_sufficientlyVisible(), nil);
  NSError *error;
  [[[EarlGrey selectElementWithMatcher:matcher]
         usingSearchAction:grey_scrollInDirection(kGREYDirectionDown, 50)
      onElementWithMatcher:grey_accessibilityLabel(@"Invalid Scroll View")]
      assertWithMatcher:grey_sufficientlyVisible()
                  error:&error];
  NSString *searchActionDescription = @"Search action failed: Interaction cannot continue";
  NSString *elementMatcherDescription = @"Element Matcher\" : \"(((respondsToSelector";
  XCTAssertTrue([error.description containsString:searchActionDescription]);
  XCTAssertTrue([error.description containsString:elementMatcherDescription]);
}

- (void)testRotationDescriptionGlossary {
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeLeft error:nil];
  [self openTestViewNamed:@"Basic Views"];
  CFTimeInterval originalInteractionTimeout =
      GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration);
  [[GREYConfiguration sharedConfiguration] setValue:@(0.0)
                                       forConfigKey:kGREYConfigKeyInteractionTimeoutDuration];
  [[GREYHostApplicationDistantObject sharedInstance] induceNonTactileActionTimeoutInTheApp];
  NSError *error;
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationPortrait error:&error];
  NSString *idlingResourceString = @"Failed to execute block because idling resources are busy";
  XCTAssertTrue([error.description containsString:idlingResourceString]);
  [[GREYConfiguration sharedConfiguration] setValue:@(originalInteractionTimeout)
                                       forConfigKey:kGREYConfigKeyInteractionTimeoutDuration];
  // Ensure that the application has idled.
  GREYWaitForAppToIdle(@"Wait for app to idle");
}

- (void)testKeyboardDismissalError {
  NSError *error;
  [EarlGrey dismissKeyboardWithError:&error];
  NSString *keyboardErrorString = @"Failed to dismiss keyboard since it was not showing. Internal "
                                  @"Error: Failed to dismiss keyboard as it was not shown.";
  XCTAssertTrue([error.description containsString:keyboardErrorString]);
}

- (void)testActionErrorContainsHierarchyForFailures {
  NSError *error;
  [[EarlGrey selectElementWithMatcher:grey_keyWindow()]
      performAction:grey_scrollInDirection(kGREYDirectionUp, 10)
              error:&error];
  XCTAssertTrue([error.description containsString:@"|--<"]);
}

- (void)testAssertionErrorContainsHierarchyForFailures {
  NSError *error;
  [[EarlGrey selectElementWithMatcher:grey_keyWindow()] assertWithMatcher:grey_nil() error:&error];
  XCTAssertTrue([error.description containsString:@"|--<"]);
}

- (void)testMatcherErrorContainsHierarchyForFailures {
  NSError *error;
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"Invalid ID")] performAction:grey_tap()
                                                                                   error:&error];
  XCTAssertTrue([error.description containsString:@"|--<"]);
  error = nil;
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"Invalid ID")]
      assertWithMatcher:grey_notNil()
                  error:&error];
  XCTAssertTrue([error.description containsString:@"|--<"]);
}

- (void)testIdlingResourceContainsOnlyOneHierarchyInstance {
  [self openTestViewNamed:@"Animations"];
  double originalTimeout = GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration);
  [[GREYConfiguration sharedConfiguration] setValue:@(1)
                                       forConfigKey:kGREYConfigKeyInteractionTimeoutDuration];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"AnimationControl")]
      performAction:grey_tap()];
  NSError *error;
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"AnimationStatus")]
      assertWithMatcher:grey_text(@"Paused")
                  error:&error];

  [[GREYConfiguration sharedConfiguration] setValue:@(originalTimeout)
                                       forConfigKey:kGREYConfigKeyInteractionTimeoutDuration];
  XCTAssertEqual([self grey_hierarchyOccurrencesInErrorDescription:error.description],
                 (NSUInteger)1);
}

- (void)testSimpleErrorDoesNotContainHierarchy {
  NSError *error = GREYErrorMake(kGREYGenericErrorDomain, kGREYGenericErrorCode, @"Generic Error");
  XCTAssertFalse([error.description containsString:@""]);
}

- (void)testNestedErrorCreatedWithASimpleErrorDoesNotContainHierarchy {
  NSError *error = [[GREYHostApplicationDistantObject sharedInstance] simpleNestedError];

  XCTAssertFalse([error.description containsString:@""]);
}

- (void)testErrorPopulatedInTheAppContainsOneHierarchy {
  NSError *error = [[GREYHostApplicationDistantObject sharedInstance] errorPopulatedInTheApp];
  XCTAssertEqual([self grey_hierarchyOccurrencesInErrorDescription:error.description],
                 (NSUInteger)1);
}

- (void)testNestedErrorPopulatedInTheAppContainsOneHierarchy {
  NSError *error = [[GREYHostApplicationDistantObject sharedInstance] notedErrorPopulatedInTheApp];
  XCTAssertEqual([self grey_hierarchyOccurrencesInErrorDescription:error.description],
                 (NSUInteger)1);
}

- (void)testErrorCreatedInTheAppContainsOneHierarchy {
  NSError *error = [[GREYHostApplicationDistantObject sharedInstance] errorPopulatedInTheApp];
  XCTAssertEqual([self grey_hierarchyOccurrencesInErrorDescription:error.description],
                 (NSUInteger)1);
}

- (void)testNestedErrorInsideAnErrorWithHierarchyContainsOneHierarchy {
  NSError *error =
      [[GREYHostApplicationDistantObject sharedInstance] nestedErrorWithHierarchyCreatedInTheApp];
  XCTAssertEqual([self grey_hierarchyOccurrencesInErrorDescription:error.description],
                 (NSUInteger)1);
}

- (void)testFormattingOfErrorCreatedInTheApp {
  NSError *error = [[GREYHostApplicationDistantObject sharedInstance] errorCreatedInTheApp];
  XCTAssertNoThrow([GREYError grey_nestedDescriptionForError:error],
                   @"Failing on an error from the app did not throw an exception");
}

/**
 * Checks if an exception thrown by EarlGrey for a matching failure contains the right screenshots,
 * hierarchy and element matcher information.
 */
- (void)testExceptionDetailsForAMatcherFailure {
  [NSThread mainThread].threadDictionary[GREYFailureHandlerKey] = [[FailureHandler alloc] init];
  @try {
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"foo")] performAction:grey_tap()];
    GREYFail(@"Should throw an exception before this point.");
  } @catch (NSException *exception) {
    NSDictionary<NSString *, id> *userInfo = exception.userInfo;
    NSDictionary<NSString *, UIImage *> *screenshots = userInfo[kErrorDetailAppScreenshotsKey];
    XCTAssertEqual(screenshots.count, 2);
    XCTAssertNotNil(screenshots[kGREYAppScreenshotAtFailure]);
    XCTAssertNotNil(screenshots[kGREYTestScreenshotAtFailure]);
    XCTAssertNotNil(userInfo[kErrorDetailAppUIHierarchyKey]);
    XCTAssertNotNil(userInfo[kErrorDetailElementMatcherKey]);
  }
}

/**
 * Checks if a visibility related exception thrown by EarlGrey contains the right screenshots.
 */
- (void)testExceptionDetails {
  [NSThread mainThread].threadDictionary[GREYFailureHandlerKey] = [[FailureHandler alloc] init];
  [self openTestViewNamed:@"Visibility Tests"];
  @try {
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"orangeView")]
        assertWithMatcher:grey_sufficientlyVisible()];
    GREYFail(@"Should throw an exception before this point.");
  } @catch (NSException *exception) {
    NSDictionary<NSString *, id> *userInfo = exception.userInfo;
    NSDictionary<NSString *, UIImage *> *screenshots = userInfo[kErrorDetailAppScreenshotsKey];
    XCTAssertEqual(screenshots.count, 5);
    XCTAssertNotNil(screenshots[kGREYAppScreenshotAtFailure]);
    XCTAssertNotNil(screenshots[kGREYTestScreenshotAtFailure]);
    XCTAssertNotNil(screenshots[kGREYScreenshotBeforeImage]);
    XCTAssertNotNil(screenshots[kGREYScreenshotExpectedAfterImage]);
    XCTAssertNotNil(screenshots[kGREYScreenshotActualAfterImage]);
    XCTAssertNotNil(userInfo[kErrorDetailAppUIHierarchyKey]);
    XCTAssertNotNil(userInfo[kErrorDetailElementMatcherKey]);
  }
}

#pragma mark - Private

/**
 * @c returns A NSUInteger for the number of times the UI hierarchy is present in the provided
 *            error description.
 *
 * @param description An NSString specifying an NSError's description.
 */
- (NSUInteger)grey_hierarchyOccurrencesInErrorDescription:(NSString *)description {
  NSRegularExpression *regex =
      [NSRegularExpression regularExpressionWithPattern:@"<UIWindow"
                                                options:NSRegularExpressionCaseInsensitive
                                                  error:nil];
  return [regex numberOfMatchesInString:description
                                options:0
                                  range:NSMakeRange(0, [description length])];
}

@end
