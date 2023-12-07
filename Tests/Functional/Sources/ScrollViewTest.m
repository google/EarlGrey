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

#import <UIKit/UIKit.h>
#import "EarlGrey.h"
#import "GREYHostApplicationDistantObject+ScrollViewTest.h"
#import "BaseIntegrationTest.h"

@interface ScrollViewTest : BaseIntegrationTest
@end

@implementation ScrollViewTest

- (void)setUp {
  [super setUp];
  [self openTestViewNamed:@"Scroll Views"];
}

- (void)testScrollToTopEdge {
  id<GREYMatcher> matcher =
      grey_allOf(GREYAccessibilityLabel(@"Label 2"), GREYSufficientlyVisible(), nil);
  [[[EarlGrey selectElementWithMatcher:matcher]
         usingSearchAction:GREYScrollInDirection(kGREYDirectionDown, 50)
      onElementWithMatcher:GREYAccessibilityLabel(@"Upper Scroll View")]
      assertWithMatcher:GREYSufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Upper Scroll View")]
      performAction:GREYScrollToContentEdge(kGREYContentEdgeTop)];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Upper Scroll View")]
      assertWithMatcher:GREYScrolledToContentEdge(kGREYContentEdgeTop)];
}

- (void)testScrollToBottomEdge {
  [[[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Upper Scroll View")]
      performAction:GREYScrollToContentEdge(kGREYContentEdgeBottom)]
      assertWithMatcher:GREYScrolledToContentEdge(kGREYContentEdgeBottom)];
}

- (void)testScrollToRightEdge {
  [[[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Bottom Scroll View")]
      performAction:GREYScrollToContentEdge(kGREYContentEdgeRight)]
      assertWithMatcher:GREYScrolledToContentEdge(kGREYContentEdgeRight)];
}

- (void)testScrollToLeftEdge {
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Bottom Scroll View")]
      performAction:GREYScrollToContentEdge(kGREYContentEdgeRight)];
  [[[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Bottom Scroll View")]
      performAction:GREYScrollToContentEdge(kGREYContentEdgeLeft)]
      assertWithMatcher:GREYScrolledToContentEdge(kGREYContentEdgeLeft)];
}

- (void)testScrollToLeftEdgeWithCustomStartPoint {
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Bottom Scroll View")]
      performAction:GREYScrollToContentEdgeWithStartPoint(kGREYContentEdgeLeft, 0.5, 0.5)];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Bottom Scroll View")]
      assertWithMatcher:GREYScrolledToContentEdge(kGREYContentEdgeLeft)];
}

- (void)testScrollToRightEdgeWithCustomStartPoint {
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Bottom Scroll View")]
      performAction:GREYScrollToContentEdgeWithStartPoint(kGREYContentEdgeRight, 0.5, 0.5)];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Bottom Scroll View")]
      assertWithMatcher:GREYScrolledToContentEdge(kGREYContentEdgeRight)];
}

- (void)testScrollToTopEdgeWithCustomStartPoint {
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Bottom Scroll View")]
      performAction:GREYScrollToContentEdgeWithStartPoint(kGREYContentEdgeTop, 0.5, 0.5)];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Bottom Scroll View")]
      assertWithMatcher:GREYScrolledToContentEdge(kGREYContentEdgeTop)];
}

- (void)testScrollToBottomEdgeWithCustomStartPoint {
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Bottom Scroll View")]
      performAction:GREYScrollToContentEdgeWithStartPoint(kGREYContentEdgeBottom, 0.5, 0.5)];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Bottom Scroll View")]
      assertWithMatcher:GREYScrolledToContentEdge(kGREYContentEdgeBottom)];
}

- (void)testScrollToTopWorksWithPositiveInsets {
  // Scroll down.
  id<GREYMatcher> matcher =
      grey_allOf(GREYAccessibilityLabel(@"Label 2"), GREYSufficientlyVisible(), nil);
  [[[EarlGrey selectElementWithMatcher:matcher]
         usingSearchAction:GREYScrollInDirection(kGREYDirectionDown, 50)
      onElementWithMatcher:GREYAccessibilityLabel(@"Upper Scroll View")]
      assertWithMatcher:GREYSufficientlyVisible()];

  // Add positive insets using this format {top,left,bottom,right}
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"topTextbox")]
      performAction:GREYTypeText(@"{100,0,0,0}\n")];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"insets toggle")]
      performAction:GREYTurnSwitchOn(YES)];

  // Scroll to top and verify.
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Upper Scroll View")]
      performAction:GREYScrollToContentEdge(kGREYContentEdgeTop)];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Upper Scroll View")]
      assertWithMatcher:GREYScrolledToContentEdge(kGREYContentEdgeTop)];
}

- (void)testScrollToTopWorksWithNegativeInsets {
  // Scroll down.
  id<GREYMatcher> matcher =
      grey_allOf(GREYAccessibilityLabel(@"Label 2"), GREYInteractable(), nil);
  [[[EarlGrey selectElementWithMatcher:matcher]
         usingSearchAction:GREYScrollInDirection(kGREYDirectionDown, 50)
      onElementWithMatcher:GREYAccessibilityLabel(@"Upper Scroll View")]
      assertWithMatcher:GREYSufficientlyVisible()];

  // Add positive insets using this format {top,left,bottom,right}
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"topTextbox")]
      performAction:GREYTypeText(@"{-100,0,0,0}\n")];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"insets toggle")]
      performAction:GREYTurnSwitchOn(YES)];

  // Scroll to top and verify.
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Upper Scroll View")]
      performAction:GREYScrollToContentEdge(kGREYContentEdgeTop)];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Upper Scroll View")]
      assertWithMatcher:GREYScrolledToContentEdge(kGREYContentEdgeTop)];
}

- (void)testSearchActionReturnsNilWhenElementIsNotFound {
  id<GREYMatcher> matcher =
      grey_allOf(GREYAccessibilityLabel(@"Unobtainium"), GREYInteractable(), nil);
  [[[EarlGrey selectElementWithMatcher:matcher]
         usingSearchAction:GREYScrollInDirection(kGREYDirectionUp, 50)
      onElementWithMatcher:GREYAccessibilityLabel(@"Upper Scroll View")]
      assertWithMatcher:GREYNil()];
}

- (void)testScrollToTopWhenAlreadyAtTheTopWithoutBounce {
  GREYHostApplicationDistantObject *host = GREYHostApplicationDistantObject.sharedInstance;
  id<GREYAction> bounceOff = [host actionForToggleBounces];

  // Verify this test with and without bounce enabled by toggling it.
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Upper Scroll View")]
      performAction:bounceOff];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Upper Scroll View")]
      performAction:GREYScrollToContentEdge(kGREYContentEdgeTop)];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Upper Scroll View")]
      assertWithMatcher:GREYScrolledToContentEdge(kGREYContentEdgeTop)];
}

- (void)testScrollToTopWhenAlreadyAtTheTopWithBounce {
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Upper Scroll View")]
      performAction:GREYScrollToContentEdge(kGREYContentEdgeTop)];

  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Upper Scroll View")]
      assertWithMatcher:GREYScrolledToContentEdge(kGREYContentEdgeTop)];
}

- (void)testVisibilityOnPartiallyObscuredScrollView {
  if (iOS13_OR_ABOVE()) {
    GREYHostApplicationDistantObject *host = GREYHostApplicationDistantObject.sharedInstance;
    id<GREYAssertion> assertion = [host assertionWithPartiallyVisible];
    [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Bottom Scroll View")]
        assert:assertion];
  }
}

// Tests the action to scroll the view vertically.
- (void)testInfiniteScrollVertically {
  id<GREYMatcher> scrollView = GREYAccessibilityLabel(@"Infinite Scroll View");
  [[EarlGrey selectElementWithMatcher:scrollView]
      performAction:GREYScrollInDirection(kGREYDirectionDown, 100)];
  [[EarlGrey selectElementWithMatcher:scrollView]
      performAction:GREYScrollInDirection(kGREYDirectionUp, 100)];
}

// Tests the action to scroll the view horizontally.
- (void)testInfiniteScrollHorizontally {
  id<GREYMatcher> scrollView = GREYAccessibilityLabel(@"Infinite Scroll View");
  [[EarlGrey selectElementWithMatcher:scrollView]
      performAction:GREYScrollInDirection(kGREYDirectionRight, 100)];
  [[EarlGrey selectElementWithMatcher:scrollView]
      performAction:GREYScrollInDirection(kGREYDirectionLeft, 100)];
}

- (void)testScrollInDirectionCausesExactChangesToContentOffsetInPortraitMode {
  [self assertScrollInDirectionCausesExactChangesToContentOffset];
}

- (void)testScrollInDirectionCausesExactChangesToContentOffsetInPortraitUpsideDownMode {
  if (@available(iOS 16.0, *)) {
    // PortraitUpsideDown mode is unavailable in iOS16
    return;
  }
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationPortraitUpsideDown error:nil];
  [self assertScrollInDirectionCausesExactChangesToContentOffset];
}

- (void)testScrollInDirectionCausesExactChangesToContentOffsetInLandscapeLeftMode {
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeLeft error:nil];
  [self assertScrollInDirectionCausesExactChangesToContentOffset];
}

- (void)testScrollInDirectionCausesExactChangesToContentOffsetInLandscapeRightMode {
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeRight error:nil];
  [self assertScrollInDirectionCausesExactChangesToContentOffset];
}

// TODO: Because the action is performed outside the main thread, the synchronization // NOLINT
//       waits until the scrolling stops, where the scroll view's inertia causes itself
//       to move more than needed.
- (void)testScrollInDirectionCausesExactChangesToContentOffsetWithTinyScrollAmounts {
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Infinite Scroll View")]
      performAction:GREYScrollInDirection(kGREYDirectionDown, 7)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"topTextbox")]
      assertWithMatcher:GREYText(NSStringFromCGPoint(CGPointMake(0, 7)))];
  // Go right to (6, 7)
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Infinite Scroll View")]
      performAction:GREYScrollInDirection(kGREYDirectionRight, 6)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"topTextbox")]
      assertWithMatcher:GREYText(NSStringFromCGPoint(CGPointMake(6, 7)))];
  // Go up to (6, 4)
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Infinite Scroll View")]
      performAction:GREYScrollInDirection(kGREYDirectionUp, 3)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"topTextbox")]
      assertWithMatcher:GREYText(NSStringFromCGPoint(CGPointMake(6, 4)))];
  // Go left to (3, 4)
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Infinite Scroll View")]
      performAction:GREYScrollInDirection(kGREYDirectionLeft, 3)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"topTextbox")]
      assertWithMatcher:GREYText(NSStringFromCGPoint(CGPointMake(3, 4)))];
}

- (void)testScrollToTopWithZeroXOffset {
  // Scroll down.
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Upper Scroll View")]
      performAction:GREYScrollInDirection(kGREYDirectionDown, 500)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"topTextbox")]
      assertWithMatcher:GREYText(NSStringFromCGPoint(CGPointMake(0, 500)))];
  // Scroll up using grey_scrollToTop(...) and verify scroll offset is back at 0.
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Upper Scroll View")]
      performAction:GREYScrollToContentEdge(kGREYContentEdgeTop)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"topTextbox")]
      assertWithMatcher:GREYText(NSStringFromCGPoint(CGPointMake(0, 0)))];
}

- (void)testScrollToTopWithNonZeroXOffset {
  // Scroll to (50, 370) as going higher might cause bouncing because of iOS 13+ autoresizing.
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Infinite Scroll View")]
      performAction:GREYScrollInDirection(kGREYDirectionDown, 370)];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Infinite Scroll View")]
      performAction:GREYScrollInDirection(kGREYDirectionRight, 50)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"topTextbox")]
      assertWithMatcher:GREYText(NSStringFromCGPoint(CGPointMake(50, 370)))];
  // Scroll up using GREYScrollToContentEdge(...) and verify scroll offset is back at 0.
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Infinite Scroll View")]
      performAction:GREYScrollToContentEdge(kGREYContentEdgeTop)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"topTextbox")]
      assertWithMatcher:GREYText(NSStringFromCGPoint(CGPointMake(50, 0)))];
}

- (void)testScrollingBeyondTheContentViewCausesScrollErrors {
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Upper Scroll View")]
      performAction:GREYScrollInDirection(kGREYDirectionDown, 100)];
  NSError *scrollError;
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Upper Scroll View")]
      performAction:GREYScrollInDirection(kGREYDirectionUp, 200)
              error:&scrollError];
  GREYAssertEqualObjects(scrollError.domain, kGREYScrollErrorDomain, @"should be equal");
  GREYAssertEqual(scrollError.code, kGREYScrollReachedContentEdge, @"should be equal");
}

- (void)testSetContentOffsetAnimatedYesWaitsForAnimation {
  [self setContentOffSet:CGPointMake(0, 100) animated:YES];

  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"SquareElementLabel")]
      assertWithMatcher:GREYSufficientlyVisible()];
}

- (void)testSetContentOffsetAnimatedNoDoesNotWaitForAnimation {
  [self setContentOffSet:CGPointMake(0, 100) animated:NO];

  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"SquareElementLabel")]
      assertWithMatcher:GREYSufficientlyVisible()];
}

- (void)testSetContentOffsetToSameCGPointDoesNotWait {
  [self setContentOffSet:CGPointZero animated:YES];
}

- (void)testContentSizeSmallerThanViewSize {
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Small Content Scroll View")]
      performAction:GREYScrollToContentEdge(kGREYContentEdgeBottom)];
}

/** Verifies that the NSTimer and animation for making the scroll bar disappear is called. */
- (void)testScrollIndicatorRemovalImmediatelyAfterAnAction {
  id<GREYMatcher> infiniteScrollViewMatcher = GREYAccessibilityLabel(@"Infinite Scroll View");
  [[EarlGrey selectElementWithMatcher:infiniteScrollViewMatcher]
      performAction:GREYScrollInDirection(kGREYDirectionDown, 99)];
  id<GREYMatcher> axValueMatcher = grey_allOf(GREYAncestor(infiniteScrollViewMatcher),
                                              InfiniteScrollViewIndicatorMatcher(), nil);
  [GREYConfiguration.sharedConfiguration setValue:@(NO)
                                     forConfigKey:kGREYConfigKeySynchronizationEnabled];
  [[EarlGrey selectElementWithMatcher:axValueMatcher] assertWithMatcher:GREYSufficientlyVisible()];
  [GREYConfiguration.sharedConfiguration setValue:@(YES)
                                     forConfigKey:kGREYConfigKeySynchronizationEnabled];

  [[EarlGrey selectElementWithMatcher:infiniteScrollViewMatcher]
      performAction:GREYScrollInDirection(kGREYDirectionUp, 99)];
  [[EarlGrey selectElementWithMatcher:axValueMatcher] assertWithMatcher:GREYNotVisible()];
}

/**
 * Verifies that UIScrollView's indicator won't show with the config
 * @c kGREYConfigKeyAutoHideScrollViewIndicators on.
 */
- (void)testScrollIndicatorAutomaticallyHidenWithConfig {
  [GREYConfiguration.sharedConfiguration setValue:@(YES)
                                     forConfigKey:kGREYConfigKeyAutoHideScrollViewIndicators];
  [self addTeardownBlock:^{
    [GREYConfiguration.sharedConfiguration setValue:@(NO)
                                       forConfigKey:kGREYConfigKeyAutoHideScrollViewIndicators];
  }];

  id<GREYMatcher> infiniteScrollViewMatcher = GREYAccessibilityLabel(@"Infinite Scroll View");
  [[EarlGrey selectElementWithMatcher:infiniteScrollViewMatcher]
      performAction:GREYScrollInDirection(kGREYDirectionDown, 99)];

  id<GREYMatcher> axValueMatcher = grey_allOf(GREYAncestor(infiniteScrollViewMatcher),
                                              InfiniteScrollViewIndicatorMatcher(), nil);
  [GREYConfiguration.sharedConfiguration setValue:@(NO)
                                     forConfigKey:kGREYConfigKeySynchronizationEnabled];
  [self addTeardownBlock:^{
    [GREYConfiguration.sharedConfiguration setValue:@(YES)
                                       forConfigKey:kGREYConfigKeySynchronizationEnabled];
  }];
  [[EarlGrey selectElementWithMatcher:axValueMatcher] assertWithMatcher:GREYNotVisible()];
}

/** Scroll Indicators should be tracked post a scroll action being done. */
- (void)testScrollIndicatorRemovalAfterTurningOffSynchronizationAndPerformingAScrollAction {
  id<GREYMatcher> infiniteScrollViewMatcher = GREYAccessibilityLabel(@"Infinite Scroll View");
  [[EarlGrey selectElementWithMatcher:infiniteScrollViewMatcher]
      performAction:GREYScrollInDirection(kGREYDirectionDown, 99)];
  [[GREYConfiguration sharedConfiguration] setValue:@(NO)
                                       forConfigKey:kGREYConfigKeySynchronizationEnabled];
  [[EarlGrey selectElementWithMatcher:infiniteScrollViewMatcher]
      performAction:GREYScrollInDirection(kGREYDirectionDown, 99)];
  [[GREYConfiguration sharedConfiguration] setValue:@(YES)
                                       forConfigKey:kGREYConfigKeySynchronizationEnabled];
  id<GREYMatcher> axValueMatcher = grey_allOf(GREYAncestor(infiniteScrollViewMatcher),
                                              InfiniteScrollViewIndicatorMatcher(), nil);
  [[EarlGrey selectElementWithMatcher:axValueMatcher] assertWithMatcher:GREYNotVisible()];
}

#pragma mark - Private

/**
 * @return A GREYMatcher showing us the scroll indicator for the Infinite ScrollView.
 */
static id<GREYMatcher> InfiniteScrollViewIndicatorMatcher(void) {
  return [GREYElementMatcherBlock
      matcherWithMatchesBlock:^BOOL(NSObject *element) {
        return [element.accessibilityLabel containsString:@"Vertical scroll bar"];
      }
      descriptionBlock:^(id<GREYDescription> _Nonnull description) {
        [description appendText:@"Indicator not present"];
      }];
}

/**
 * Asserts that the scroll actions work accurately in all four directions by verifying the content
 * offset changes caused by them.
 */
- (void)assertScrollInDirectionCausesExactChangesToContentOffset {
  // Scroll by a fixed amount and verify that the scroll offset has changed by that amount.
  // Go down to (0, 99)
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Infinite Scroll View")]
      performAction:GREYScrollInDirection(kGREYDirectionDown, 99)];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"topTextbox")]
      assertWithMatcher:GREYText(NSStringFromCGPoint(CGPointMake(0, 99)))];
  // Go right to (77, 99)
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Infinite Scroll View")]
      performAction:GREYScrollInDirection(kGREYDirectionRight, 77)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"topTextbox")]
      assertWithMatcher:GREYText(NSStringFromCGPoint(CGPointMake(77, 99)))];
  // Go up to (77, 44)
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Infinite Scroll View")]
      performAction:GREYScrollInDirection(kGREYDirectionUp, 55)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"topTextbox")]
      assertWithMatcher:GREYText(NSStringFromCGPoint(CGPointMake(77, 44)))];
  // Go left to (33, 44)
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Infinite Scroll View")]
      performAction:GREYScrollInDirection(kGREYDirectionLeft, 44)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"topTextbox")]
      assertWithMatcher:GREYText(NSStringFromCGPoint(CGPointMake(33, 44)))];
}

/** Makes a setContentOffset:animated: call on an element of type UIScrollView. */
- (void)setContentOffSet:(CGPoint)offset animated:(BOOL)animated {
  GREYHostApplicationDistantObject *host = GREYHostApplicationDistantObject.sharedInstance;
  id<GREYAction> action = [host actionForSetScrollViewContentOffSet:offset animated:animated];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Upper Scroll View")]
      performAction:action];
}

@end
