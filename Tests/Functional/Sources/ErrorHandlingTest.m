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

#import "GREYMatchersShorthand.h"
#import "GREYError.h"
#import "GREYObjectFormatter.h"
#import "GREYConstants.h"
#import "EarlGrey.h"
#import "GREYHostApplicationDistantObject+ErrorHandlingTest.h"
#import "FailureHandler.h"
#import "GREYVisibilityChecker+Private.h"
#import "GREYVisibilityChecker.h"
#import "EDOClientService.h"

@interface ErrorHandlingTest : BaseIntegrationTest
@end

@implementation ErrorHandlingTest

- (void)tearDown {
  // Make sure to reset the images so it doesn't affect the screenshot checks on the preceding test
  // methods. This is necessary for some of the tests because it's try catching exception.
  [GREY_REMOTE_CLASS_IN_APP(GREYVisibilityChecker) resetVisibilityImages];
  [super tearDown];
}

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
  XCTAssertFalse([error.description containsString:@"Stack Trace:"]);
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

/**
 * Ensures that on failures in a search action with an EarlGrey assertion, the API, matcher and
 * failure are printed.
 **/
- (void)testDescriptionForSearchActionWithAssertion {
  [self openTestViewNamed:@"Scroll Views"];
  id<GREYMatcher> matcher = grey_allOf(grey_accessibilityLabel(@"Label 2"), grey_interactable(),
                                       grey_sufficientlyVisible(), nil);
  NSError *error;
  [[[EarlGrey selectElementWithMatcher:matcher]
         usingSearchAction:grey_scrollInDirection(kGREYDirectionDown, 50)
      onElementWithMatcher:grey_accessibilityLabel(@"Invalid Scroll View")]
      assertWithMatcher:grey_sufficientlyVisible()
                  error:&error];
  NSString *searchAPIDescription = @"Search API Info\nSearch Action:";
  NSString *searchAPIMatcherDescription = @"                    \"Search Matcher";
  NSString *searchActionDescription = @"Search action failed: Interaction cannot continue";
  NSString *elementMatcherDescription = @"Element Matcher:\n(((respondsToSelector";
  XCTAssertTrue([error.description containsString:searchAPIDescription],
                @"Search API Prefix and Action info: %@ not present in Error Description: %@",
                searchAPIDescription, error.description);
  XCTAssertTrue([error.description containsString:searchAPIMatcherDescription],
                @"Search API Matcher info: %@ not present in Error Description: %@",
                searchAPIMatcherDescription, error.description);
  XCTAssertTrue([error.description containsString:searchActionDescription],
                @"Search Action Failure Description: %@ not present in Error Description: %@",
                searchActionDescription, error.description);
  XCTAssertTrue([error.description containsString:elementMatcherDescription],
                @"Element Matcher Info: %@ not present in Error Description: %@",
                elementMatcherDescription, error.description);

  [[[EarlGrey selectElementWithMatcher:matcher]
         usingSearchAction:grey_scrollInDirection(kGREYDirectionDown, 50)
      onElementWithMatcher:grey_kindOfClass([UIView class])]
      assertWithMatcher:grey_sufficientlyVisible()
                  error:&error];
  searchActionDescription = @"Search action failed: Multiple elements were matched";
  XCTAssertTrue([error.description containsString:searchAPIDescription],
                @"Search API Prefix and Action info: %@ not present in Error Description: %@",
                searchAPIDescription, error.description);
  XCTAssertTrue([error.description containsString:searchAPIMatcherDescription],
                @"Search API Matcher info: %@ not present in Error Description: %@",
                searchAPIMatcherDescription, error.description);
  XCTAssertTrue([error.description containsString:searchActionDescription],
                @"Search Action Failure Description: %@ not present in Error Description: %@",
                searchActionDescription, error.description);
  XCTAssertTrue([error.description containsString:elementMatcherDescription],
                @"Element Matcher Info: %@ not present in Error Description: %@",
                elementMatcherDescription, error.description);
}

/**
 * Ensures that on failures in a search action with an EarlGrey action, the API, matcher and
 * failure are printed.
 **/
- (void)testDescriptionForSearchActionWithAction {
  [self openTestViewNamed:@"Scroll Views"];
  id<GREYMatcher> matcher = grey_allOf(grey_accessibilityLabel(@"Label 2"), grey_interactable(),
                                       grey_sufficientlyVisible(), nil);
  NSError *error;
  [[[EarlGrey selectElementWithMatcher:matcher]
         usingSearchAction:grey_scrollInDirection(kGREYDirectionDown, 50)
      onElementWithMatcher:grey_accessibilityLabel(@"Invalid Scroll View")] performAction:grey_tap()
                                                                                    error:&error];
  NSString *searchAPIDescription = @"Search API Info\nSearch Action:";
  NSString *searchAPIMatcherDescription = @"                    \"Search Matcher";
  NSString *searchActionDescription = @"Search action failed: Interaction cannot continue";
  NSString *elementMatcherDescription = @"Element Matcher:\n(((respondsToSelector";
  XCTAssertTrue([error.description containsString:searchAPIDescription],
                @"Search API Prefix and Action info: %@ not present in Error Description: %@",
                searchAPIDescription, error.description);
  XCTAssertTrue([error.description containsString:searchAPIMatcherDescription],
                @"Search API Matcher info: %@ not present in Error Description: %@",
                searchAPIMatcherDescription, error.description);
  XCTAssertTrue([error.description containsString:searchActionDescription],
                @"Search Action Failure Description: %@ not present in Error Description: %@",
                searchActionDescription, error.description);
  XCTAssertTrue([error.description containsString:elementMatcherDescription],
                @"Element Matcher Info: %@ not present in Error Description: %@",
                elementMatcherDescription, error.description);

  [[[EarlGrey selectElementWithMatcher:matcher]
         usingSearchAction:grey_scrollInDirection(kGREYDirectionDown, 50)
      onElementWithMatcher:grey_kindOfClass([UIView class])] performAction:grey_tap() error:&error];
  searchActionDescription = @"Search action failed: Multiple elements were matched";
  XCTAssertTrue([error.description containsString:searchAPIDescription],
                @"Search API Prefix and Action info: %@ not present in Error Description: %@",
                searchAPIDescription, error.description);
  XCTAssertTrue([error.description containsString:searchAPIMatcherDescription],
                @"Search API info: %@ not present in Error Description: %@",
                searchAPIMatcherDescription, error.description);
  XCTAssertTrue([error.description containsString:searchActionDescription],
                @"Search Action Failure Description: %@ not present in Error Description: %@",
                searchActionDescription, error.description);
  XCTAssertTrue([error.description containsString:elementMatcherDescription],
                @"Element Matcher Info: %@ not present in Error Description: %@",
                elementMatcherDescription, error.description);
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
  XCTAssertFalse([error.description containsString:@"Stack Trace:"]);
  [[GREYConfiguration sharedConfiguration] setValue:@(originalInteractionTimeout)
                                       forConfigKey:kGREYConfigKeyInteractionTimeoutDuration];
  // Ensure that the application has idled.
  GREYWaitForAppToIdle(@"Wait for app to idle");
}

- (void)testKeyboardDismissalError {
  NSError *error;
  [EarlGrey dismissKeyboardWithError:&error];
  NSString *keyboardErrorString = @"Failed to dismiss keyboard.\nInternal Keyboard Error: The "
                                  @"keyboard was not showing.";
  XCTAssertTrue([error.description containsString:keyboardErrorString]);
}

/**
 * Verifies the printed information for a GREYError found for an assertion failure.
 */
- (void)testAssertionFailureDescription {
  GREYError *error;
  NSString *assertionFailureString = @"Element does not meet assertion criteria: isNil \n"
                                     @"Element:";
  [[EarlGrey selectElementWithMatcher:grey_keyWindow()] assertWithMatcher:grey_nil() error:&error];
  XCTAssertTrue([error.description containsString:assertionFailureString]);
}

- (void)testActionErrorContainsHierarchyForFailures {
  NSError *error;
  [[EarlGrey selectElementWithMatcher:grey_keyWindow()]
      performAction:grey_scrollInDirection(kGREYDirectionUp, 10)
              error:&error];
  XCTAssertTrue([error.description containsString:@"|--<"]);
  XCTAssertFalse([error.description containsString:@"Stack Trace:"]);
}

- (void)testAssertionErrorContainsHierarchyForFailures {
  NSError *error;
  [[EarlGrey selectElementWithMatcher:grey_keyWindow()] assertWithMatcher:grey_nil() error:&error];
  XCTAssertTrue([error.description containsString:@"|--<"]);
  XCTAssertFalse([error.description containsString:@"Stack Trace:"]);
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
