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

#import "EarlGrey.h"
#import "BaseIntegrationTest.h"

@interface EarlGreyImplTest : BaseIntegrationTest
@end

// Custom Failure handler for the EarlGreyImpl Tests.
@interface GREYTestingFailureHandler : NSObject <GREYFailureHandler>
@property(nonatomic) NSString *fileName;
@property(nonatomic, assign) NSUInteger lineNumber;
@property(nonatomic) GREYFrameworkException *exception;
@property(nonatomic) NSString *details;
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
 * Test to type a word in a text field. However, on typing each letter in the word, a keyboard
 * dismissal is done and the next letter is typed independently. Once all letters are typed, the
 * word is finally asserted for being present in the text field.
 */
- (void)testDismissingKeyboard {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:GREYTap()];
  // Ensure the keyboard button for the character e is visible.
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"E")]
      assertWithMatcher:GREYSufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:GREYTypeText(@"h")];
  [EarlGrey dismissKeyboardWithError:nil];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"e")]
      assertWithMatcher:GREYNotVisible()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      assertWithMatcher:GREYText(@"h")];
}

/**
 * Test to check if the error returned on failure is the same as the keyboard dismissal one.
 */
- (void)testDismissingKeyboardError {
  NSError *error;
  XCTAssertFalse([EarlGrey dismissKeyboardWithError:&error]);
  XCTAssertEqualObjects(error.domain, kGREYKeyboardDismissalErrorDomain);
  XCTAssertEqual(error.code, GREYKeyboardDismissalFailedErrorCode);
}

/**
 * Sanity check for RMI calls for matcher and action shorthand calls.
 */
- (void)testSelectElementWithMatcherWithRMICall {
  XCTAssertNoThrow(grey_anyOf(GREYFirstResponder(), GREYInteractable(), nil));
  XCTAssertNoThrow(grey_allOf(grey_accessibilityID(@"Text Field"), GREYInteractable(), nil));
  XCTAssertNotNil([EarlGrey selectElementWithMatcher:grey_allOf(grey_accessibilityID(@"Text Field"),
                                                                GREYInteractable(), nil)]);
  XCTAssertNoThrow(({
    [[EarlGrey selectElementWithMatcher:GREYKeyWindow()]
        assertWithMatcher:GREYSufficientlyVisible()];
  }));
  id<GREYAction> nilAction = nil;
  id<GREYMatcher> nilMatcher = nil;
  XCTAssertThrows(
      ({ [[EarlGrey selectElementWithMatcher:GREYKeyWindow()] performAction:nilAction]; }));
  XCTAssertThrows(
      ({ [[EarlGrey selectElementWithMatcher:GREYKeyWindow()] assertWithMatcher:nilMatcher]; }));
  XCTAssertThrows(({
    [[[EarlGrey selectElementWithMatcher:GREYKeyWindow()] performAction:GREYTap()]
           usingSearchAction:nilAction
        onElementWithMatcher:GREYKeyWindow()];
  }));
  XCTAssertThrows(({
    [[[EarlGrey selectElementWithMatcher:GREYKeyWindow()] performAction:GREYTap()]
           usingSearchAction:GREYTap()
        onElementWithMatcher:nilMatcher];
  }));
  XCTAssertThrows(({
    [[[EarlGrey selectElementWithMatcher:GREYKeyWindow()] assertWithMatcher:GREYNotNil()]
        inRoot:nilMatcher];
  }));
}

- (void)testFailureHandlerIsInvokedByEarlGrey {
  GREYTestingFailureHandler *handler = [[GREYTestingFailureHandler alloc] init];
  [NSThread mainThread].threadDictionary[GREYFailureHandlerKey] = handler;

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

- (void)testFailureHandlerSetToNewValueIsNotReplaced {
  id<GREYFailureHandler> handler = [[GREYTestingFailureHandler alloc] init];
  [NSThread mainThread].threadDictionary[GREYFailureHandlerKey] = handler;
  [EarlGrey isKeyboardShownWithError:nil];
  XCTAssertEqualObjects(GetCurrentFailureHandler(), handler);
}

- (void)testFailureHandlerResetsWhenSetToNil {
  NSThread *mainThread = [NSThread mainThread];
  id<GREYFailureHandler> handler = [[GREYTestingFailureHandler alloc] init];
  mainThread.threadDictionary[GREYFailureHandlerKey] = handler;
  [EarlGrey isKeyboardShownWithError:nil];

  mainThread.threadDictionary[GREYFailureHandlerKey] = nil;
  [EarlGrey isKeyboardShownWithError:nil];
  id<GREYFailureHandler> failureHandler = GetCurrentFailureHandler();
  XCTAssertNotNil(failureHandler);
  XCTAssertNotEqualObjects(failureHandler, handler);
}

- (void)testEarlGreyIsSingleton {
  id instance1 = EarlGrey;
  id instance2 = EarlGrey;
  XCTAssertEqual(instance1, instance2, @"EarlGrey is a singleton so instances much be the same");
}

/** Ensures that an EarlGrey failure does not increment the failure count. */
- (void)testEarlGreyExceptionDoesNotIncrementFailureCount {
  NSUInteger failureCount = self.testRun.failureCount;
  NSError *error;
  [[EarlGrey selectElementWithMatcher:GREYKeyWindow()] assertWithMatcher:GREYNil() error:&error];
  XCTAssertNotNil(error, @"An error should be populated");
  XCTAssertEqual(self.testRun.failureCount, failureCount, @"The failure count is not incremented.");
}

static inline id<GREYFailureHandler> GetCurrentFailureHandler(void) {
  return [[[NSThread mainThread] threadDictionary] valueForKey:GREYFailureHandlerKey];
}

@end
