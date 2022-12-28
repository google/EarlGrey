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

#import "ExposedForTesting.h"
#import "EarlGrey.h"
#import "GREYHostApplicationDistantObject+VisibilityTest.h"
#import "BaseIntegrationTest.h"

@interface VisibilityTest : BaseIntegrationTest
@end

@implementation VisibilityTest

- (void)setUp {
  [super setUp];
  [self openTestViewNamed:@"Visibility Tests"];
}

- (void)testVisualEffectsView {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"visualEffectsImageView")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

- (void)testOverlappingViews {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"bottomScrollView")]
      performAction:grey_scrollToContentEdge(kGREYContentEdgeTop)];
  id<GREYAssertion> assertion =
      [GREYHostApplicationDistantObject.sharedInstance coverContentOffsetChangedAssertion];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"coverScrollView")] assert:assertion];
}

- (void)testTranslucentViews {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"translucentLabel")]
      assertWithMatcher:grey_sufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"translucentOverlappingView")]
      assertWithMatcher:grey_sufficientlyVisible()];
  GREYHostApplicationDistantObject *host = GREYHostApplicationDistantObject.sharedInstance;
  id<GREYAssertion> assertion = [host translucentOverlappingViewVisibleAreaAssertion];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"translucentOverlappingView")]
      assert:assertion];
}

- (void)testNonPixelBoundaryAlignedLabel {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"unalignedPixel1")]
      assertWithMatcher:grey_sufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"unalignedPixel2")]
      assertWithMatcher:grey_sufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"unalignedPixel3")]
      assertWithMatcher:grey_sufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"unalignedPixel4")]
      assertWithMatcher:grey_sufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"unalignedPixelWithOnePixelSize")]
      assertWithMatcher:grey_sufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"unalignedPixelWithHalfPixelSize")]
      assertWithMatcher:grey_notVisible()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"unalignedPixelWithFractionPixelSize")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

- (void)testButtonIsVisible {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"VisibilityButton")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

- (void)testObscuredButtonIsNotVisible {
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"VisibilityButton")]
      performAction:grey_tap()] assertWithMatcher:grey_notVisible()];
}

- (void)testRasterization {
  [GREYHostApplicationDistantObject.sharedInstance setupOuterView];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"RasterizedLayer")]
      assertWithMatcher:grey_sufficientlyVisible()];
  [GREYHostApplicationDistantObject.sharedInstance removeOuterView];
}

- (void)testVisibleRectOfPartiallyObscuredView {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"RedSquare")]
      assert:[GREYHostApplicationDistantObject.sharedInstance visibleRectangleSizeAssertion]];
}

- (void)testVisibleEnclosingRectangleOfVisibleViewIsEntireView {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"VisibilityButton")]
      assert:[GREYHostApplicationDistantObject.sharedInstance entireRectangleVisibleAssertion]];
}

- (void)testVisibleEnclosingRectangleOfObscuredViewIsCGRectNull {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"VisibilityButton")]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"VisibilityButton")]
      assert:[GREYHostApplicationDistantObject.sharedInstance visibleRectangleAssertion]];
}

- (void)testInteractablityFailureDescription {
  NSError *error;
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"RedBar")]
      assertWithMatcher:grey_interactable()
                  error:&error];
  XCTAssertTrue([error.description containsString:@"interactable Point:{nan, nan}"]);
}

- (void)testVisibilityFailsWhenViewIsObscured {
  // Verify RedBar cannot be interacted with when overlapped by another view.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"RedBar")]
      assertWithMatcher:grey_not(grey_interactable())];

  // Unhide the activation point.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"UnObscureRedBar")]
      performAction:grey_turnSwitchOn(YES)];

  // Verify RedBar can now be interacted with.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"RedBar")]
      assertWithMatcher:grey_interactable()];
}

- (void)testVisibilityOfViewsWithSameAccessibilityLabelAndAtIndex {
  NSError *error;

  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"AView")]
      assertWithMatcher:grey_sufficientlyVisible()
                  error:&error];
  GREYAssertEqual(error.code, kGREYInteractionMultipleElementsMatchedErrorCode, @"should be equal");

  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"AView")] performAction:grey_tap()
                                                                                 error:&error];
  GREYAssertEqual(error.code, kGREYInteractionMultipleElementsMatchedErrorCode, @"should be equal");

  NSMutableSet<NSString *> *idSet = [GREY_REMOTE_CLASS_IN_APP(NSMutableSet) set];
  GREYHostApplicationDistantObject *host = [GREYHostApplicationDistantObject sharedInstance];
  // Match against the first view present.
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"AView")] atIndex:0]
      assert:[host assertOnIDSet:idSet]];

  // Match against the second view present.
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"AView")] atIndex:1]
      assert:[host assertOnIDSet:idSet]];

  // Match against the third and last view present.
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"AView")] atIndex:2]
      assert:[host assertOnIDSet:idSet]];

  // Use the element at index matcher with an incorrect matcher.
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"InvalidView")] atIndex:0]
      assertWithMatcher:grey_sufficientlyVisible()
                  error:&error];
  GREYAssertEqual(error.code, kGREYInteractionElementNotFoundErrorCode, @"should be equal");

  // Use the element at index matcher with an incorrect matcher on an action.
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"InvalidView")] atIndex:0]
      performAction:grey_tap()
              error:&error];
  GREYAssertEqual(error.code, kGREYInteractionElementNotFoundErrorCode, @"should be equal");

  // Use the element at index matcher with an incorrect matcher and also an invalid bounds.
  // This should throw an error with the code as kGREYInteractionElementNotFoundErrorCode
  // since we first check if the number of matched elements is greater than zero.
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"InvalidView")] atIndex:99]
      assertWithMatcher:grey_sufficientlyVisible()
                  error:&error];
  GREYAssertEqual(error.code, kGREYInteractionElementNotFoundErrorCode, @"should be equal");

  // Use the element at index matcher with an index greater than the number of
  // matched elements.
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"AView")] atIndex:999]
      assertWithMatcher:grey_sufficientlyVisible()
                  error:&error];
  GREYAssertEqual(error.code, kGREYInteractionMatchedElementIndexOutOfBoundsErrorCode,
                  @"should be equal");

  GREYAssertEqual(idSet.count, 3, @"should be equal");
}

- (void)testElementsInHierarchyDump {
  NSString *hierarchyDump = [GREYElementHierarchy hierarchyString];
  NSArray<NSString *> *stringTargetHierarchy = @[
    @"========== Window 1 ==========", @"<UIWindow:", @"  |--<UILayoutContainerView:",
    @"  |  |--<UINavigationTransitionView:", @"  |  |  |--<UIViewControllerWrapperView:",
    @"  |  |  |  |--<UIView", @"  |  |  |  |  |--<UIView:"
  ];
  for (NSString *targetString in stringTargetHierarchy) {
    XCTAssertNotEqual([hierarchyDump rangeOfString:targetString].location, (NSUInteger)NSNotFound);
  }
}

/**
 * Checks the values of the Visibility Checker's saved images. You have to make sure the thorough
 * visibility checker is used because only thorough visibility checker will generate an image. This
 * is done by checking the visibility of the orange view that is under a rotated view (which will
 * cause a fallback to thorough visibility checker).
 */
- (void)testVisibilityCheckerImages {
  GREYHostApplicationDistantObject *host = [GREYHostApplicationDistantObject sharedInstance];
  // Since we all checks are successful till here, there should be no visibility images.
  XCTAssertTrue([host visibilityImagesAreAbsent]);
  // On a visibility failure, the images must be generated.
  NSError *error;
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"orangeView")]
      assertWithMatcher:grey_sufficientlyVisible()
                  error:&error];
  XCTAssertNotNil(error);
  // Images are nilled out on a successful check of any sort.
  XCTAssertTrue([host visibilityImagesArePresent]);
  [[EarlGrey selectElementWithMatcher:grey_keyWindow()]
      assertWithMatcher:grey_sufficientlyVisible()];
  XCTAssertTrue([host visibilityImagesAreAbsent]);
  // Images are still nil on a non-visibility failure.
  error = nil;
  [[EarlGrey selectElementWithMatcher:grey_text(@"Garbage Value")] assertWithMatcher:grey_notNil()
                                                                               error:&error];
  XCTAssertNotNil(error);
  XCTAssertTrue([host visibilityImagesAreAbsent]);
}

@end
