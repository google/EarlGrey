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

#import "GREYConstants.h"
#import "GREYDefines.h"

#if COCOAPODS
#import <eDistantObject/EDORemoteVariable.h>
#else
#import "EDORemoteVariable.h"
#endif  // COCOAPODS

NS_ASSUME_NONNULL_BEGIN

@protocol GREYAction;

#if !defined(GREY_DISABLE_SHORTHAND) || !(GREY_DISABLE_SHORTHAND)

#pragma mark - Pressing / Clicking based actions.

/** Shorthand macro for GREYActions::actionForMultipleTapsWithCount: with count @c 2. */
GREY_EXPORT id<GREYAction> GREYDoubleTap(void);
GREY_EXPORT id<GREYAction> grey_doubleTap(void);

/**
 * Shorthand macro for
 * GREYActions::actionForMultipleTapsWithCount: with count @c 2 and @c point.
 */
GREY_EXPORT id<GREYAction> GREYDoubleTapAtPoint(CGPoint point);
GREY_EXPORT id<GREYAction> grey_doubleTapAtPoint(CGPoint point);

/** Shorthand macro for GREYActions::actionForLongPress. */
GREY_EXPORT id<GREYAction> GREYLongPress(void);
GREY_EXPORT id<GREYAction> grey_longPress(void);

/** Shorthand macro for GREYActions::actionForLongPressWithDuration:. */
GREY_EXPORT id<GREYAction> GREYLongPressWithDuration(CFTimeInterval duration);
GREY_EXPORT id<GREYAction> grey_longPressWithDuration(CFTimeInterval duration);

/** Shorthand macro for GREYActions::actionForLongPressAtPoint:duration:. */
GREY_EXPORT id<GREYAction> GREYLongPressAtPointWithDuration(CGPoint point, CFTimeInterval duration);
GREY_EXPORT id<GREYAction> grey_longPressAtPointWithDuration(CGPoint point,
                                                             CFTimeInterval duration);

/** Shorthand macro for GREYActions::actionForMultipleTapsWithCount:. */
GREY_EXPORT id<GREYAction> GREYMultipleTapsWithCount(NSUInteger count);
GREY_EXPORT id<GREYAction> grey_multipleTapsWithCount(NSUInteger count);

/** Shorthand macro for GREYActions::actionForTap. */
GREY_EXPORT id<GREYAction> GREYTap(void);
GREY_EXPORT id<GREYAction> grey_tap(void);

/** Shorthand macro for GREYActions::actionForTapAtPoint:. */
GREY_EXPORT id<GREYAction> GREYTapAtPoint(CGPoint point);
GREY_EXPORT id<GREYAction> grey_tapAtPoint(CGPoint point);

#pragma mark - Gesture based actions.

/**
 * Shorthand macro for
 * GREYActions::actionForMultiFingerSwipeFastInDirection:numberOfFingers:.
 */
GREY_EXPORT id<GREYAction> GREYMultiFingerSwipeFastInDirection(GREYDirection direction,
                                                               NSUInteger numberOfFingers);
GREY_EXPORT id<GREYAction> grey_multiFingerSwipeFastInDirection(GREYDirection direction,
                                                                NSUInteger numberOfFingers);

/**
 * Shorthand macro for
 * GREYActions::actionForMultiFingerSwipeSlowInDirection:numberOfFingers:.
 */
GREY_EXPORT id<GREYAction> GREYMultiFingerSwipeSlowInDirection(GREYDirection direction,
                                                               NSUInteger numberOfFingers);
GREY_EXPORT id<GREYAction> grey_multiFingerSwipeSlowInDirection(GREYDirection direction,
                                                                NSUInteger numberOfFingers);

/**
 * Shorthand macro for
 * GREYActions::actionForMultiFingerSwipeFastInDirection:numberOfFingers:xOriginStartPercentage:
 * yOriginStartPercentage:.
 */
GREY_EXPORT id<GREYAction> GREYMultiFingerSwipeFastInDirectionWithStartPoint(
    GREYDirection direction, NSUInteger numberOfFingers, CGFloat xOriginStartPercentage,
    CGFloat yOriginStartPercentage);
GREY_EXPORT id<GREYAction> grey_multiFingerSwipeFastInDirectionWithStartPoint(
    GREYDirection direction, NSUInteger numberOfFingers, CGFloat xOriginStartPercentage,
    CGFloat yOriginStartPercentage);

/**
 * Shorthand macro for
 * GREYActions::actionForMultiFingerSwipeSlowInDirection:numberOfFingers:xOriginStartPercentage:
 * yOriginStartPercentage:.
 */
GREY_EXPORT id<GREYAction> GREYMultiFingerSwipeSlowInDirectionWithStartPoint(
    GREYDirection direction, NSUInteger numberOfFingers, CGFloat xOriginStartPercentage,
    CGFloat yOriginStartPercentage);
GREY_EXPORT id<GREYAction> grey_multiFingerSwipeSlowInDirectionWithStartPoint(
    GREYDirection direction, NSUInteger numberOfFingers, CGFloat xOriginStartPercentage,
    CGFloat yOriginStartPercentage);

/** Shorthand macro for GREYActions::actionForPinchFastInDirection:pinchDirection:angle:. */
GREY_EXPORT id<GREYAction> GREYPinchFastInDirectionAndAngle(GREYPinchDirection pinchDirection,
                                                            double angle);
GREY_EXPORT id<GREYAction> grey_pinchFastInDirectionAndAngle(GREYPinchDirection pinchDirection,
                                                             double angle);

/** Shorthand macro for GREYActions::actionForPinchSlowInDirection:pinchDirection:angle:. */
GREY_EXPORT id<GREYAction> GREYPinchSlowInDirectionAndAngle(GREYPinchDirection pinchDirection,
                                                            double angle);
GREY_EXPORT id<GREYAction> grey_pinchSlowInDirectionAndAngle(GREYPinchDirection pinchDirection,
                                                             double angle);

/** Shorthand macro for GREYActions::actionForTwistFastWithAngle:. */
GREY_EXPORT id<GREYAction> GREYTwistFastWithAngle(double angle);
GREY_EXPORT id<GREYAction> grey_twistFastWithAngle(double angle);

/** Shorthand macro for GREYActions::actionForTwistSlowWithAngle:. */
GREY_EXPORT id<GREYAction> GREYTwistSlowWithAngle(double angle);
GREY_EXPORT id<GREYAction> grey_twistSlowWithAngle(double angle);

/** Shorthand macro for GREYActions::actionForScrollInDirection:amount:. */
GREY_EXPORT id<GREYAction> GREYScrollInDirection(GREYDirection direction, CGFloat amount);
GREY_EXPORT id<GREYAction> grey_scrollInDirection(GREYDirection direction, CGFloat amount);

/**
 * Shorthand macro for
 * GREYActions::actionForScrollInDirection:amount:xOriginStartPercentage:yOriginStartPercentage:.
 */
GREY_EXPORT id<GREYAction> GREYScrollInDirectionWithStartPoint(GREYDirection direction,
                                                               CGFloat amount,
                                                               CGFloat xOriginStartPercentage,
                                                               CGFloat yOriginStartPercentage);
GREY_EXPORT id<GREYAction> grey_scrollInDirectionWithStartPoint(GREYDirection direction,
                                                                CGFloat amount,
                                                                CGFloat xOriginStartPercentage,
                                                                CGFloat yOriginStartPercentage);

/** Shorthand macro for GREYActions::actionForScrollToContentEdge:. */
GREY_EXPORT id<GREYAction> GREYScrollToContentEdge(GREYContentEdge edge);
GREY_EXPORT id<GREYAction> grey_scrollToContentEdge(GREYContentEdge edge);

/**
 * Shorthand macro for
 * GREYActions::actionForScrollToContentEdge:xOriginStartPercentage:yOriginStartPercentage:.
 */
GREY_EXPORT id<GREYAction> GREYScrollToContentEdgeWithStartPoint(GREYContentEdge edge,
                                                                 CGFloat xOriginStartPercentage,
                                                                 CGFloat yOriginStartPercentage);
GREY_EXPORT id<GREYAction> grey_scrollToContentEdgeWithStartPoint(GREYContentEdge edge,
                                                                  CGFloat xOriginStartPercentage,
                                                                  CGFloat yOriginStartPercentage);

/** Shorthand macro for GREYActions::actionForSwipeFastInDirection:. */
GREY_EXPORT id<GREYAction> GREYSwipeFastInDirection(GREYDirection direction);
GREY_EXPORT id<GREYAction> grey_swipeFastInDirection(GREYDirection direction);

/**
 * Shorthand macro for
 * GREYActions::actionForSwipeFastInDirection:xOriginStartPercentage:yOriginStartPercentage:.
 */
GREY_EXPORT id<GREYAction> GREYSwipeFastInDirectionWithStartPoint(GREYDirection direction,
                                                                  CGFloat xOriginStartPercentage,
                                                                  CGFloat yOriginStartPercentage);
GREY_EXPORT id<GREYAction> grey_swipeFastInDirectionWithStartPoint(GREYDirection direction,
                                                                   CGFloat xOriginStartPercentage,
                                                                   CGFloat yOriginStartPercentage);

/** Shorthand macro for GREYActions::actionForSwipeSlowInDirection:. */
GREY_EXPORT id<GREYAction> GREYSwipeSlowInDirection(GREYDirection direction);
GREY_EXPORT id<GREYAction> grey_swipeSlowInDirection(GREYDirection direction);

/**
 * Shorthand macro for
 * GREYActions::actionForSwipeSlowInDirection:xOriginStartPercentage:yOriginStartPercentage:.
 */
GREY_EXPORT id<GREYAction> GREYSwipeSlowInDirectionWithStartPoint(GREYDirection direction,
                                                                  CGFloat xOriginStartPercentage,
                                                                  CGFloat yOriginStartPercentage);
GREY_EXPORT id<GREYAction> grey_swipeSlowInDirectionWithStartPoint(GREYDirection direction,
                                                                   CGFloat xOriginStartPercentage,
                                                                   CGFloat yOriginStartPercentage);

#pragma mark - Text based actions.

/** Shorthand macro for GREYActions::actionForClearText. */
GREY_EXPORT id<GREYAction> GREYClearText(void);
GREY_EXPORT id<GREYAction> grey_clearText(void);

/** Shorthand macro for GREYActions::actionForReplaceText:. */
GREY_EXPORT id<GREYAction> GREYReplaceText(NSString *text);
GREY_EXPORT id<GREYAction> grey_replaceText(NSString *text);

/** Shorthand macro for GREYActions::actionForTypeText:. */
GREY_EXPORT id<GREYAction> GREYTypeText(NSString *text);
GREY_EXPORT id<GREYAction> grey_typeText(NSString *text);

#pragma mark - Other Actions

/** Shorthand macro for GREYActions::actionForJavaScriptExecution:output:.
 * Pass an EDORemoteVariable for the @c outResult.
 */
GREY_EXPORT id<GREYAction> GREYJavaScriptExecution(
    NSString *js, EDORemoteVariable<NSString *> *_Nullable outResult);
GREY_EXPORT id<GREYAction> grey_javaScriptExecution(
    NSString *js, EDORemoteVariable<NSString *> *_Nullable outResult);

/** Shorthand macro for GREYActions::actionForMoveSliderToValue:. */
GREY_EXPORT id<GREYAction> GREYMoveSliderToValue(float value);
GREY_EXPORT id<GREYAction> grey_moveSliderToValue(float value);

/** Shorthand macro for GREYActions::actionForSetDate:. */
GREY_EXPORT id<GREYAction> GREYSetDate(NSDate *date);
GREY_EXPORT id<GREYAction> grey_setDate(NSDate *date);

/** Shorthand macro for GREYActions::actionForSetPickerColumn:toValue:. */
GREY_EXPORT id<GREYAction> GREYSetPickerColumnToValue(NSInteger column, NSString *value);
GREY_EXPORT id<GREYAction> grey_setPickerColumnToValue(NSInteger column, NSString *value);

/** Shorthand macro for GREYActions::actionForSetStepperValue:. */
GREY_EXPORT id<GREYAction> GREYSetStepperValue(double value);
GREY_EXPORT id<GREYAction> grey_setStepperValue(double value);

/** Shorthand macro for GREYActions::actionForSnapshot:.
 * Pass an EDORemoteVariable for the @c outImage.
 */
GREY_EXPORT id<GREYAction> GREYSnapshot(EDORemoteVariable<UIImage *> *outImage);
GREY_EXPORT id<GREYAction> grey_snapshot(EDORemoteVariable<UIImage *> *outImage);

/** Shorthand macro for GREYActions::actionForTurnSwitchOn:. */
GREY_EXPORT id<GREYAction> GREYTurnSwitchOn(BOOL on);
GREY_EXPORT id<GREYAction> grey_turnSwitchOn(BOOL on);

/** Shorthand macro for GREYActions::actionForTurnSwitchOnWithShortTap:. */
GREY_EXPORT id<GREYAction> GREYTurnSwitchOnWithShortTap(BOOL on);
GREY_EXPORT id<GREYAction> grey_turnSwitchOnWithShortTap(BOOL on);

#endif  // GREY_DISABLE_SHORTHAND

NS_ASSUME_NONNULL_END
