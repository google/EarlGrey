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
#import "EarlGrey.h"
#import "BaseIntegrationTest.h"

/**
 * Keyboard typing tests that cause flakiness on iOS 12 or earlier due to keyplane changing
 * unexpectedly after typing space key or uppercase letter.
 */
@interface KeyboardKeysTest_IOS12OrEarlier : BaseIntegrationTest
@end

@implementation KeyboardKeysTest_IOS12OrEarlier

- (void)setUp {
  [super setUp];
  [self openTestViewNamed:@"Typing Views"];
}

/**
 * On iOS 12 or earlier, this test is flaky without an explicit sleep after typing space or
 * uppercase letter. (b/149326665)
 */
- (void)testNumbersAndSpacesTyping {
  NSString *string = @"0 1 2 3 4 5 6 7 8 9";
  // With the explicit sleep after each space or capital letter, the minimum time for the type
  // action is equal to the number of spaces times 0.5(s).
  CGFloat minimumSleep = (string.length / 2) * 0.5f;
  CFTimeInterval startTime = CACurrentMediaTime();
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_typeText(string)] assertWithMatcher:grey_text(string)];
  CFTimeInterval duration = CACurrentMediaTime() - startTime;
  XCTAssertGreaterThan(duration, minimumSleep);
}

/**
 * On iOS 12 or earlier, this test is flaky without an explicit sleep after typing space or
 * uppercase letter. (b/149326665)
 */
- (void)testSymbolsAndSpacesTyping {
  NSString *string = @"[ ] # + = _ < > { }";
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_typeText(string)] assertWithMatcher:grey_text(string)];
}

/**
 * This makes sure typing capital letters don't cause flakiness.
 */
- (void)testCapitalLettersTyping {
  NSString *string = @"ABCDEFG";
  // With the explicit sleep after each space or capital letter, the minimum time for the type
  // action is equal to the number of capital letters times 0.5(s).
  CGFloat minimumSleep = string.length * 0.5f;
  CFTimeInterval startTime = CACurrentMediaTime();
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_typeText(string)] assertWithMatcher:grey_text(string)];
  CFTimeInterval duration = CACurrentMediaTime() - startTime;
  XCTAssertGreaterThan(duration, minimumSleep);
}

/**
 * The explicit sleep added to fix the flakiness shouldn't affect the time for clearing the text.
 */
- (void)testClearAfterTyping {
  NSString *string = @"Very long text. This should not take too much time to delete.";
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_typeText(string)];
  // If delete key triggers the sleep, which it shouldn't, the minimum time clearText: would take is
  // the number of chacters in the string times sleep time for each deletion (0.5s). Therefore,
  // assert that the actual duration is less than this minimum time.
  CGFloat minimumSleep = string.length * 0.5f;
  CFTimeInterval startTime = CACurrentMediaTime();
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_clearText()];
  CFTimeInterval duration = CACurrentMediaTime() - startTime;
  XCTAssertLessThanOrEqual(duration, minimumSleep);
}

@end
