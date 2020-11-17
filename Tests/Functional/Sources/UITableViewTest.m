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
#import "GREYHostApplicationDistantObject+UITableViewTest.h"
#import "BaseIntegrationTest.h"

@interface UITableViewTest : BaseIntegrationTest
@end

@implementation UITableViewTest

- (void)setUp {
  [super setUp];
  [self openTestViewNamed:@"Table Views"];
}

- (void)testContextMenuInteractionsWithATableView {
  // TODO(b/169197992): Add a drag action test with press and drag action.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Row 5")]
      performAction:grey_longPress()];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Some")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Row 6")]
      performAction:grey_longPress()];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Some")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Row 7")]
      assertWithMatcher:grey_not(grey_selected())];
}

- (void)testRemoveRow {
  id<GREYMatcher> deleteRowMatcher =
      grey_allOf(grey_accessibilityLabel(@"Delete"), grey_kindOfClass([UIButton class]), nil);
  for (int i = 0; i < 5; i++) {
    NSString *labelForRowToDelete = [NSString stringWithFormat:@"Row %d", i];
    [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(labelForRowToDelete)]
        performAction:grey_swipeSlowInDirection(kGREYDirectionLeft)];
    [[EarlGrey selectElementWithMatcher:deleteRowMatcher] performAction:grey_tap()];
    [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(labelForRowToDelete)]
        assertWithMatcher:grey_notVisible()];
  }
}

/** Tests the visibility of a table view cell when the above cell is in delete mode. */
- (void)testVisibilityOfTheBelowRowInDeleteMode {
  for (int i = 0; i < 5; i++) {
    NSString *labelForRowToDelete = [NSString stringWithFormat:@"Row %d", i];
    NSString *labelForNextRow = [NSString stringWithFormat:@"Row %d", i + 1];
    [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(labelForRowToDelete)]
        performAction:grey_swipeSlowInDirection(kGREYDirectionLeft)];
    [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(labelForNextRow)]
        assertWithMatcher:grey_sufficientlyVisible()];
  }
}

- (void)testSearchActionWithTinyScrollIncrements {
  [[self ftr_scrollToCellAtIndex:18 byScrollingInAmounts:50
                     InDirection:kGREYDirectionDown] assertWithMatcher:grey_notNil()];
  [[self ftr_scrollToCellAtIndex:0 byScrollingInAmounts:50
                     InDirection:kGREYDirectionUp] assertWithMatcher:grey_notNil()];
  [[self ftr_scrollToCellAtIndex:18 byScrollingInAmounts:50
                     InDirection:kGREYDirectionDown] assertWithMatcher:grey_notNil()];
}

- (void)testSearchActionWithLargeScrollIncrements {
  [[self ftr_scrollToCellAtIndex:20 byScrollingInAmounts:200
                     InDirection:kGREYDirectionDown] assertWithMatcher:grey_notNil()];
  [[self ftr_scrollToCellAtIndex:0 byScrollingInAmounts:200
                     InDirection:kGREYDirectionUp] assertWithMatcher:grey_notNil()];
  [[self ftr_scrollToCellAtIndex:20 byScrollingInAmounts:200
                     InDirection:kGREYDirectionDown] assertWithMatcher:grey_notNil()];
}

- (void)testScrollToTop {
  // Scroll down.
  [[self ftr_scrollToCellAtIndex:20 byScrollingInAmounts:200
                     InDirection:kGREYDirectionDown] assertWithMatcher:grey_notNil()];
  // Scroll to top and verify that we are at the top.
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"main_table_view")]
      performAction:grey_scrollToContentEdge(kGREYContentEdgeTop)]
      assertWithMatcher:grey_scrolledToContentEdge(kGREYContentEdgeTop)];
}

- (void)testScrollToTopWithPositiveInsets {
  // Add positive insets using this format {top,left,bottom,right}
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"insets value")]
      performAction:grey_typeText(@"{100,0,0,0}\n")];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"insets toggle")]
      performAction:grey_turnSwitchOn(YES)];
  // Scroll down.
  [[self ftr_scrollToCellAtIndex:20 byScrollingInAmounts:200
                     InDirection:kGREYDirectionDown] assertWithMatcher:grey_notNil()];
  // Scroll to top and verify that we are at the top.
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"main_table_view")]
      performAction:grey_scrollToContentEdge(kGREYContentEdgeTop)]
      assertWithMatcher:grey_scrolledToContentEdge(kGREYContentEdgeTop)];
}

- (void)testScrollToTopWithNegativeInsets {
  // Add negative insets using this format {top,left,bottom,right}
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"insets value")]
      performAction:grey_typeText(@"{-100,0,0,0}\n")];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"insets toggle")]
      performAction:grey_turnSwitchOn(YES)];
  // Scroll down.
  [[self ftr_scrollToCellAtIndex:20 byScrollingInAmounts:200
                     InDirection:kGREYDirectionDown] assertWithMatcher:grey_notNil()];
  // Scroll to top and verify that we are at the top.
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"main_table_view")]
      performAction:grey_scrollToContentEdge(kGREYContentEdgeTop)]
      assertWithMatcher:grey_scrolledToContentEdge(kGREYContentEdgeTop)];
}

- (void)testScrollToTopWhenAlreadyAtTheTopWithoutBounce {
  id<GREYAction> bounceOff =
      [GREYHostApplicationDistantObject.sharedInstance actionForTableViewBoundOff];

  // Verify this test with and without bounce enabled by toggling it.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"main_table_view")]
      performAction:bounceOff];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"main_table_view")]
      performAction:grey_scrollToContentEdge(kGREYContentEdgeTop)];
  // Verify that top most cell is visible.
  [[EarlGrey selectElementWithMatcher:[self ftr_matcherForCellAtIndex:0]]
      assertWithMatcher:grey_sufficientlyVisible()];
}

- (void)testScrollToTopWhenAlreadyAtTheTopWithBounce {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"main_table_view")]
      performAction:grey_scrollToContentEdge(kGREYContentEdgeTop)];
  // Verify that top most cell is visible.
  [[EarlGrey selectElementWithMatcher:[self ftr_matcherForCellAtIndex:0]]
      assertWithMatcher:grey_sufficientlyVisible()];
}

- (void)testTableViewVisibleWhenScrolled {
  [[[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"main_table_view")]
      assertWithMatcher:grey_sufficientlyVisible()]
      performAction:grey_swipeFastInDirection(kGREYDirectionUp)]
      performAction:grey_swipeFastInDirection(kGREYDirectionUp)]
      assertWithMatcher:grey_sufficientlyVisible()];
}

- (void)testFrameworkSynchronizesWithScrolling {
  id<GREYMatcher> notScrollingMatcher =
      [GREYHostApplicationDistantObject.sharedInstance matcherForNotScrolling];
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"main_table_view")]
      performAction:grey_swipeSlowInDirection(kGREYDirectionDown)]
      assertWithMatcher:notScrollingMatcher];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Row 1")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

/**
 * Test scrolling to the bottom of a UITableView and tapping on a cell.
 */
- (void)testTapOnLastCell {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"main_table_view")]
      performAction:grey_scrollToContentEdge(kGREYContentEdgeBottom)];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Row 99")] performAction:grey_tap()];
}

/**
 * Test scrolling to the bottom of a UITableView and tapping on a cell using a search action.
 */
- (void)testTapOnLastCellUsingSearchAction {
  [[[EarlGrey selectElementWithMatcher:grey_text(@"Row 99")]
         usingSearchAction:grey_scrollToContentEdge(kGREYContentEdgeBottom)
      onElementWithMatcher:grey_accessibilityID(@"main_table_view")] performAction:grey_tap()];
}

#pragma mark - Private

- (id<GREYMatcher>)ftr_matcherForCellAtIndex:(NSInteger)index {
  return grey_accessibilityLabel([NSString stringWithFormat:@"Row %d", (int)index]);
}

- (GREYElementInteraction *)ftr_scrollToCellAtIndex:(NSInteger)index
                               byScrollingInAmounts:(CGFloat)amount
                                        InDirection:(GREYDirection)direction {
  id<GREYMatcher> matcher =
      grey_allOf([self ftr_matcherForCellAtIndex:index], grey_interactable(), nil);
  return [[EarlGrey selectElementWithMatcher:matcher]
         usingSearchAction:grey_scrollInDirection(direction, amount)
      onElementWithMatcher:grey_kindOfClass([UITableView class])];
}

@end
