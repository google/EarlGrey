//
//  EGUITests.m
//  EGUITests
//
//  Created by Brett Fazio on 6/19/19.
//  Copyright © 2019 Google Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <EarlGreyTest/EarlGrey.h>

#import "EarlGreyExampleSwift-Swift.h"

@interface PrintOnlyHandler : NSObject<GREYFailureHandler>
@end

@implementation PrintOnlyHandler

- (void)handleException:(GREYFrameworkException *)exception details:(NSString *)details {
  NSLog(@"Test Failed With Reason : %@ and details : %@", [exception reason], details);
}

@end

@interface EGUITests : XCTestCase
- (id<GREYMatcher>) matcherForThursdays;
@end

@implementation EGUITests

- (void)setUp {
  // Put setup code here. This method is called before the invocation of each test method in the class.

  // In UI tests it is usually best to stop immediately when a failure occurs.
  self.continueAfterFailure = NO;

  // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
  [[[XCUIApplication alloc] init] launch];

  // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testBasicSelection {
  // Select the button with Accessibility ID "clickMe".
  [EarlGrey selectElementWithMatcher:grey_accessibilityID(@"ClickMe")];
}

- (void)testBasicSelectionAndAction {
  // Select and tap the button with Accessibility ID "clickMe".
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"ClickMe")]
   performAction:grey_tap()];
}

- (void)testBasicSelectionAndAssert {
  // Select the button with Accessibility ID "clickMe" and assert it's visible.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"ClickMe")]
   assertWithMatcher:grey_sufficientlyVisible()];
}

- (void)testBasicSelectionActionAssert {
  // Select and tap the button with Accessibility ID "clickMe", then assert it's visible.
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"ClickMe")]
    performAction:grey_tap()]
   assertWithMatcher:grey_sufficientlyVisible()];
}

- (void)testSelectionOnMultipleElements {
  // This test will fail because both buttons are visible and match the selection.
  // We add a custom error here to prevent the Test Suite failing.
  NSError *error;
  [[EarlGrey selectElementWithMatcher:grey_sufficientlyVisible()]
   performAction:grey_tap() error:&error];
  if (error) {
    NSLog(@"Test Failed with Error : %@", [error description]);
  }
}

- (void)testCollectionMatchers {
  id<GREYMatcher> visibleSendButtonMatcher =
  grey_allOf(grey_accessibilityID(@"ClickMe"), grey_sufficientlyVisible(), nil);
  [[EarlGrey selectElementWithMatcher:visibleSendButtonMatcher]
   performAction:grey_doubleTap()];
}

- (void)testWithInRoot {
  // Second way to disambiguate: use inRoot to focus on a specific window or container.
  // There are two buttons with accessibility id "Send", but only one is inside SendMessageView.

  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"Send")]
    inRoot:grey_kindOfClassName(@"EarlGreyExampleSwift.SendMessageView")]
   performAction:grey_doubleTap()];
}

// Define a custom matcher for table cells that contains a date for a Thursday.
- (id<GREYMatcher>)matcherForThursdays {
  GREYMatchesBlock matches = ^BOOL(UITableViewCell *cell) {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterLongStyle;
    NSDate *date = [formatter dateFromString:[[(UITableViewCell *)cell textLabel] text]];
    if (!date) {
      return NO;
    }
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSInteger weekday = [calendar component:NSCalendarUnitWeekday fromDate:date];
    return weekday == 5;
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:@"Date for a Thursday"];
  };

  return [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches
                                              descriptionBlock:describe];
}

- (void)testWithCustomMatcher {
  // Use the custom matcher.
  [[EarlGrey selectElementWithMatcher:grey_allOf(grey_kindOfClass([UITableViewCell class]),
                                                 [self matcherForThursdays], nil)]
   performAction:grey_doubleTap()];
}

- (void)testTableCellOutOfScreen {
  // Go find one cell out of the screen.
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"Cell30")]
    usingSearchAction:grey_scrollInDirection(kGREYDirectionDown, 50)
    onElementWithMatcher:grey_accessibilityID(@"table")]
   performAction:grey_doubleTap()];

  // Move back to top of the table.
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"Cell1")]
    usingSearchAction:grey_scrollInDirection(kGREYDirectionUp, 500)
    onElementWithMatcher:grey_accessibilityID(@"table")]
   performAction:grey_doubleTap()];
}

- (void)testCatchErrorOnFailure {
  // TapMe doesn't exist, but the test doesn't fail because we are getting a pointer to the error.
  NSError *error;
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TapMe")]
   performAction:grey_tap() error:&error];
  if (error) {
    NSLog(@"Error: %@", [error localizedDescription]);
  }
}

// Fade in and out an element.
- (void)fadeInAndOut:(UIView *)element {
  [UIView animateWithDuration:1.0
                        delay:0.0
                      options:UIViewAnimationOptionCurveEaseOut
                   animations: ^{
                     element.alpha = 0.0;}
                   completion: ^(BOOL finished) {
                     [UIView animateWithDuration:1.0
                                           delay:0.0
                                         options:UIViewAnimationOptionCurveEaseIn
                                      animations: ^{
                                        element.alpha = 1.0;}
                                      completion: nil];
                   }];

}

// Write a custom assertion that checks if the alpha of an element is equal to the expected value.
- (id<GREYAssertion>)alphaEqual:(CGFloat)expectedAlpha {
  return [GREYAssertionBlock assertionWithName:@"Assert Alpha Equal"
                       assertionBlockWithError:^BOOL(UIView *element,
                                                     NSError *__strong *errorOrNil) {
                         // Assertions can be performed on nil elements. Make sure view isn’t nil.
                         if (element == nil) {
                           *errorOrNil =
                           [NSError errorWithDomain:kGREYInteractionErrorDomain
                                               code:kGREYInteractionElementNotFoundErrorCode
                                           userInfo:nil];
                           return NO;
                         }
                         return element.alpha == expectedAlpha;
                       }];
}


- (void)testWithCustomAssertion {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"ClickMe")]
   assert:([self alphaEqual:1.0])];
}

- (void)testWithCondition {
  GREYCondition *myCondition = [GREYCondition conditionWithName: @"Example condition" block: ^BOOL {
    int i = 1;
    while (i <= 100000) {
      i++;
    }
    return YES;
  }];
  // Wait for my condition to be satisfied or timeout after 5 seconds.
  BOOL success = [myCondition waitWithTimeout:5];
  if (!success) {
    // Just printing for the example.
    NSLog(@"Condition not met");
  } else {
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"ClickMe")]
     performAction:grey_tap()];
  }
}


@end
