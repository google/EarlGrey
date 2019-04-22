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

#import <XCTest/XCTest.h>

#import "BaseIntegrationTest.h"

@interface EarlGreyImplTest : BaseIntegrationTest
@end

// Custom Failure handler for the EarlGreyImpl Tests.
@interface GREYTestingFailureHandler : NSObject <GREYFailureHandler>
@property NSString *fileName;
@property(assign) NSUInteger lineNumber;
@property GREYFrameworkException *exception;
@property NSString *details;
@end

// Failure handler for EarlGrey unit tests
@implementation GREYTestingFailureHandler

- (void)resetIvars {
  self.exception = nil;
  self.details = nil;
  self.fileName = nil;
  self.lineNumber = 0;
}

- (void)handleException:(GREYFrameworkException *)exception details:(NSString *)details {
  self.exception = exception;
  self.details = details;
}

- (void)setInvocationFile:(NSString *)fileName andInvocationLine:(NSUInteger)lineNumber {
  self.fileName = fileName;
  self.lineNumber = lineNumber;
}

@end

@implementation EarlGreyImplTest

- (void)setUp {
  [super setUp];
  [self openTestViewNamed:@"Typing Views"];
}

/**
 *  Test to type a word in a text field. However, on typing each letter in the word, a keyboard
 *  dismissal is done and the next letter is typed independently. Once all letters are typed, the
 *  word is finally asserted for being present in the text field.
 */
- (void)testDismissingKeyboard {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_tap()];
  // Ensure the keyboard button for the character e is visible.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"e")]
      assertWithMatcher:grey_sufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_typeText(@"h")];
  [EarlGrey dismissKeyboardWithError:nil];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"e")]
      assertWithMatcher:grey_notVisible()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      assertWithMatcher:grey_text(@"h")];
}

/**
 *  Test to check if the error returned on failure is the same as the keyboard dismissal one.
 */
- (void)testDismissingKeyboardError {
  NSError *error;
  XCTAssertFalse([EarlGrey dismissKeyboardWithError:&error]);
  XCTAssertEqualObjects(error.domain, kGREYKeyboardDismissalErrorDomain);
  XCTAssertEqual(error.code, GREYKeyboardDismissalFailedErrorCode);
}

/**
 *  Sanity check for RMI calls for matcher and action shorthand calls.
 */
- (void)testSelectElementWithMatcherWithRMICall {
  XCTAssertNoThrow(grey_anyOf(grey_interactable(), grey_firstResponder(), nil));
  XCTAssertNoThrow(grey_allOf(grey_accessibilityID(@"Text Field"), grey_interactable(), nil));
  XCTAssertNotNil([EarlGrey selectElementWithMatcher:grey_allOf(grey_accessibilityID(@"Text Field"),
                                                                grey_interactable(), nil)]);
  XCTAssertNoThrow(({
    [[EarlGrey selectElementWithMatcher:grey_keyWindow()]
        assertWithMatcher:grey_sufficientlyVisible()];
  }));
  XCTAssertThrows(({ [[EarlGrey selectElementWithMatcher:grey_keyWindow()] performAction:nil]; }));
  XCTAssertThrows(
      ({ [[EarlGrey selectElementWithMatcher:grey_keyWindow()] assertWithMatcher:nil]; }));
  XCTAssertThrows(({
    [[[EarlGrey selectElementWithMatcher:grey_keyWindow()] performAction:grey_tap()]
           usingSearchAction:nil
        onElementWithMatcher:grey_keyWindow()];
  }));
  XCTAssertThrows(({
    [[[EarlGrey selectElementWithMatcher:grey_keyWindow()] performAction:grey_tap()]
           usingSearchAction:grey_tap()
        onElementWithMatcher:nil];
  }));
  XCTAssertThrows(({
    [[[EarlGrey selectElementWithMatcher:grey_keyWindow()] assertWithMatcher:grey_notNil()]
        inRoot:nil];
  }));
}

- (void)testFailureHandlerIsInvokedByEarlGrey {
  GREYTestingFailureHandler *handler = [[GREYTestingFailureHandler alloc] init];
  [EarlGrey setFailureHandler:handler];
  GREYFrameworkException *exception = [GREYFrameworkException exceptionWithName:@"foo" reason:nil];
  NSUInteger lineNumber = __LINE__;
  [EarlGrey handleException:exception details:@"bar"];
  XCTAssertEqualObjects(handler.exception, exception);
  XCTAssertEqualObjects(handler.details, @"bar");
  XCTAssertEqualObjects(handler.fileName, [NSString stringWithUTF8String:__FILE__]);
  XCTAssertEqual(handler.lineNumber, lineNumber + 1 /* failure happens in next line */);
}

- (void)testFailureHandlerIsSet {
  id<GREYFailureHandler> failureHandler = GetCurrentFailureHandler();
  XCTAssertNotNil(failureHandler);
}

- (void)testFailureHandlerSetToNewValue {
  id<GREYFailureHandler> handler = [[GREYTestingFailureHandler alloc] init];
  [EarlGrey setFailureHandler:handler];
  XCTAssertEqualObjects(GetCurrentFailureHandler(), handler);
}

- (void)testFailureHandlerResetsWhenSetToNil {
  id<GREYFailureHandler> handler = [[GREYTestingFailureHandler alloc] init];
  [EarlGrey setFailureHandler:handler];
  XCTAssertEqualObjects(GetCurrentFailureHandler(), handler);

  [EarlGrey setFailureHandler:nil];
  id<GREYFailureHandler> failureHandler = GetCurrentFailureHandler();
  XCTAssertNotNil(failureHandler);
  XCTAssertNotEqualObjects(failureHandler, handler);
}

- (void)testEarlGreyIsSingleton {
  id instance1 = EarlGrey;
  id instance2 = EarlGrey;
  XCTAssertEqual(instance1, instance2, @"EarlGrey is a singleton so instances much be the same");
}

static inline id<GREYFailureHandler> GetCurrentFailureHandler() {
  return [[[NSThread mainThread] threadDictionary] valueForKey:kGREYFailureHandlerKey];
}

@end
