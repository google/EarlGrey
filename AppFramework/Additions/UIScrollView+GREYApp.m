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

#import "UIScrollView+GREYApp.h"

#include <objc/message.h>
#include <objc/runtime.h>

#import "GREYSurrogateDelegate.h"
#import "GREYAppStateTracker.h"
#import "GREYFatalAsserts.h"
#import "GREYAppState.h"
#import "GREYAppleInternals.h"
#import "GREYSwizzler.h"

@implementation UIScrollView (GREYApp)

+ (void)load {
  GREYSwizzler *swizzler = [[GREYSwizzler alloc] init];

  SEL originalSel = @selector(_scrollViewWillBeginDragging);
  SEL swizzledSel = @selector(greyswizzled_scrollViewWillBeginDragging);
  BOOL swizzled = [swizzler swizzleClass:[UIScrollView class]
                   replaceInstanceMethod:originalSel
                              withMethod:swizzledSel];
  GREYFatalAssertWithMessage(swizzled,
                             @"Cannot swizzle [UIScrollView _scrollViewWillBeginDragging]");

  originalSel = @selector(_scrollViewDidEndDraggingWithDeceleration:);
  swizzledSel = @selector(greyswizzled_scrollViewDidEndDraggingWithDeceleration:);
  swizzled = [swizzler swizzleClass:[UIScrollView class]
              replaceInstanceMethod:originalSel
                         withMethod:swizzledSel];
  GREYFatalAssertWithMessage(swizzled,
                             @"Cannot swizzle "
                             @"[UIScrollView _scrollViewDidEndDraggingWithDeceleration:]");

  originalSel = @selector(_stopScrollDecelerationNotify:);
  swizzledSel = @selector(greyswizzled_stopScrollDecelerationNotify:);
  swizzled = [swizzler swizzleClass:[UIScrollView class]
              replaceInstanceMethod:originalSel
                         withMethod:swizzledSel];
  GREYFatalAssertWithMessage(swizzled,
                             @"Cannot swizzle [UIScrollView _stopScrollDecelerationNotify:]");
  originalSel = @selector(setContentOffset:);
  swizzledSel = @selector(greyswizzled_setContentOffset:);
  swizzled = [swizzler swizzleClass:[UIScrollView class]
              replaceInstanceMethod:originalSel
                         withMethod:swizzledSel];
  GREYFatalAssertWithMessage(swizzled, @"Cannot swizzle [UIScrollView setContentOffset:]");

  if (@available(iOS 17.4, tvOS 17.4, *)) {
    originalSel = @selector(setContentOffset:animated:);
    swizzledSel = @selector(greyswizzled_setContentOffset:animated:);
    swizzled = [swizzler swizzleClass:[UIScrollView class]
                replaceInstanceMethod:originalSel
                           withMethod:swizzledSel];
    GREYFatalAssertWithMessage(swizzled,
                               @"Cannot swizzle [UIScrollView setContentOffset:animated:]");

    originalSel = @selector(_delegateScrollViewAnimationEnded);
    swizzledSel = @selector(greyswizzled_delegateScrollViewAnimationEnded);
    swizzled = [swizzler swizzleClass:[UIScrollView class]
                replaceInstanceMethod:originalSel
                           withMethod:swizzledSel];
    GREYFatalAssertWithMessage(swizzled,
                               @"Cannot swizzle [UIScrollView _delegateScrollViewAnimationEnded]");

    originalSel = @selector(_stopScrollingNotify:pin:);
    swizzledSel = @selector(greyswizzled_stopScrollingNotify:pin:);
    swizzled = [swizzler swizzleClass:[UIScrollView class]
                replaceInstanceMethod:originalSel
                           withMethod:swizzledSel];
    GREYFatalAssertWithMessage(swizzled,
                               @"Cannot swizzle [UIScrollView _stopScrollingNotify:pin:]");

    originalSel = @selector(didMoveToWindow);
    swizzledSel = @selector(greyswizzled_didMoveToWindow);
    swizzled = [swizzler swizzleClass:[UIScrollView class]
                replaceInstanceMethod:originalSel
                           withMethod:swizzledSel];
    GREYFatalAssertWithMessage(swizzled, @"Cannot swizzle [UIScrollView didMoveToWindow]");
  }
}

- (BOOL)grey_hasScrollResistance {
  if (self.bounces) {
    return ((BOOL(*)(id, SEL))objc_msgSend)(self, NSSelectorFromString(@"_isBouncing"));
  } else {
    // NOTE that these values are not reliable as scroll views without bounce have non-zero
    // velocities even when they are at the edge of the content and cannot be scrolled.
    double horizontalVelocity =
        ((double (*)(id, SEL))objc_msgSend)(self, NSSelectorFromString(@"_horizontalVelocity"));
    double verticalVelocity =
        ((double (*)(id, SEL))objc_msgSend)(self, NSSelectorFromString(@"_verticalVelocity"));
    return horizontalVelocity == 0 && verticalVelocity == 0;
  }
}

- (id<GREYScrollViewDelegate>)greyScrollViewDelegate {
  GREYSurrogateDelegate *delegate =
      objc_getAssociatedObject(self, @selector(greyScrollViewDelegate));
  return delegate.originalDelegate;
}

- (void)setGreyScrollViewDelegate:(id<GREYScrollViewDelegate>)delegate {
  GREYSurrogateDelegate *surrogateDelegate =
      [[GREYSurrogateDelegate alloc] initWithOriginalDelegate:delegate isWeak:YES];
  objc_setAssociatedObject(self, @selector(greyScrollViewDelegate), surrogateDelegate,
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Swizzled Implementation

- (void)greyswizzled_scrollViewWillBeginDragging {
  GREYAppStateTrackerObject *object =
      TRACK_STATE_FOR_OBJECT(kGREYPendingUIScrollViewScrolling, self);
  objc_setAssociatedObject(self, @selector(greyswizzled_scrollViewWillBeginDragging), object,
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  INVOKE_ORIGINAL_IMP(void, @selector(greyswizzled_scrollViewWillBeginDragging));
}

- (void)greyswizzled_scrollViewDidEndDraggingWithDeceleration:(BOOL)deceleration {
  if (!deceleration) {
    GREYAppStateTrackerObject *object =
        objc_getAssociatedObject(self, @selector(greyswizzled_scrollViewWillBeginDragging));
    UNTRACK_STATE_FOR_OBJECT(kGREYPendingUIScrollViewScrolling, object);
    objc_setAssociatedObject(self, @selector(greyswizzled_scrollViewWillBeginDragging), nil,
                             OBJC_ASSOCIATION_ASSIGN);
  }
  INVOKE_ORIGINAL_IMP1(void, @selector(greyswizzled_scrollViewDidEndDraggingWithDeceleration:),
                       deceleration);
}

- (void)greyswizzled_stopScrollDecelerationNotify:(BOOL)notify {
  [self grey_untrackProgrammaticScrollAnimation];
  GREYAppStateTrackerObject *object =
      objc_getAssociatedObject(self, @selector(greyswizzled_scrollViewWillBeginDragging));
  UNTRACK_STATE_FOR_OBJECT(kGREYPendingUIScrollViewScrolling, object);
  objc_setAssociatedObject(self, @selector(greyswizzled_scrollViewWillBeginDragging), nil,
                           OBJC_ASSOCIATION_ASSIGN);

  INVOKE_ORIGINAL_IMP1(void, @selector(greyswizzled_stopScrollDecelerationNotify:), notify);
}

- (void)greyswizzled_setContentOffset:(CGPoint)offset {
  CGPoint currentOffset = self.contentOffset;
  if (offset.x != currentOffset.x || offset.y != currentOffset.y) {
    [self.greyScrollViewDelegate scrollView:self willScrollToOffset:offset];
  }
  INVOKE_ORIGINAL_IMP1(void, @selector(greyswizzled_setContentOffset:), offset);
  if (@available(iOS 17.4, tvOS 17.4, *)) {
    if (!self.window || !self.isScrollAnimating) {
      [self grey_untrackProgrammaticScrollAnimation];
    }
  }
}

- (void)greyswizzled_setContentOffset:(CGPoint)offset animated:(BOOL)animated {
  INVOKE_ORIGINAL_IMP2(void, @selector(greyswizzled_setContentOffset:animated:), offset, animated);
  if (@available(iOS 17.4, tvOS 17.4, *)) {
    if (animated && self.window && self.isScrollAnimating) {
      GREYAppStateTrackerObject *object =
          TRACK_STATE_FOR_OBJECT(kGREYPendingUIScrollViewScrolling, self);
      objc_setAssociatedObject(self, @selector(greyswizzled_setContentOffset:animated:), object,
                               OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    } else {
      [self grey_untrackProgrammaticScrollAnimation];
    }
  }
}

- (void)greyswizzled_delegateScrollViewAnimationEnded {
  INVOKE_ORIGINAL_IMP(void, @selector(greyswizzled_delegateScrollViewAnimationEnded));
  [self grey_untrackProgrammaticScrollAnimation];
}

- (void)greyswizzled_stopScrollingNotify:(BOOL)notify pin:(BOOL)pin {
  INVOKE_ORIGINAL_IMP2(void, @selector(greyswizzled_stopScrollingNotify:pin:), notify, pin);
  [self grey_untrackProgrammaticScrollAnimation];
}

- (void)greyswizzled_didMoveToWindow {
  INVOKE_ORIGINAL_IMP(void, @selector(greyswizzled_didMoveToWindow));
  if (!self.window) {
    [self grey_untrackProgrammaticScrollAnimation];
  }
}

- (void)grey_untrackProgrammaticScrollAnimation {
  GREYAppStateTrackerObject *object =
      objc_getAssociatedObject(self, @selector(greyswizzled_setContentOffset:animated:));
  if (object) {
    UNTRACK_STATE_FOR_OBJECT(kGREYPendingUIScrollViewScrolling, object);
    objc_setAssociatedObject(self, @selector(greyswizzled_setContentOffset:animated:), nil,
                             OBJC_ASSOCIATION_ASSIGN);
  }
}

@end
