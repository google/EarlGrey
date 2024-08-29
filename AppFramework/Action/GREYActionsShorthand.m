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

#import "GREYActionsShorthand.h"

#import "GREYActions.h"
#import "EDORemoteVariable.h"

#if !defined(GREY_DISABLE_SHORTHAND) || !(GREY_DISABLE_SHORTHAND)

id<GREYAction> GREYDoubleTap(void) { return [GREYActions actionForMultipleTapsWithCount:2]; }
id<GREYAction> grey_doubleTap(void) { return GREYDoubleTap(); }

id<GREYAction> GREYDoubleTapAtPoint(CGPoint point) {
  return [GREYActions actionForMultipleTapsWithCount:2 atPoint:point];
}
id<GREYAction> grey_doubleTapAtPoint(CGPoint point) { return GREYDoubleTapAtPoint(point); }

id<GREYAction> GREYMultipleTapsWithCount(NSUInteger count) {
  return [GREYActions actionForMultipleTapsWithCount:count];
}
id<GREYAction> grey_multipleTapsWithCount(NSUInteger count) {
  return GREYMultipleTapsWithCount(count);
}

id<GREYAction> GREYLongPress(void) { return [GREYActions actionForLongPress]; }
id<GREYAction> grey_longPress(void) { return GREYLongPress(); }

id<GREYAction> GREYLongPressWithDuration(CFTimeInterval duration) {
  return [GREYActions actionForLongPressWithDuration:duration];
}
id<GREYAction> grey_longPressWithDuration(CFTimeInterval duration) {
  return GREYLongPressWithDuration(duration);
}

id<GREYAction> GREYLongPressAtPointWithDuration(CGPoint point, CFTimeInterval duration) {
  return [GREYActions actionForLongPressAtPoint:point duration:duration];
}
id<GREYAction> grey_longPressAtPointWithDuration(CGPoint point, CFTimeInterval duration) {
  return GREYLongPressAtPointWithDuration(point, duration);
}

id<GREYAction> GREYScrollInDirection(GREYDirection direction, CGFloat amount) {
  return [GREYActions actionForScrollInDirection:direction amount:amount];
}
id<GREYAction> grey_scrollInDirection(GREYDirection direction, CGFloat amount) {
  return GREYScrollInDirection(direction, amount);
}

id<GREYAction> GREYScrollInDirectionWithStartPoint(GREYDirection direction, CGFloat amount,
                                                   CGFloat xOriginStartPercentage,
                                                   CGFloat yOriginStartPercentage) {
  return [GREYActions actionForScrollInDirection:direction
                                          amount:amount
                          xOriginStartPercentage:xOriginStartPercentage
                          yOriginStartPercentage:yOriginStartPercentage];
}
id<GREYAction> grey_scrollInDirectionWithStartPoint(GREYDirection direction, CGFloat amount,
                                                    CGFloat xOriginStartPercentage,
                                                    CGFloat yOriginStartPercentage) {
  return GREYScrollInDirectionWithStartPoint(direction, amount, xOriginStartPercentage,
                                             yOriginStartPercentage);
}

id<GREYAction> GREYScrollToContentEdge(GREYContentEdge edge) {
  return [GREYActions actionForScrollToContentEdge:edge];
}
id<GREYAction> grey_scrollToContentEdge(GREYContentEdge edge) {
  return GREYScrollToContentEdge(edge);
}

id<GREYAction> GREYScrollToContentEdgeWithStartPoint(GREYContentEdge edge,
                                                     CGFloat xOriginStartPercentage,
                                                     CGFloat yOriginStartPercentage) {
  return [GREYActions actionForScrollToContentEdge:edge
                            xOriginStartPercentage:xOriginStartPercentage
                            yOriginStartPercentage:yOriginStartPercentage];
}
id<GREYAction> grey_scrollToContentEdgeWithStartPoint(GREYContentEdge edge,
                                                      CGFloat xOriginStartPercentage,
                                                      CGFloat yOriginStartPercentage) {
  return GREYScrollToContentEdgeWithStartPoint(edge, xOriginStartPercentage,
                                               yOriginStartPercentage);
}

id<GREYAction> GREYSwipeFastInDirection(GREYDirection direction) {
  return [GREYActions actionForSwipeFastInDirection:direction];
}
id<GREYAction> grey_swipeFastInDirection(GREYDirection direction) {
  return GREYSwipeFastInDirection(direction);
}

id<GREYAction> GREYSwipeSlowInDirection(GREYDirection direction) {
  return [GREYActions actionForSwipeSlowInDirection:direction];
}
id<GREYAction> grey_swipeSlowInDirection(GREYDirection direction) {
  return GREYSwipeSlowInDirection(direction);
}

id<GREYAction> GREYSwipeFastInDirectionWithStartPoint(GREYDirection direction,
                                                      CGFloat xOriginStartPercentage,
                                                      CGFloat yOriginStartPercentage) {
  return [GREYActions actionForSwipeFastInDirection:direction
                             xOriginStartPercentage:xOriginStartPercentage
                             yOriginStartPercentage:yOriginStartPercentage];
}
id<GREYAction> grey_swipeFastInDirectionWithStartPoint(GREYDirection direction,
                                                       CGFloat xOriginStartPercentage,
                                                       CGFloat yOriginStartPercentage) {
  return GREYSwipeFastInDirectionWithStartPoint(direction, xOriginStartPercentage,
                                                yOriginStartPercentage);
}

id<GREYAction> GREYSwipeSlowInDirectionWithStartPoint(GREYDirection direction,
                                                      CGFloat xOriginStartPercentage,
                                                      CGFloat yOriginStartPercentage) {
  return [GREYActions actionForSwipeSlowInDirection:direction
                             xOriginStartPercentage:xOriginStartPercentage
                             yOriginStartPercentage:yOriginStartPercentage];
}
id<GREYAction> grey_swipeSlowInDirectionWithStartPoint(GREYDirection direction,
                                                       CGFloat xOriginStartPercentage,
                                                       CGFloat yOriginStartPercentage) {
  return GREYSwipeSlowInDirectionWithStartPoint(direction, xOriginStartPercentage,
                                                yOriginStartPercentage);
}

id<GREYAction> GREYMultiFingerSwipeSlowInDirection(GREYDirection direction,
                                                   NSUInteger numberOfFingers) {
  return [GREYActions actionForMultiFingerSwipeSlowInDirection:direction
                                               numberOfFingers:numberOfFingers];
}
id<GREYAction> grey_multiFingerSwipeSlowInDirection(GREYDirection direction,
                                                    NSUInteger numberOfFingers) {
  return GREYMultiFingerSwipeSlowInDirection(direction, numberOfFingers);
}

id<GREYAction> GREYMultiFingerSwipeFastInDirection(GREYDirection direction,
                                                   NSUInteger numberOfFingers) {
  return [GREYActions actionForMultiFingerSwipeFastInDirection:direction
                                               numberOfFingers:numberOfFingers];
}
id<GREYAction> grey_multiFingerSwipeFastInDirection(GREYDirection direction,
                                                    NSUInteger numberOfFingers) {
  return GREYMultiFingerSwipeFastInDirection(direction, numberOfFingers);
}

id<GREYAction> GREYMultiFingerSwipeSlowInDirectionWithStartPoint(GREYDirection direction,
                                                                 NSUInteger numberOfFingers,
                                                                 CGFloat xOriginStartPercentage,
                                                                 CGFloat yOriginStartPercentage) {
  return [GREYActions actionForMultiFingerSwipeSlowInDirection:direction
                                               numberOfFingers:numberOfFingers
                                        xOriginStartPercentage:xOriginStartPercentage
                                        yOriginStartPercentage:yOriginStartPercentage];
}
id<GREYAction> grey_multiFingerSwipeSlowInDirectionWithStartPoint(GREYDirection direction,
                                                                  NSUInteger numberOfFingers,
                                                                  CGFloat xOriginStartPercentage,
                                                                  CGFloat yOriginStartPercentage) {
  return GREYMultiFingerSwipeSlowInDirectionWithStartPoint(
      direction, numberOfFingers, xOriginStartPercentage, yOriginStartPercentage);
}

id<GREYAction> GREYMultiFingerSwipeFastInDirectionWithStartPoint(GREYDirection direction,
                                                                 NSUInteger numberOfFingers,
                                                                 CGFloat xOriginStartPercentage,
                                                                 CGFloat yOriginStartPercentage) {
  return [GREYActions actionForMultiFingerSwipeFastInDirection:direction
                                               numberOfFingers:numberOfFingers
                                        xOriginStartPercentage:xOriginStartPercentage
                                        yOriginStartPercentage:yOriginStartPercentage];
}
id<GREYAction> grey_multiFingerSwipeFastInDirectionWithStartPoint(GREYDirection direction,
                                                                  NSUInteger numberOfFingers,
                                                                  CGFloat xOriginStartPercentage,
                                                                  CGFloat yOriginStartPercentage) {
  return GREYMultiFingerSwipeFastInDirectionWithStartPoint(
      direction, numberOfFingers, xOriginStartPercentage, yOriginStartPercentage);
}

id<GREYAction> GREYPinchFastInDirectionAndAngle(GREYPinchDirection pinchDirection, double angle) {
  return [GREYActions actionForPinchFastInDirection:pinchDirection withAngle:angle];
}
id<GREYAction> grey_pinchFastInDirectionAndAngle(GREYPinchDirection pinchDirection, double angle) {
  return GREYPinchFastInDirectionAndAngle(pinchDirection, angle);
}

id<GREYAction> GREYPinchSlowInDirectionAndAngle(GREYPinchDirection pinchDirection, double angle) {
  return [GREYActions actionForPinchSlowInDirection:pinchDirection withAngle:angle];
}
id<GREYAction> grey_pinchSlowInDirectionAndAngle(GREYPinchDirection pinchDirection, double angle) {
  return GREYPinchSlowInDirectionAndAngle(pinchDirection, angle);
}

/** Shorthand macro for GREYActions::actionForTwistFastWithAngle:. */
id<GREYAction> GREYTwistFastWithAngle(double angle) {
  return [GREYActions actionForTwistFastWithAngle:angle];
}
id<GREYAction> grey_twistFastWithAngle(double angle) { return GREYTwistFastWithAngle(angle); }

id<GREYAction> GREYTwistSlowWithAngle(double angle) {
  return [GREYActions actionForTwistSlowWithAngle:angle];
}
id<GREYAction> grey_twistSlowWithAngle(double angle) { return GREYTwistSlowWithAngle(angle); }

id<GREYAction> GREYMoveSliderToValue(float value) {
  return [GREYActions actionForMoveSliderToValue:value];
}
id<GREYAction> grey_moveSliderToValue(float value) { return GREYMoveSliderToValue(value); }

id<GREYAction> GREYSetStepperValue(double value) {
  return [GREYActions actionForSetStepperValue:value];
}
id<GREYAction> grey_setStepperValue(double value) { return GREYSetStepperValue(value); }

id<GREYAction> GREYTap(void) { return [GREYActions actionForTap]; }
id<GREYAction> grey_tap(void) { return GREYTap(); }

id<GREYAction> GREYTapAtPoint(CGPoint point) { return [GREYActions actionForTapAtPoint:point]; }
id<GREYAction> grey_tapAtPoint(CGPoint point) { return GREYTapAtPoint(point); }

id<GREYAction> GREYTypeText(NSString *text) { return [GREYActions actionForTypeText:text]; }
id<GREYAction> grey_typeText(NSString *text) { return GREYTypeText(text); }

id<GREYAction> GREYReplaceText(NSString *text) { return [GREYActions actionForReplaceText:text]; }
id<GREYAction> grey_replaceText(NSString *text) { return GREYReplaceText(text); }

id<GREYAction> GREYClearText(void) { return [GREYActions actionForClearText]; }
id<GREYAction> grey_clearText(void) { return GREYClearText(); }

id<GREYAction> GREYTurnSwitchOn(BOOL on) { return [GREYActions actionForTurnSwitchOn:on]; }
id<GREYAction> grey_turnSwitchOn(BOOL on) { return GREYTurnSwitchOn(on); }

id<GREYAction> GREYTurnSwitchOnWithShortTap(BOOL on) {
  return [GREYActions actionForTurnSwitchOnWithShortTap:on];
}
id<GREYAction> grey_turnSwitchOnWithShortTap(BOOL on) { return GREYTurnSwitchOnWithShortTap(on); }

id<GREYAction> GREYSetDate(NSDate *date) { return [GREYActions actionForSetDate:date]; }
id<GREYAction> grey_setDate(NSDate *date) { return GREYSetDate(date); }

id<GREYAction> GREYSetPickerColumnToValue(NSInteger column, NSString *value) {
  return [GREYActions actionForSetPickerColumn:column toValue:value];
}
id<GREYAction> grey_setPickerColumnToValue(NSInteger column, NSString *value) {
  return GREYSetPickerColumnToValue(column, value);
}

id<GREYAction> GREYJavaScriptExecution(NSString *js, EDORemoteVariable<NSString *> *outResult) {
  return [GREYActions actionForJavaScriptExecution:js output:outResult];
}
id<GREYAction> grey_javaScriptExecution(NSString *js, EDORemoteVariable<NSString *> *outResult) {
  return GREYJavaScriptExecution(js, outResult);
}

id<GREYAction> GREYAsyncJavaScriptExecution(NSString *js,
                                            EDORemoteVariable<NSString *> *_Nullable outResult) {
  return [GREYActions actionForAsyncJavaScriptExecution:js output:outResult];
}
id<GREYAction> grey_asyncJavaScriptExecution(NSString *js,
                                             EDORemoteVariable<NSString *> *_Nullable outResult) {
  return GREYAsyncJavaScriptExecution(js, outResult);
}

id<GREYAction> GREYSnapshot(EDORemoteVariable<UIImage *> *outImage) {
  return [GREYActions actionForSnapshot:outImage];
}
id<GREYAction> grey_snapshot(EDORemoteVariable<UIImage *> *outImage) {
  return GREYSnapshot(outImage);
}

#endif  // GREY_DISABLE_SHORTHAND
