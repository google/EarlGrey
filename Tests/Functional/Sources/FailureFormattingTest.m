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

#include "third_party/objective_c/EarlGreyV2/AppFramework/Matcher/GREYMatchersShorthand.h"
#import "BaseIntegrationTest.h"

#import "GREYError.h"
#import "GREYConstants.h"
#import "EarlGrey.h"
#import "FailureHandler.h"

#pragma mark - Failure Handler

/**
 * Failure handler used for testing the console output of failures
 */
@interface FailureFormatTestingFailureHandler : NSObject <GREYFailureHandler>

/** The filename where the failure is located at. */
@property NSString *fileName;

/** The line number where the failure is located at. */
@property(assign) NSUInteger lineNumber;

/** Exception to handle the failure for*/
@property GREYFrameworkException *exception;

/** Details for the exception. */
@property NSString *details;
@end

@implementation FailureFormatTestingFailureHandler

- (void)handleException:(GREYFrameworkException *)exception details:(NSString *)details {
  self.exception = exception;
  self.details = details;
}

- (void)setInvocationFile:(NSString *)fileName andInvocationLine:(NSUInteger)lineNumber {
  self.fileName = fileName;
  self.lineNumber = lineNumber;
}

@end

#pragma mark - FailureFormattingTest

/**
 * Verifies that the user-facing console output follows expectations.
 */
@interface FailureFormattingTest : BaseIntegrationTest
@end

@implementation FailureFormattingTest {
  /** Custom failure handler for checking the formatting. */
  FailureFormatTestingFailureHandler *_handler;
  /** The original failure handler. */
  id<GREYFailureHandler> _originalHandler;
}

- (void)setUp {
  [super setUp];
  _originalHandler = [NSThread mainThread].threadDictionary[GREYFailureHandlerKey];
  _handler = [[FailureFormatTestingFailureHandler alloc] init];
  [NSThread mainThread].threadDictionary[GREYFailureHandlerKey] = _handler;
}

- (void)tearDown {
  [NSThread mainThread].threadDictionary[GREYFailureHandlerKey] = _originalHandler;
  [super tearDown];
}

/**
 * Checks the formatting of logs for an element not found error for an assertion without a search
 * action failure.
 */
- (void)testNotFoundAssertionErrorDescription {
  [self openTestViewNamed:@"Animations"];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Basic Views")] assertWithMatcher:grey_notNil()];

  NSString *expectedDetails = @"Interaction cannot continue because the desired element was not "
                              @"found.\n"
                              @"\n"
                              @"Check if the element exists in the UI hierarchy printed below. If "
                              @"it exists, adjust the matcher so that it accurately matches "
                              @"the element.\n"
                              @"\n"
                              @"Element Matcher:\n"
                              @"((kindOfClass('UILabel') || kindOfClass('UITextField') || "
                              @"kindOfClass('UITextView')) && hasText('Basic Views'))\n"
                              @"\n"
                              @"Failed Assertion: assertWithMatcher:isNotNil";
  XCTAssertTrue([_handler.details containsString:expectedDetails],
                @"Expected info does not appear in the actual exception details:\n\n"
                @"========== expected info ===========\n%@\n\n"
                @"========== actual exception details ==========\n%@",
                expectedDetails, _handler.details);
}

/**
 * Checks the formatting of logs for an element not found error for an assertion with a search
 * action failure.
 */
- (void)testSearchNotFoundAssertionErrorDescription {
  [self openTestViewNamed:@"Scroll Views"];
  id<GREYMatcher> matcher = grey_allOf(grey_accessibilityLabel(@"Label 2"), grey_interactable(),
                                       grey_sufficientlyVisible(), nil);
  [[[EarlGrey selectElementWithMatcher:matcher]
         usingSearchAction:grey_scrollInDirection(kGREYDirectionDown, 50)
      onElementWithMatcher:grey_accessibilityLabel(@"Invalid Scroll View")]
      assertWithMatcher:grey_sufficientlyVisible()];

  NSString *expectedDetails = @"Search action failed: Interaction cannot continue because the "
                              @"desired element was not found.\n"
                              @"\n"
                              @"Check if the element exists in the UI hierarchy printed below. If "
                              @"it exists, adjust the matcher so that it accurately matches "
                              @"the element.\n"
                              @"\n"
                              @"Element Matcher:\n"
                              @"(((respondsToSelector(isAccessibilityElement) && "
                              @"isAccessibilityElement) && accessibilityLabel('Label 2')) && "
                              @"interactable Point:{nan, nan} && sufficientlyVisible(Expected: "
                              @"0.750000, Actual: 0.000000))\n"
                              @"\n"
                              @"Failed Assertion: assertWithMatcher:sufficientlyVisible(Expe"
                              @"cted: 0.750000, Actual: 0.000000)\n"
                              @"\n"
                              @"Search API Info\n"
                              @"Search Action: ";
  XCTAssertTrue([_handler.details containsString:expectedDetails],
                @"Expected info does not appear in the actual exception details:\n\n"
                @"========== expected info ===========\n%@\n\n"
                @"========== actual exception details ==========\n%@",
                expectedDetails, _handler.details);
}

/**
 * Checks the formatting of logs for an element not found error for an action without a search
 * action failure.
 */
- (void)testSearchNotFoundActionErrorDescription {
  [self openTestViewNamed:@"Scroll Views"];
  id<GREYMatcher> matcher = grey_allOf(grey_accessibilityLabel(@"Label 2"), grey_interactable(),
                                       grey_sufficientlyVisible(), nil);
  [[[EarlGrey selectElementWithMatcher:matcher]
         usingSearchAction:grey_scrollInDirection(kGREYDirectionDown, 50)
      onElementWithMatcher:grey_accessibilityLabel(@"Invalid Scroll View")]
      performAction:grey_tap()];

  NSString *expectedDetails = @"Search action failed: Interaction cannot continue because the "
                              @"desired element was not found.\n"
                              @"\n"
                              @"Check if the element exists in the UI hierarchy printed below. If "
                              @"it exists, adjust the matcher so that it accurately matches "
                              @"the element.\n"
                              @"\n"
                              @"Element Matcher:\n"
                              @"(((respondsToSelector(isAccessibilityElement) && "
                              @"isAccessibilityElement) && accessibilityLabel('Label 2')) && "
                              @"interactable Point:{nan, nan} && sufficientlyVisible(Expected: "
                              @"0.750000, Actual: 0.000000))\n"
                              @"\n"
                              @"Failed Action: Tap\n\n"
                              @"Search API Info\n"
                              @"Search Action: ";
  XCTAssertTrue([_handler.details containsString:expectedDetails],
                @"Expected info does not appear in the actual exception details:\n\n"
                @"========== expected info ===========\n%@\n\n"
                @"========== actual exception details ==========\n%@",
                expectedDetails, _handler.details);
}

/**
 * Checks the formatting of logs for an element not found error for an action without a search
 * action failure.
 */
- (void)testNotFoundActionErrorDescription {
  CFTimeInterval originalInteractionTimeout =
      GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration);
  [[GREYConfiguration sharedConfiguration] setValue:@(1)
                                       forConfigKey:kGREYConfigKeyInteractionTimeoutDuration];
  NSString *jsStringAboveTimeout =
      @"start = new Date().getTime(); while (new Date().getTime() < start + 3000);";
  // JS action timeout greater than the threshold.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TestWKWebView")]
      performAction:grey_javaScriptExecution(jsStringAboveTimeout, nil)];
  [[GREYConfiguration sharedConfiguration] setValue:@(originalInteractionTimeout)
                                       forConfigKey:kGREYConfigKeyInteractionTimeoutDuration];
  NSString *expectedDetails = @"Interaction cannot continue because the "
                              @"desired element was not found.\n"
                              @"\n"
                              @"Check if the element exists in the UI hierarchy printed below. If "
                              @"it exists, adjust the matcher so that it accurately matches "
                              @"the element.\n"
                              @"\n"
                              @"Element Matcher:\n"
                              @"(respondsToSelector(accessibilityIdentifier) && "
                              @"accessibilityID('TestWKWebView'))\n"
                              @"\n"
                              @"Failed Action: Execute JavaScript";
  XCTAssertTrue([_handler.details containsString:expectedDetails],
                @"Expected info does not appear in the actual exception details:\n\n"
                @"========== expected info ===========\n%@\n\n"
                @"========== actual exception details ==========\n%@",
                expectedDetails, _handler.details);
}

/**
 * Checks the formatting of logs for timeout error.
 */
- (void)testTimeoutErrorDescription {
  [self openTestViewNamed:@"Scroll Views"];
  id<GREYMatcher> matcher = grey_allOf(grey_accessibilityLabel(@"Label 2"), grey_interactable(),
                                       grey_sufficientlyVisible(), nil);
  [[GREYConfiguration sharedConfiguration] setValue:@(1)
                                       forConfigKey:kGREYConfigKeyInteractionTimeoutDuration];
  [[[EarlGrey selectElementWithMatcher:matcher]
         usingSearchAction:grey_scrollInDirection(kGREYDirectionDown, 50)
      onElementWithMatcher:grey_accessibilityLabel(@"Upper Scroll View")]
      assertWithMatcher:grey_sufficientlyVisible()];
  NSString *expectedDetails = @"Interaction timed out after 1 seconds while searching "
                              @"for element.\n"
                              @"\n"
                              @"Increase timeout for matching element.\n"
                              @"\n"
                              @"Element Matcher:\n"
                              @"(((respondsToSelector(isAccessibilityElement) && "
                              @"isAccessibilityElement) && accessibilityLabel('Label 2')) && "
                              @"interactable Point:{nan, nan} && sufficientlyVisible(Expected: "
                              @"0.750000, Actual: 0.000000))\n"
                              @"\n"
                              @"Failed Assertion: assertWithMatcher:sufficientlyVisible(E"
                              @"xpected: 0.750000, Actual: 0.000000)\n"
                              @"\n"
                              @"UI Hierarchy";
  XCTAssertTrue([_handler.details containsString:expectedDetails]);
}

/**
 * Checks the formatting for a type interaction failing.
 */
- (void)testActionInteractionErrorDescription {
  [[EarlGrey selectElementWithMatcher:grey_text(@"Basic Views")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"foo")]
      performAction:grey_typeText(@"")];

  NSString *expectedDetails =
      @"Failed to type because the provided string was empty.\n"
      @"\n"
      @"Element Matcher:\n"
      @"(respondsToSelector(accessibilityIdentifier) && accessibilityID('foo'))\n"
      @"\n"
      @"UI Hierarchy";
  XCTAssertTrue([_handler.details containsString:expectedDetails]);
}

/**
 * Checks the formatting for an assertion failure.
 */
- (void)testAssertionInteractionErrorDescription {
  [[EarlGrey selectElementWithMatcher:grey_keyWindow()] assertWithMatcher:grey_nil()];
  NSString *expectedDetailsTillElement = @"Element does not meet assertion criteria: isNil \n"
                                          "Element: <UIWindow:";
  NSString *expectedDetailsForMatcher = @"\n\nMismatch: isNil.\n\nElement Matcher:\n"
                                        @"(kindOfClass('UIWindow') && keyWindow)\n\nUI Hierarchy";
  XCTAssertTrue([_handler.details containsString:expectedDetailsTillElement],
                @"Expected info does not appear in the actual exception details:\n\n"
                @"========== expected info ===========\n%@\n\n"
                @"========== actual exception details ==========\n%@",
                expectedDetailsTillElement, _handler.details);
  XCTAssertTrue([_handler.details containsString:expectedDetailsForMatcher],
                @"Expected info does not appear in the actual exception details:\n\n"
                @"========== expected info ===========\n%@\n\n"
                @"========== actual exception details ==========\n%@",
                expectedDetailsForMatcher, _handler.details);
}

@end
