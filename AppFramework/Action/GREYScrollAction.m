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

#import "GREYScrollAction.h"

#if TARGET_OS_IOS
#import <WebKit/WebKit.h>
#endif  // TARGET_OS_IOS

#import "GREYPathGestureUtils.h"
#import "UIScrollView+GREYApp.h"
#import "GREYSurrogateDelegate.h"
#import "GREYAppError.h"
#import "GREYFailureScreenshotter.h"
#import "GREYSyntheticEvents.h"
#import "GREYAllOf.h"
#import "GREYAnyOf.h"
#import "GREYMatchers.h"
#import "GREYAppStateTracker.h"
#import "GREYSyncAPI.h"
#import "GREYUIThreadExecutor+GREYApp.h"
#import "GREYUIThreadExecutor.h"
#import "GREYFatalAsserts.h"
#import "GREYThrowDefines.h"
#import "GREYAppState.h"
#import "GREYConfigKey.h"
#import "GREYConfiguration.h"
#import "GREYError.h"
#import "GREYErrorConstants.h"
#import "GREYConstants.h"
#import "GREYDiagnosable.h"
#import "GREYLogger.h"
#import "CGGeometry+GREYUI.h"
#import "GREYElementHierarchy.h"

/**
 * Scroll views under web views take at least (depending on speed of execution environment) two
 * touch points to accurately determine scroll resistance. For apps that has busy recurring
 * executions, it can take up to three touch points to start the initial scroll.
 */
static const NSInteger kMinTouchPointsToDetectScrollResistance = 3;

/**
 * Returns whether the scroll detection is performed by the old way - scroll offset.
 *
 * TODO(b/222748919): The fallback should be removed once the bug is fixed.
 */
static BOOL IsScrollDetectionFallback(UIScrollView *scrollView) {
  // If the scroll view does not enable scroll, EarlGrey is not able to detect the scroll amount
  // triggered by the touch injection. Thus EarlGrey will use fallback strategy to ignore the
  // scroll amount, and the touch injection won't produce precise scroll result.
  BOOL fallback = !scrollView.scrollEnabled;
  return fallback;
}

/**
 * Returns whether the scroll action should retry touch injection when it's failed.
 */
static BOOL IsEligibleForRetry(UIScrollView *scrollView, GREYDirection scrollDirection,
                               BOOL success, NSInteger errorCode) {
  if (success ||                                  // scroll already succeeded
      errorCode != kGREYScrollNoTouchReaction ||  // only kGREYScrollNoTouchReaction can retry
      IsScrollDetectionFallback(scrollView) ||  // the scroll view with fallback may already scroll
                                                // without being detected by EarlGrey
      (scrollView.contentOffset.y <= 0 &&
       scrollDirection == kGREYDirectionUp) ||  // The scroll view is already at the edge, so no
                                                // retry is needed towards the edge.
      !scrollView.window) {  // The scroll may fail with other gesture being recognized, if it
                             // causes scroll view being detached from screen, no retry is needed.
    return NO;
  }

  return YES;
}

/**
 * UIScrollView delegate that detects the initial scroll event.
 *
 * This delegate will explicitly remove itself from the delegate chain after the initial scroll
 * event.
 */
@interface GREYScrollDetectionDelegate : GREYSurrogateDelegate <GREYScrollViewDelegate>

/** Indicates if the scroll view has detected the scroll event. */
@property(nonatomic, readonly) BOOL scrollDetected;

/** Indicates the scroll amount of the initial scroll event since this delegate is attached. */
@property(nonatomic, readonly) CGVector scrollAmount;

/**
 * Initializer for the scroll view delegate.
 *
 * @param scrollView The UIScrollView to be attached by this delegate.
 * @return The instance of the delegate.
 */
- (instancetype)initWithScrolView:(UIScrollView *)scrollView;

@end

@implementation GREYScrollDetectionDelegate {
  UIScrollView *_scrollView;
}

- (instancetype)initWithScrolView:(UIScrollView *)scrollView {
  self = [super initWithOriginalDelegate:scrollView.greyScrollViewDelegate isWeak:YES];
  if (self) {
    _scrollView = scrollView;
  }
  return self;
}

- (void)dealloc {
  [self reset];
}

- (void)reset {
  id<GREYScrollViewDelegate> currentDelegate = _scrollView.greyScrollViewDelegate;
  // If this surrogate delegate is never called, the delegate is eventually dealloced when the touch
  // injection ends without calling reset. In this case, @c _scrollView's delegate property will be
  // @c nil instead of @c self.
  if (!currentDelegate || currentDelegate == self) {
    _scrollView.greyScrollViewDelegate = self.originalDelegate;
  }
  _scrollView = nil;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollView:(UIScrollView *)scrollView willScrollToOffset:(CGPoint)offset {
  if (!_scrollDetected) {
    _scrollDetected = YES;
    CGPoint previousOffset = _scrollView.contentOffset;
    _scrollAmount = CGVectorFromEndPoints(previousOffset, offset, NO);
  }
  id<UIScrollViewDelegate> originalDelegate = self.originalDelegate;
  if (originalDelegate && [originalDelegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
    [originalDelegate scrollViewDidScroll:scrollView];
  }
  [self reset];
}

@end

@implementation GREYScrollAction {
  /**
   * The direction in which the content must be scrolled.
   */
  GREYDirection _direction;
  /**
   * The amount of scroll (in the units of scrollView's coordinate system) to be applied.
   */
  CGFloat _amount;
  /**
   * The start point of the scroll defined as percentages of the visible area's width and height.
   * If any of the coordinate is set to @c NAN the corresponding coordinate of the scroll start
   * point will be set to achieve maximum scroll.
   */
  CGPoint _startPointPercents;
}

- (instancetype)initWithDirection:(GREYDirection)direction
                           amount:(CGFloat)amount
               startPointPercents:(CGPoint)startPointPercents {
  GREYThrowOnFailedConditionWithMessage(amount > 0,
                                        @"Scroll amount must be positive and greater than zero.");
  GREYThrowOnFailedConditionWithMessage(
      isnan(startPointPercents.x) || (startPointPercents.x > 0 && startPointPercents.x < 1),
      @"startPointPercents must be NAN or in the range (0, 1) "
      @"exclusive");
  GREYThrowOnFailedConditionWithMessage(
      isnan(startPointPercents.y) || (startPointPercents.y > 0 && startPointPercents.y < 1),
      @"startPointPercents must be NAN or in the range (0, 1) "
      @"exclusive");

  NSString *name =
      [NSString stringWithFormat:@"Scroll %@ for %g", NSStringFromGREYDirection(direction), amount];

  NSArray *classMatchers = @[
    [GREYMatchers matcherForKindOfClass:[UIScrollView class]],
#if TARGET_OS_IOS
    [GREYMatchers matcherForKindOfClass:[WKWebView class]],
#endif  // TARGET_OS_IOS
  ];
  id<GREYMatcher> systemAlertShownMatcher = [GREYMatchers matcherForSystemAlertViewShown];
  NSArray *constraintMatchers = @[
    [[GREYAnyOf alloc] initWithMatchers:classMatchers],
    [GREYMatchers matcherForNegation:systemAlertShownMatcher]
  ];
  self = [super initWithName:name
                 constraints:[[GREYAllOf alloc] initWithMatchers:constraintMatchers]];
  if (self) {
    _direction = direction;
    _amount = amount;
    _startPointPercents = startPointPercents;
  }
  return self;
}

- (instancetype)initWithDirection:(GREYDirection)direction amount:(CGFloat)amount {
  return [self initWithDirection:direction amount:amount startPointPercents:GREYCGPointNull];
}

#pragma mark - GREYAction

- (BOOL)perform:(id)element error:(__strong NSError **)error {
  __block BOOL retVal = NO;
  grey_dispatch_sync_on_main_thread(^{
    // We aggressively access UI elements when performing the action, rather than having pieces
    // running on the main thread separately, the whole action will be performed on the main thread.
    retVal = [self grey_perform:element error:error];
  });
  return retVal;
}

#pragma mark - Private

- (BOOL)grey_perform:(UIScrollView *)element error:(__strong NSError **)error {
  if (![self satisfiesConstraintsForElement:element error:error]) {
    return NO;
  }

  // To scroll WebViews we must use the UIScrollView in its hierarchy and scroll it.
#if TARGET_OS_IOS
  if ([element isKindOfClass:[WKWebView class]]) {
    element = [(WKWebView *)element scrollView];
  }
#endif  // TARGET_OS_IOS

  CGFloat amountRemaining = _amount;
  BOOL success = YES;
  NSError *scrollError;
  while (amountRemaining > 0 && success) {
    @autoreleasepool {
      // To scroll the content view in a direction
      GREYDirection reverseDirection = [GREYConstants reverseOfDirection:_direction];
      NSArray<NSValue *> *touchPath = GREYTouchPathForGestureInView(
          element, _startPointPercents, reverseDirection, amountRemaining, &amountRemaining);
      if (!touchPath) {
        I_GREYPopulateError(error, kGREYScrollErrorDomain, kGREYScrollImpossible,
                            @"Cannot scroll, ensure that the selected scroll view "
                            @"is wide enough to scroll.");
        return NO;
      }
      success = [GREYScrollAction grey_injectTouchPath:touchPath
                                          onScrollView:element
                                    outRemainingAmount:&amountRemaining
                                                 error:&scrollError];
      for (int retry = 1;
           retry <= 3 && IsEligibleForRetry(element, _direction, success, scrollError.code);
           ++retry) {
        GREYLog(@"The %d attempt to retry scroll action for no touch reaction", retry);
        success = [GREYScrollAction grey_injectTouchPath:touchPath
                                            onScrollView:element
                                      outRemainingAmount:&amountRemaining
                                                   error:&scrollError];
      }
    }
  }
  if (!success) {
    I_GREYPopulateError(error, scrollError.domain, scrollError.code,
                        scrollError.userInfo[kErrorFailureReasonKey]);
  }
  return success;
}

/**
 * Injects the touch path into the given @c scrollView until the content edge could be reached.
 *
 * @param touchPath            The touch path to be injected.
 * @param scrollView           The UIScrollView for the injection.
 * @param[out] amountRemaining The remaining scroll amount to be delivered to the next rounds of
 *                             scroll actions.
 *
 * @return @c YES if entire touchPath was injected, else @c NO.
 */
+ (BOOL)grey_injectTouchPath:(NSArray<NSValue *> *)touchPath
                onScrollView:(UIScrollView *)scrollView
          outRemainingAmount:(CGFloat *)amountRemaining
                       error:(__strong NSError **)error {
  GREYFatalAssert([touchPath count] >= 1);

  // In scrollviews that have their bounce turned off the horizontal and vertical velocities are
  // not reliable for detecting scroll resistance because they report non-zero velocities even
  // when content edge has been reached. So we are using contentOffsets as a workaround. But note
  // that this can be broken by AUT since it can modify the offsets during the scroll and if it
  // resets the offset to the same point for kMinTouchPointsToDetectScrollResistance times, this
  // algorithm interprets it as scroll resistance and stops scrolling.
  BOOL shouldDetectResistanceFromContentOffset = !scrollView.bounces;
  CGPoint originalOffset = scrollView.contentOffset;
  GREYScrollDetectionDelegate *delegate =
      [[GREYScrollDetectionDelegate alloc] initWithScrolView:scrollView];
  BOOL fallback = IsScrollDetectionFallback(scrollView);
  scrollView.greyScrollViewDelegate = delegate;

  CFTimeInterval interactionTimeout = GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration);
  GREYSyntheticEvents *eventGenerator = [[GREYSyntheticEvents alloc] init];
  [eventGenerator beginTouchAtPoint:touchPath[0].CGPointValue
                   relativeToWindow:scrollView.window
                  immediateDelivery:YES
                            timeout:interactionTimeout];

  __block BOOL hasResistance = NO;
  __block NSUInteger consecutiveTouchPointsWithSameContentOffset = 0;
  __block NSUInteger numberOfTouchPoints = 1;
  __block CGPoint prevOffset = scrollView.contentOffset;
  void (^detectResistance)(void) = ^{
    numberOfTouchPoints++;
    BOOL detectedResistanceFromContentOffsets = NO;
    // Keep track of |consecutiveTouchPointsWithSameContentOffset| if we must detect resistance
    // from content offset.
    if (shouldDetectResistanceFromContentOffset) {
      if (CGPointEqualToPoint(prevOffset, scrollView.contentOffset)) {
        consecutiveTouchPointsWithSameContentOffset++;
      } else {
        consecutiveTouchPointsWithSameContentOffset = 0;
        prevOffset = scrollView.contentOffset;
      }
    }
    if (numberOfTouchPoints > kMinTouchPointsToDetectScrollResistance) {
      if (shouldDetectResistanceFromContentOffset &&
          consecutiveTouchPointsWithSameContentOffset > kMinTouchPointsToDetectScrollResistance) {
        detectedResistanceFromContentOffsets = YES;
      }
      if ([scrollView grey_hasScrollResistance] || detectedResistanceFromContentOffsets) {
        // Looks like we have reached the edge we can stop scrolling now.
        hasResistance = YES;
      }
    }
  };

  BOOL hasOffsetChanged = NO;
  NSArray<NSValue *> *adjustedTouchPath = nil;
  for (NSUInteger touchPointIndex = 1; touchPointIndex < [touchPath count] && !hasResistance;
       touchPointIndex++) {
    @autoreleasepool {
      CGPoint currentTouchPoint = touchPath[touchPointIndex].CGPointValue;
      [eventGenerator continueTouchAtPoint:currentTouchPoint
                         immediateDelivery:YES
                                   timeout:interactionTimeout];

      if (!hasOffsetChanged && delegate.scrollDetected) {
        hasOffsetChanged = YES;
        NSArray<NSValue *> *remainingTouchPath = [touchPath
            subarrayWithRange:NSMakeRange(touchPointIndex, touchPath.count - touchPointIndex)];
        CGVector scrollDeviation = GREYDeviationBetweenTouchPathAndActualOffset(
            touchPath, delegate.scrollAmount, remainingTouchPath);
        if (round(CGVectorLength(scrollDeviation)) > 0) {
          adjustedTouchPath =
              GREYFixTouchPathDeviation(touchPath, scrollDeviation, currentTouchPoint, scrollView);

          if (adjustedTouchPath) {
            break;
          } else {
            // When the adjusted touch path doesn't meet the safe screen bounds, it means the new
            // path goes forward the current touch direction, instead of backward. Thus this round
            // of touch injection continues without adjustment, and adds the length of the deviation
            // to the next round.
            *amountRemaining += CGVectorLength(scrollDeviation);
          }
        }
      }

      // Resistance detection should be performed after the scroll is detected. If the scroll view
      // is not bounced and it is at the edge before the touch injection, the scroll may never be
      // detected. In this case, the error is porpagated as @c kGREYScrollNoTouchReaction.
      if (delegate.scrollDetected) {
        detectResistance();
      } else if (shouldDetectResistanceFromContentOffset &&
                 touchPointIndex > kMinTouchPointsToDetectScrollResistance) {
        // Even if scroll is not detected, scroll detection can be delayed and cause side-effect. So
        // the remaining touch is injected without moving the touch point to avoid the side-effect.
        for (NSUInteger remainingIndex = touchPointIndex; remainingIndex < [touchPath count];
             ++remainingIndex) {
          [eventGenerator continueTouchAtPoint:currentTouchPoint
                             immediateDelivery:YES
                                       timeout:interactionTimeout];
        }
        break;
      }
    }
  }

  // If @c adjustedTouchPath exists, the @c touchPath is proved to cause deviation. By continuing
  // touch injection starting from the second touch point of @c adjustedTouchPath (the first element
  // is the current touch point), the deviation will be fixed.
  if (adjustedTouchPath) {
    for (NSUInteger touchPointIndex = 1;
         touchPointIndex < adjustedTouchPath.count && !hasResistance; ++touchPointIndex) {
      @autoreleasepool {
        [eventGenerator continueTouchAtPoint:adjustedTouchPath[touchPointIndex].CGPointValue
                           immediateDelivery:YES
                                     timeout:interactionTimeout];
        detectResistance();
      }
    }
  }

  [eventGenerator endTouchWithTimeout:interactionTimeout];

  // Drain the main loop to process the touch path and finish scroll bounce animation if any.
  while ([[GREYAppStateTracker sharedInstance] currentState] & kGREYPendingUIScrollViewScrolling) {
    [[GREYUIThreadExecutor sharedInstance] drainOnce];
  }

  BOOL success = YES;
  if (hasResistance) {
    success = NO;
    I_GREYPopulateError(error, kGREYScrollErrorDomain, kGREYScrollReachedContentEdge,
                        @"Cannot scroll, the scrollview is already at the edge.");
  } else if (!fallback && !delegate.scrollDetected) {
    success = NO;
    // If the scroll has content size smaller than the view size, even without resistance, offset
    // won't change and the scroll does not take any effect.
    if (scrollView.contentSize.width < scrollView.frame.size.width &&
        scrollView.contentSize.height < scrollView.frame.size.height) {
      I_GREYPopulateError(error, kGREYScrollErrorDomain, kGREYScrollReachedContentEdge,
                          @"Cannot scroll, the scrollview is already at the edge.");
    } else {
      I_GREYPopulateError(error, kGREYScrollErrorDomain, kGREYScrollNoTouchReaction,
                          @"Scroll view didn't respond to touch.");
    }
  } else if (fallback && CGPointEqualToPoint(scrollView.contentOffset, originalOffset)) {
    success = NO;
    I_GREYPopulateError(error, kGREYScrollErrorDomain, kGREYScrollNoTouchReaction,
                        @"Scroll view didn't respond to touch.");
  }
  return success;
}

#pragma mark - GREYDiagnosable

- (NSString *)diagnosticsID {
  return GREYCorePrefixedDiagnosticsID(@"scroll");
}

@end
