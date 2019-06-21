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

#import "UIView+GREYCommon.h"

#include <objc/runtime.h>

#import "GREYConstants.h"

@implementation UIView (GREYCommon)

/**
 * Sets the view's alpha value to the provided @c alpha value, storing the current value so it can
 * be restored using UIView::grey_restoreAlpha.
 *
 * @param alpha The new alpha value for the view.
 */
- (void)grey_saveCurrentAlphaAndUpdateWithValue:(float)alpha {
  objc_setAssociatedObject(self, @selector(grey_restoreAlpha), @(self.alpha),
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  self.alpha = alpha;
}

- (void)grey_bringAlwaysTopSubviewToFront {
  UIView *alwaysTopSubview =
      objc_getAssociatedObject(self, @selector(grey_bringAlwaysTopSubviewToFront));
  if (alwaysTopSubview && [self.subviews containsObject:alwaysTopSubview]) {
    [self bringSubviewToFront:alwaysTopSubview];
  }
}

/**
 * Restores the view's alpha to the value it contained when
 * UIView::grey_saveCurrentAlphaAndUpdateWithValue: was last invoked.
 */
- (void)grey_restoreAlpha {
  id alpha = objc_getAssociatedObject(self, @selector(grey_restoreAlpha));
  self.alpha = [alpha floatValue];
  objc_setAssociatedObject(self, @selector(grey_restoreAlpha), nil, OBJC_ASSOCIATION_ASSIGN);
}

/**
 * Quick check to see if a view meets the basic visibility criteria of being not hidden, visible
 * with a minimum alpha and has a valid accessibility frame. It also checks to ensure if a view
 * is not a subview of another view or window that has a translucent alpha value or is hidden.
 */
- (BOOL)grey_isVisible {
  if (CGRectIsEmpty([self accessibilityFrame])) {
    return NO;
  }

  UIView *ancestorView = self;
  do {
    if (ancestorView.hidden || ancestorView.alpha < kGREYMinimumVisibleAlpha) {
      return NO;
    }
    ancestorView = ancestorView.superview;
  } while (ancestorView);

  return YES;
}

- (BOOL)grey_isAncestorOfView:(UIView *)view {
  view = view.superview;
  while (view) {
    if (self == view) {
      return YES;
    }
    view = view.superview;
  }
  return NO;
}

- (void)grey_recursivelyMakeOpaque {
  objc_setAssociatedObject(self, @selector(grey_restoreOpacity), @(self.alpha),
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  self.alpha = 1.0;
  [self.superview grey_recursivelyMakeOpaque];
}

- (void)grey_restoreOpacity {
  NSNumber *alpha = objc_getAssociatedObject(self, @selector(grey_restoreOpacity));
  if (alpha) {
    self.alpha = [alpha floatValue];
    objc_setAssociatedObject(self, @selector(grey_restoreOpacity), nil, OBJC_ASSOCIATION_ASSIGN);
  }
  [self.superview grey_restoreOpacity];
}

- (void)grey_keepSubviewOnTopAndFrameFixed:(UIView *)view {
  NSValue *frameRect = [NSValue valueWithCGRect:view.frame];
  objc_setAssociatedObject(view, @selector(grey_keepSubviewOnTopAndFrameFixed:), frameRect,
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  objc_setAssociatedObject(self, @selector(grey_bringAlwaysTopSubviewToFront), view,
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  [self bringSubviewToFront:view];
}

@end
