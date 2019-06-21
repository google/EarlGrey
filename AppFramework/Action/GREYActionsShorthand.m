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

#if !defined(GREY_DISABLE_SHORTHAND) || !(GREY_DISABLE_SHORTHAND)

id<GREYAction> grey_doubleTap(void) { return [GREYActions actionForMultipleTapsWithCount:2]; }

id<GREYAction> grey_doubleTapAtPoint(CGPoint point) {
  return [GREYActions actionForMultipleTapsWithCount:2 atPoint:point];
}

id<GREYAction> grey_multipleTapsWithCount(NSUInteger count) {
  return [GREYActions actionForMultipleTapsWithCount:count];
}

id<GREYAction> grey_longPress(void) { return [GREYActions actionForLongPress]; }

id<GREYAction> grey_longPressWithDuration(CFTimeInterval duration) {
  return [GREYActions actionForLongPressWithDuration:duration];
}

id<GREYAction> grey_longPressAtPointWithDuration(CGPoint point, CFTimeInterval duration) {
  return [GREYActions actionForLongPressAtPoint:point duration:duration];
}

id<GREYAction> grey_scrollInDirection(GREYDirection direction, CGFloat amount) {
  return [GREYActions actionForScrollInDirection:direction amount:amount];
}

id<GREYAction> grey_scrollInDirectionWithStartPoint(GREYDirection direction, CGFloat amount,
                                                    CGFloat xOriginStartPercentage,
                                                    CGFloat yOriginStartPercentage) {
  return [GREYActions actionForScrollInDirection:direction
                                          amount:amount
                          xOriginStartPercentage:xOriginStartPercentage
                          yOriginStartPercentage:yOriginStartPercentage];
}

id<GREYAction> grey_scrollToContentEdge(GREYContentEdge edge) {
  return [GREYActions actionForScrollToContentEdge:edge];
}

id<GREYAction> grey_scrollToContentEdgeWithStartPoint(GREYContentEdge edge,
                                                      CGFloat xOriginStartPercentage,
                                                      CGFloat yOriginStartPercentage) {
  return [GREYActions actionForScrollToContentEdge:edge
                            xOriginStartPercentage:xOriginStartPercentage
                            yOriginStartPercentage:yOriginStartPercentage];
}

id<GREYAction> grey_swipeFastInDirection(GREYDirection direction) {
  return [GREYActions actionForSwipeFastInDirection:direction];
}

id<GREYAction> grey_swipeSlowInDirection(GREYDirection direction) {
  return [GREYActions actionForSwipeSlowInDirection:direction];
}

id<GREYAction> grey_swipeFastInDirectionWithStartPoint(GREYDirection direction,
                                                       CGFloat xOriginStartPercentage,
                                                       CGFloat yOriginStartPercentage) {
  return [GREYActions actionForSwipeFastInDirection:direction
                             xOriginStartPercentage:xOriginStartPercentage
                             yOriginStartPercentage:yOriginStartPercentage];
}

id<GREYAction> grey_swipeSlowInDirectionWithStartPoint(GREYDirection direction,
                                                       CGFloat xOriginStartPercentage,
                                                       CGFloat yOriginStartPercentage) {
  return [GREYActions actionForSwipeSlowInDirection:direction
                             xOriginStartPercentage:xOriginStartPercentage
                             yOriginStartPercentage:yOriginStartPercentage];
}

id<GREYAction> grey_multiFingerSwipeSlowInDirection(GREYDirection direction,
                                                    NSUInteger numberOfFingers) {
  return [GREYActions actionForMultiFingerSwipeSlowInDirection:direction
                                               numberOfFingers:numberOfFingers];
}

id<GREYAction> grey_multiFingerSwipeFastInDirection(GREYDirection direction,
                                                    NSUInteger numberOfFingers) {
  return [GREYActions actionForMultiFingerSwipeFastInDirection:direction
                                               numberOfFingers:numberOfFingers];
}

id<GREYAction> grey_multiFingerSwipeSlowInDirectionWithStartPoint(GREYDirection direction,
                                                                  NSUInteger numberOfFingers,
                                                                  CGFloat xOriginStartPercentage,
                                                                  CGFloat yOriginStartPercentage) {
  return [GREYActions actionForMultiFingerSwipeSlowInDirection:direction
                                               numberOfFingers:numberOfFingers
                                        xOriginStartPercentage:xOriginStartPercentage
                                        yOriginStartPercentage:yOriginStartPercentage];
}

id<GREYAction> grey_multiFingerSwipeFastInDirectionWithStartPoint(GREYDirection direction,
                                                                  NSUInteger numberOfFingers,
                                                                  CGFloat xOriginStartPercentage,
                                                                  CGFloat yOriginStartPercentage) {
  return [GREYActions actionForMultiFingerSwipeFastInDirection:direction
                                               numberOfFingers:numberOfFingers
                                        xOriginStartPercentage:xOriginStartPercentage
                                        yOriginStartPercentage:yOriginStartPercentage];
}

id<GREYAction> grey_pinchFastInDirectionAndAngle(GREYPinchDirection pinchDirection, double angle) {
  return [GREYActions actionForPinchFastInDirection:pinchDirection withAngle:angle];
}

id<GREYAction> grey_pinchSlowInDirectionAndAngle(GREYPinchDirection pinchDirection, double angle) {
  return [GREYActions actionForPinchSlowInDirection:pinchDirection withAngle:angle];
}

id<GREYAction> grey_moveSliderToValue(float value) {
  return [GREYActions actionForMoveSliderToValue:value];
}

id<GREYAction> grey_setStepperValue(double value) {
  return [GREYActions actionForSetStepperValue:value];
}

id<GREYAction> grey_tap(void) { return [GREYActions actionForTap]; }

id<GREYAction> grey_tapAtPoint(CGPoint point) { return [GREYActions actionForTapAtPoint:point]; }

id<GREYAction> grey_typeText(NSString *text) { return [GREYActions actionForTypeText:text]; }

id<GREYAction> grey_replaceText(NSString *text) { return [GREYActions actionForReplaceText:text]; }

id<GREYAction> grey_clearText(void) { return [GREYActions actionForClearText]; }

id<GREYAction> grey_turnSwitchOn(BOOL on) { return [GREYActions actionForTurnSwitchOn:on]; }

id<GREYAction> grey_setDate(NSDate *date) { return [GREYActions actionForSetDate:date]; }

id<GREYAction> grey_setPickerColumnToValue(NSInteger column, NSString *value) {
  return [GREYActions actionForSetPickerColumn:column toValue:value];
}

id<GREYAction> grey_javaScriptExecution(NSString *js, EDORemoteVariable<NSString *> *outResult) {
  return [GREYActions actionForJavaScriptExecution:js output:outResult];
}

id<GREYAction> grey_snapshot(EDORemoteVariable<UIImage *> *outImage) {
  return [GREYActions actionForSnapshot:outImage];
}

#endif  // GREY_DISABLE_SHORTHAND
