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

#import "GREYConfigKey.h"
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
  [self openTestViewNamed:@"Active Animations"];
  _originalAnimationTime = GREY_CONFIG_DOUBLE(kGREYConfigKeyCALayerMaxAnimationDuration);
  [[GREYConfiguration sharedConfiguration] setValue:@(3)
                                       forConfigKey:kGREYConfigKeyCALayerMaxAnimationDuration];
  [[GREYConfiguration sharedConfiguration] setValue:@(YES)
                                       forConfigKey:kGREYConfigKeyIgnoreHiddenAnimations];
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
      assertWithMatcher:grey_notNil()];
  CFTimeInterval startTime = CACurrentMediaTime();
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"animateAnimatingViewButton")]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_keyWindow()] assertWithMatcher:grey_notNil()];
  CFTimeInterval stopTime = CACurrentMediaTime() - startTime;
  XCTAssertGreaterThan(stopTime, GREY_CONFIG_DOUBLE(kGREYConfigKeyCALayerMaxAnimationDuration));
}

/**
 * Checks turning the config key on and off will change EarlGrey's tracking behavior with hidden
 * animations.
 */
- (void)testConfigKeyForHiddenAnimationTracking {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"animatingView")]
      assertWithMatcher:grey_notNil()];
  CFTimeInterval startTime = CACurrentMediaTime();
  [self hideAndUnhideAnimatingViewWithSynchronizationDisabled];
  XCTAssertLessThan(CACurrentMediaTime() - startTime,
                    GREY_CONFIG_DOUBLE(kGREYConfigKeyCALayerMaxAnimationDuration));
  [[GREYConfiguration sharedConfiguration] setValue:@(NO)
                                       forConfigKey:kGREYConfigKeyIgnoreHiddenAnimations];

  startTime = CACurrentMediaTime();
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"animateAnimatingViewButton")]
      performAction:grey_tap()];
  [self hideAndUnhideAnimatingViewWithSynchronizationDisabled];
  CFTimeInterval duration = CACurrentMediaTime() - startTime;
  XCTAssertGreaterThan(duration, GREY_CONFIG_DOUBLE(kGREYConfigKeyCALayerMaxAnimationDuration));
  XCTAssertLessThan(duration, 4.5,
                    @"The duration should be lower than the longest animation ~4.5s");
}

/**
 * Checks that an activity indicator is not tracked if hidden and is fully tracked if not hidden.
 */
- (void)testHidingActivityIndicatorAndThenUnhiding {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"activityIndicator")]
      assertWithMatcher:grey_notNil()];
  CFTimeInterval startTime = CACurrentMediaTime();
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"animateActivityIndicatorButton")]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"activityIndicator")]
      assertWithMatcher:grey_notNil()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"hideActivityIndicatorButton")]
      performAction:grey_tap()];
  // Add an extra second for the animation tracking delay.
  XCTAssertGreaterThanOrEqual((CACurrentMediaTime() - startTime),
                              GREY_CONFIG_DOUBLE(kGREYConfigKeyCALayerMaxAnimationDuration) - 1);

  startTime = CACurrentMediaTime();
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"hideActivityIndicatorButton")]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"animateActivityIndicatorButton")]
      performAction:grey_tap()];
  XCTAssertGreaterThan(CACurrentMediaTime() - startTime, 1);

  startTime = CACurrentMediaTime();
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"animateActivityIndicatorButton")]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_keyWindow()] assertWithMatcher:grey_notNil()];
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
      assertWithMatcher:grey_notNil()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"addMoreLayersButton")]
      performAction:grey_tap()];

  CFTimeInterval startTime = CACurrentMediaTime();
  [self hideAndUnhideAnimatingViewWithSynchronizationDisabled];
  XCTAssertLessThan(CACurrentMediaTime() - startTime, 8);

  [[EarlGrey selectElementWithMatcher:grey_keyWindow()] assertWithMatcher:grey_notNil()];
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
      assertWithMatcher:grey_notNil()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"addMoreRecurringLayersButton")]
      performAction:grey_tap()];
  CFTimeInterval startTime = CACurrentMediaTime();
  [self hideAndUnhideAnimatingViewWithSynchronizationDisabled];
  XCTAssertLessThan(CACurrentMediaTime() - startTime, 8);

  // Longest animation is a sublayer with a 8 second animation enqueued on it.
  [[EarlGrey selectElementWithMatcher:grey_keyWindow()] assertWithMatcher:grey_notNil()];
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
      assertWithMatcher:grey_notNil()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"addMoreLayersButton")]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"hideCertainLayersButton")]
      performAction:grey_tap()];
  CFTimeInterval startTime = CACurrentMediaTime();
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"animateAnimatingViewButton")]
      performAction:grey_tap()];
  // Longest animation is a simple animation with an 8 second animation enqued on it which is
  // hidden.
  [[EarlGrey selectElementWithMatcher:grey_keyWindow()] assertWithMatcher:grey_notNil()];
  CFTimeInterval duration = CACurrentMediaTime() - startTime;
  XCTAssertGreaterThan(duration, 8);
  XCTAssertLessThan(duration, 9);
}

/**
 * Ensures that if there are multiple animations on different layers in the same subtree, the
 * slowest _non-hidden_ will be tracked to completion and the hidden ones will not be tracked.
 */
- (void)testSynchingToTheSlowestAnimationWhenMultipleRecurrentLayersArePresentWithSomeHidden {
  // We test if multiple animations are happening, that the longest one is waited for irrespective
  // of the layer hierarchy. All have repeat count set to 0, which means one animation.
  [[GREYConfiguration sharedConfiguration] setValue:@(100)
                                       forConfigKey:kGREYConfigKeyCALayerMaxAnimationDuration];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"animatingView")]
      assertWithMatcher:grey_notNil()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"addMoreLayersButton")]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"hideCertainLayersButton")]
      performAction:grey_tap()];
  CFTimeInterval startTime = CACurrentMediaTime();
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"animateAnimatingViewButton")]
      performAction:grey_tap()];

  // Longest animation is a simple animation with an 8 second animation enqued on it which is
  // hidden.
  [[EarlGrey selectElementWithMatcher:grey_keyWindow()] assertWithMatcher:grey_notNil()];
  CFTimeInterval duration = CACurrentMediaTime() - startTime;
  XCTAssertGreaterThan(duration, 8);
  XCTAssertLessThan(duration, 9);
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
      assertWithMatcher:grey_notNil()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"specialAnimationsButton")]
      performAction:grey_tap()];
  NSError *error;
  [[EarlGrey selectElementWithMatcher:grey_keyWindow()] assertWithMatcher:grey_notNil()
                                                                    error:&error];
  XCTAssertNotNil(error);
  XCTAssertEqual(error.code, kGREYInteractionTimeoutErrorCode);
}

/**
 * Ensures hidden animations are also trimmed as all animations.
 */
- (void)testTrimmingOfHiddenAnimationsWhenAdded {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"animatingView")]
      assertWithMatcher:grey_notNil()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"addMoreLayersButton")]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"hideCertainLayersButton")]
      performAction:grey_tap()];

  CFTimeInterval startTime = CACurrentMediaTime();
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"animateAnimatingViewButton")]
      performAction:grey_tap()];

  // Longest animation is a sublayer with an 8 second animation enqueued on it. However it will be
  // trimmed to around 3 seconds as that's the allowable duration.
  [[EarlGrey selectElementWithMatcher:grey_keyWindow()] assertWithMatcher:grey_notNil()];
  XCTAssertLessThan(CACurrentMediaTime() - startTime, 4);
}

#pragma mark - Private

/**
 * Starts animating the @c animatingView. Then turns off synchronization and hides it.
 * Synchronization is turned back on and the hidden animation is processed.
 */
- (void)hideAndUnhideAnimatingViewWithSynchronizationDisabled {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"animateAnimatingViewButton")]
      performAction:grey_tap()];
  // Turn off sync so we can hide the animating view.
  [[GREYConfiguration sharedConfiguration] setValue:@(NO)
                                       forConfigKey:kGREYConfigKeySynchronizationEnabled];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"hideAnimatingViewButton")]
      performAction:grey_tap()];
  [[GREYConfiguration sharedConfiguration] setValue:@(YES)
                                       forConfigKey:kGREYConfigKeySynchronizationEnabled];
  // On hiding the view, EarlGrey should still be able to interact with it without turning off sync.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"hideAnimatingViewButton")]
      performAction:grey_tap()];
}

@end
