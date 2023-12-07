//
// Copyright 2018 Google Inc.
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

// Note: GREYKeyboard should not be used in test cases of EarlGrey users. We are only using it here
// for test purpose.
#import "EarlGrey.h"
#import "GREYHostApplicationDistantObject+KeyboardKeysTest.h"
#import "FailureHandler.h"

@interface KeyboardKeysTest : BaseIntegrationTest
@end

@interface GREYKeyboard (ExposedForTesting)
// Expose shiftKeyIdentifyingCharacters property for testing.
@property(class, readonly) NSArray *shiftKeyIdentifyingCharacters;
@end

// TODO: 3 tests are not ported since GREYActionBlock is not supported by eDO // // NOLINT
// on test side. Will need to find workaround for it.
@implementation KeyboardKeysTest

- (void)setUp {
  [super setUp];
  [self openTestViewNamed:@"Typing Views"];
}

- (void)tearDown {
  [[GREYConfiguration sharedConfiguration] reset];
  [super tearDown];
}

- (void)testTypingAtBeginning {
  [[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:GREYTypeText(@"Foo")] performAction:[GREYActions actionForTypeText:@"Bar"
                                                                             atPosition:0]]
      assertWithMatcher:GREYText(@"BarFoo")];
}

- (void)testKeyboardIsShown {
  XCTAssertFalse([EarlGrey isKeyboardShownWithError:nil],
                 @"Keyboard is not shown when there is no first responder");
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:GREYTap()];
  XCTAssertTrue([EarlGrey isKeyboardShownWithError:nil],
                @"Keyboard is shown when there is a first responder");
}

- (void)testTypingAtEnd {
  [[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:GREYTypeText(@"Foo")] performAction:[GREYActions actionForTypeText:@"Bar"
                                                                             atPosition:-1]]
      assertWithMatcher:GREYText(@"FooBar")];
}

- (void)testTypingInMiddle {
  [[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:GREYTypeText(@"Foo")] performAction:[GREYActions actionForTypeText:@"Bar"
                                                                             atPosition:2]]
      assertWithMatcher:GREYText(@"FoBaro")];
}

- (void)testTypingInMiddleOfBigString {
  id<GREYAction> typeLongTextAction =
      GREYTypeText(@"This string is a little too long for this text field!");
  [[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:typeLongTextAction] performAction:[GREYActions actionForTypeText:@"Foo"
                                                                          atPosition:1]]
      assertWithMatcher:GREYText(@"TFoohis string is a little too long for this text field!")];
}

- (void)testTypingAfterTappingOnTextField {
  [[[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:GREYTap()] performAction:GREYTypeText(@"foo")] performAction:GREYClearText()]
      assertWithMatcher:GREYText(@"")];
}

- (void)testClearAfterTyping {
  [[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:GREYTypeText(@"Foo")] performAction:GREYClearText()]
      assertWithMatcher:GREYText(@"")];
}

- (void)testClearAfterClearing {
  [[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:GREYClearText()] performAction:GREYClearText()]
      assertWithMatcher:GREYText(@"")];
}

- (void)testClearAndType_TypeShort {
  [[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:GREYClearText()] performAction:GREYTypeText(@"Foo")]
      assertWithMatcher:GREYText(@"Foo")];
}

- (void)testTypeAfterClearing_ClearThenType {
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:GREYTypeText(@"f")] assertWithMatcher:GREYText(@"f")];

  [[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:GREYClearText()] performAction:GREYTypeText(@"g")]
      assertWithMatcher:GREYText(@"g")];
}

- (void)testTypeAfterClearing_TypeLong {
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:GREYTypeText(@"This is a long string")]
      assertWithMatcher:GREYText(@"This is a long string")];

  [[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:GREYClearText()] performAction:GREYTypeText(@"short string")]
      assertWithMatcher:GREYText(@"short string")];
}

- (void)testNonTypistKeyboardInteraction {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:GREYTap()];

  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"A")] performAction:GREYTap()];

  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"b")] performAction:GREYTap()];

  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"c")] performAction:GREYTap()];

  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"return")] performAction:GREYTap()];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      assertWithMatcher:GREYText(@"Abc")];
}

- (void)testNonTypingTextField {
  [NSThread mainThread].threadDictionary[GREYFailureHandlerKey] = [[FailureHandler alloc] init];

  @try {
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"NonTypingTextField")]
        performAction:GREYTypeText(@"Should Fail")];
    GREYFail(@"Should throw an exception");
  } @catch (NSException *exception) {
    NSRange exceptionRange =
        [[exception reason] rangeOfString:@"Keyboard did not appear after tapping on an element."];
    GREYAssertTrue(exceptionRange.length > 0,
                   @"Should throw exception indicating keyboard did not appear.");
  }
}

- (void)testTypingWordsThatTriggerAutoCorrect {
  NSString *string = @"hekp";
  [self ftr_typeString:string andVerifyOutput:string];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:GREYClearText()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextView")]
      performAction:GREYClearText()];

  string = @"helko";
  [self ftr_typeString:string andVerifyOutput:string];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:GREYClearText()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextView")]
      performAction:GREYClearText()];

  string = @"balk";
  [self ftr_typeString:string andVerifyOutput:string];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:GREYClearText()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextView")]
      performAction:GREYClearText()];

  string = @"surr";
  [self ftr_typeString:string andVerifyOutput:string];
}

- (void)testNumbersTyping {
  NSString *string = @"1234567890";
  [self ftr_typeString:string andVerifyOutput:string];
}

- (void)testSymbolsTyping {
  NSString *string = @"~!@#$%^&*()_+-={}:;<>?";
  [self ftr_typeString:string andVerifyOutput:string];
}

- (void)testLetterTyping {
  NSString *string = @"aBc";
  [self ftr_typeString:string andVerifyOutput:string];
}

- (void)testEmailTyping {
  NSString *string = @"donec.metus+spam@google.com";
  [self ftr_typeString:string andVerifyOutput:string];
}

- (void)testUpperCaseLettersTyping {
  NSString *string = @"VERYLONGTEXTWITHMANYLETTERS";
  [self ftr_typeString:string andVerifyOutput:string];
}

- (void)testNumbersAndSpacesTyping {
  NSString *string = @"0 1 2 3 4 5 6 7 8 9";
  [self ftr_typeString:string andVerifyOutput:string];
}

- (void)testSymbolsAndSpacesTyping {
  NSString *string = @"[ ] # + = _ < > { }";
  [self ftr_typeString:string andVerifyOutput:string];
}

- (void)testSymbolsAndNumbersWithSpacesTyping {
  NSString *string = @": A $ 1 = a 0 ^ 8 ;";
  [self ftr_typeString:string andVerifyOutput:string];
}

- (void)testSpaceKey {
  NSString *string = @"a b";
  [self ftr_typeString:string andVerifyOutput:string];
}

- (void)testBackspaceKey {
  NSString *string = @"ab\b";
  NSString *verificationString = @"a";
  [self ftr_typeString:string andVerifyOutput:verificationString];
}

- (void)testReturnKey {
  NSString *kbViewClassName = @"UIKeyboardImpl";
  NSString *textFieldString = @"and\n";
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:GREYTypeText(textFieldString)] assertWithMatcher:GREYText(@"and")];

  [[EarlGrey selectElementWithMatcher:GREYKindOfClassName(kbViewClassName)]
      assertWithMatcher:GREYNil()];

  NSString *string = @"and\nand";
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextView")]
      performAction:GREYTypeText(string)] assertWithMatcher:GREYText(@"and\nand")];

  [[EarlGrey selectElementWithMatcher:GREYKindOfClassName(kbViewClassName)]
      assertWithMatcher:GREYNotNil()];
}

- (void)testAllReturnKeyTypes {
  NSString *kbViewClassName = @"UIKeyboardImpl";
  // There are 11 returnKeyTypes; test all of them.
  for (int i = 0; i < 11; i++) {
    [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
        performAction:GREYTypeText(@"a\n")] assertWithMatcher:GREYText(@"a")];

    [[EarlGrey selectElementWithMatcher:GREYKindOfClassName(kbViewClassName)]
        assertWithMatcher:GREYNil()];

    [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
        performAction:GREYTypeText(@"*\n")] assertWithMatcher:GREYText(@"a*")];

    [[EarlGrey selectElementWithMatcher:GREYKindOfClassName(kbViewClassName)]
        assertWithMatcher:GREYNil()];

    [[EarlGrey selectElementWithMatcher:GREYButtonTitle(@"next returnKeyType")]
        performAction:GREYTap()];
  }
}

- (void)testPanelNavigation {
  NSString *string = @"a1a%a%1%";
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:GREYTypeText(string)];
}

- (void)testKeyplaneIsDetectedCorrectlyWhenSwitchingTextFields {
  NSString *string = @"$";

  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:GREYTypeText(string)] assertWithMatcher:GREYText(string)];

  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextView")]
      performAction:GREYTypeText(string)] assertWithMatcher:GREYText(string)];
}

- (void)testUIKeyboardTypeDefault {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"KeyboardPicker")]
      performAction:GREYSetPickerColumnToValue(0, @"Default")];

  NSString *string = @":$a8. {T<b@CC";
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:GREYTypeText(string)] assertWithMatcher:GREYText(string)];
}

- (void)testUIKeyboardTypeASCIICapable {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"KeyboardPicker")]
      performAction:GREYSetPickerColumnToValue(0, @"ASCIICapable")];

  NSString *string = @":$a8. {T<b@CC";
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:GREYTypeText(string)] assertWithMatcher:GREYText(string)];
}

- (void)testUIKeyboardTypeNumbersAndPunctuation {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"KeyboardPicker")]
      performAction:GREYSetPickerColumnToValue(0, @"NumbersAndPunctuation")];

  NSString *string = @":$a8. {T<b@CC";
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:GREYTypeText(string)] assertWithMatcher:GREYText(string)];
}

- (void)testUIKeyboardTypeURL {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"KeyboardPicker")]
      performAction:GREYSetPickerColumnToValue(0, @"URL")];

  NSString *string = @"http://www.google.com/@*s$&T+t?[]#testLabel%foo;";
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:GREYTypeText(string)] assertWithMatcher:GREYText(string)];
}

- (void)testUIKeyboardTypeNumberPad {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"KeyboardPicker")]
      performAction:GREYSetPickerColumnToValue(0, @"NumberPad")];

  NSString *string = @"\b0123456\b789\b\b";
  NSString *verificationString = @"0123457";
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:GREYTypeText(string)] assertWithMatcher:GREYText(verificationString)];
}

- (void)testUIKeyboardTypePhonePad {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"KeyboardPicker")]
      performAction:GREYSetPickerColumnToValue(0, @"PhonePad")];

  NSString *string = @"01*23\b\b+45#67,89;";
  NSString *verificationString = @"01*+45#67,89;";
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:GREYTypeText(string)] assertWithMatcher:GREYText(verificationString)];
}

- (void)testUIKeyboardTypeEmailAddress {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"KeyboardPicker")]
      performAction:GREYSetPickerColumnToValue(0, @"EmailAddress")];

  NSString *string = @"l0rem.ipsum+42@google.com#$_T*-";
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:GREYTypeText(string)] assertWithMatcher:GREYText(string)];
}

- (void)testUIKeyboardTypeDecimalPad {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"KeyboardPicker")]
      performAction:GREYSetPickerColumnToValue(0, @"DecimalPad")];

  NSString *string = @"\b0123.456\b78..9\b\b";
  NSString *verificationString = @"0123.4578.";
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:GREYTypeText(string)] assertWithMatcher:GREYText(verificationString)];
}

- (void)testUIKeyboardTypeTwitter {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"KeyboardPicker")]
      performAction:GREYSetPickerColumnToValue(0, @"Twitter")];

  NSString *string = @"@earlgrey Your framework is #awesome!!!1$:,eG%g\n";
  NSString *verificationString = @"@earlgrey Your framework is #awesome!!!1$:,eG%g";
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:GREYTypeText(string)] assertWithMatcher:GREYText(verificationString)];
}

- (void)testUIKeyboardTypeWebSearch {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"KeyboardPicker")]
      performAction:GREYSetPickerColumnToValue(0, @"WebSearch")];

  NSString *string = @":$a8. {T<b@CC";
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:GREYTypeText(string)] assertWithMatcher:GREYText(string)];
}

- (void)testTypingOnLandscapeLeft {
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeLeft error:nil];
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:GREYTypeText(@"Cat")] assertWithMatcher:GREYText(@"Cat")];
}

- (void)testTypingOnLandscapeRight {
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeRight error:nil];
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:GREYTypeText(@"Cat")] assertWithMatcher:GREYText(@"Cat")];
}

- (void)testSuccessivelyTypingInTheSameTextField {
  [[[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:GREYTypeText(@"This ")] performAction:GREYTypeText(@"Is A ")]
      performAction:GREYTypeText(@"Test")] assertWithMatcher:GREYText(@"This Is A Test")];
}

- (void)testTypingBlankString {
  NSString *string = @"       ";
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:GREYTypeText(string)] assertWithMatcher:GREYText(string)];
}

- (void)testClearAfterTypingInCustomTextView {
  [[[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"CustomTextView")]
      performAction:GREYTypeText(@"Foo")] assertWithMatcher:GREYAccessibilityLabel(@"Foo")]
      performAction:GREYClearText()] assertWithMatcher:GREYAccessibilityLabel(@"")];
}

- (void)testClearAfterClearingInCustomTextView {
  [[[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"CustomTextView")]
      performAction:GREYClearText()] assertWithMatcher:GREYAccessibilityLabel(@"")]
      performAction:GREYClearText()] assertWithMatcher:GREYAccessibilityLabel(@"")];
}

- (void)testTypeAfterClearingInCustomTextView {
  [[[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"CustomTextView")]
      performAction:GREYClearText()] assertWithMatcher:GREYAccessibilityLabel(@"")]
      performAction:GREYTypeText(@"Foo")] assertWithMatcher:GREYAccessibilityLabel(@"Foo")];
}

- (void)testKeyplaneChangeInCustomTextView {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"CustomTextView")]
      performAction:GREYTypeText(@"AAAAA")];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"CustomTextView")]
      performAction:GREYTypeText(@"\b")];
  // Keyplane should change to uppercase keyplane with backspace.
  // Note: iOS 15 onwards, the keyplane does not change. This is a general change in custom text
  // views with iOS 15.
  if (@available(iOS 15.0, *)) {
    [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"q")]
        assertWithMatcher:GREYSufficientlyVisible()];
  } else {
    [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Q")]
        assertWithMatcher:GREYSufficientlyVisible()];
  }
}

- (void)testKeyplaneChangeInTextField {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:GREYTypeText(@"AAAAA")];
  // Keyplane should change to lowercase keyplane when capital letter typed.
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"q")]
      assertWithMatcher:GREYSufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:GREYTypeText(@"\b")];
  // For versions before iOS16, pressing backspace should reset the keyplane appropriately to the
  // autoCapitalizationType property from the text input view. In this test, the text field has auto
  // capitalization on, so it should reset to uppercase keyplane on.
  if (@available(iOS 16.0, *)) {
    [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"q")]
        assertWithMatcher:GREYSufficientlyVisible()];
  } else {
    [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Q")]
        assertWithMatcher:GREYSufficientlyVisible()];
  }
}

- (void)testTypingOnTextFieldInUIInputAccessory {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"Input Button")]
      performAction:GREYTap()];
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"InputAccessoryTextField")]
      performAction:GREYTypeText(@"Test")] assertWithMatcher:GREYText(@"Test")];
}

- (void)testMatchingFailsWithUIAccessibilityTextFieldElement {
  if (iOS13()) {
    id<GREYMatcher> elementMatcher =
        grey_allOf(GREYAccessibilityValue(@"Text Field"),
                   GREYKindOfClassName(kTextFieldAXElementClassName), nil);
    [[EarlGrey selectElementWithMatcher:elementMatcher] assertWithMatcher:GREYNotNil()];
    NSError *error;
    [[EarlGrey selectElementWithMatcher:elementMatcher] performAction:GREYClearText()
                                                                error:&error];
    XCTAssertNil(error, @"Typing on a UIAccessibilityElement has an error: %@", error);
    [[EarlGrey selectElementWithMatcher:elementMatcher] performAction:GREYTypeText(@"a")];
  }
}

- (void)testClearAndReplaceWorksWithUIAccessibilityTextFieldElement {
  XCTSkipIf(iOS14_OR_ABOVE());
  id<GREYMatcher> elementMatcher =
      grey_allOf(GREYAccessibilityValue(@"Text Field"),
                 GREYKindOfClassName(kTextFieldAXElementClassName), nil);
  if (iOS13_OR_ABOVE()) {
    [[EarlGrey selectElementWithMatcher:elementMatcher] assertWithMatcher:GREYNotNil()];
    NSError *error;
    [[EarlGrey selectElementWithMatcher:elementMatcher] performAction:GREYClearText()
                                                                error:&error];
    XCTAssertNil(error, @"Typing on a UIAccessibilityElement has an error: %@", error);
    [[EarlGrey selectElementWithMatcher:elementMatcher] performAction:GREYTypeText(@"a")];
  } else {
    [[[EarlGrey selectElementWithMatcher:elementMatcher] performAction:GREYClearText()]
        performAction:GREYReplaceText(@"foo")];
    // Ensure the element exists by tapping on it. This also removes the cursor.
    [[EarlGrey selectElementWithMatcher:GREYTextFieldValue(@"foo")] performAction:GREYTap()];
  }
}
- (void)testTypingAndResigningOfFirstResponder {
  GREYAssertFalse([GREYKeyboard keyboardShownWithError:nil], @"Keyboard shouldn't be shown");

  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:GREYTypeText(@"Foo")] assertWithMatcher:GREYText(@"Foo")];
  GREYAssertTrue([GREYKeyboard keyboardShownWithError:nil], @"Keyboard shouldn't be shown");

  XCTAssertTrue([EarlGrey dismissKeyboardWithError:nil]);
  GREYAssertFalse([GREYKeyboard keyboardShownWithError:nil],
                  @"Keyboard shouldn't be shown as it is resigned");

  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:GREYTypeText(@"Foo")] assertWithMatcher:GREYText(@"FooFoo")];
  GREYAssertTrue([GREYKeyboard keyboardShownWithError:nil], @"Keyboard shouldn't be shown");
}

- (void)testTogglingShiftByChangingCase {
  NSString *multiCaseString = @"aA1a1A1aA1AaAa1A1a";
  for (NSUInteger i = 0; i < multiCaseString.length; i++) {
    NSString *currentCharacter = [multiCaseString substringWithRange:NSMakeRange(i, 1)];
    [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
        performAction:GREYTypeText(currentCharacter)]
        assertWithMatcher:GREYText([multiCaseString substringToIndex:i + 1])];
    id keyboardClass = GREY_REMOTE_CLASS_IN_APP(GREYKeyboard);
    for (NSString *axLabel in [[keyboardClass returnByValue] shiftKeyIdentifyingCharacters]) {
      NSError *error;
      [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(axLabel)] performAction:GREYTap()
                                                                                    error:&error];
    }
  }

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      assertWithMatcher:GREYText(multiCaseString)];
}

- (void)testIsKeyboardShownWithCustomKeyboardTracker {
  GREYAssertFalse([GREYKeyboard keyboardShownWithError:nil], @"Keyboard shouldn't be shown");

  GREYHostApplicationDistantObject *host = GREYHostApplicationDistantObject.sharedInstance;
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"CustomKeyboardTracker")]
      performAction:host.actionForSetFirstResponder];
  GREYAssertFalse([GREYKeyboard keyboardShownWithError:nil], @"Keyboard shouldn't be shown");
}

/**
 *  Verifies error details for dismissing a keyboard when the keyboard is not present.
 */
- (void)testTypingAndResigningWithError {
  GREYAssertFalse([GREYKeyboard keyboardShownWithError:nil], @"Keyboard shouldn't be shown");

  GREYHostApplicationDistantObject *host = GREYHostApplicationDistantObject.sharedInstance;
  NSError *error;
  XCTAssertFalse([EarlGrey dismissKeyboardWithError:&error]);
  NSString *localizedErrorDescription = [error localizedDescription];
  NSString *reason = @"Failed to dismiss keyboard:";
  GREYAssertTrue([localizedErrorDescription containsString:reason],
                 @"Unexpected error message for initial dismiss: %@, Original error: %@",
                 localizedErrorDescription, error);

  [[EarlGrey selectElementWithMatcher:GREYKeyWindow()] performAction:host.actionForSetFirstResponder
                                                               error:&error];
  XCTAssertFalse([EarlGrey dismissKeyboardWithError:&error]);
  localizedErrorDescription = [error localizedDescription];
  GREYAssertTrue([localizedErrorDescription containsString:reason],
                 @"Unexpected error message for second dismiss: %@, Original error: %@",
                 localizedErrorDescription, error);
}

- (void)testDismissingKeyboardWhenReturnIsNotPresent {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"KeyboardPicker")]
      performAction:GREYSetPickerColumnToValue(0, @"PhonePad")];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:GREYTap()];
  XCTAssertTrue([EarlGrey dismissKeyboardWithError:nil]);
}

- (void)testDismissingKeyboardWhenReturnIsPresentButDoesNotDismissTheKeyboard {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"CustomTextView")]
      performAction:GREYTap()];
  NSError *error;
  XCTAssertTrue([EarlGrey dismissKeyboardWithError:&error]);
  XCTAssertNil(error);
  GREYAssertFalse([GREYKeyboard keyboardShownWithError:nil], @"Keyboard shouldn't be shown");
}

- (void)testTextViewDidChangeCalled {
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextView")]
      performAction:GREYTypeText(@"Check Delegate")]
      assertWithMatcher:GREYText(@"textViewDidChange Called")];
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextView")]
      performAction:GREYReplaceText(@"Check Delegate")]
      assertWithMatcher:GREYText(@"textViewDidChange Called")];
}

- (void)testReplaceTextTypingForAnEmoji {
  NSString *emoji = @"😒";
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:GREYReplaceText(emoji)] assertWithMatcher:GREYText(emoji)];
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextView")]
      performAction:GREYReplaceText(emoji)] assertWithMatcher:GREYText(emoji)];
}

/**
 * Ensures that EarlGrey doesn't wait any longer after a typing action for the keyboard's Caret
 * animation to be be tracked.
 */
- (void)testCaretBlinkingAnimationNotTracked {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:GREYTypeText(@"Foo")];
  GREYConfiguration *config = [GREYConfiguration sharedConfiguration];
  [config setValue:@(3) forConfigKey:kGREYConfigKeyInteractionTimeoutDuration];
  NSError *error;
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:GREYClearText()
              error:&error];
  XCTAssertFalse([error.description containsString:@"UITextSelectionViewCaretBlinkAnimation"],
                 @"Caret blinking animation should not be present");
}

- (void)testCursorNotPresent {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:GREYTap()];
  id<GREYMatcher> cursorMatcher = nil;
  if (iOS17_OR_ABOVE()) {
    cursorMatcher = grey_allOf(GREYAncestor(GREYKindOfClassName(@"_UITextCursorView")),
                               GREYKindOfClassName(@"_UIShapeView"), nil);
  } else {
    cursorMatcher = GREYKindOfClassName(@"UITextSelectionView");
  }
  [[EarlGrey selectElementWithMatcher:cursorMatcher] assertWithMatcher:GREYHidden(YES)];
}

#pragma mark - Private

- (void)ftr_typeString:(NSString *)string andVerifyOutput:(NSString *)verificationString {
  [[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:GREYTypeText(string)] performAction:GREYTypeText(@"\n")]
      assertWithMatcher:GREYText(verificationString)];
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextView")]
      performAction:GREYTypeText(string)] assertWithMatcher:GREYText(verificationString)];
  [[EarlGrey selectElementWithMatcher:GREYButtonTitle(@"Done")] performAction:GREYTap()];
}

@end
