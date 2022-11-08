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

#import "GREYElementInteraction.h"
#import "GREYConfigKey.h"
#import "GREYHostBackgroundDistantObject.h"
#import "EarlGrey.h"
#import "GREYHostApplicationDistantObject+BasicInteractionTest.h"
#import "GREYHostApplicationDistantObject+RemoteTest.h"
#import "GREYHostBackgroundDistantObject+BasicInteractionTest.h"
#import "BaseIntegrationTest.h"
#import "GREYElementHierarchy.h"

/**
 * Tests to ensure the basic functionality of EarlGrey is intact.
 */
@interface BasicInteractionTest : BaseIntegrationTest
@end

@implementation BasicInteractionTest

/**
 * Check if launch environment variables are present in user defaults and process info of the
 * application under test.
 */
- (void)testLaunchEnvironmentsPresent {
  XCTAssertFalse([[NSUserDefaults standardUserDefaults] boolForKey:@"-IsRunningEarlGreyTest"]);
  XCTAssertFalse([[[NSProcessInfo processInfo] arguments] containsObject:@"IsRunningEarlGreyTest"]);
  XCTAssertTrue([[GREY_REMOTE_CLASS_IN_APP(NSUserDefaults) standardUserDefaults]
      boolForKey:@"IsRunningEarlGreyTest"]);
  XCTAssertTrue([[[GREY_REMOTE_CLASS_IN_APP(NSProcessInfo) processInfo] arguments]
      containsObject:@"-IsRunningEarlGreyTest"]);
}

/**
 * Ensure operations within the trackable EarlGrey interval are synchronized with.
 */
- (void)testIndependentAppSideAccessOfTestSideVariableWhenInsideTrackingInterval {
  NSMutableArray<NSValue *> *mutableArray = [NSMutableArray array];
  // Perform operation within the EarlGrey trackable interval.
  [[GREYHostApplicationDistantObject sharedInstance] addToMutableArray:mutableArray afterTime:0.5];
  [[EarlGrey selectElementWithMatcher:grey_keyWindow()] assertWithMatcher:grey_notNil()];
  XCTAssertEqualObjects(mutableArray[0], @(1));
}

/**
 * Ensure operations outside the trackable EarlGrey interval are not synchronized with and need
 * separate waiting logic in the text.
 */
- (void)testIndependentAppSideAccessOfTestSideVariableWhenOutsideTrackingInterval {
  NSMutableArray<NSValue *> *mutableArray = [NSMutableArray array];
  NSTimeInterval waitTime = 3;
  // Perform operation after the EarlGrey trackable interval.
  [[GREYHostApplicationDistantObject sharedInstance] addToMutableArray:mutableArray
                                                             afterTime:waitTime];
  // EarlGrey Statement doesn't care about the dispatch_after since it's after the trackable
  // duration. The wait time here is insufficient for the dispatch_after to be called.
  [[EarlGrey selectElementWithMatcher:grey_keyWindow()] assertWithMatcher:grey_notNil()];
  // Sleeping on the test's main thread will not work, since  the thread is asleep and the array
  // cannot be obtained. Hence the value isn't added.
  [NSThread sleepForTimeInterval:waitTime];
  XCTAssertEqual([mutableArray count], (NSUInteger)0);
  // Spinning the test's runloop here will ensure that the block is called.
  CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1, NO);
  XCTAssertEqualObjects(mutableArray[0], @(1));
}

/**
 * Performs a long press on an accessibility element in the Basic Views.
 */
- (void)testLongPressOnAccessibilityElement {
  [[EarlGrey selectElementWithMatcher:grey_text(@"Basic Views")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")] performAction:grey_longPress()];

  [[EarlGrey selectElementWithMatcher:grey_buttonTitle(@"EarlGrey TestApp")]
      performAction:grey_tap()];
  // sleep(999);
}

/**
 * Verify that matching time is not part of the interaction timeout time. Interaction timeout time
 * should be the time until the application is becomes idle.
 */
- (void)testMatcherThatTakesALongTime {
  GREYConfiguration *config = [GREYConfiguration sharedConfiguration];
  NSNumber *originalTimeout = [config valueForConfigKey:kGREYConfigKeyInteractionTimeoutDuration];
  [config setValue:@(5) forConfigKey:kGREYConfigKeyInteractionTimeoutDuration];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Basic Views")] performAction:grey_tap()];
  // This matcher should at least 10(s) to match.
  id<GREYMatcher> matcher =
      [[GREYHostApplicationDistantObject sharedInstance] matcherThatTakesTime:10];
  NSError *error;
  [[EarlGrey selectElementWithMatcher:grey_allOf(grey_keyWindow(), matcher, NULL)]
      assertWithMatcher:grey_notNil()
                  error:&error];
  XCTAssertNil(error, @"Interaction should finish successfully although matching takes longer than "
                      @"interaction time out time which is 5(s).");
  [config setValue:originalTimeout forConfigKey:kGREYConfigKeyInteractionTimeoutDuration];
}

/**
 * Checks if hierarchy printing can work using different distant object mechanisms.
 */
- (void)testHierarchyPrinting {
  [[EarlGrey selectElementWithMatcher:grey_text(@"Basic Views")] assertWithMatcher:grey_notNil()];
  NSString *hierarchyFromTheTest = [GREYElementHierarchy hierarchyString];
  NSString *hierarchyFromRemoteClass =
      [GREY_REMOTE_CLASS_IN_APP(GREYElementHierarchy) hierarchyString];
  NSString *hierarchyFromMainDistantObject =
      [[GREYHostApplicationDistantObject sharedInstance] elementHierarchyString];
  NSString *hierarchyFromBackgroundDistantObject =
      [[GREYHostBackgroundDistantObject sharedInstance] elementHierarchyString];
  XCTAssertEqualObjects(hierarchyFromTheTest, hierarchyFromRemoteClass);
  XCTAssertEqualObjects(hierarchyFromMainDistantObject, hierarchyFromRemoteClass);
  XCTAssertEqualObjects(hierarchyFromMainDistantObject, hierarchyFromBackgroundDistantObject);
}

/**
 * Check zooming outward from a scroll view.
 */
- (void)testZoomingOutwardFromScrollView {
  [self openTestViewNamed:@"Zooming Scroll View"];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"ZoomingScrollView")]
      performAction:grey_pinchSlowInDirectionAndAngle(kGREYPinchDirectionOutward,
                                                      kGREYPinchAngleDefault)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"ZoomingScrollView")]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_buttonTitle(@"EarlGrey TestApp")]
      performAction:grey_tap()];
}

/**
 * Check zooming into a scroll view.
 */
- (void)testZoomingIntoScrollView {
  [self openTestViewNamed:@"Zooming Scroll View"];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"ZoomingScrollView")]
      performAction:grey_pinchSlowInDirectionAndAngle(kGREYPinchDirectionInward,
                                                      kGREYPinchAngleDefault)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"ZoomingScrollView")]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_buttonTitle(@"EarlGrey TestApp")]
      performAction:grey_tap()];
}

/**
 * Tap on a button five times and ensure that it went through by checking a label that is changed
 * on a button press.
 */
- (void)testTappingOnSimpleTapView {
  [self openTestViewNamed:@"Simple Tap View"];
  for (int i = 0; i < 20; i++) {
    NSString *text = [NSString stringWithFormat:@"Num Clicks: %d", i];
    [[EarlGrey selectElementWithMatcher:grey_text(text)]
        assertWithMatcher:grey_sufficientlyVisible()];
    [[EarlGrey selectElementWithMatcher:grey_text(@"Button")] performAction:grey_tap()];
  }
}

/**
 * Ensure that any assertion on an unmatched element throws an exception.
 */
- (void)testNotNilCallOnUnmatchedElementThrowsException {
  XCTAssertThrows([[[EarlGrey selectElementWithMatcher:grey_kindOfClassName(@"GarbageValue")]
      atIndex:0] assertWithMatcher:grey_notNil()]);
}

/**
 * Ensure that a not-nil assertion on a matched element does not throw an exception.
 */
- (void)testNotNilCheckOnMatchedElementDoesNotThrowException {
  GREYElementInteraction *interaction =
      [[EarlGrey selectElementWithMatcher:grey_kindOfClass([UITableViewCell class])] atIndex:0];
  [interaction assertWithMatcher:grey_notNil()];
}

/**
 * Checks for error handling using EarlGrey's Error API.
 */
- (void)testErrorHandling {
  NSError *error;
  [[EarlGrey selectElementWithMatcher:grey_text(@"GarbageValue")] performAction:grey_tap()
                                                                          error:&error];
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain,
                        @"Interaction Error not thrown for tapping on an invalid element.");
  error = nil;
  [[EarlGrey selectElementWithMatcher:grey_text(@"GarbageValue")] assertWithMatcher:grey_notNil()
                                                                              error:&error];
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain,
                        @"Interaction Error not thrown for not-nil assert on an invalid element.");
  error = nil;
  [[EarlGrey selectElementWithMatcher:grey_text(@"Basic Views")] performAction:grey_tap()
                                                                         error:&error];
  XCTAssertNil(error, @"Error not nil for tapping on a valid element");
  error = nil;
  [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")] assertWithMatcher:grey_notNil()
                                                                       error:&error];
  XCTAssertNil(error, @"Error not nil for asserting not-nil on a valid element");
}

/**
 * Perform typing in a text field and assert the typed value.
 */
- (void)testTypingRandomValueInTextFields {
  [[EarlGrey selectElementWithMatcher:grey_text(@"Basic Views")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"foo")]
      performAction:grey_typeText(@"hi")];
  [[EarlGrey selectElementWithMatcher:grey_text(@"hi")]
      assertWithMatcher:grey_sufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:grey_buttonTitle(@"EarlGrey TestApp")]
      performAction:grey_tap()];
}

/**
 * Perform typing a longer string with spaces and capital text in a text field and assert the
 * typed value.
 */
- (void)testTypingLongStringInTextField {
  [[EarlGrey selectElementWithMatcher:grey_text(@"Basic Views")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"foo")]
      performAction:grey_typeText(@"Sam01le SWiFt TeSt")];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Sam01le SWiFt TeSt")]
      assertWithMatcher:grey_sufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:grey_buttonTitle(@"EarlGrey TestApp")]
      performAction:grey_tap()];
}

/**
 * Perform replace-text in a text field and assert the typed value.
 */
- (void)testReplaceTextInTextField {
  [[EarlGrey selectElementWithMatcher:grey_text(@"Basic Views")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"foo")]
      performAction:grey_replaceText(@"donec.metus+spam@google.com")];
  [[EarlGrey selectElementWithMatcher:grey_allOf(grey_text(@"donec.metus+spam@google.com"),
                                                 grey_kindOfClass([UITextField class]), nil)]
      assertWithMatcher:grey_sufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"foo")]
      performAction:grey_replaceText(@"aA1a1A1aA1AaAa1A1a")];
  [[EarlGrey selectElementWithMatcher:grey_allOf(grey_text(@"aA1a1A1aA1AaAa1A1a"),
                                                 grey_kindOfClass([UITextField class]), nil)]
      assertWithMatcher:grey_sufficientlyVisible()];
}

/**
 * Check notifications are fired on the main thread for the replace text action in a UITextField.
 */
- (void)testReplaceTextFiredNotifications {
  [[EarlGrey selectElementWithMatcher:grey_text(@"Basic Views")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")] performAction:grey_tap()];
  [[GREYHostApplicationDistantObject sharedInstance] setUpObserverForReplaceText];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"foo")]
      performAction:grey_replaceText(@"donec.metus+spam@google.com")];
  BOOL notificationReceived = [[GREYHostApplicationDistantObject sharedInstance]
      textFieldTextDidBeginEditingNotificationFiredOnMainThread];
  XCTAssertTrue(notificationReceived);
}

/**
 * Check for basic visibility checking in the Basic Views.
 */
- (void)testAssertionsInBasicViews {
  [[EarlGrey selectElementWithMatcher:grey_text(@"Basic Views")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")]
      assertWithMatcher:grey_sufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:grey_buttonTitle(@"EarlGrey TestApp")]
      performAction:grey_tap()];
}

/**
 * Use a GREYCondition to check if an element is visible on the screen. Toggle a Switch for the
 * element to be visible.
 */
- (void)testEarlGreyInvocationInsideConditionUsingWaitWithTimeout {
  [[EarlGrey selectElementWithMatcher:grey_text(@"Basic Views")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")] performAction:grey_tap()];
  __block id<GREYAction> action =
      [[GREYHostApplicationDistantObject sharedInstance] actionForGettingTextFromMatchedElement];
  // Setup a condition to wait until a specific label says specific text.
  GREYCondition *waitCondition = [GREYCondition
      conditionWithName:@"WaitForLabelText"
                  block:^BOOL() {
                    NSError *error;
                    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"sampleLabel")]
                        performAction:action
                                error:&error];
                    return error == nil;
                  }];

  // Switch text and wait.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Switch")]
      performAction:grey_turnSwitchOn(NO)];
  XCTAssertTrue([waitCondition waitWithTimeout:10.0],
                @"Switch not manipulated within the allotted time for a Condition.");
}

/**
 * Use a GREYCondition to check if an element is visible on the screen. Change a stepper value for
 * the element to be visible.
 */
- (void)testEarlGreyInvocationInsideConditionUsingWaitWithLargeTimeout {
  [[EarlGrey selectElementWithMatcher:grey_text(@"Basic Views")] performAction:grey_tap()];
  GREYCondition *waitCondition = [GREYCondition
      conditionWithName:@"conditionWithAction"
                  block:^BOOL {
                    static double stepperValue = 51;
                    [[EarlGrey selectElementWithMatcher:grey_kindOfClass([UIStepper class])]
                        performAction:grey_setStepperValue(++stepperValue)];
                    return stepperValue == 55;
                  }];
  XCTAssertTrue([waitCondition waitWithTimeout:15.0],
                @"Stepper Change not completed within the allotted time for the Condition.");

  [[EarlGrey selectElementWithMatcher:grey_kindOfClass([UIStepper class])]
      assertWithMatcher:grey_stepperValue(55)];
}

/**
 * Ensure basic interaction with a stepper.
 */
- (void)testBasicInteractionWithStepper {
  [[EarlGrey selectElementWithMatcher:grey_text(@"Basic Views")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_kindOfClass([UIStepper class])]
      performAction:grey_setStepperValue(87)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Value Label")]
      assertWithMatcher:grey_text(@"Value: 87%")];
  [[[EarlGrey selectElementWithMatcher:grey_kindOfClass([UIStepper class])]
      performAction:grey_setStepperValue(16)] assertWithMatcher:grey_stepperValue(16)];
}

/**
 * Ensure basic interaction with a switch.
 */
- (void)testInteractionWithSwitch {
  [[EarlGrey selectElementWithMatcher:grey_text(@"Basic Views")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")] performAction:grey_tap()];

  [[[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Switch")]
      performAction:grey_turnSwitchOn(NO)] assertWithMatcher:grey_switchWithOnState(NO)];

  [[[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Switch")]
      performAction:grey_turnSwitchOn(YES)] assertWithMatcher:grey_switchWithOnState(YES)];

  [[[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Switch")]
      performAction:grey_turnSwitchOn(YES)] assertWithMatcher:grey_switchWithOnState(YES)];

  [[[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Switch")]
      performAction:grey_turnSwitchOn(NO)] assertWithMatcher:grey_switchWithOnState(NO)];
}

/**
 * Ensure basic interaction with a switch using a short tap.
 */
- (void)testInteractionWithSwitchWithShortTap {
  [self openTestViewNamed:@"Switch Views"];
  [[EarlGrey selectElementWithMatcher:grey_allOf(grey_accessibilityID(@"switch1"),
                                                 grey_interactable(), nil)]
      performAction:grey_turnSwitchOnWithShortTap(NO)];

  [[EarlGrey selectElementWithMatcher:grey_allOf(grey_accessibilityID(@"switch1"),
                                                 grey_interactable(), nil)]
      performAction:grey_turnSwitchOnWithShortTap(YES)];

  [[EarlGrey selectElementWithMatcher:grey_allOf(grey_accessibilityID(@"switch1"),
                                                 grey_interactable(), nil)]
      performAction:grey_turnSwitchOnWithShortTap(YES)];

  [[EarlGrey selectElementWithMatcher:grey_allOf(grey_accessibilityID(@"switch1"),
                                                 grey_interactable(), nil)]
      performAction:grey_turnSwitchOnWithShortTap(NO)];
}

/**
 * Ensure basic interaction with a hidden label.
 */
- (void)testInteractionWithHiddenLabel {
  [[EarlGrey selectElementWithMatcher:grey_text(@"Basic Views")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Hidden Label")]
      assertWithMatcher:grey_text(@"Hidden Label")];
}

/**
 * Ensure basic interaction with a view who's parent has alpha set to zero.
 */
- (void)testInteractionWithLabelWithParentWithAlphaZero {
  [[EarlGrey selectElementWithMatcher:grey_text(@"Basic Views")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Long Press")]
      assertWithMatcher:grey_not(grey_sufficientlyVisible())];
}

/**
 * Ensure basic interaction using a remote matcher.
 */
- (void)testEarlGreyRemoteMatcher {
  id<GREYMatcher> matcher =
      [[GREYHostApplicationDistantObject sharedInstance] matcherForFirstElement];
  [[EarlGrey selectElementWithMatcher:grey_allOf(grey_kindOfClass([UITableViewCell class]), matcher,
                                                 nil)] performAction:grey_tap()];
  NSError *error;
  [[EarlGrey selectElementWithMatcher:grey_text(@"Basic Views")] assertWithMatcher:grey_notNil()
                                                                             error:&error];
  XCTAssertEqual(error.code, kGREYInteractionElementNotFoundErrorCode,
                 @"No table view cell from the main Table can be visible.");
}

/**
 * Ensure basic interaction using a remote action.
 */
- (void)testEarlGreyRemoteAction {
  [[EarlGrey selectElementWithMatcher:grey_text(@"Basic Views")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")] performAction:grey_tap()];
  id<GREYAction> action =
      [[GREYHostApplicationDistantObject sharedInstance] actionForTapOnAccessibleElement];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Switch")] performAction:action];
}

/**
 * Ensure basic interaction using a remote assertion.
 */
- (void)testEarlGreyRemoteAssertion {
  id<GREYAssertion> assertion =
      [[GREYHostApplicationDistantObject sharedInstance] assertionThatAlphaIsGreaterThanZero];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Basic Views")] assert:assertion];
}

/**
 * Disabled UIControl should still be tapped if requested.
 */
- (void)testTappingOnADisabledButton {
  [[EarlGrey selectElementWithMatcher:grey_text(@"Basic Views")] performAction:grey_tap()];
  NSError *error;
  [[EarlGrey selectElementWithMatcher:grey_buttonTitle(@"Disabled")] performAction:grey_tap()
                                                                             error:&error];
  XCTAssertNil(error);
}

/**
 * Checks the working of a condition with a large timeout.
 */
- (void)testEarlGreyInvocationInsideGREYConditionUsingWaitWithLargeTimeout {
  [[EarlGrey selectElementWithMatcher:grey_text(@"Basic Views")] performAction:grey_tap()];
  GREYCondition *condition = [GREYCondition
      conditionWithName:@"conditionWithAction"
                  block:^BOOL {
                    static double stepperValue = 51;
                    [[EarlGrey selectElementWithMatcher:grey_kindOfClass([UIStepper class])]
                        performAction:grey_setStepperValue(++stepperValue)];
                    return stepperValue == 55;
                  }];
  XCTAssertTrue([condition waitWithTimeout:10.0]);

  [[EarlGrey selectElementWithMatcher:grey_kindOfClass([UIStepper class])]
      assertWithMatcher:grey_stepperValue(55)];
}

/**
 * Checks the working of a condition with a normal timeout.
 */
- (void)testEarlGreyInvocationInsideGREYConditionUsingWaitWithTimeout {
  [[EarlGrey selectElementWithMatcher:grey_text(@"Basic Views")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")] performAction:grey_tap()];

  id<GREYAction> action = [[GREYHostApplicationDistantObject sharedInstance] actionToGetLabelText];
  // Setup a condition to wait until a specific label says specific text.
  GREYCondition *waitCondition = [GREYCondition
      conditionWithName:@"WaitForLabelText"
                  block:^BOOL() {
                    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"sampleLabel")]
                        performAction:action];
                    NSString *text = [[GREYHostApplicationDistantObject sharedInstance] labelText];
                    return [text isEqualToString:@"OFF"];
                  }];

  // Switch text and wait.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Switch")]
      performAction:grey_turnSwitchOn(NO)];
  XCTAssertTrue([waitCondition waitWithTimeout:10.0]);
}

/**
 * Check tapping on a new custom window that covers the whole screen.
 */
- (void)testTapOnWindow {
  [[EarlGrey selectElementWithMatcher:grey_text(@"Basic Views")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_keyWindow()] performAction:grey_tap()];
  UIWindow *window = [[GREYHostApplicationDistantObject sharedInstance] setupGestureRecognizer];
  XCTAssertNotNil(window);

  // Tap on topmost window.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TopMostWindow")]
      performAction:grey_tap()];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TopMostWindow")]
      assertWithMatcher:grey_notVisible()];
}

/**
 * Check setting of the root view controller multiple times in the main window.
 */
- (void)testRootViewControllerSetMultipleTimesOnMainWindow {
  [[EarlGrey selectElementWithMatcher:grey_text(@"Basic Views")] performAction:grey_tap()];
  UIViewController *originalVC =
      [[GREYHostApplicationDistantObject sharedInstance] originalVCAfterSettingNewVCAsRoot];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")] assertWithMatcher:grey_nil()];
  [[GREYHostApplicationDistantObject sharedInstance] setRootViewController:nil];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")] assertWithMatcher:grey_nil()];

  [[GREYHostApplicationDistantObject sharedInstance] setRootViewController:originalVC];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")] assertWithMatcher:grey_notNil()];
}

/**
 * Check setting of the root view controller in different windows.
 */
- (void)testRootViewControllerSetOnMultipleWindows {
  [[EarlGrey selectElementWithMatcher:grey_text(@"Basic Views")] performAction:grey_tap()];
  UIWindow *window = nil;
  UIViewController *originalVC = [[GREYHostApplicationDistantObject sharedInstance]
      originalVCAfterSettingRootVCInAnotherWindow:window];

  [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")] assertWithMatcher:grey_nil()];
  [[GREYHostApplicationDistantObject sharedInstance] setRootViewController:nil inWindow:window];
  [[GREYHostApplicationDistantObject sharedInstance] setRootViewController:originalVC];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")] assertWithMatcher:grey_notNil()];
}

/**
 * Ensures basic interactions with views.
 */
- (void)testBasicInteractionWithViews {
  [[EarlGrey selectElementWithMatcher:grey_text(@"Basic Views")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")] performAction:grey_tap()];

  GREYElementInteraction *typeHere =
      [EarlGrey selectElementWithMatcher:grey_allOf(grey_accessibilityLabel(@"Type Something Here"),
                                                    grey_kindOfClass([UITextField class]), nil)];

  [[typeHere performAction:grey_replaceText(@"Hello 2")] assertWithMatcher:grey_text(@"Hello 2")];

  [typeHere performAction:grey_clearText()];

  [[typeHere performAction:grey_tapAtPoint(CGPointMake(0, 0))]
      performAction:grey_replaceText(@"Hello!")];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"return")] performAction:grey_tap()];

  [[EarlGrey selectElementWithMatcher:grey_buttonTitle(@"Send")]
      performAction:grey_tapAtPoint(CGPointMake(5, 5))];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Simple Label")]
      assertWithMatcher:grey_text(@"Hello!")];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Switch")]
      performAction:grey_turnSwitchOn(NO)];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Simple Label")]
      assertWithMatcher:grey_text(@"OFF")];

  [[[EarlGrey selectElementWithMatcher:grey_text(@"Long Press")]
      performAction:grey_longPressWithDuration(1.1f)] assertWithMatcher:grey_notVisible()];

  [[[EarlGrey selectElementWithMatcher:grey_text(@"Double Tap")] performAction:grey_doubleTap()]
      assertWithMatcher:grey_notVisible()];
}

/**
 * Checks a custom action.
 */
- (void)testEarlGreyInvocationInsideCustomAction {
  [[EarlGrey selectElementWithMatcher:grey_text(@"Basic Views")] performAction:grey_tap()];
  id<GREYAction> action =
      [[GREYHostApplicationDistantObject sharedInstance] actionForCheckingIfElementHidden];
  NSError *error;
  [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")] performAction:action error:&error];
  if (!error) {
    [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")] performAction:grey_tap()];
    [[[EarlGrey selectElementWithMatcher:grey_text(@"Long Press")]
        performAction:grey_longPressWithDuration(1.1f)] assertWithMatcher:grey_hidden(YES)];
  } else {
    GREYFail(@"Element should exist. We should not be here.");
  }
}

/**
 * Checks a custom assertion.
 */
- (void)testEarlGreyInvocationInsideCustomAssertion {
  [[EarlGrey selectElementWithMatcher:grey_text(@"Basic Views")] performAction:grey_tap()];
  id<GREYAssertion> assertion =
      [[GREYHostApplicationDistantObject sharedInstance] assertionForCheckingIfElementPresent];
  NSError *error;
  [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")] assert:assertion error:&error];
  if (!error) {
    [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")] performAction:grey_tap()];
    [[[EarlGrey selectElementWithMatcher:grey_text(@"Long Press")]
        performAction:grey_longPressWithDuration(1.1f)] assertWithMatcher:grey_hidden(YES)];
  } else {
    GREYFail(@"Element should exist. We should not be here.");
  }
}

/**
 * Verifies a long press at a point.
 */
- (void)testLongPressAtPointOnAccessibilityElement {
  [[EarlGrey selectElementWithMatcher:grey_text(@"Basic Views")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")] performAction:grey_tap()];

  [[[EarlGrey selectElementWithMatcher:grey_text(@"Long Press")]
      performAction:grey_longPressAtPointWithDuration(CGPointMake(10, 10), 1.1f)]
      assertWithMatcher:grey_hidden(YES)];
}

/**
 * Checks long press on a text field.
 */
- (void)testLongPressOnTextField {
  [[EarlGrey selectElementWithMatcher:grey_text(@"Basic Views")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")] performAction:grey_tap()];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"foo")]
      performAction:grey_longPressWithDuration(1.0f)];

  [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")] assertWithMatcher:grey_notNil()];
}

/**
 * Check long pressing followed by selecting a menu option.
 */
- (void)testLongPressFollowedBySelectingMenuOption {
  [[EarlGrey selectElementWithMatcher:grey_text(@"Basic Views")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")] performAction:grey_tap()];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"foo")]
      performAction:grey_typeText(@"Hello")];

  // For iOS 14, on doing a long press, the caret goes into a selection mode. To bring up the menu
  // a tap is required at the point of selection.
  if (iOS14_OR_ABOVE()) {
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"foo")]
        performAction:grey_tapAtPoint(CGPointMake(1, 1))];
  }
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"foo")]
      performAction:grey_longPressAtPointWithDuration(CGPointMake(1, 1), 1.0f)];

  [[EarlGrey selectElementWithMatcher:grey_text(@"Select")] performAction:grey_tap()];

  [[EarlGrey selectElementWithMatcher:grey_text(@"Cut")] performAction:grey_tap()];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"foo")]
      performAction:grey_typeText(@"FromEarlGrey")];

  // For iOS 14, on doing a long press, the caret goes into a selection mode. To bring up the menu
  // a tap is required at the point of selection.
  if (iOS14_OR_ABOVE()) {
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"foo")]
        performAction:grey_tapAtPoint(CGPointMake(1, 1))];
  }
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"foo")]
      performAction:grey_longPressAtPointWithDuration(CGPointMake(1, 1), 1.0f)];

  [[EarlGrey selectElementWithMatcher:grey_text(@"Paste")] performAction:grey_tap()];

  // Smart Inserts in Xcode 9 cause a space to appear by default after a paste. With iOS 13,
  // the text is selected entirely on doing a long press, so the above paste will remove any
  // existing text in the textfield.
  if (iOS13()) {
    [[EarlGrey selectElementWithMatcher:grey_text(@"Hello")]
        assertWithMatcher:grey_sufficientlyVisible()];
  } else {
    [[EarlGrey selectElementWithMatcher:grey_text(@"Hello FromEarlGrey")]
        assertWithMatcher:grey_sufficientlyVisible()];
  }
}

/**
 * Check interaction with a view that has its parent view hidden and unhidden.
 */
- (void)testInteractionWithLabelWithParentHiddenAndUnhidden {
  [[EarlGrey selectElementWithMatcher:grey_text(@"Basic Views")] performAction:grey_tap()];
  id<GREYAction> hideAction =
      [[GREYHostApplicationDistantObject sharedInstance] actionToHideOrUnhideBlock:YES];
  id<GREYAction> unhideAction =
      [[GREYHostApplicationDistantObject sharedInstance] actionToHideOrUnhideBlock:NO];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"tab2Container")]
      performAction:hideAction];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Long Press")]
      assertWithMatcher:grey_not(grey_sufficientlyVisible())];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"tab2Container")]
      performAction:unhideAction];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Long Press")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

/**
 * Check interaction with a view that has its parent view opaque and translucent.
 */
- (void)testInteractionWithLabelWithParentTranslucentAndOpaque {
  [[EarlGrey selectElementWithMatcher:grey_text(@"Basic Views")] performAction:grey_tap()];
  id<GREYAction> makeOpaqueAction =
      [[GREYHostApplicationDistantObject sharedInstance] actionToMakeOpaque:YES];
  id<GREYAction> makeTransparentAction =
      [[GREYHostApplicationDistantObject sharedInstance] actionToMakeOpaque:NO];

  [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"tab2Container")]
      performAction:makeTransparentAction];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Long Press")]
      assertWithMatcher:grey_not(grey_sufficientlyVisible())];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"tab2Container")]
      performAction:makeOpaqueAction];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Long Press")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

/**
 * Check interaction with a view that has its window opaque and translucent.
 *
 * @remark No test is provided for the key window since changing its hidden value will
 *         cause other tests to fail since the keyWindow is modified.
 */
- (void)testInteractionWithLabelWithWindowTranslucentAndOpaque {
  [[EarlGrey selectElementWithMatcher:grey_text(@"Basic Views")] performAction:grey_tap()];
  id<GREYAction> makeOpaqueAction =
      [[GREYHostApplicationDistantObject sharedInstance] actionToMakeWindowOpaque:YES];
  id<GREYAction> makeTransparentAction =
      [[GREYHostApplicationDistantObject sharedInstance] actionToMakeWindowOpaque:NO];

  [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"tab2Container")]
      performAction:makeTransparentAction];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Long Press")]
      assertWithMatcher:grey_not(grey_sufficientlyVisible())];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"tab2Container")]
      performAction:makeOpaqueAction];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Long Press")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

/**
 * Checks the state of a UIButton.
 */
- (void)testButtonSelectedState {
  [[EarlGrey selectElementWithMatcher:grey_text(@"Basic Views")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")] performAction:grey_tap()];

  id<GREYMatcher> buttonMatcher = grey_buttonTitle(@"Send");
  [[EarlGrey selectElementWithMatcher:buttonMatcher] assertWithMatcher:grey_not(grey_selected())];
  [[EarlGrey selectElementWithMatcher:buttonMatcher] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:buttonMatcher] assertWithMatcher:grey_selected()];
}

/**
 * Checks the removal and addition of the status bar.
 */
- (void)testStatusBarRemoval {
  GREYElementInteraction *interaction;
  if (@available(iOS 16, *)) {
    id<GREYMatcher> statusBarWindowMatcher =
        [[GREYHostApplicationDistantObject sharedInstance] matcherForStatusBarWindow];
    ;
    interaction = [EarlGrey selectElementWithMatcher:statusBarWindowMatcher];
  } else {
    NSString *statusBarClassName = iOS13_OR_ABOVE() ? @"UIStatusBar_Modern" : @"UIStatusBarWindow";
    interaction = [EarlGrey selectElementWithMatcher:grey_kindOfClassName(statusBarClassName)];
  }
  // By default, the status bar should not be included.
  NSError *error;
  [interaction assertWithMatcher:grey_notNil() error:&error];
  XCTAssertNotNil(error, @"Error is nil.");
  error = nil;
  // By setting the includeStatusBar variable, the Status Bar should be found.
  [interaction includeStatusBar];
  [interaction assertWithMatcher:grey_notNil() error:&error];
  XCTAssertNil(error, @"Error: %@ is not nil.", error);
}

/**
 * Checks an interaction with shorthand matchers created in the app side.
 */
- (void)testActionAndMatcherShorthandCreatedInTheApp {
  id<GREYAction> tapAction =
      [[GREYHostApplicationDistantObject sharedInstance] sampleShorthandAction];
  id<GREYMatcher> keyWindowMatcher =
      [[GREYHostApplicationDistantObject sharedInstance] sampleShorthandMatcher];
  [[EarlGrey selectElementWithMatcher:keyWindowMatcher] performAction:tapAction];
}

/**
 * Checks that using the EarlGrey Wait function synchronizes correctly.
 */
- (void)testAssertionForAppIdling {
  [self openTestViewNamed:@"Animations"];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"AnimationControl")]
      performAction:grey_tap()];
  GREYWaitForAppToIdle(@"Wait for Animations");
  [[GREYConfiguration sharedConfiguration] setValue:@(NO)
                                       forConfigKey:kGREYConfigKeySynchronizationEnabled];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"AnimationStatus")]
      assertWithMatcher:grey_text(@"Paused")];
  [[GREYConfiguration sharedConfiguration] setValue:@(YES)
                                       forConfigKey:kGREYConfigKeySynchronizationEnabled];
}

/**
 * Checks that using the EarlGrey Wait function with a sufficient timeout synchronizes correctly.
 */
- (void)testAssertionForAppIdlingWithTimeout {
  [self openTestViewNamed:@"Animations"];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"AnimationControl")]
      performAction:grey_tap()];
  GREYWaitForAppToIdleWithTimeout(5.0, @"Wait for Animations");
  [[GREYConfiguration sharedConfiguration] setValue:@(NO)
                                       forConfigKey:kGREYConfigKeySynchronizationEnabled];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"AnimationStatus")]
      assertWithMatcher:grey_text(@"Paused")];
  [[GREYConfiguration sharedConfiguration] setValue:@(YES)
                                       forConfigKey:kGREYConfigKeySynchronizationEnabled];
}

/**
 * Checks that using the wait and assert-block API synchronizes correctly.
 */
- (void)testWaitAndAssertBlock {
  [self openTestViewNamed:@"Animations"];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"AnimationControl")]
      performAction:grey_tap()];
  GREYWaitAndAssertBlock(@"Confirm Animations finished", ^void(void) {
    [[GREYConfiguration sharedConfiguration] setValue:@(NO)
                                         forConfigKey:kGREYConfigKeySynchronizationEnabled];
    [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"AnimationStatus")]
        assertWithMatcher:grey_text(@"Paused")];
  });
  [[GREYConfiguration sharedConfiguration] setValue:@(YES)
                                       forConfigKey:kGREYConfigKeySynchronizationEnabled];
}

/**
 * Checks basic interactions on a context menu with top-level and child-actions obtained from
 * long-pressing a button.
 */
- (void)testInteractionWithContextMenu {
  if (@available(iOS 13.0, *)) {
    [self openTestViewNamed:@"Basic Views"];
    [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"ContextMenuButton")]
        performAction:grey_longPress()];
    XCTAssertTrue([self waitForVisibilityForText:@"Top-level Action"]);
    [[EarlGrey selectElementWithMatcher:grey_text(@"Top-level Action")] performAction:grey_tap()];
    XCTAssertTrue([self waitForVisibilityForText:@"Top-level Action Tapped"]);

    [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"ContextMenuButton")]
        performAction:grey_longPress()];
    XCTAssertTrue([self waitForVisibilityForText:@"Child Actions"]);
    [[EarlGrey selectElementWithMatcher:grey_text(@"Child Actions")] performAction:grey_tap()];
    XCTAssertTrue([self waitForVisibilityForText:@"Child Action 0"]);
    [[EarlGrey selectElementWithMatcher:grey_text(@"Child Action 0")] performAction:grey_tap()];
    XCTAssertTrue([self waitForVisibilityForText:@"Child Action 0 Tapped"]);

    [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"ContextMenuButton")]
        performAction:grey_longPress()];
    XCTAssertTrue([self waitForVisibilityForText:@"Child Actions"]);
    [[EarlGrey selectElementWithMatcher:grey_text(@"Child Actions")] performAction:grey_tap()];
    XCTAssertTrue([self waitForVisibilityForText:@"Child Action 1"]);
    [[EarlGrey selectElementWithMatcher:grey_text(@"Child Action 1")] performAction:grey_tap()];
    XCTAssertTrue([self waitForVisibilityForText:@"Child Action 1 Tapped"]);
  }
}

/**
 * Perform typing in a text field and assert the typed value.
 */
- (void)testSettingAndResettingRootWindow {
  [[GREY_REMOTE_CLASS_IN_APP(UIApplication) sharedApplication] keyWindow].accessibilityIdentifier =
      @"Main Window";
  [[EarlGrey selectElementWithMatcher:grey_text(@"Basic Views")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"foo")] performAction:grey_tap()];

  NSError *error;
  id<GREYMatcher> keyboardWindowMatcher = grey_kindOfClassName(@"UIRemoteKeyboardWindow");
  [EarlGrey setRootMatcherForSubsequentInteractions:keyboardWindowMatcher];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"u")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")] performAction:grey_tap() error:&error];
  XCTAssertNotNil(error, @"Tab 2 should not be present in the keyboard window");

  error = nil;
  [EarlGrey setRootMatcherForSubsequentInteractions:grey_accessibilityID(@"Main Window")];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"u")] performAction:grey_tap()
                                                                             error:&error];
  XCTAssertNotNil(error, @"Keyboard key should not be present in the main window");

  [EarlGrey setRootMatcherForSubsequentInteractions:nil];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"u")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"foo")]
      assertWithMatcher:grey_text(@"uu")];
}

/** Confirms time saved in a drain from the test side. */
- (void)testAssertionForDrainForTime {
  CFTimeInterval start = CACurrentMediaTime();
  GREYWaitForTime(3);
  CFTimeInterval interval = CACurrentMediaTime() - start;
  XCTAssertGreaterThan(interval, 3, @"The app must have been drained for 3 seconds");
  XCTAssertLessThan(interval, 3.1, @"The app must have been drained for 3 seconds");
}

/** Confirms EarlGrey's app deletion API works as intended. */
- (void)testCloseAndDeleteApp {
  if (@available(iOS 16.0, *)) {
    XCTSkip(@"b/257407039 Fails on Xcode 14");
  }
  [self addTeardownBlock:^{
    [[[XCUIApplication alloc] init] launch];
  }];
  [EarlGrey closeAndDeleteTestRig];
}

#pragma mark - Private

/**
 * Wait for the text to appear on screen.
 *
 * @param text The text to wait for.
 *
 * @return A @c BOOL whether or not the text appeared before timing out.
 */
- (BOOL)waitForVisibilityForText:(NSString *)text {
  GREYCondition *condition =
      [GREYCondition conditionWithName:@""
                                 block:^BOOL {
                                   NSError *error;
                                   [[EarlGrey selectElementWithMatcher:grey_text(text)]
                                       assertWithMatcher:grey_sufficientlyVisible()
                                                   error:&error];
                                   return error == nil;
                                 }];
  return [condition waitWithTimeout:5];
}

@end
