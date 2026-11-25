//
// Copyright 2021 Google Inc.
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

/**
 *  Tests Animations on activity indicators when hidden. Also checks animations on a custom view
 *  which adds layers on to itself in a recurring and direct fashion and checks animation timeouts.
 */
@interface ActiveAnimationsTest : BaseIntegrationTest
@end

@implementation ActiveAnimationsTest {
  double _originalAnimationTime;
}

- (void)setUp {
  [super setUp];
  _originalAnimationTime = GREY_CONFIG_DOUBLE(kGREYConfigKeyCALayerMaxAnimationDuration);
  [[GREYConfiguration sharedConfiguration] setValue:@(3)
                                       forConfigKey:kGREYConfigKeyCALayerMaxAnimationDuration];
  [[GREYConfiguration sharedConfiguration] setValue:@(YES)
                                       forConfigKey:kGREYConfigKeyIgnoreHiddenAnimations];
  [self openTestViewNamed:@"Active Animations"];
  // Wait for the pushed view controller and any system navigation bar animations to settle before
  // individual tests adjust the max animation duration or interaction timeout.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"animatingView")]
      assertWithMatcher:GREYNotNil()];
}

- (void)tearDown {
  [[GREYConfiguration sharedConfiguration] setValue:@(_originalAnimationTime)
                                       forConfigKey:kGREYConfigKeyCALayerMaxAnimationDuration];
  [[GREYConfiguration sharedConfiguration] setValue:@(NO)
                                       forConfigKey:kGREYConfigKeyIgnoreHiddenAnimations];
  [super tearDown];
}

/**
 * Ensures that by default, EarlGrey will track an animation even if it is hidden.
 */
- (void)testSimpleAnimatingViewTime {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"animatingView")]
      assertWithMatcher:GREYNotNil()];
  CFTimeInterval startTime = CACurrentMediaTime();
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"animateAnimatingViewButton")]
      performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYKeyWindow()] assertWithMatcher:GREYNotNil()];
  CFTimeInterval stopTime = CACurrentMediaTime() - startTime;
  XCTAssertGreaterThan(stopTime, GREY_CONFIG_DOUBLE(kGREYConfigKeyCALayerMaxAnimationDuration));
}

/**
 * Checks turning the config key on and off will change EarlGrey's tracking behavior with hidden
 * animations.
 */
- (void)testConfigKeyForHiddenAnimationTracking {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"animatingView")]
      assertWithMatcher:GREYNotNil()];
  CFTimeInterval startTime = CACurrentMediaTime();
  [self hideAndUnhideAnimatingViewWithSynchronizationDisabled];
  XCTAssertLessThan(CACurrentMediaTime() - startTime,
                    GREY_CONFIG_DOUBLE(kGREYConfigKeyCALayerMaxAnimationDuration));
  [[GREYConfiguration sharedConfiguration] setValue:@(NO)
                                       forConfigKey:kGREYConfigKeyIgnoreHiddenAnimations];

  startTime = CACurrentMediaTime();
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"animateAnimatingViewButton")]
      performAction:GREYTap()];
  [self hideAndUnhideAnimatingViewWithSynchronizationDisabled];
  CFTimeInterval duration = CACurrentMediaTime() - startTime;
  XCTAssertGreaterThan(duration, GREY_CONFIG_DOUBLE(kGREYConfigKeyCALayerMaxAnimationDuration));
  XCTAssertLessThan(duration, 8,
                    @"Duration should reflect the 3s trimmed animation plus 1s safeguard padding "
                    @"and four tap interactions.");
}

/**
 * Checks that an activity indicator is not tracked if hidden and is fully tracked if not hidden.
 */
- (void)testHidingActivityIndicatorAndThenUnhiding {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"activityIndicator")]
      assertWithMatcher:GREYNotNil()];
  CFTimeInterval startTime = CACurrentMediaTime();
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"animateActivityIndicatorButton")]
      performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"activityIndicator")]
      assertWithMatcher:GREYNotNil()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"hideActivityIndicatorButton")]
      performAction:GREYTap()];
  // Add an extra second for the animation tracking delay.
  XCTAssertGreaterThanOrEqual((CACurrentMediaTime() - startTime),
                              GREY_CONFIG_DOUBLE(kGREYConfigKeyCALayerMaxAnimationDuration) - 1);

  startTime = CACurrentMediaTime();
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"hideActivityIndicatorButton")]
      performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"animateActivityIndicatorButton")]
      performAction:GREYTap()];
  XCTAssertGreaterThan(CACurrentMediaTime() - startTime, 1);

  startTime = CACurrentMediaTime();
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"animateActivityIndicatorButton")]
      performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYKeyWindow()] assertWithMatcher:GREYNotNil()];
  XCTAssertGreaterThan(ceil(CACurrentMediaTime() - startTime),
                       GREY_CONFIG_DOUBLE(kGREYConfigKeyCALayerMaxAnimationDuration) - 1);
}

/**
 * Ensures that if there are multiple animations on different layers, the slowest will be tracked to
 * completion.
 */
- (void)testSynchingToTheSlowestAnimationWhenMultipleLayersArePresent {
  [[GREYConfiguration sharedConfiguration] setValue:@(10)
                                       forConfigKey:kGREYConfigKeyCALayerMaxAnimationDuration];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"animatingView")]
      assertWithMatcher:GREYNotNil()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"addMoreLayersButton")]
      performAction:GREYTap()];

  CFTimeInterval startTime = CACurrentMediaTime();
  [self hideAndUnhideAnimatingViewWithSynchronizationDisabled];
  XCTAssertLessThan(CACurrentMediaTime() - startTime, 8);

  [[EarlGrey selectElementWithMatcher:GREYKeyWindow()] assertWithMatcher:GREYNotNil()];
  XCTAssertGreaterThan(CACurrentMediaTime() - startTime, 8);
}

/**
 * Ensures that if there are multiple animations on different layers in the same subtree, the
 * slowest will be tracked to completion.
 */
- (void)testSynchingToTheSlowestAnimationWhenMultipleRecurrentLayersArePresent {
  // We test if multiple animations are happening, that the longest one is waited for irrespective
  // of the layer hierarchy. All have repeat count set to 0, which means one animation.
  [[GREYConfiguration sharedConfiguration] setValue:@(10)
                                       forConfigKey:kGREYConfigKeyCALayerMaxAnimationDuration];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"animatingView")]
      assertWithMatcher:GREYNotNil()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"addMoreRecurringLayersButton")]
      performAction:GREYTap()];
  CFTimeInterval startTime = CACurrentMediaTime();
  [self hideAndUnhideAnimatingViewWithSynchronizationDisabled];
  XCTAssertLessThan(CACurrentMediaTime() - startTime, 8);

  // Longest animation is a sublayer with a 8 second animation enqueued on it.
  [[EarlGrey selectElementWithMatcher:GREYKeyWindow()] assertWithMatcher:GREYNotNil()];
  XCTAssertGreaterThan(CACurrentMediaTime() - startTime, 8);
}

/**
 * Ensures that if there are multiple animations on different layers, the
 * slowest _non-hidden_ will be tracked to completion and the hidden ones will not be tracked.
 */
- (void)testSynchingToTheSlowestAnimationWhenMultipleLayersArePresentWithSomeHidden {
  // We test if multiple animations are happening, that the longest one is waited for irrespective
  // of the layer hierarchy. All have repeat count set to 0, which means one animation.
  [[GREYConfiguration sharedConfiguration] setValue:@(10)
                                       forConfigKey:kGREYConfigKeyCALayerMaxAnimationDuration];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"animatingView")]
      assertWithMatcher:GREYNotNil()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"addMoreLayersButton")]
      performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"hideCertainLayersButton")]
      performAction:GREYTap()];
  CFTimeInterval startTime = CACurrentMediaTime();
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"animateAnimatingViewButton")]
      performAction:GREYTap()];
  // Longest animation is a simple animation with an 8 second animation enqued on it which is
  // hidden.
  [[EarlGrey selectElementWithMatcher:GREYKeyWindow()] assertWithMatcher:GREYNotNil()];
  CFTimeInterval duration = CACurrentMediaTime() - startTime;
  XCTAssertGreaterThan(duration, 8);
  XCTAssertLessThan(duration, 15,
                    @"Duration should reflect the 8s animation plus 1s safeguard padding and "
                    @"interaction overhead.");
}

/**
 * Ensures that if there are multiple animations on different layers in the same subtree, the
 * slowest _non-hidden_ will be tracked to completion and the hidden ones will not be tracked.
 */
- (void)testSynchingToTheSlowestAnimationWhenMultipleRecurrentLayersArePresentWithSomeHidden {
  // We test if multiple animations are happening, that the longest one is waited for irrespective
  // of the layer hierarchy. All have repeat count set to 0, which means one animation.
  [[GREYConfiguration sharedConfiguration] setValue:@(10)
                                       forConfigKey:kGREYConfigKeyCALayerMaxAnimationDuration];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"animatingView")]
      assertWithMatcher:GREYNotNil()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"addMoreLayersButton")]
      performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"hideCertainLayersButton")]
      performAction:GREYTap()];
  CFTimeInterval startTime = CACurrentMediaTime();
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"animateAnimatingViewButton")]
      performAction:GREYTap()];

  // Longest animation is a simple animation with an 8 second animation enqued on it which is
  // hidden.
  [[EarlGrey selectElementWithMatcher:GREYKeyWindow()] assertWithMatcher:GREYNotNil()];
  CFTimeInterval duration = CACurrentMediaTime() - startTime;
  XCTAssertGreaterThan(duration, 8);
  XCTAssertLessThan(duration, 15,
                    @"Duration should reflect the 8s animation plus 1s safeguard padding and "
                    @"interaction overhead.");
}

/**
 * Ensures that a tail-recurrent animation will cause synchronization failures with EarlGrey's
 * tracking.
 */
- (void)testSynchingWithAnimationsWhichAddsAnotherAnimationOnCompletion {
  [[GREYConfiguration sharedConfiguration] setValue:@(8)
                                       forConfigKey:kGREYConfigKeyCALayerMaxAnimationDuration];
  double originalInteractionTimeout = GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration);
  [self addTeardownBlock:^{
    [[GREYConfiguration sharedConfiguration] setValue:@(originalInteractionTimeout)
                                         forConfigKey:kGREYConfigKeyInteractionTimeoutDuration];
  }];
  [[GREYConfiguration sharedConfiguration] setValue:@(10)
                                       forConfigKey:kGREYConfigKeyInteractionTimeoutDuration];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"animatingView")]
      assertWithMatcher:GREYNotNil()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"specialAnimationsButton")]
      performAction:GREYTap()];
  NSError *error;
  [[EarlGrey selectElementWithMatcher:GREYKeyWindow()] assertWithMatcher:GREYNotNil()
                                                                   error:&error];
  XCTAssertNotNil(error);
  XCTAssertEqual(error.code, kGREYInteractionTimeoutErrorCode);
}

/**
 * Ensures hidden animations are also trimmed as all animations.
 */
- (void)testTrimmingOfHiddenAnimationsWhenAdded {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"animatingView")]
      assertWithMatcher:GREYNotNil()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"addMoreLayersButton")]
      performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"hideCertainLayersButton")]
      performAction:GREYTap()];

  CFTimeInterval startTime = CACurrentMediaTime();
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"animateAnimatingViewButton")]
      performAction:GREYTap()];

  // Longest animation is a sublayer with an 8 second animation enqueued on it. However it will be
  // trimmed to around 3 seconds as that's the allowable duration.
  [[EarlGrey selectElementWithMatcher:GREYKeyWindow()] assertWithMatcher:GREYNotNil()];
  XCTAssertLessThan(CACurrentMediaTime() - startTime, 7,
                    @"Duration should reflect the 8s animation trimmed to 3s plus 1s safeguard "
                    @"padding and interaction overhead.");
}

#pragma mark - Private

/**
 * Starts animating the @c animatingView. Then turns off synchronization and hides it.
 * Synchronization is turned back on and the hidden animation is processed.
 */
- (void)hideAndUnhideAnimatingViewWithSynchronizationDisabled {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"animateAnimatingViewButton")]
      performAction:GREYTap()];
  // Turn off sync so we can hide the animating view.
  GREYExecuteWithSynchronizationDisabled(^{
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"hideAnimatingViewButton")]
        performAction:GREYTap()];
  });
  // On hiding the view, EarlGrey should still be able to interact with it without turning off sync.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"hideAnimatingViewButton")]
      performAction:GREYTap()];
}

@end
