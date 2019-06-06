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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  EarlGrey specific common additions to UIView.
 */
@interface UIView (GREYCommon)

/**
 * Sets the view's alpha value to the provided @c alpha value, storing the current value so it can
 * be restored using UIView::grey_restoreAlpha.
 *
 * @param alpha The new alpha value for the view.
 */
- (void)grey_saveCurrentAlphaAndUpdateWithValue:(float)alpha;

/**
 * Restores the view's alpha to the value it contained when
 * UIView::grey_saveCurrentAlphaAndUpdateWithValue: was last invoked.
 */
- (void)grey_restoreAlpha;

/**
 * Quick check to see if a view meets the basic visibility criteria of being not hidden, visible
 * with a minimum alpha and has a valid accessibility frame. It also checks to ensure if a view
 * is not a subview of another view or window that has a translucent alpha value or is hidden.
 */
- (BOOL)grey_isVisible;

/**
 * Check if the current view is an ancestor of the specified view. A view cannot be an ancestor
 * of itself.
 */
- (BOOL)grey_isAncestorOfView:(UIView *)view;

/**
 *  Makes sure that subview @c view is always on top, even if other subviews are added in front of
 *  it. Also keeps the @c view's frame fixed to the current value so parent can't change it.
 *
 *  @param view The view to keep as the top-most fixed subview.
 */
- (void)grey_keepSubviewOnTopAndFrameFixed:(UIView *)view;

/**
 *  Makes this view and all its super view opaque. Successive calls to this method will replace
 *  the previously stored alpha value, causing any saved value to be lost.
 *
 *  @remark Each invocation will save the current alpha value which can be restored by calling
 *          -[UIView grey_restoreOpacity]
 */
- (void)grey_recursivelyMakeOpaque;

/**
 *  Restores the opacity of this view and it's super views if they were made opaque by calling
 *  -[UIView grey_recursivelyMakeOpaque]. If -[UIView grey_recursivelyMakeOpaque] was not
 *  called before, then this method will perform a no-op on each of the view's superviews.
 */
- (void)grey_restoreOpacity;

/**
 *  Makes sure that subview @c view is always on top is added to the front of all other subviews.
 */
- (void)grey_bringAlwaysTopSubviewToFront;

@end
NS_ASSUME_NONNULL_END
