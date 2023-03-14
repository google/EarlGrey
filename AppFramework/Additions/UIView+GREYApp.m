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

#import "UIView+GREYApp.h"

#include <objc/runtime.h>

#import "GREYTimedIdlingResource.h"
#import "GREYAppStateTracker.h"
#import "UIView+GREYCommon.h"
#import "GREYFatalAsserts.h"
#import "GREYAppState.h"
#import "GREYConfigKey.h"
#import "GREYConfiguration.h"
#import "GREYAppleInternals.h"
#import "GREYDefines.h"
#import "GREYLogger.h"
#import "GREYSwizzler.h"
#import "GREYElementProvider.h"

/** Typedef for the wrapper for the animation method's completion block. */
typedef void (^GREYAnimationCompletionBlock)(BOOL);

/** Typedef for the UIView block of animations. */
typedef void (^GREYAnimationsBlock)(void);

/**
 * A BOOL denoting if the UIView animation's function pointer will be printed.
 */
BOOL gPrintFunctionPointer;

/**
 * Class for Scroll view indicators. Unused directive added as this will be utilized only in iOS 13.
 **/
__unused static Class gScrollViewIndicatorClass;

@implementation UIView (GREYApp)

+ (void)load {
  GREYSwizzler *swizzler = [[GREYSwizzler alloc] init];

  BOOL swizzleSuccess = [swizzler swizzleClass:self
                         replaceInstanceMethod:@selector(setNeedsDisplay)
                                    withMethod:@selector(greyswizzled_setNeedsDisplay)];
  GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle UIView setNeedsDisplay");

  swizzleSuccess = [swizzler swizzleClass:self
                    replaceInstanceMethod:@selector(setFrame:)
                               withMethod:@selector(greyswizzled_setFrame:)];
  GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle UIView setFrame");

  // TODO: We are making the assumption that no parent view will adjust the bounds of // NOLINT
  // its subview. If this assumption fails, we would need to swizzle setBounds as well and make
  // sure it is not changed if subview is expected to be on top and fixed at a specific position.
  swizzleSuccess = [swizzler swizzleClass:self
                    replaceInstanceMethod:@selector(setCenter:)
                               withMethod:@selector(greyswizzled_setCenter:)];
  GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle UIView setCenter");

  swizzleSuccess = [swizzler swizzleClass:self
                    replaceInstanceMethod:@selector(addSubview:)
                               withMethod:@selector(greyswizzled_addSubview:)];
  GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle UIView addSubview");

  swizzleSuccess = [swizzler swizzleClass:self
                    replaceInstanceMethod:@selector(willRemoveSubview:)
                               withMethod:@selector(greyswizzled_willRemoveSubview:)];
  GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle UIView willRemoveSubview");

  swizzleSuccess = [swizzler swizzleClass:self
                    replaceInstanceMethod:@selector(insertSubview:atIndex:)
                               withMethod:@selector(greyswizzled_insertSubview:atIndex:)];
  GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle UIView insertSubview:atIndex:");

  SEL originalSel = @selector(exchangeSubviewAtIndex:withSubviewAtIndex:);
  SEL swizzledSel = @selector(greyswizzled_exchangeSubviewAtIndex:withSubviewAtIndex:);
  swizzleSuccess =
      [swizzler swizzleClass:self replaceInstanceMethod:originalSel withMethod:swizzledSel];
  GREYFatalAssertWithMessage(swizzleSuccess,
                             @"Cannot swizzle UIView exchangeSubviewAtIndex:withSubviewAtIndex:");

  swizzleSuccess = [swizzler swizzleClass:self
                    replaceInstanceMethod:@selector(insertSubview:aboveSubview:)
                               withMethod:@selector(greyswizzled_insertSubview:aboveSubview:)];
  GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle UIView insertSubview:aboveSubview:");

  swizzleSuccess = [swizzler swizzleClass:self
                    replaceInstanceMethod:@selector(insertSubview:belowSubview:)
                               withMethod:@selector(greyswizzled_insertSubview:belowSubview:)];
  GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle UIView insertSubview:belowSubview:");

  swizzleSuccess = [swizzler swizzleClass:self
                    replaceInstanceMethod:@selector(setNeedsDisplayInRect:)
                               withMethod:@selector(greyswizzled_setNeedsDisplayInRect:)];
  GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle UIView setNeedsDisplayInRect");

  swizzleSuccess = [swizzler swizzleClass:self
                    replaceInstanceMethod:@selector(setNeedsLayout)
                               withMethod:@selector(greyswizzled_setNeedsLayout)];
  GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle UIView setNeedsLayout");

  swizzleSuccess = [swizzler swizzleClass:self
                    replaceInstanceMethod:@selector(sizeToFit)
                               withMethod:@selector(greyswizzled_sizeToFit)];
  GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle UIView sizeToFit");

  swizzleSuccess = [swizzler swizzleClass:self
                    replaceInstanceMethod:@selector(setNeedsUpdateConstraints)
                               withMethod:@selector(greyswizzled_setNeedsUpdateConstraints)];
  GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle UIView setNeedsUpdateConstraints");

  // Swizzle for tracking block based animations.
  swizzleSuccess = [swizzler swizzleClass:self
                       replaceClassMethod:@selector(animateWithDuration:animations:)
                               withMethod:@selector(greyswizzled_animateWithDuration:animations:)];
  GREYFatalAssertWithMessage(swizzleSuccess,
                             @"Cannot swizzle UIView animateWithDuration:animations:");

  originalSel = @selector(animateWithDuration:animations:completion:);
  swizzledSel = @selector(greyswizzled_animateWithDuration:animations:completion:);
  swizzleSuccess =
      [swizzler swizzleClass:self replaceClassMethod:originalSel withMethod:swizzledSel];
  GREYFatalAssertWithMessage(swizzleSuccess,
                             @"Cannot swizzle UIView animateWithDuration:animations:completion:");

  originalSel = @selector(animateWithDuration:delay:options:animations:completion:);
  swizzledSel = @selector(greyswizzled_animateWithDuration:delay:options:animations:completion:);
  swizzleSuccess =
      [swizzler swizzleClass:self replaceClassMethod:originalSel withMethod:swizzledSel];
  GREYFatalAssertWithMessage(swizzleSuccess,
                             @"Cannot swizzle "
                             @"UIView animateWithDuration:delay:options:animations:completion:");

  originalSel = @selector(animateWithDuration:
                                        delay:usingSpringWithDamping:initialSpringVelocity:options
                                             :animations:completion:);
  swizzledSel =
      @selector(greyswizzled_animateWithDuration:
                                           delay:usingSpringWithDamping:initialSpringVelocity
                                                :options:animations:completion:);
  swizzleSuccess =
      [swizzler swizzleClass:self replaceClassMethod:originalSel withMethod:swizzledSel];
  GREYFatalAssertWithMessage(swizzleSuccess,
                             @"Cannot swizzle UIView animateWithDuration:delay:"
                             @"usingSpringWithDamping:initialSpringVelocity:options:animations"
                             @":completion:");

  originalSel = @selector(transitionWithView:duration:options:animations:completion:);
  swizzledSel = @selector(greyswizzled_transitionWithView:duration:options:animations:completion:);
  swizzleSuccess =
      [swizzler swizzleClass:self replaceClassMethod:originalSel withMethod:swizzledSel];
  GREYFatalAssertWithMessage(swizzleSuccess,
                             @"Cannot swizzle UIView "
                             @"transitionWithView:duration:options:animations:completion:");

  originalSel = @selector(transitionFromView:toView:duration:options:completion:);
  swizzledSel = @selector(greyswizzled_transitionFromView:toView:duration:options:completion:);
  swizzleSuccess =
      [swizzler swizzleClass:self replaceClassMethod:originalSel withMethod:swizzledSel];
  GREYFatalAssertWithMessage(swizzleSuccess,
                             @"Cannot swizzle "
                             @"UIView transitionFromView:toView:duration:options:completion:");

  originalSel = @selector(animateKeyframesWithDuration:delay:options:animations:completion:);
  swizzledSel =
      @selector(greyswizzled_animateKeyframesWithDuration:delay:options:animations:completion:);
  swizzleSuccess =
      [swizzler swizzleClass:self replaceClassMethod:originalSel withMethod:swizzledSel];
  GREYFatalAssertWithMessage(swizzleSuccess,
                             @"Cannot swizzle UIView animateKeyframesWithDuration:delay:options:"
                             @"animations:completion:");

  originalSel = @selector(performSystemAnimation:onViews:options:animations:completion:);
  swizzledSel =
      @selector(greyswizzled_performSystemAnimation:onViews:options:animations:completion:);
  swizzleSuccess =
      [swizzler swizzleClass:self replaceClassMethod:originalSel withMethod:swizzledSel];
  GREYFatalAssertWithMessage(swizzleSuccess,
                             @"Cannot swizzle UIView performSystemAnimation:onViews:"
                             @"options:animations:completion:");

  if (iOS13()) {
    gScrollViewIndicatorClass = NSClassFromString(@"_UIScrollViewScrollIndicator");
    originalSel = @selector(setAlpha:);
    swizzledSel = @selector(greyswizzled_setAlpha:);
    swizzleSuccess = [swizzler swizzleClass:self
                      replaceInstanceMethod:originalSel
                                 withMethod:swizzledSel];
    GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle UIView setAlpha:");
  }

  originalSel = NSSelectorFromString(@"_adjustScrollerIndicators:alwaysShowingThem:");
  swizzledSel = @selector(greyswizzled_adjustScrollerIndicators:alwaysShowingThem:);
  swizzleSuccess = [swizzler swizzleClass:[UIScrollView class]
                    replaceInstanceMethod:originalSel
                               withMethod:swizzledSel];
  GREYFatalAssertWithMessage(
      swizzleSuccess, @"Cannot swizzle UIScrollView _adjustScrollerIndicators:alwaysShowingThem:");

  if (GREYVerboseLoggingEnabled()) {
    gPrintFunctionPointer = YES;
  }
}

- (NSArray<UIView *> *)grey_childrenAssignableFromClass:(Class)klass {
  NSMutableArray<UIView *> *subviews = [[NSMutableArray alloc] init];
  for (UIView *child in self.subviews) {
    GREYElementProvider *childHierarchy = [GREYElementProvider providerWithRootElements:@[ child ]];
    [subviews addObjectsFromArray:[[childHierarchy dataEnumerator] allObjects]];
  }

  NSPredicate *filterPredicate = [NSPredicate
      predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary<NSString *, id> *bindings) {
        return [evaluatedObject isKindOfClass:klass];
      }];
  return [subviews filteredArrayUsingPredicate:filterPredicate];
}

#pragma mark - Swizzled Implementation

- (void)greyswizzled_adjustScrollerIndicators:(BOOL)scrollViewIndicators
                            alwaysShowingThem:(BOOL)alwaysShowingThem {
  // In UIScrollView, this method is called when the view is scrolled. This method will show the
  // scroll view indicator, and move its position during the scrolling. When scroll interaction is
  // completed, it schedules a NSTimer to hide the scroll view indicator.
  //
  // EarlGrey provides a config to stop this behavior. When it's turned on, scroll view indicator
  // will not show, and the NSTimer to hide it won't be scheduled. So it accelerates the test since
  // EarlGrey doesn't need to synchronize the NSTimer.
  if (!GREY_CONFIG_BOOL(kGREYConfigKeyAutoHideScrollViewIndicators)) {
    INVOKE_ORIGINAL_IMP2(void, @selector(greyswizzled_adjustScrollerIndicators:alwaysShowingThem:),
                         scrollViewIndicators, alwaysShowingThem);
  }
}

- (void)greyswizzled_setAlpha:(CGFloat)alpha {
  INVOKE_ORIGINAL_IMP1(void, @selector(greyswizzled_setAlpha:), alpha);
  // An additional check is added at the end of a setAlpha: call done for a scroll indicator being
  // hidden. In iOS 13.x, the behavior was updated to have a a block animation called after a timing
  // delay.
  // When a touch is added near the bottom end of a scroll view right after an indicator disappears,
  // The touch action seems to be absorbed by the indicators / bringing them up again. The calls
  // seen when the indicator is to disappear is:
  // 1. On finishing a scroll, stopScrollDecelerationNotify being called,
  //    _adjustScrollerIndicatorsIfNeeded is called which further calls
  //    adjustScrollIndicators:alwaysShowingThem:.
  // 2. _layout(Horizontal | Vertical)ScrollIndicatorWithBounds: is called which has different
  //    implementation for horizontal / vertical indicators.
  // 3. Either indicator has a timer property obtained from the scroll view.
  //    _hideScrollIndicator:afterDelay:animated: is called as the selector added to these timers
  //    and calls blocks created in the method on them.
  // 4. _block_invoke calls _block_invoke_2. Also called is _block_invoke_3 which calls
  //    setExpandedForDirectManipulation: on the indicator which calls _layoutFillViewAnimated: with
  //    YES. Here a separate block is called directly which does not seem to be tracked as it is
  //    updating the indicator's information within it.
  // 5. After the _block_invoke_2 and _block_invoke_3 calls, control returns to _block_invoke which
  //    calls an animation with a completion block which calls setAlpha:. Control then returns to
  //    _hideScrollIndicator:afterDelay:animated: which is still being called in a timer. Beyond
  //    this call, there are still adjustments being done in the _layout methods in (2),
  //    particularly in the horizontal indicator's case. Hence, a small delay is added to account
  //    for it.
  if (alpha == 0 && [self isKindOfClass:gScrollViewIndicatorClass]) {
    [GREYTimedIdlingResource resourceForObject:self
                         thatIsBusyForDuration:0.7
                                          name:@"ScrollIndicators Timer"];
  }
}

- (void)greyswizzled_setCenter:(CGPoint)center {
  NSValue *fixedFrame =
      objc_getAssociatedObject(self, @selector(grey_keepSubviewOnTopAndFrameFixed:));
  if (fixedFrame) {
    center =
        CGPointMake(CGRectGetMidX(fixedFrame.CGRectValue), CGRectGetMidY(fixedFrame.CGRectValue));
  }
  INVOKE_ORIGINAL_IMP1(void, @selector(greyswizzled_setCenter:), center);
}

- (void)greyswizzled_setFrame:(CGRect)frame {
  NSValue *fixedFrame =
      objc_getAssociatedObject(self, @selector(grey_keepSubviewOnTopAndFrameFixed:));
  if (fixedFrame) {
    frame = fixedFrame.CGRectValue;
  }
  INVOKE_ORIGINAL_IMP1(void, @selector(greyswizzled_setFrame:), frame);
}

- (void)greyswizzled_addSubview:(UIView *)view {
  INVOKE_ORIGINAL_IMP1(void, @selector(greyswizzled_addSubview:), view);
  [self grey_bringAlwaysTopSubviewToFront];
}

- (void)greyswizzled_willRemoveSubview:(UIView *)view {
  UIView *alwaysTopSubview =
      objc_getAssociatedObject(self, @selector(grey_bringAlwaysTopSubviewToFront));
  if ([view isEqual:alwaysTopSubview]) {
    objc_setAssociatedObject(self, @selector(grey_bringAlwaysTopSubviewToFront), nil,
                             OBJC_ASSOCIATION_ASSIGN);
    objc_setAssociatedObject(view, @selector(grey_keepSubviewOnTopAndFrameFixed:), nil,
                             OBJC_ASSOCIATION_ASSIGN);
  }
  INVOKE_ORIGINAL_IMP1(void, @selector(greyswizzled_willRemoveSubview:), view);
}

- (void)greyswizzled_insertSubview:(UIView *)view aboveSubview:(UIView *)siblingSubview {
  INVOKE_ORIGINAL_IMP2(void, @selector(greyswizzled_insertSubview:aboveSubview:), view,
                       siblingSubview);
  [self grey_bringAlwaysTopSubviewToFront];
}

- (void)greyswizzled_insertSubview:(UIView *)view belowSubview:(UIView *)siblingSubview {
  INVOKE_ORIGINAL_IMP2(void, @selector(greyswizzled_insertSubview:belowSubview:), view,
                       siblingSubview);
  [self grey_bringAlwaysTopSubviewToFront];
}

- (void)greyswizzled_insertSubview:(UIView *)view atIndex:(NSInteger)index {
  INVOKE_ORIGINAL_IMP2(void, @selector(greyswizzled_insertSubview:atIndex:), view, index);
  [self grey_bringAlwaysTopSubviewToFront];
}

- (void)greyswizzled_exchangeSubviewAtIndex:(NSInteger)index1 withSubviewAtIndex:(NSInteger)index2 {
  INVOKE_ORIGINAL_IMP2(void, @selector(greyswizzled_exchangeSubviewAtIndex:withSubviewAtIndex:),
                       index1, index2);
  [self grey_bringAlwaysTopSubviewToFront];
}

- (void)greyswizzled_setNeedsDisplayInRect:(CGRect)rect {
  GREYAppStateTrackerObject *object = TRACK_STATE_FOR_OBJECT(kGREYPendingDrawLayoutPass, self);
  // Next runloop drain will perform the draw pass.
  dispatch_async(dispatch_get_main_queue(), ^{
    UNTRACK_STATE_FOR_OBJECT(kGREYPendingDrawLayoutPass, object);
  });
  INVOKE_ORIGINAL_IMP1(void, @selector(greyswizzled_setNeedsDisplayInRect:), rect);
}

- (void)greyswizzled_sizeToFit {
  GREYAppStateTrackerObject *object = TRACK_STATE_FOR_OBJECT(kGREYPendingDrawLayoutPass, self);
  // Next runloop drain will perform the draw pass.
  dispatch_async(dispatch_get_main_queue(), ^{
    UNTRACK_STATE_FOR_OBJECT(kGREYPendingDrawLayoutPass, object);
  });
  INVOKE_ORIGINAL_IMP(void, @selector(greyswizzled_sizeToFit));
}

- (void)greyswizzled_setNeedsDisplay {
  GREYAppStateTrackerObject *object = TRACK_STATE_FOR_OBJECT(kGREYPendingDrawLayoutPass, self);
  // Next runloop drain will perform the draw pass.
  dispatch_async(dispatch_get_main_queue(), ^{
    UNTRACK_STATE_FOR_OBJECT(kGREYPendingDrawLayoutPass, object);
  });
  INVOKE_ORIGINAL_IMP(void, @selector(greyswizzled_setNeedsDisplay));
}

- (void)greyswizzled_setNeedsLayout {
  GREYAppStateTrackerObject *object = TRACK_STATE_FOR_OBJECT(kGREYPendingDrawLayoutPass, self);
  // Next runloop drain will perform the draw pass.
  dispatch_async(dispatch_get_main_queue(), ^{
    UNTRACK_STATE_FOR_OBJECT(kGREYPendingDrawLayoutPass, object);
  });
  INVOKE_ORIGINAL_IMP(void, @selector(greyswizzled_setNeedsLayout));
}

- (void)greyswizzled_setNeedsUpdateConstraints {
  GREYAppStateTrackerObject *object = TRACK_STATE_FOR_OBJECT(kGREYPendingDrawLayoutPass, self);
  // Next runloop drain will perform the draw pass.
  dispatch_async(dispatch_get_main_queue(), ^{
    UNTRACK_STATE_FOR_OBJECT(kGREYPendingDrawLayoutPass, object);
  });
  INVOKE_ORIGINAL_IMP(void, @selector(greyswizzled_setNeedsUpdateConstraints));
}

#pragma mark - Swizzled Block based Animation

+ (void)greyswizzled_animateWithDuration:(NSTimeInterval)duration
                              animations:(void (^)(void))animations {
  INVOKE_ORIGINAL_IMP2(void, @selector(greyswizzled_animateWithDuration:animations:), duration,
                       animations);
  [GREYTimedIdlingResource resourceForObject:FuncPtrFromAnimationsBlock(animations)
                       thatIsBusyForDuration:duration
                                        name:NSStringFromSelector(_cmd)];
}

+ (void)greyswizzled_animateWithDuration:(NSTimeInterval)duration
                              animations:(void (^)(void))animations
                              completion:(void (^)(BOOL))completion {
  GREYAnimationCompletionBlock wrappedCompletion = nil;
  GREYAppStateTrackerObject *object = nil;
  if (completion) {
    object = TRACK_STATE_FOR_OBJECT(kGREYPendingUIAnimation, self);
    wrappedCompletion = ^(BOOL finished) {
      completion(finished);
      UNTRACK_STATE_FOR_OBJECT(kGREYPendingUIAnimation, object);
    };
  }
  INVOKE_ORIGINAL_IMP3(void, @selector(greyswizzled_animateWithDuration:animations:completion:),
                       duration, animations, wrappedCompletion);
  [GREYTimedIdlingResource resourceForObject:FuncPtrFromAnimationsBlock(animations)
                       thatIsBusyForDuration:duration
                                        name:NSStringFromSelector(_cmd)];
}

+ (void)greyswizzled_animateWithDuration:(NSTimeInterval)duration
                                   delay:(NSTimeInterval)delay
                                 options:(UIViewAnimationOptions)options
                              animations:(void (^)(void))animations
                              completion:(void (^)(BOOL))completion {
  GREYAnimationCompletionBlock wrappedCompletion = nil;
  GREYAppStateTrackerObject *object = nil;
  if (completion) {
    object = TRACK_STATE_FOR_OBJECT(kGREYPendingUIAnimation, self);
    wrappedCompletion = ^(BOOL finished) {
      completion(finished);
      UNTRACK_STATE_FOR_OBJECT(kGREYPendingUIAnimation, object);
    };
  }

  SEL swizzledSEL =
      @selector(greyswizzled_animateWithDuration:delay:options:animations:completion:);
  INVOKE_ORIGINAL_IMP5(void, swizzledSEL, duration, delay, options, animations, wrappedCompletion);
  // The call stack check is done as a workaround for certain MediaPlayer animations that are not
  // truncated by EarlGrey's CALayer truncation code and make the idling resource busy infinitely.
  if ((options & UIViewAnimationOptionAllowUserInteraction) == 0) {
    if (duration == INFINITY &&
        [[NSThread callStackSymbols].description containsString:@"MediaPlayer"]) {
      GREYLogVerbose(@"Not tracking MediaPlayer infinite animation for view class: \n%@", self);
    } else {
      [GREYTimedIdlingResource resourceForObject:FuncPtrFromAnimationsBlock(animations)
                           thatIsBusyForDuration:(delay + duration)
                                            name:NSStringFromSelector(_cmd)];
    }
  }
}

+ (void)greyswizzled_animateWithDuration:(NSTimeInterval)duration
                                   delay:(NSTimeInterval)delay
                  usingSpringWithDamping:(CGFloat)dampingRatio
                   initialSpringVelocity:(CGFloat)velocity
                                 options:(UIViewAnimationOptions)options
                              animations:(void (^)(void))animations
                              completion:(void (^)(BOOL))completion {
  GREYAnimationCompletionBlock wrappedCompletion = nil;
  GREYAppStateTrackerObject *object = nil;
  if (completion) {
    object = TRACK_STATE_FOR_OBJECT(kGREYPendingUIAnimation, self);
    wrappedCompletion = ^(BOOL finished) {
      completion(finished);
      UNTRACK_STATE_FOR_OBJECT(kGREYPendingUIAnimation, object);
    };
  }

  SEL swizzledSEL =
      @selector(greyswizzled_animateWithDuration:
                                           delay:usingSpringWithDamping:initialSpringVelocity
                                                :options:animations:completion:);
  INVOKE_ORIGINAL_IMP7(void, swizzledSEL, duration, delay, dampingRatio, velocity, options,
                       animations, wrappedCompletion);
  if ((options & UIViewAnimationOptionAllowUserInteraction) == 0) {
    [GREYTimedIdlingResource resourceForObject:FuncPtrFromAnimationsBlock(animations)
                         thatIsBusyForDuration:(delay + duration)
                                          name:NSStringFromSelector(_cmd)];
  }
}

+ (void)greyswizzled_animateKeyframesWithDuration:(NSTimeInterval)duration
                                            delay:(NSTimeInterval)delay
                                          options:(UIViewKeyframeAnimationOptions)options
                                       animations:(void (^)(void))animations
                                       completion:(void (^)(BOOL))completion {
  GREYAnimationCompletionBlock wrappedCompletion = nil;
  GREYAppStateTrackerObject *object = nil;
  if (completion) {
    object = TRACK_STATE_FOR_OBJECT(kGREYPendingUIAnimation, self);
    wrappedCompletion = ^(BOOL finished) {
      completion(finished);
      UNTRACK_STATE_FOR_OBJECT(kGREYPendingUIAnimation, object);
    };
  }

  SEL swizzledSEL =
      @selector(greyswizzled_animateKeyframesWithDuration:delay:options:animations:completion:);
  INVOKE_ORIGINAL_IMP5(void, swizzledSEL, duration, delay, options, animations, wrappedCompletion);

  if ((options & UIViewKeyframeAnimationOptionAllowUserInteraction) == 0) {
    [GREYTimedIdlingResource resourceForObject:FuncPtrFromAnimationsBlock(animations)
                         thatIsBusyForDuration:(delay + duration)
                                          name:NSStringFromSelector(_cmd)];
  }
}

+ (void)greyswizzled_transitionFromView:(UIView *)fromView
                                 toView:(UIView *)toView
                               duration:(NSTimeInterval)duration
                                options:(UIViewAnimationOptions)options
                             completion:(void (^)(BOOL))completion {
  GREYAnimationCompletionBlock wrappedCompletion = nil;
  GREYAppStateTrackerObject *object = nil;
  if (completion) {
    object = TRACK_STATE_FOR_OBJECT(kGREYPendingUIAnimation, self);
    wrappedCompletion = ^(BOOL finished) {
      completion(finished);
      UNTRACK_STATE_FOR_OBJECT(kGREYPendingUIAnimation, object);
    };
  }

  SEL swizzledSEL = @selector(greyswizzled_transitionFromView:toView:duration:options:completion:);
  INVOKE_ORIGINAL_IMP5(void, swizzledSEL, fromView, toView, duration, options, wrappedCompletion);

  if ((options & UIViewAnimationOptionAllowUserInteraction) == 0) {
    NSObject *trackingObject = [[NSObject alloc] init];
    [GREYTimedIdlingResource resourceForObject:trackingObject
                         thatIsBusyForDuration:duration
                                          name:NSStringFromSelector(_cmd)];
  }
}

+ (void)greyswizzled_transitionWithView:(UIView *)view
                               duration:(NSTimeInterval)duration
                                options:(UIViewAnimationOptions)options
                             animations:(void (^)(void))animations
                             completion:(void (^)(BOOL))completion {
  GREYAnimationCompletionBlock wrappedCompletion = nil;
  GREYAppStateTrackerObject *object = nil;
  if (completion) {
    object = TRACK_STATE_FOR_OBJECT(kGREYPendingUIAnimation, self);
    wrappedCompletion = ^(BOOL finished) {
      completion(finished);
      UNTRACK_STATE_FOR_OBJECT(kGREYPendingUIAnimation, object);
    };
  }
  SEL swizzledSEL =
      @selector(greyswizzled_transitionWithView:duration:options:animations:completion:);
  INVOKE_ORIGINAL_IMP5(void, swizzledSEL, view, duration, options, animations, wrappedCompletion);

  if ((options & UIViewAnimationOptionAllowUserInteraction) == 0) {
    [GREYTimedIdlingResource resourceForObject:FuncPtrFromAnimationsBlock(animations)
                         thatIsBusyForDuration:duration
                                          name:NSStringFromSelector(_cmd)];
  }
}

+ (void)greyswizzled_performSystemAnimation:(UISystemAnimation)animation
                                    onViews:(NSArray<UIView *> *)views
                                    options:(UIViewAnimationOptions)options
                                 animations:(void (^)(void))parallelAnimations
                                 completion:(void (^)(BOOL))completion {
  GREYTimedIdlingResource *resource;
  if ((options & UIViewAnimationOptionAllowUserInteraction) == 0) {
    // TODO: Refactor this to use the completion block with a timeout in case it isn't invoked.
    resource =
        [GREYTimedIdlingResource resourceForObject:FuncPtrFromAnimationsBlock(parallelAnimations)
                             thatIsBusyForDuration:2.0  // assume animation finishes in 2 sec.
                                              name:NSStringFromSelector(_cmd)];
  }
  SEL swizzledSEL =
      @selector(greyswizzled_performSystemAnimation:onViews:options:animations:completion:);
  GREYAnimationCompletionBlock wrappedCompletion = ^(BOOL finished) {
    if (completion) {
      completion(finished);
    }
    [resource stopMonitoring];
  };
  INVOKE_ORIGINAL_IMP5(void, swizzledSEL, animation, views, options, parallelAnimations,
                       wrappedCompletion);
}

/**
 * A testing-only method to toggle the printing of the animation block pointer.
 *
 * @param printPointer @c YES if the pointer is to be printed in the logs. @c NO otherwise.
 */
+ (void)printAnimationsBlockPointer:(BOOL)printPointer {
  gPrintFunctionPointer = printPointer;
}

/**
 * @return Either an NSString with the __FuncPtr value for a block (if iOS 13 or above) or an empty
 *         NSObject if lower.
 *
 * @note Detailed information on the block's pointer is only available post iOS 13. Pre-iOS 13, the
 *.      debugDescription will only print the block's class and pointer.
 * @param animationsBlock A (void(^)(void)) block with the animation block related to a UIView class
 *                        animation.
 */
static id FuncPtrFromAnimationsBlock(GREYAnimationsBlock animationsBlock) {
  if (gPrintFunctionPointer && iOS13_OR_ABOVE()) {
    BlockHeader *blockHeader = (__bridge BlockHeader *)animationsBlock;
    NSString *description = [(__bridge NSObject *)blockHeader debugDescription];
    description = [description substringFromIndex:[description rangeOfString:@"("].location + 1];
    NSString *blockPtr = [description substringToIndex:[description rangeOfString:@")"].location];
    return [blockPtr lastPathComponent];
  } else {
    return [[NSObject alloc] init];
  }
}

@end

/**
 * Swizzles MDCActivityIndicators to ensure they untrack automatically instead of spinning forever.
 */
@interface MDCActivityIndicator_GREYApp : NSObject
@end

@implementation MDCActivityIndicator_GREYApp

+ (void)load {
  Class class = NSClassFromString(@"MDCActivityIndicator");
  if (class) {
    GREYSwizzler *swizzler = [[GREYSwizzler alloc] init];
    IMP newStartAnimatingImplementation =
        [self instanceMethodForSelector:@selector(greyswizzled_startAnimating)];
    BOOL swizzleSuccess = [swizzler swizzleClass:class
                               addInstanceMethod:@selector(greyswizzled_startAnimating)
                              withImplementation:newStartAnimatingImplementation
                    andReplaceWithInstanceMethod:NSSelectorFromString(@"startAnimating")];
    GREYFatalAssertWithMessage(swizzleSuccess, @"Could not swizzle resume in %@", class);
  }
}

- (void)greyswizzled_startAnimating {
  if (GREY_CONFIG_BOOL(kGREYConfigKeyAutoUntrackMDCActivityIndicators)) {
    [self performSelector:NSSelectorFromString(@"stopAnimating")
               withObject:nil
               afterDelay:GREY_CONFIG_DOUBLE(kGREYConfigKeyCALayerMaxAnimationDuration)];
  }
  INVOKE_ORIGINAL_IMP(void, @selector(greyswizzled_startAnimating));
}

@end
