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

#import "GREYElementMatcherBlock.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * A subclass of GREYElementMatcherBlock for visibility matching only.
 *
 * @note Visibility checks are some of the most resource-intensive operations in EarlGrey. This
 *       helps optimize their usage separately from other matchers.
 */
@interface GREYVisibilityMatcher : GREYElementMatcherBlock

/**
 * @remark init is not an available initializer. Use the other initializers.
 *         Use GREYElementMatcherBlock: initWithName:matchesBlock:descriptionBlock: instead.
 **/
- (instancetype)init NS_UNAVAILABLE;

/**
 * Matcher for UI element whose percent visible area (of its accessibility frame) exceeds the
 * given @c percent.
 *
 * @note This is an expensive check (can take around 250ms for a simple 100 x 100 pt view). Do not
 *       use it in your selectElementWithMatcher statement for matching an element but use it to
 *       assert on a matched element's state.
 *
 * @param percent The percent visible area that the UI element being matched has to be visible.
 *                Allowed values for @c percent are [0,1] inclusive.
 *
 * @return A matcher that checks if a UI element has a visible area at least equal
 *         to a minimum value.
 */
- (instancetype)initForMinimumVisiblePercent:(CGFloat)percent;

/**
 * Matcher for UI element that is sufficiently visible to the user. EarlGrey considers elements
 * that are more than @c kElementSufficientlyVisiblePercentage (75 %) visible areawise to be
 * sufficiently visible.
 *
 * @note This is an expensive check (can take around 250ms for a simple 100 x 100 pt view). Do not
 *       use it in your selectElementWithMatcher statement for matching an element but use it to
 *       assert on a matched element's state. Also, an element is considered not visible if it is
 *       obscured by another view with an @c alpha greater than or equal to 0.95.
 *
 * @return A matcher initialized with a visibility percentage that confirms an element is
 *         sufficiently visible.
 */
- (instancetype)initForSufficientlyVisible;

/**
 * Matcher for UI element that is not visible to the user at all i.e. it has a zero visible area.
 *
 * @note This is an expensive check (can take around 250ms for a simple 100 x 100 pt view). Do not
 *       use it in your selectElementWithMatcher statement for matching an element but use it to
 *       assert on a matched element's state.
 *
 * @return A matcher for verifying if an element is not visible.
 */
- (instancetype)initForNotVisible;

/**
 * Matcher for UI element that matches EarlGrey's criteria for user interaction. Currently it must
 * satisfy at least the following criteria:
 * 1) At least a few pixels of the element are visible to the user.
 * 2) The element's accessibility activation point OR the center of the element's visible area
 *    is completely visible.
 *
 * @return A matcher that checks if a UI element is interactable.
 */
- (instancetype)initForInteractable;

@end

NS_ASSUME_NONNULL_END
