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
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Row 5")]
      performAction:GREYLongPress()];
  XCTAssertTrue([self waitForVisibilityForText:@"Some"]);
  [[EarlGrey selectElementWithMatcher:GREYText(@"Some")] performAction:GREYTap()];
  XCTAssertTrue([self waitForVisibilityForText:@"Row 6"]);
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Row 6")]
      performAction:GREYLongPress()];
  XCTAssertTrue([self waitForVisibilityForText:@"Some"]);
  [[EarlGrey selectElementWithMatcher:GREYText(@"Some")] performAction:GREYTap()];
  XCTAssertTrue([self waitForVisibilityForText:@"Row 7"]);
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Row 7")]
      assertWithMatcher:GREYNot(GREYSelected())];
}

- (void)testRemoveRow {
  id<GREYMatcher> deleteRowMatcher =
      grey_allOf(GREYAccessibilityLabel(@"Delete"), GREYKindOfClass([UIButton class]), nil);
  for (int i = 0; i < 5; i++) {
    NSString *labelForRowToDelete = [NSString stringWithFormat:@"Row %d", i];
    [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(labelForRowToDelete)]
        performAction:GREYSwipeSlowInDirection(kGREYDirectionLeft)];
    [[EarlGrey selectElementWithMatcher:deleteRowMatcher] performAction:GREYTap()];
    [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(labelForRowToDelete)]
        assertWithMatcher:GREYNotVisible()];
  }
}

/** Tests the visibility of a table view cell when the above cell is in delete mode. */
- (void)testVisibilityOfTheBelowRowInDeleteMode {
  for (int i = 0; i < 5; i++) {
    NSString *labelForRowToDelete = [NSString stringWithFormat:@"Row %d", i];
    NSString *labelForNextRow = [NSString stringWithFormat:@"Row %d", i + 1];
    [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(labelForRowToDelete)]
        performAction:GREYSwipeSlowInDirection(kGREYDirectionLeft)];
    [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(labelForNextRow)]
        assertWithMatcher:GREYSufficientlyVisible()];
  }
}

- (void)testSearchActionWithTinyScrollIncrements {
  [[self ftr_scrollToCellAtIndex:18 byScrollingInAmounts:50
                     InDirection:kGREYDirectionDown] assertWithMatcher:GREYNotNil()];
  [[self ftr_scrollToCellAtIndex:0 byScrollingInAmounts:50
                     InDirection:kGREYDirectionUp] assertWithMatcher:GREYNotNil()];
  [[self ftr_scrollToCellAtIndex:18 byScrollingInAmounts:50
                     InDirection:kGREYDirectionDown] assertWithMatcher:GREYNotNil()];
}

- (void)testSearchActionWithLargeScrollIncrements {
  [[self ftr_scrollToCellAtIndex:20 byScrollingInAmounts:200
                     InDirection:kGREYDirectionDown] assertWithMatcher:GREYNotNil()];
  [[self ftr_scrollToCellAtIndex:0 byScrollingInAmounts:200
                     InDirection:kGREYDirectionUp] assertWithMatcher:GREYNotNil()];
  [[self ftr_scrollToCellAtIndex:20 byScrollingInAmounts:200
                     InDirection:kGREYDirectionDown] assertWithMatcher:GREYNotNil()];
}

- (void)testScrollToTop {
  // Scroll down.
  [[self ftr_scrollToCellAtIndex:20 byScrollingInAmounts:200
                     InDirection:kGREYDirectionDown] assertWithMatcher:GREYNotNil()];
  // Scroll to top and verify that we are at the top.
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"main_table_view")]
      performAction:GREYScrollToContentEdge(kGREYContentEdgeTop)]
      assertWithMatcher:GREYScrolledToContentEdge(kGREYContentEdgeTop)];
}

- (void)testScrollToTopWithPositiveInsets {
  // Add positive insets using this format {top,left,bottom,right}
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"insets value")]
      performAction:GREYTypeText(@"{100,0,0,0}\n")];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"insets toggle")]
      performAction:GREYTurnSwitchOn(YES)];
  // Scroll down.
  [[self ftr_scrollToCellAtIndex:20 byScrollingInAmounts:200
                     InDirection:kGREYDirectionDown] assertWithMatcher:GREYNotNil()];
  // Scroll to top and verify that we are at the top.
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"main_table_view")]
      performAction:GREYScrollToContentEdge(kGREYContentEdgeTop)]
      assertWithMatcher:GREYScrolledToContentEdge(kGREYContentEdgeTop)];
}

- (void)testScrollToTopWithNegativeInsets {
  // Add negative insets using this format {top,left,bottom,right}
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"insets value")]
      performAction:GREYTypeText(@"{-100,0,0,0}\n")];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"insets toggle")]
      performAction:GREYTurnSwitchOn(YES)];
  // Scroll down.
  [[self ftr_scrollToCellAtIndex:20 byScrollingInAmounts:200
                     InDirection:kGREYDirectionDown] assertWithMatcher:GREYNotNil()];
  // Scroll to top and verify that we are at the top.
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"main_table_view")]
      performAction:GREYScrollToContentEdge(kGREYContentEdgeTop)]
      assertWithMatcher:GREYScrolledToContentEdge(kGREYContentEdgeTop)];
}

- (void)testScrollToTopWhenAlreadyAtTheTopWithoutBounce {
  id<GREYAction> bounceOff =
      [GREYHostApplicationDistantObject.sharedInstance actionForTableViewBoundOff];

  // Verify this test with and without bounce enabled by toggling it.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"main_table_view")]
      performAction:bounceOff];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"main_table_view")]
      performAction:GREYScrollToContentEdge(kGREYContentEdgeTop)];
  // Verify that top most cell is visible.
  [[EarlGrey selectElementWithMatcher:[self ftr_matcherForCellAtIndex:0]]
      assertWithMatcher:GREYSufficientlyVisible()];
}

- (void)testScrollToTopWhenAlreadyAtTheTopWithBounce {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"main_table_view")]
      performAction:GREYScrollToContentEdge(kGREYContentEdgeTop)];
  // Verify that top most cell is visible.
  [[EarlGrey selectElementWithMatcher:[self ftr_matcherForCellAtIndex:0]]
      assertWithMatcher:GREYSufficientlyVisible()];
}

- (void)testTableViewVisibleWhenScrolled {
  [[[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"main_table_view")]
      assertWithMatcher:GREYSufficientlyVisible()]
      performAction:GREYSwipeFastInDirection(kGREYDirectionUp)]
      performAction:GREYSwipeFastInDirection(kGREYDirectionUp)]
      assertWithMatcher:GREYSufficientlyVisible()];
}

- (void)testFrameworkSynchronizesWithScrolling {
  id<GREYMatcher> notScrollingMatcher =
      [GREYHostApplicationDistantObject.sharedInstance matcherForNotScrolling];
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"main_table_view")]
      performAction:GREYSwipeSlowInDirection(kGREYDirectionDown)]
      assertWithMatcher:notScrollingMatcher];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Row 1")]
      assertWithMatcher:GREYSufficientlyVisible()];
}

/**
 * Test scrolling to the bottom of a UITableView and tapping on a cell.
 */
- (void)testTapOnLastCell {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"main_table_view")]
      performAction:GREYScrollToContentEdge(kGREYContentEdgeBottom)];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Row 99")] performAction:GREYTap()];
}

/**
 * Test scrolling to the bottom of a UITableView and tapping on a cell using a search action.
 */
- (void)testTapOnLastCellUsingSearchAction {
  NSTimeInterval previousTimeout = GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration);
  [GREYConfiguration.sharedConfiguration setValue:@60
                                     forConfigKey:kGREYConfigKeyInteractionTimeoutDuration];
  [self addTeardownBlock:^{
    [GREYConfiguration.sharedConfiguration setValue:@(previousTimeout)
                                       forConfigKey:kGREYConfigKeyInteractionTimeoutDuration];
  }];
  [[[EarlGrey selectElementWithMatcher:GREYText(@"Row 99")]
         usingSearchAction:GREYScrollToContentEdge(kGREYContentEdgeBottom)
      onElementWithMatcher:grey_accessibilityID(@"main_table_view")] performAction:GREYTap()];
}

#pragma mark - Private

- (id<GREYMatcher>)ftr_matcherForCellAtIndex:(NSInteger)index {
  return GREYAccessibilityLabel([NSString stringWithFormat:@"Row %d", (int)index]);
}

- (GREYElementInteraction *)ftr_scrollToCellAtIndex:(NSInteger)index
                               byScrollingInAmounts:(CGFloat)amount
                                        InDirection:(GREYDirection)direction {
  id<GREYMatcher> matcher =
      grey_allOf([self ftr_matcherForCellAtIndex:index], GREYInteractable(), nil);
  return [[EarlGrey selectElementWithMatcher:matcher]
         usingSearchAction:GREYScrollInDirection(direction, amount)
      onElementWithMatcher:GREYKindOfClass([UITableView class])];
}

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
