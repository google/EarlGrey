//
// Copyright 2016 Google Inc.
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
#import "FailureHandler.h"

@interface AccessibilityTest : BaseIntegrationTest
@end

// TODO: Test edge cases for UI Accessibility Element visibility as well.
@implementation AccessibilityTest

- (void)setUp {
  [super setUp];
  [self openTestViewNamed:@"Accessibility Views"];
}

// Test for https://github.com/google/EarlGrey/issues/108
- (void)testAccessibilityMessageViewController {
  [[EarlGrey selectElementWithMatcher:grey_buttonTitle(@"Open MVC")] performAction:grey_tap()];
  [[[EarlGrey selectElementWithMatcher:grey_anything()] atIndex:0] assertWithMatcher:grey_notNil()];
}

- (void)testAccessibilityValues {
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityValue(@"SquareElementValue")]
      assertWithMatcher:grey_sufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityValue(@"CircleElementValue")]
      assertWithMatcher:grey_sufficientlyVisible()];
  [[EarlGrey
      selectElementWithMatcher:GREYAccessibilityValue(@"PartialOffScreenRectangleElementValue")]
      assertWithMatcher:grey_not(grey_sufficientlyVisible())];
}

- (void)testAccessibilityElementTappedSuccessfullyWithTapAtPoint {
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"SquareElementLabel")]
      performAction:grey_tapAtPoint(CGPointMake(1, 1))];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"AccessibilityElementStatus")]
      assertWithMatcher:grey_text(@"Square Tapped")];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"CircleElementLabel")]
      performAction:grey_tapAtPoint(CGPointMake(49, 49))];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"AccessibilityElementStatus")]
      assertWithMatcher:grey_text(@"Circle Tapped")];
}

- (void)testSquareTappedSuccessfully {
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"SquareElementLabel")]
      assertWithMatcher:grey_sufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"SquareElementLabel")]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"AccessibilityElementStatus")]
      assertWithMatcher:grey_text(@"Square Tapped")];
}

- (void)testSquareTappedAtOriginSuccessfully {
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"SquareElementLabel")]
      assertWithMatcher:grey_sufficientlyVisible()];
  // Square element rect is {50, 150, 100, 100}
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"SquareElementLabel")]
      performAction:grey_tapAtPoint(CGPointMake(0, 0))];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"AccessibilityElementStatus")]
      assertWithMatcher:grey_text(@"Square Tapped")];
}

- (void)testSquareTappedAtSpecificPointSuccessfully {
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"SquareElementLabel")]
      assertWithMatcher:grey_sufficientlyVisible()];
  // Square element rect is {50, 150, 100, 100}
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"SquareElementLabel")]
      performAction:grey_tapAtPoint(CGPointMake(50, 50))];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"AccessibilityElementStatus")]
      assertWithMatcher:grey_text(@"Square Tapped")];
}

- (void)testSquareTappedAtEndBoundsSuccessfully {
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"SquareElementLabel")]
      assertWithMatcher:grey_sufficientlyVisible()];
  // Square element rect is {50, 150, 100, 100}
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"SquareElementLabel")]
      performAction:grey_tapAtPoint(CGPointMake(99, 99))];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"AccessibilityElementStatus")]
      assertWithMatcher:grey_text(@"Square Tapped")];
}

- (void)testSquareTappedOutsideBoundsDoesNothing {
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"SquareElementLabel")]
      assertWithMatcher:grey_sufficientlyVisible()];
  // Square element rect is {50, 150, 100, 100}
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"SquareElementLabel")]
      performAction:grey_tapAtPoint(CGPointMake(151, 251))];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"AccessibilityElementStatus")]
      assertWithMatcher:grey_not(grey_text(@"Square Tapped"))];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"SquareElementLabel")]
      performAction:grey_tapAtPoint(CGPointMake(49, 150))];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"AccessibilityElementStatus")]
      assertWithMatcher:grey_not(grey_text(@"Square Tapped"))];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"SquareElementLabel")]
      performAction:grey_tapAtPoint(CGPointMake(50, 149))];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"AccessibilityElementStatus")]
      assertWithMatcher:grey_not(grey_text(@"Square Tapped"))];
}

- (void)testSquareTappedOutsideWindowBoundsFails {
  [NSThread mainThread].threadDictionary[GREYFailureHandlerKey] = [[FailureHandler alloc] init];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"SquareElementLabel")]
      assertWithMatcher:grey_sufficientlyVisible()];

  @try {
    // Square element rect is {50, 150, 100, 100}
    [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"SquareElementLabel")]
        performAction:grey_tapAtPoint(CGPointMake(-51, -151))];
    GREYFail(@"Should throw an exception");
  } @catch (NSException *exception) {
    NSRange exceptionRange = [[exception reason] rangeOfString:@"Cannot perform tap"];
    GREYAssertNotEqual(exceptionRange.location, NSNotFound, @"Action error should be present.");
  }
}

- (void)testCircleTappedSuccessfully {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"CircleElementIdentifier")]
      assertWithMatcher:grey_sufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"CircleElementIdentifier")]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"AccessibilityElementStatus")]
      assertWithMatcher:grey_text(@"Circle Tapped")];
}

- (void)testRectangleIsNotSufficientlyVisible {
  [[EarlGrey
      selectElementWithMatcher:GREYAccessibilityLabel(@"PartialOffScreenRectangleElementLabel")]
      assertWithMatcher:grey_not(grey_sufficientlyVisible())];
}

- (void)testErrorDescriptionOfVisibilityMatchers {
  NSError *error;
  [[EarlGrey
      selectElementWithMatcher:GREYAccessibilityLabel(@"PartialOffScreenRectangleElementLabel")]
      assertWithMatcher:grey_sufficientlyVisible()
                  error:&error];
  XCTAssertTrue([error.description containsString:@"Expected:"]);
  XCTAssertTrue([error.description containsString:@"Actual:"]);

  error = nil;
  [[EarlGrey
      selectElementWithMatcher:GREYAccessibilityLabel(@"PartialOffScreenRectangleElementLabel")]
      assertWithMatcher:grey_minimumVisiblePercent(1.0)
                  error:&error];
  XCTAssertTrue([error.description containsString:@"Expected:"]);
  XCTAssertTrue([error.description containsString:@"Actual:"]);
}

- (void)testOffScreenAccessibilityElementIsNotVisible {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"OffScreenElementIdentifier")]
      assertWithMatcher:grey_notVisible()];
}

- (void)testElementWithZeroHeightIsNotVisible {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"ElementWithZeroHeightIdentifier")]
      assertWithMatcher:grey_notVisible()];
}

- (void)testElementWithZeroWidthIsNotVisible {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"ElementWithZeroWidthIdentifier")]
      assertWithMatcher:grey_notVisible()];
}

- (void)testTapElementPartiallyOutside {
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"PartiallyOutsideElementLabel")]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"AccessibilityElementStatus")]
      assertWithMatcher:grey_text(@"Partially Outside Tapped")];
}

@end
