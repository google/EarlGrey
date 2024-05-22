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

#import "EarlGrey.h"
#import "GREYHostApplicationDistantObject+BasicInteractionTest.h"
#import "GREYHostApplicationDistantObject+RemoteTest.h"
#import "GREYHostBackgroundDistantObject+BasicInteractionTest.h"
#import "BaseIntegrationTest.h"

// Extended long press duration to reduce test flakiness due to slow simulator speeds.
static const CFTimeInterval kExtendedLongPressDuration = 4.0;

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
  [[EarlGrey selectElementWithMatcher:GREYKeyWindow()] assertWithMatcher:GREYNotNil()];
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
  [[EarlGrey selectElementWithMatcher:GREYKeyWindow()] assertWithMatcher:GREYNotNil()];
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
  [[EarlGrey selectElementWithMatcher:GREYText(@"Basic Views")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Tab 2")] performAction:GREYLongPress()];

  [[EarlGrey selectElementWithMatcher:GREYButtonTitle(@"EarlGrey TestApp")]
      performAction:GREYTap()];
}

/**
 * Verify that matching time is not part of the interaction timeout time. Interaction timeout time
 * should be the time until the application is becomes idle.
 */
- (void)testMatcherThatTakesALongTime {
  GREYConfiguration *config = [GREYConfiguration sharedConfiguration];
  NSNumber *originalTimeout = [config valueForConfigKey:kGREYConfigKeyInteractionTimeoutDuration];
  [config setValue:@(5) forConfigKey:kGREYConfigKeyInteractionTimeoutDuration];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Basic Views")] performAction:GREYTap()];
  // This matcher should at least 10(s) to match.
  id<GREYMatcher> matcher =
      [[GREYHostApplicationDistantObject sharedInstance] matcherThatTakesTime:10];
  NSError *error;
  [[EarlGrey selectElementWithMatcher:grey_allOf(GREYKeyWindow(), matcher, NULL)]
      assertWithMatcher:GREYNotNil()
                  error:&error];
  XCTAssertNil(error, @"Interaction should finish successfully although matching takes longer than "
                      @"interaction time out time which is 5(s).");
  [config setValue:originalTimeout forConfigKey:kGREYConfigKeyInteractionTimeoutDuration];
}

/**
 * Checks if hierarchy printing can work using different distant object mechanisms.
 */
- (void)testHierarchyPrinting {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Basic Views")] assertWithMatcher:GREYNotNil()];
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
      performAction:GREYPinchSlowInDirectionAndAngle(kGREYPinchDirectionOutward,
                                                     kGREYPinchAngleDefault)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"ZoomingScrollView")]
      performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYButtonTitle(@"EarlGrey TestApp")]
      performAction:GREYTap()];
}

/**
 * Check zooming into a scroll view.
 */
- (void)testZoomingIntoScrollView {
  [self openTestViewNamed:@"Zooming Scroll View"];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"ZoomingScrollView")]
      performAction:GREYPinchSlowInDirectionAndAngle(kGREYPinchDirectionInward,
                                                     kGREYPinchAngleDefault)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"ZoomingScrollView")]
      performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYButtonTitle(@"EarlGrey TestApp")]
      performAction:GREYTap()];
}

/**
 * Tap on a button 20 times and ensure that it went through by checking a label that is changed
 * on a button press.
 */
- (void)testTappingOnSimpleTapView {
  [self openTestViewNamed:@"Simple Tap View"];
  for (int i = 0; i < 20; i++) {
    NSString *text = [NSString stringWithFormat:@"Num Clicks: %d", i];
    [[EarlGrey selectElementWithMatcher:GREYText(text)]
        assertWithMatcher:GREYSufficientlyVisible()];
    [[EarlGrey selectElementWithMatcher:GREYText(@"Button")] performAction:GREYTap()];
  }
}

/**
 * Tap on a button 20 times with fast tap events enabled, and ensure that it went through by
 * checking a label that is changed on a button press.
 */
- (void)testFastTapEvents {
  NSDictionary<NSString *, NSString *> *originalLaunchEnvironment =
      self.application.launchEnvironment;
  NSMutableDictionary<NSString *, NSString *> *fastTapLaunchEnvironment =
      [originalLaunchEnvironment mutableCopy];
  fastTapLaunchEnvironment[kFastTapEnvironmentVariableName] = @"true";

  self.application.launchEnvironment = fastTapLaunchEnvironment;
  [self.application launch];

  [self openTestViewNamed:@"Simple Tap View"];
  for (int i = 0; i < 20; i++) {
    NSString *text = [NSString stringWithFormat:@"Num Clicks: %d", i];
    [[EarlGrey selectElementWithMatcher:GREYText(text)]
        assertWithMatcher:GREYSufficientlyVisible()];
    [[EarlGrey selectElementWithMatcher:GREYText(@"Button")] performAction:GREYTap()];
  }

  self.application.launchEnvironment = originalLaunchEnvironment;
  [self.application launch];
}

/**
 * Ensure that any assertion on an unmatched element throws an exception.
 */
- (void)testNotNilCallOnUnmatchedElementThrowsException {
  XCTAssertThrows([[[EarlGrey selectElementWithMatcher:GREYKindOfClassName(@"GarbageValue")]
      atIndex:0] assertWithMatcher:GREYNotNil()]);
}

/**
 * Ensure that a not-nil assertion on a matched element does not throw an exception.
 */
- (void)testNotNilCheckOnMatchedElementDoesNotThrowException {
  GREYElementInteraction *interaction =
      [[EarlGrey selectElementWithMatcher:GREYKindOfClass([UITableViewCell class])] atIndex:0];
  [interaction assertWithMatcher:GREYNotNil()];
}

/**
 * Checks for error handling using EarlGrey's Error API.
 */
- (void)testErrorHandling {
  NSError *error;
  [[EarlGrey selectElementWithMatcher:GREYText(@"GarbageValue")] performAction:GREYTap()
                                                                         error:&error];
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain,
                        @"Interaction Error not thrown for tapping on an invalid element.");
  error = nil;
  [[EarlGrey selectElementWithMatcher:GREYText(@"GarbageValue")] assertWithMatcher:GREYNotNil()
                                                                             error:&error];
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain,
                        @"Interaction Error not thrown for not-nil assert on an invalid element.");
  error = nil;
  [[EarlGrey selectElementWithMatcher:GREYText(@"Basic Views")] performAction:GREYTap()
                                                                        error:&error];
  XCTAssertNil(error, @"Error not nil for tapping on a valid element");
  error = nil;
  [[EarlGrey selectElementWithMatcher:GREYText(@"Tab 2")] assertWithMatcher:GREYNotNil()
                                                                      error:&error];
  XCTAssertNil(error, @"Error not nil for asserting not-nil on a valid element");
}

/**
 * Perform typing in a text field and assert the typed value.
 */
- (void)testTypingRandomValueInTextFields {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Basic Views")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Tab 2")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"foo")]
      performAction:GREYTypeText(@"hi")];
  [[EarlGrey selectElementWithMatcher:GREYText(@"hi")] assertWithMatcher:GREYSufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:GREYButtonTitle(@"EarlGrey TestApp")]
      performAction:GREYTap()];
}

/**
 * Perform typing a longer string with spaces and capital text in a text field and assert the
 * typed value.
 */
- (void)testTypingLongStringInTextField {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Basic Views")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Tab 2")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"foo")]
      performAction:GREYTypeText(@"Sam01le SWiFt TeSt")];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Sam01le SWiFt TeSt")]
      assertWithMatcher:GREYSufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:GREYButtonTitle(@"EarlGrey TestApp")]
      performAction:GREYTap()];
}

/**
 * Perform replace-text in a text field and assert the typed value.
 */
- (void)testReplaceTextInTextField {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Basic Views")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Tab 2")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"foo")]
      performAction:GREYReplaceText(@"donec.metus+spam@google.com")];
  [[EarlGrey selectElementWithMatcher:grey_allOf(GREYText(@"donec.metus+spam@google.com"),
                                                 GREYKindOfClass([UITextField class]), nil)]
      assertWithMatcher:GREYSufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"foo")]
      performAction:GREYReplaceText(@"aA1a1A1aA1AaAa1A1a")];
  [[EarlGrey selectElementWithMatcher:grey_allOf(GREYText(@"aA1a1A1aA1AaAa1A1a"),
                                                 GREYKindOfClass([UITextField class]), nil)]
      assertWithMatcher:GREYSufficientlyVisible()];
}

/**
 * Check notifications are fired on the main thread for the replace text action in a UITextField.
 */
- (void)testReplaceTextFiredNotifications {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Basic Views")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Tab 2")] performAction:GREYTap()];
  [[GREYHostApplicationDistantObject sharedInstance] setUpObserverForReplaceText];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"foo")]
      performAction:GREYReplaceText(@"donec.metus+spam@google.com")];
  BOOL notificationReceived = [[GREYHostApplicationDistantObject sharedInstance]
      textFieldTextDidBeginEditingNotificationFiredOnMainThread];
  XCTAssertTrue(notificationReceived);
}

/**
 * Check for basic visibility checking in the Basic Views.
 */
- (void)testAssertionsInBasicViews {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Basic Views")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Tab 2")]
      assertWithMatcher:GREYSufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:GREYButtonTitle(@"EarlGrey TestApp")]
      performAction:GREYTap()];
}

/**
 * Use a GREYCondition to check if an element is visible on the screen. Toggle a Switch for the
 * element to be visible.
 */
- (void)testEarlGreyInvocationInsideConditionUsingWaitWithTimeout {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Basic Views")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Tab 2")] performAction:GREYTap()];
  __block id<GREYAction> action =
      [[GREYHostApplicationDistantObject sharedInstance] actionForGettingTextFromMatchedElement];
  // Setup a condition to wait until a specific label says specific text.
  GREYCondition *waitCondition = [GREYCondition
      conditionWithName:@"WaitForLabelText"
                  block:^BOOL(void) {
                    NSError *error;
                    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"sampleLabel")]
                        performAction:action
                                error:&error];
                    return error == nil;
                  }];

  // Switch text and wait.
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Switch")]
      performAction:GREYTurnSwitchOn(NO)];
  XCTAssertTrue([waitCondition waitWithTimeout:10.0],
                @"Switch not manipulated within the allotted time for a Condition.");
}

/**
 * Use a GREYCondition to check if an element is visible on the screen. Change a stepper value for
 * the element to be visible.
 */
- (void)testEarlGreyInvocationInsideConditionUsingWaitWithLargeTimeout {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Basic Views")] performAction:GREYTap()];
  GREYCondition *waitCondition = [GREYCondition
      conditionWithName:@"conditionWithAction"
                  block:^BOOL {
                    static double stepperValue = 51;
                    [[EarlGrey selectElementWithMatcher:GREYKindOfClass([UIStepper class])]
                        performAction:GREYSetStepperValue(++stepperValue)];
                    return stepperValue == 55;
                  }];
  XCTAssertTrue([waitCondition waitWithTimeout:15.0],
                @"Stepper Change not completed within the allotted time for the Condition.");

  [[EarlGrey selectElementWithMatcher:GREYKindOfClass([UIStepper class])]
      assertWithMatcher:GREYStepperValue(55)];
}

/**
 * Ensure basic interaction with a stepper.
 */
- (void)testBasicInteractionWithStepper {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Basic Views")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYKindOfClass([UIStepper class])]
      performAction:GREYSetStepperValue(87)];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Value Label")]
      assertWithMatcher:GREYText(@"Value: 87%")];
  [[[EarlGrey selectElementWithMatcher:GREYKindOfClass([UIStepper class])]
      performAction:GREYSetStepperValue(16)] assertWithMatcher:GREYStepperValue(16)];
}

/**
 * Ensure basic interaction with a switch.
 */
- (void)testInteractionWithSwitch {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Basic Views")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Tab 2")] performAction:GREYTap()];

  [[[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Switch")]
      performAction:GREYTurnSwitchOn(NO)] assertWithMatcher:GREYSwitchWithOnState(NO)];

  [[[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Switch")]
      performAction:GREYTurnSwitchOn(YES)] assertWithMatcher:GREYSwitchWithOnState(YES)];

  [[[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Switch")]
      performAction:GREYTurnSwitchOn(YES)] assertWithMatcher:GREYSwitchWithOnState(YES)];

  [[[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Switch")]
      performAction:GREYTurnSwitchOn(NO)] assertWithMatcher:GREYSwitchWithOnState(NO)];
}

/**
 * Ensure basic interaction with a switch using a short tap.
 */
- (void)testInteractionWithSwitchWithShortTap {
  [self openTestViewNamed:@"Switch Views"];
  [[EarlGrey selectElementWithMatcher:grey_allOf(grey_accessibilityID(@"switch1"),
                                                 GREYInteractable(), nil)]
      performAction:GREYTurnSwitchOnWithShortTap(NO)];

  [[EarlGrey selectElementWithMatcher:grey_allOf(grey_accessibilityID(@"switch1"),
                                                 GREYInteractable(), nil)]
      performAction:GREYTurnSwitchOnWithShortTap(YES)];

  [[EarlGrey selectElementWithMatcher:grey_allOf(grey_accessibilityID(@"switch1"),
                                                 GREYInteractable(), nil)]
      performAction:GREYTurnSwitchOnWithShortTap(YES)];

  [[EarlGrey selectElementWithMatcher:grey_allOf(grey_accessibilityID(@"switch1"),
                                                 GREYInteractable(), nil)]
      performAction:GREYTurnSwitchOnWithShortTap(NO)];
}

/**
 * Ensure basic interaction with a hidden label.
 */
- (void)testInteractionWithHiddenLabel {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Basic Views")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Hidden Label")]
      assertWithMatcher:GREYText(@"Hidden Label")];
}

/**
 * Ensure basic interaction with a view who's parent has alpha set to zero.
 */
- (void)testInteractionWithLabelWithParentWithAlphaZero {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Basic Views")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Long Press")]
      assertWithMatcher:GREYNot(GREYSufficientlyVisible())];
}

/**
 * Ensure basic interaction using a remote matcher.
 */
- (void)testEarlGreyRemoteMatcher {
  id<GREYMatcher> matcher =
      [[GREYHostApplicationDistantObject sharedInstance] matcherForFirstElement];
  [[EarlGrey selectElementWithMatcher:grey_allOf(GREYKindOfClass([UITableViewCell class]), matcher,
                                                 nil)] performAction:GREYTap()];
  NSError *error;
  [[EarlGrey selectElementWithMatcher:GREYText(@"Basic Views")] assertWithMatcher:GREYNotNil()
                                                                            error:&error];
  XCTAssertEqual(error.code, kGREYInteractionElementNotFoundErrorCode,
                 @"No table view cell from the main Table can be visible.");
}

/**
 * Ensure basic interaction using a remote action.
 */
- (void)testEarlGreyRemoteAction {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Basic Views")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Tab 2")] performAction:GREYTap()];
  id<GREYAction> action =
      [[GREYHostApplicationDistantObject sharedInstance] actionForTapOnAccessibleElement];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Switch")] performAction:action];
}

/**
 * Ensure basic interaction using a remote assertion.
 */
- (void)testEarlGreyRemoteAssertion {
  id<GREYAssertion> assertion =
      [[GREYHostApplicationDistantObject sharedInstance] assertionThatAlphaIsGreaterThanZero];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Basic Views")] assert:assertion];
}

/**
 * Disabled UIControl should still be tapped if requested.
 */
- (void)testTappingOnADisabledButton {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Basic Views")] performAction:GREYTap()];
  NSError *error;
  [[EarlGrey selectElementWithMatcher:GREYButtonTitle(@"Disabled")] performAction:GREYTap()
                                                                            error:&error];
  XCTAssertNil(error);
}

/**
 * Checks the working of a condition with a large timeout.
 */
- (void)testEarlGreyInvocationInsideGREYConditionUsingWaitWithLargeTimeout {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Basic Views")] performAction:GREYTap()];
  GREYCondition *condition = [GREYCondition
      conditionWithName:@"conditionWithAction"
                  block:^BOOL {
                    static double stepperValue = 51;
                    [[EarlGrey selectElementWithMatcher:GREYKindOfClass([UIStepper class])]
                        performAction:GREYSetStepperValue(++stepperValue)];
                    return stepperValue == 55;
                  }];
  XCTAssertTrue([condition waitWithTimeout:10.0]);

  [[EarlGrey selectElementWithMatcher:GREYKindOfClass([UIStepper class])]
      assertWithMatcher:GREYStepperValue(55)];
}

/**
 * Checks the working of a condition with a normal timeout.
 */
- (void)testEarlGreyInvocationInsideGREYConditionUsingWaitWithTimeout {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Basic Views")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Tab 2")] performAction:GREYTap()];

  id<GREYAction> action = [[GREYHostApplicationDistantObject sharedInstance] actionToGetLabelText];
  // Setup a condition to wait until a specific label says specific text.
  GREYCondition *waitCondition = [GREYCondition
      conditionWithName:@"WaitForLabelText"
                  block:^BOOL(void) {
                    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"sampleLabel")]
                        performAction:action];
                    NSString *text = [[GREYHostApplicationDistantObject sharedInstance] labelText];
                    return [text isEqualToString:@"OFF"];
                  }];

  // Switch text and wait.
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Switch")]
      performAction:GREYTurnSwitchOn(NO)];
  XCTAssertTrue([waitCondition waitWithTimeout:10.0]);
}

/**
 * Check tapping on a new custom window that covers the whole screen.
 */
- (void)testTapOnWindow {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Basic Views")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYKeyWindow()] performAction:GREYTap()];
  UIWindow *window = [[GREYHostApplicationDistantObject sharedInstance] setupGestureRecognizer];
  XCTAssertNotNil(window);

  // Tap on topmost window.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TopMostWindow")]
      performAction:GREYTap()];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TopMostWindow")]
      assertWithMatcher:GREYNotVisible()];
}

/**
 * Check setting of the root view controller multiple times in the main window.
 */
- (void)testRootViewControllerSetMultipleTimesOnMainWindow {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Basic Views")] performAction:GREYTap()];
  UIViewController *originalVC =
      [[GREYHostApplicationDistantObject sharedInstance] originalVCAfterSettingNewVCAsRoot];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Tab 2")] assertWithMatcher:GREYNil()];
  [[GREYHostApplicationDistantObject sharedInstance] setRootViewController:nil];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Tab 2")] assertWithMatcher:GREYNil()];

  [[GREYHostApplicationDistantObject sharedInstance] setRootViewController:originalVC];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Tab 2")] assertWithMatcher:GREYNotNil()];
}

/**
 * Check setting of the root view controller in different windows.
 */
- (void)testRootViewControllerSetOnMultipleWindows {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Basic Views")] performAction:GREYTap()];
  UIWindow *window = nil;
  UIViewController *originalVC = [[GREYHostApplicationDistantObject sharedInstance]
      originalVCAfterSettingRootVCInAnotherWindow:window];

  [[EarlGrey selectElementWithMatcher:GREYText(@"Tab 2")] assertWithMatcher:GREYNil()];
  [[GREYHostApplicationDistantObject sharedInstance] setRootViewController:nil inWindow:window];
  [[GREYHostApplicationDistantObject sharedInstance] setRootViewController:originalVC];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Tab 2")] assertWithMatcher:GREYNotNil()];
}

/**
 * Ensures basic interactions with views.
 */
- (void)testBasicInteractionWithViews {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Basic Views")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Tab 2")] performAction:GREYTap()];

  GREYElementInteraction *typeHere =
      [EarlGrey selectElementWithMatcher:grey_allOf(GREYAccessibilityLabel(@"Type Something Here"),
                                                    GREYKindOfClass([UITextField class]), nil)];

  [[typeHere performAction:GREYReplaceText(@"Hello 2")] assertWithMatcher:GREYText(@"Hello 2")];

  [typeHere performAction:GREYClearText()];

  [[typeHere performAction:GREYTapAtPoint(CGPointMake(0, 0))]
      performAction:GREYReplaceText(@"Hello!")];

  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"return")] performAction:GREYTap()];

  [[EarlGrey selectElementWithMatcher:GREYButtonTitle(@"Send")]
      performAction:GREYTapAtPoint(CGPointMake(5, 5))];

  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Simple Label")]
      assertWithMatcher:GREYText(@"Hello!")];

  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Switch")]
      performAction:GREYTurnSwitchOn(NO)];

  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Simple Label")]
      assertWithMatcher:GREYText(@"OFF")];

  [[[EarlGrey selectElementWithMatcher:GREYText(@"Long Press")]
      performAction:GREYLongPressWithDuration(1.1f)] assertWithMatcher:GREYNotVisible()];

  [[[EarlGrey selectElementWithMatcher:GREYText(@"Double Tap")] performAction:GREYDoubleTap()]
      assertWithMatcher:GREYNotVisible()];
}

/**
 * Checks a custom action.
 */
- (void)testEarlGreyInvocationInsideCustomAction {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Basic Views")] performAction:GREYTap()];
  id<GREYAction> action =
      [[GREYHostApplicationDistantObject sharedInstance] actionForCheckingIfElementHidden];
  NSError *error;
  [[EarlGrey selectElementWithMatcher:GREYText(@"Tab 2")] performAction:action error:&error];
  if (!error) {
    [[EarlGrey selectElementWithMatcher:GREYText(@"Tab 2")] performAction:GREYTap()];
    [[[EarlGrey selectElementWithMatcher:GREYText(@"Long Press")]
        performAction:GREYLongPressWithDuration(1.1f)] assertWithMatcher:GREYHidden(YES)];
  } else {
    GREYFail(@"Element should exist. We should not be here.");
  }
}

/**
 * Checks a custom assertion.
 */
- (void)testEarlGreyInvocationInsideCustomAssertion {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Basic Views")] performAction:GREYTap()];
  id<GREYAssertion> assertion =
      [[GREYHostApplicationDistantObject sharedInstance] assertionForCheckingIfElementPresent];
  NSError *error;
  [[EarlGrey selectElementWithMatcher:GREYText(@"Tab 2")] assert:assertion error:&error];
  if (!error) {
    [[EarlGrey selectElementWithMatcher:GREYText(@"Tab 2")] performAction:GREYTap()];
    [[[EarlGrey selectElementWithMatcher:GREYText(@"Long Press")]
        performAction:GREYLongPressWithDuration(1.1f)] assertWithMatcher:GREYHidden(YES)];
  } else {
    GREYFail(@"Element should exist. We should not be here.");
  }
}

/**
 * Verifies a long press at a point.
 */
- (void)testLongPressAtPointOnAccessibilityElement {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Basic Views")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Tab 2")] performAction:GREYTap()];

  [[[EarlGrey selectElementWithMatcher:GREYText(@"Long Press")]
      performAction:GREYLongPressAtPointWithDuration(CGPointMake(10, 10), 1.1f)]
      assertWithMatcher:GREYHidden(YES)];
}

/**
 * Checks long press on a text field.
 */
- (void)testLongPressOnTextField {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Basic Views")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Tab 2")] performAction:GREYTap()];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"foo")]
      performAction:GREYLongPressWithDuration(1.0f)];

  [[EarlGrey selectElementWithMatcher:GREYText(@"Tab 2")] assertWithMatcher:GREYNotNil()];
}

/**
 * Check long pressing followed by selecting a menu option.
 */
- (void)testLongPressFollowedBySelectingMenuOption {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Basic Views")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Tab 2")] performAction:GREYTap()];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"foo")]
      performAction:GREYTypeText(@"Hello")];

  // For iOS 14, on doing a long press, the caret goes into a selection mode. To bring up the menu
  // a tap is required at the point of selection.
  if (iOS14_OR_ABOVE()) {
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"foo")]
        performAction:GREYTapAtPoint(CGPointMake(1, 1))];
  }
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"foo")]
      performAction:GREYLongPressAtPointWithDuration(CGPointMake(1, 1),
                                                     kExtendedLongPressDuration)];

  [[EarlGrey selectElementWithMatcher:GREYText(@"Select")] performAction:GREYTap()];

  [[EarlGrey selectElementWithMatcher:GREYText(@"Cut")] performAction:GREYTap()];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"foo")]
      performAction:GREYTypeText(@"FromEarlGrey")];

  // On slow simulators, tapping "Paste" sometimes fail (2-3 times out of 200 runs), resulting in
  // flaky tests. Waiting for the app to idle reduces the flakiness, which may presumably be caused
  // by the text-typing above.
  GREYWaitForAppToIdle(@"Waiting for the App to Idle");

  // For iOS 14, on doing a long press, the caret goes into a selection mode. To bring up the menu
  // a tap is required at the point of selection.
  if (iOS14_OR_ABOVE()) {
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"foo")]
        performAction:GREYTapAtPoint(CGPointMake(1, 1))];
  }
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"foo")]
      performAction:GREYLongPressAtPointWithDuration(CGPointMake(1, 1),
                                                     kExtendedLongPressDuration)];

  [[EarlGrey selectElementWithMatcher:GREYText(@"Paste")] performAction:GREYTap()];

  // Smart Inserts in Xcode 9 cause a space to appear by default after a paste. With iOS 13,
  // the text is selected entirely on doing a long press, so the above paste will remove any
  // existing text in the textfield.
  if (iOS13()) {
    [[EarlGrey selectElementWithMatcher:GREYText(@"Hello")]
        assertWithMatcher:GREYSufficientlyVisible()];
  } else {
    [[EarlGrey selectElementWithMatcher:GREYText(@"Hello FromEarlGrey")]
        assertWithMatcher:GREYSufficientlyVisible()];
  }
}

/**
 * Check interaction with a view that has its parent view hidden and unhidden.
 */
- (void)testInteractionWithLabelWithParentHiddenAndUnhidden {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Basic Views")] performAction:GREYTap()];
  id<GREYAction> hideAction =
      [[GREYHostApplicationDistantObject sharedInstance] actionToHideOrUnhideBlock:YES];
  id<GREYAction> unhideAction =
      [[GREYHostApplicationDistantObject sharedInstance] actionToHideOrUnhideBlock:NO];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Tab 2")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"tab2Container")]
      performAction:hideAction];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Long Press")]
      assertWithMatcher:GREYNot(GREYSufficientlyVisible())];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"tab2Container")]
      performAction:unhideAction];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Long Press")]
      assertWithMatcher:GREYSufficientlyVisible()];
}

/**
 * Check interaction with a view that has its parent view opaque and translucent.
 */
- (void)testInteractionWithLabelWithParentTranslucentAndOpaque {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Basic Views")] performAction:GREYTap()];
  id<GREYAction> makeOpaqueAction =
      [[GREYHostApplicationDistantObject sharedInstance] actionToMakeOpaque:YES];
  id<GREYAction> makeTransparentAction =
      [[GREYHostApplicationDistantObject sharedInstance] actionToMakeOpaque:NO];

  [[EarlGrey selectElementWithMatcher:GREYText(@"Tab 2")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"tab2Container")]
      performAction:makeTransparentAction];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Long Press")]
      assertWithMatcher:GREYNot(GREYSufficientlyVisible())];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"tab2Container")]
      performAction:makeOpaqueAction];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Long Press")]
      assertWithMatcher:GREYSufficientlyVisible()];
}

/**
 * Check interaction with a view that has its window opaque and translucent.
 *
 * @remark No test is provided for the key window since changing its hidden value will
 *         cause other tests to fail since the keyWindow is modified.
 */
- (void)testInteractionWithLabelWithWindowTranslucentAndOpaque {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Basic Views")] performAction:GREYTap()];
  id<GREYAction> makeOpaqueAction =
      [[GREYHostApplicationDistantObject sharedInstance] actionToMakeWindowOpaque:YES];
  id<GREYAction> makeTransparentAction =
      [[GREYHostApplicationDistantObject sharedInstance] actionToMakeWindowOpaque:NO];

  [[EarlGrey selectElementWithMatcher:GREYText(@"Tab 2")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"tab2Container")]
      performAction:makeTransparentAction];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Long Press")]
      assertWithMatcher:GREYNot(GREYSufficientlyVisible())];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"tab2Container")]
      performAction:makeOpaqueAction];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Long Press")]
      assertWithMatcher:GREYSufficientlyVisible()];
}

/**
 * Checks the state of a UIButton.
 */
- (void)testButtonSelectedState {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Basic Views")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Tab 2")] performAction:GREYTap()];

  id<GREYMatcher> buttonMatcher = GREYButtonTitle(@"Send");
  [[EarlGrey selectElementWithMatcher:buttonMatcher] assertWithMatcher:GREYNot(GREYSelected())];
  [[EarlGrey selectElementWithMatcher:buttonMatcher] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:buttonMatcher] assertWithMatcher:GREYSelected()];
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
    interaction = [EarlGrey selectElementWithMatcher:GREYKindOfClassName(statusBarClassName)];
  }
  // By default, the status bar should not be included.
  NSError *error;
  [interaction assertWithMatcher:GREYNotNil() error:&error];
  XCTAssertNotNil(error, @"Error is nil.");
  error = nil;
  // By setting the includeStatusBar variable, the Status Bar should be found.
  [interaction includeStatusBar];
  [interaction assertWithMatcher:GREYNotNil() error:&error];
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
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"AnimationControl")]
      performAction:GREYTap()];
  GREYWaitForAppToIdle(@"Wait for Animations");
  [[GREYConfiguration sharedConfiguration] setValue:@(NO)
                                       forConfigKey:kGREYConfigKeySynchronizationEnabled];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"AnimationStatus")]
      assertWithMatcher:GREYText(@"Paused")];
  [[GREYConfiguration sharedConfiguration] setValue:@(YES)
                                       forConfigKey:kGREYConfigKeySynchronizationEnabled];
}

/**
 * Checks that using the EarlGrey Wait function with a sufficient timeout synchronizes correctly.
 */
- (void)testAssertionForAppIdlingWithTimeout {
  [self openTestViewNamed:@"Animations"];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"AnimationControl")]
      performAction:GREYTap()];
  GREYWaitForAppToIdleWithTimeout(5.0, @"Wait for Animations");
  [[GREYConfiguration sharedConfiguration] setValue:@(NO)
                                       forConfigKey:kGREYConfigKeySynchronizationEnabled];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"AnimationStatus")]
      assertWithMatcher:GREYText(@"Paused")];
  [[GREYConfiguration sharedConfiguration] setValue:@(YES)
                                       forConfigKey:kGREYConfigKeySynchronizationEnabled];
}

/**
 * Checks that using the wait and assert-block API synchronizes correctly.
 */
- (void)testWaitAndAssertBlock {
  [self openTestViewNamed:@"Animations"];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"AnimationControl")]
      performAction:GREYTap()];
  GREYWaitAndAssertBlock(@"Confirm Animations finished", ^void(void) {
    [[GREYConfiguration sharedConfiguration] setValue:@(NO)
                                         forConfigKey:kGREYConfigKeySynchronizationEnabled];
    [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"AnimationStatus")]
        assertWithMatcher:GREYText(@"Paused")];
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

    [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"ContextMenuButton")]
        performAction:GREYLongPressWithDuration(kExtendedLongPressDuration)];
    XCTAssertTrue([self waitForVisibilityForText:@"Top-level Action"]);
    [[EarlGrey selectElementWithMatcher:GREYText(@"Top-level Action")] performAction:GREYTap()];
    XCTAssertTrue([self waitForVisibilityForText:@"Top-level Action Tapped"]);

    [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"ContextMenuButton")]
        performAction:GREYLongPressWithDuration(kExtendedLongPressDuration)];
    XCTAssertTrue([self waitForVisibilityForText:@"Child Actions"]);
    [[EarlGrey selectElementWithMatcher:GREYText(@"Child Actions")] performAction:GREYTap()];
    XCTAssertTrue([self waitForVisibilityForText:@"Child Action 0"]);
    [[EarlGrey selectElementWithMatcher:GREYText(@"Child Action 0")] performAction:GREYTap()];
    XCTAssertTrue([self waitForVisibilityForText:@"Child Action 0 Tapped"]);

    [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"ContextMenuButton")]
        performAction:GREYLongPressWithDuration(kExtendedLongPressDuration)];
    XCTAssertTrue([self waitForVisibilityForText:@"Child Actions"]);
    [[EarlGrey selectElementWithMatcher:GREYText(@"Child Actions")] performAction:GREYTap()];
    XCTAssertTrue([self waitForVisibilityForText:@"Child Action 1"]);
    [[EarlGrey selectElementWithMatcher:GREYText(@"Child Action 1")] performAction:GREYTap()];
    XCTAssertTrue([self waitForVisibilityForText:@"Child Action 1 Tapped"]);
  }
}

/**
 * Perform typing in a text field and assert the typed value.
 */
- (void)testSettingAndResettingRootWindow {
  UIWindow *mainWindow = [GREY_REMOTE_CLASS_IN_APP(GREYUILibUtils) window];
  mainWindow.accessibilityIdentifier = @"Main Window";
  [[EarlGrey selectElementWithMatcher:GREYText(@"Basic Views")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Tab 2")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"foo")] performAction:GREYTap()];

  NSError *error;
  id<GREYMatcher> keyboardWindowMatcher = GREYKindOfClassName(@"UIRemoteKeyboardWindow");
  [EarlGrey setRootMatcherForSubsequentInteractions:keyboardWindowMatcher];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"u")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Tab 2")] performAction:GREYTap() error:&error];
  XCTAssertNotNil(error, @"Tab 2 should not be present in the keyboard window");

  error = nil;
  [EarlGrey setRootMatcherForSubsequentInteractions:grey_accessibilityID(@"Main Window")];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Tab 2")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"u")] performAction:GREYTap()
                                                                            error:&error];
  XCTAssertNotNil(error, @"Keyboard key should not be present in the main window");

  [EarlGrey setRootMatcherForSubsequentInteractions:nil];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Tab 2")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"u")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"foo")]
      assertWithMatcher:GREYText(@"uu")];
}

/** Confirms time saved in a drain from the test side. */
- (void)testAssertionForDrainForTime {
  CFTimeInterval start = CACurrentMediaTime();
  GREYWaitForTime(3);
  CFTimeInterval interval = CACurrentMediaTime() - start;
  XCTAssertGreaterThan(interval, 3, @"The app must have been drained for 3 seconds");
  XCTAssertLessThan(interval, 3.1, @"The app must have been drained for 3 seconds");
}

#pragma mark - Activity Sheet Tests (iOS 17 only)

- (void)testShareSheetOpenAndClose {
  XCTSkipUnless(iOS17_OR_ABOVE());
  if (@available(iOS 17.0, *)) {
    [self openTestViewNamed:@"Share Sheet"];
    XCTAssertTrue([EarlGrey activitySheetPresentWithError:nil]);
    [EarlGrey closeActivitySheetWithError:nil];
  }
}

- (void)testShareSheetWithURL {
  XCTSkipUnless(iOS17_OR_ABOVE());
  if (@available(iOS 17.0, *)) {
    [self openTestViewNamed:@"Share Sheet"];
    XCTAssertTrue([EarlGrey activitySheetPresentWithURL:@"apple.com" error:nil]);
    [EarlGrey closeActivitySheetWithError:nil];
  }
}

- (void)testShareSheetButtonsPresent {
  XCTSkipUnless(iOS17_OR_ABOVE());
  if (@available(iOS 17.0, *)) {
    [self openTestViewNamed:@"Share Sheet"];
    XCTAssertTrue([EarlGrey buttonPresentInActivitySheetWithId:@"Copy" error:nil]);

    NSError *error;
    [EarlGrey buttonPresentInActivitySheetWithId:@"Missing button" error:&error];
    XCTAssertNotNil(error, @"Error is nil.");
    [EarlGrey closeActivitySheetWithError:nil];
  }
}

- (void)testTappingOnShareSheetButtons {
  XCTSkipUnless(iOS17_OR_ABOVE());
  if (@available(iOS 17.0, *)) {
    [self openTestViewNamed:@"Share Sheet"];
    XCTAssertTrue([EarlGrey tapButtonInActivitySheetWithId:@"Copy" error:nil]);

    [self openTestViewNamed:@"Share Sheet"];
    XCTAssertTrue([EarlGrey tapButtonInActivitySheetWithId:@"More" error:nil]);
    XCTAssertTrue([EarlGrey tapButtonInActivitySheetWithId:@"Messages" error:nil]);
  }
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
                                   [[EarlGrey selectElementWithMatcher:GREYText(text)]
                                       assertWithMatcher:GREYSufficientlyVisible()
                                                   error:&error];
                                   return error == nil;
                                 }];
  return [condition waitWithTimeout:5];
}

@end
