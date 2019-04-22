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

#import "BaseIntegrationTest.h"
#import "UILib/GREYElementHierarchy.h"

@interface AnimationsTest : BaseIntegrationTest
@end

@implementation AnimationsTest

- (void)setUp {
  [super setUp];
  [self openTestViewNamed:@"Animations"];
}

- (void)testUIViewAnimation {
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"UIViewAnimationControl")]
      performAction:grey_tap()] assertWithMatcher:grey_buttonTitle(@"Started")];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"AnimationStatus")]
      assertWithMatcher:grey_text(@"UIView animation finished")];
}

- (void)testPausedAnimations {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"AnimationStatus")]
      assertWithMatcher:grey_text(@"Stopped")];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"AnimationControl")]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"AnimationStatus")]
      assertWithMatcher:grey_text(@"Paused")];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"AnimationControl")]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"AnimationStatus")]
      assertWithMatcher:grey_notVisible()];
}

- (void)testAnimationsNotPresentStringInHierarchyOnUnrelatedFailure {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"AnimationStatus")]
      assertWithMatcher:grey_text(@"Stopped")];
  NSError *error;
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"GarbageValue")]
      assertWithMatcher:grey_notNil()
                  error:&error];
  NSString *animationHeaderString = @"**** Currently Animating Elements: ****";
  NSString *noAnimatingElementsString = @"**** No Animating Views Found. ****";
  XCTAssertNotNil(error);
  XCTAssertTrue([error.description containsString:noAnimatingElementsString]);
  XCTAssertFalse([error.description containsString:animationHeaderString]);
}

- (void)testAnimatingElementsPresentInTheHierarchyOnAnAnimationIdlingFailure {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"AnimationStatus")]
      assertWithMatcher:grey_text(@"Stopped")];
  double originalTimeout = GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration);
  [[GREYConfiguration sharedConfiguration] setValue:@(0.5)
                                       forConfigKey:kGREYConfigKeyInteractionTimeoutDuration];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"AnimationControl")]
      performAction:grey_tap()];
  NSError *error;
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"AnimationStatus")]
      assertWithMatcher:grey_text(@"Paused")
                  error:&error];
  XCTAssertNotNil(error);

  NSString *animationHeaderString = @"**** Currently Animating Elements: ****";
  NSString *animationViewString = @"UIView: <UIView";
  NSString *animationInfoString = @"AnimationKey: moveView withAnimation: <CABasicAnimation: ";
  XCTAssertTrue([error.description containsString:animationHeaderString]);
  XCTAssertTrue([error.description containsString:animationViewString]);
  XCTAssertTrue([error.description containsString:animationInfoString]);
  [[GREYConfiguration sharedConfiguration] setValue:@(originalTimeout)
                                       forConfigKey:kGREYConfigKeyInteractionTimeoutDuration];
}

- (void)testBeginEndIgnoringEvents {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"BeginIgnoringEvents")]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"AnimationStatus")]
      assertWithMatcher:grey_text(@"EndIgnoringEvents")];
}

- (void)testDelayedExecution {
  [[EarlGrey selectElementWithMatcher:grey_text(@"Perform Delayed Execution")]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"delayedLabelStatus")]
      assertWithMatcher:grey_text(@"Executed Twice!")];
}

@end
