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
#import <WebKit/WebKit.h>

#import "GREYConstants.h"
#import "GREYDefines.h"

@protocol GREYAction;
@class EDORemoteVariable<ObjectType>;

/**
 *  A interface that exposes UI element actions.
 */
@interface GREYActions : NSObject

/**
 *  @return A GREYAction that performs multiple taps of a specified @c count.
 */
+ (id<GREYAction>)actionForMultipleTapsWithCount:(NSUInteger)count;

/**
 *  @return A GREYAction that performs multiple taps of a specified @c count at a specified
 *          @c point.
 */
+ (id<GREYAction>)actionForMultipleTapsWithCount:(NSUInteger)count atPoint:(CGPoint)point;

/**
 *  Returns an action that holds down finger for 1.0 second (@c kGREYLongPressDefaultDuration) to
 *  simulate a long press.
 *
 *  @return A GREYAction that performs a long press on an element.
 */
+ (id<GREYAction>)actionForLongPress;

/**
 *  Returns an action that holds down finger for specified @c duration to simulate a long press.
 *
 *  @param duration The duration of the long press.
 *
 *  @return A GREYAction that performs a long press on an element.
 */
+ (id<GREYAction>)actionForLongPressWithDuration:(CFTimeInterval)duration;

/**
 *  Returns an action that holds down finger for specified @c duration at the specified @c point
 *  (interpreted as being relative to the element) to simulate a long press.
 *
 *  @param point    The point that should be tapped.
 *  @param duration The duration of the long press.
 *
 *  @return A GREYAction that performs a long press on an element.
 */
+ (id<GREYAction>)actionForLongPressAtPoint:(CGPoint)point duration:(CFTimeInterval)duration;

/**
 *  Returns an action that scrolls a @c UIScrollView by @c amount (in points) in the specified
 *  @c direction.
 *
 *  @param direction The direction of the swipe.
 *  @param amount    The amount of points in CGPoints to scroll.
 *
 *  @return A GREYAction that scrolls a scroll view in a given @c direction for a given @c amount.
 */
+ (id<GREYAction>)actionForScrollInDirection:(GREYDirection)direction amount:(CGFloat)amount;

/**
 *  Returns a scroll action that scrolls in a @c direction for an @c amount of points starting from
 *  the given start point specified as percentages. @c xOriginStartPercentage is the x start
 *  position as a percentage of the total width of the scrollable visible area,
 *  @c yOriginStartPercentage is the y start position as a percentage of the total height of the
 *  scrollable visible area. @c xOriginStartPercentage and @c yOriginStartPercentage must be between
 *  0 and 1, exclusive.
 *
 *  @param direction              The direction of the scroll.
 *  @param amount                 The amount scroll in points to inject.
 *  @param xOriginStartPercentage X coordinate of the start point specified as a percentage (0, 1)
 *                                exclusive, of the total width of the scrollable visible area.
 *  @param yOriginStartPercentage Y coordinate of the start point specified as a percentage (0, 1)
 *                                exclusive, of the total height of the scrollable visible area.
 *
 *  @return A GREYAction that scrolls a scroll view in a given @c direction for a given @c amount
 *          starting from the given start points.
 */
+ (id<GREYAction>)actionForScrollInDirection:(GREYDirection)direction
                                      amount:(CGFloat)amount
                      xOriginStartPercentage:(CGFloat)xOriginStartPercentage
                      yOriginStartPercentage:(CGFloat)yOriginStartPercentage;

/**
 *  @return A GREYAction that scrolls to the given content @c edge of a scroll view.
 */
+ (id<GREYAction>)actionForScrollToContentEdge:(GREYContentEdge)edge;

/**
 *  A GREYAction that scrolls to the given content @c edge of a scroll view with the scroll action
 *  starting from the given start point specified as percentages. @c xOriginStartPercentage is the x
 *  start position as a percentage of the total width of the scrollable visible area,
 *  @c yOriginStartPercentage is the y start position as a percentage of the total height of the
 *  scrollable visible area. @c xOriginStartPercentage and @c yOriginStartPercentage must be between
 *  0 and 1, exclusive.
 *
 *  @param edge                   The edge towards which the scrolling is to take place.
 *  @param xOriginStartPercentage X coordinate of the start point specified as a percentage (0, 1)
 *                                exclusive, of the total width of the scrollable visible area.
 *  @param yOriginStartPercentage Y coordinate of the start point specified as a percentage (0, 1)
 *                                exclusive, of the total height of the scrollable visible area.
 *
 *  @return A GREYAction that scrolls to the given content @c edge of a scroll view with the scroll
 *          action starting from the given start point.
 */
+ (id<GREYAction>)actionForScrollToContentEdge:(GREYContentEdge)edge
                        xOriginStartPercentage:(CGFloat)xOriginStartPercentage
                        yOriginStartPercentage:(CGFloat)yOriginStartPercentage;

/**
 *  Returns an action that fast swipes through the view. The start point of the swipe is chosen to
 *  achieve the maximum the swipe possible to the other edge.
 *
 *  @param direction The direction of the swipe.
 *
 *  @return A GREYAction that performs a fast swipe in the given direction.
 */
+ (id<GREYAction>)actionForSwipeFastInDirection:(GREYDirection)direction;

/**
 *  Returns an action that slow swipes through the view. The start point of the swipe is chosen to
 *  achieve maximum the swipe possible to the other edge.
 *
 *  @param direction The direction of the swipe.
 *
 *  @return A GREYAction that performs a slow swipe in the given direction.
 */
+ (id<GREYAction>)actionForSwipeSlowInDirection:(GREYDirection)direction;

/**
 *  Returns an action that swipes through the view quickly in the given @c direction from a specific
 *  origin.
 *
 *  @param direction              The direction of the swipe.
 *  @param xOriginStartPercentage the x start position as a percentage of the total width
 *                                of the view. This must be between 0 and 1.
 *  @param yOriginStartPercentage the y start position as a percentage of the total height
 *                                of the view. This must be between 0 and 1.
 *
 *  @return A GREYAction that performs a fast swipe through a view in a specific direction from
 *          the specified point.
 */
+ (id<GREYAction>)actionForSwipeFastInDirection:(GREYDirection)direction
                         xOriginStartPercentage:(CGFloat)xOriginStartPercentage
                         yOriginStartPercentage:(CGFloat)yOriginStartPercentage;

/**
 *  Returns an action that swipes through the view quickly in the given @c direction from a
 *  specific origin.
 *
 *  @param direction              The direction of the swipe.
 *  @param xOriginStartPercentage the x start position as a percentage of the total width
 *                                of the view. This must be between 0 and 1.
 *  @param yOriginStartPercentage the y start position as a percentage of the total height
 *                                of the view. This must be between 0 and 1.
 *
 *  @return A GREYAction that performs a slow swipe through a view in a specific direction from
 *          the specified point.
 */
+ (id<GREYAction>)actionForSwipeSlowInDirection:(GREYDirection)direction
                         xOriginStartPercentage:(CGFloat)xOriginStartPercentage
                         yOriginStartPercentage:(CGFloat)yOriginStartPercentage;

/**
 *  Returns an action that performs a multi-finger slow swipe through the view in the given
 *  @c direction.
 *
 *  @param direction       The direction of the swipe.
 *  @param numberOfFingers Number of fingers touching the screen for the swipe.
 *
 *  @return A GREYAction that performs a multi-finger slow swipe through a view in a specific
 *          direction from the specified point.
 */
+ (id<GREYAction>)actionForMultiFingerSwipeSlowInDirection:(GREYDirection)direction
                                           numberOfFingers:(NSUInteger)numberOfFingers;

/**
 *  Returns an action that performs a multi-finger fast swipe through the view in the given
 *  @c direction.
 *
 *  @param direction       The direction of the swipe.
 *  @param numberOfFingers Number of fingers touching the screen for the swipe.
 *
 *  @return A GREYAction that performs a multi-finger fast swipe through a view in a specific
 *          direction from the specified point.
 */
+ (id<GREYAction>)actionForMultiFingerSwipeFastInDirection:(GREYDirection)direction
                                           numberOfFingers:(NSUInteger)numberOfFingers;

/**
 *  Returns an action that performs a multi-finger slow swipe through the view in the given
 *  @c direction from a specified origin.
 *
 *  @param direction              The direction of the swipe.
 *  @param numberOfFingers        Number of fingers touching the screen for the swipe.
 *  @param xOriginStartPercentage The x start position as a percentage of the total width
 *                                of the view. This must be between 0 and 1.
 *  @param yOriginStartPercentage The y start position as a percentage of the total height
 *                                of the view. This must be between 0 and 1.
 *
 *  @return A GREYAction that performs a multi-finger slow swipe through a view in a specific
 *          direction from the specified point.
 */
+ (id<GREYAction>)actionForMultiFingerSwipeSlowInDirection:(GREYDirection)direction
                                           numberOfFingers:(NSUInteger)numberOfFingers
                                    xOriginStartPercentage:(CGFloat)xOriginStartPercentage
                                    yOriginStartPercentage:(CGFloat)yOriginStartPercentage;

/**
 *  Returns an action that performs a multi-finger fast swipe through the view in the given
 *  @c direction from a specified origin.
 *
 *  @param direction              The direction of the swipe.
 *  @param numberOfFingers        Number of fingers touching the screen for the swipe.
 *  @param xOriginStartPercentage The x start position as a percentage of the total width
 *                                of the view. This must be between 0 and 1.
 *  @param yOriginStartPercentage The y start position as a percentage of the total height
 *                                of the view. This must be between 0 and 1.
 *
 *  @return A GREYAction that performs a multi-finger fast swipe through a view in a specific
 *          direction from the specified point.
 */
+ (id<GREYAction>)actionForMultiFingerSwipeFastInDirection:(GREYDirection)direction
                                           numberOfFingers:(NSUInteger)numberOfFingers
                                    xOriginStartPercentage:(CGFloat)xOriginStartPercentage
                                    yOriginStartPercentage:(CGFloat)yOriginStartPercentage;

/**
 *  Returns an action that pinches view quickly in the specified @c direction and @c angle.
 *
 *  @param  pinchDirection The direction of the pinch action.
 *  @param  angle          The angle of the pinch action in radians.
 *                         Use @c kGREYPinchAngleDefault for the default angle (currently set to
 *                         30 degrees).
 *
 *  @return A GREYAction that performs a fast pinch on the view in the specified @c direction.
 */
+ (id<GREYAction>)actionForPinchFastInDirection:(GREYPinchDirection)pinchDirection
                                      withAngle:(double)angle;

/**
 *  Returns an action that pinches view slowly in the specified @c direction and @c angle.
 *
 *  @param  pinchDirection The direction of the pinch action.
 *  @param  angle          The angle of the pinch action in radians.
 *                         Use @c kGREYPinchAngleDefault for the default angle (currently set to
 *                         30 degrees).
 *
 *  @return A GREYAction that performs a slow pinch on the view in the specified @c direction.
 */
+ (id<GREYAction>)actionForPinchSlowInDirection:(GREYPinchDirection)pinchDirection
                                      withAngle:(double)angle;

/**
 * Returns an action that attempts to move slider to within 1.0e-6f values of @c value.
 *
 * @param value The value to which the slider should be moved. If this is not attainable after a
 *              reasonable number of attempts (currently 10) we assume that the @c value is
 *              unattainable for a user (it is probably the case this value resides between two
 *              pixels). In this case, the slider will end up at a user attainable value
 *              that is closest to @c value.
 *
 * @return A GREYAction that moves a slider to a given @c value.
 */
+ (id<GREYAction>)actionForMoveSliderToValue:(float)value;

/**
 *  Returns an action that changes the value of UIStepper to @c value by tapping the appropriate
 *  button multiple times.
 *
 *  @param value The value to change the UIStepper to.
 *
 *  @return A GREYAction that sets the given @c value on a stepper.
 */
+ (id<GREYAction>)actionForSetStepperValue:(double)value;

/**
 *  Returns an action that taps on an element at the activation point of the element.
 *
 *  @return A GREYAction to tap on an element.
 */
+ (id<GREYAction>)actionForTap;

/**
 *  Returns an action that taps on an element at the specified @c point.
 *
 *  @param point The point that should be tapped. It must be in the coordinate system of the
 *               element and it's position is relative to the origin of the element, as in
 *               (element_width/2, element_height/2) will tap at the center of element.
 *
 *  @return A GREYAction to tap on an element at a specific point.
 */
+ (id<GREYAction>)actionForTapAtPoint:(CGPoint)point;

/**
 *  Returns an action that uses the iOS keyboard to input a string.
 *
 *  @param text The text to be typed. For Objective-C, backspace is supported by using "\b" in the
 *              string and "\u{8}" in Swift strings. Return key is supported with "\n".
 *              For Example: @"Helpo\b\bloWorld" will type HelloWorld in Objective-C.
 *                           "Helpo\u{8}\u{8}loWorld" will type HelloWorld in Swift.
 *
 *  @return A GREYAction to type a specific text string in a text field.
 */
+ (id<GREYAction>)actionForTypeText:(NSString *)text;

/**
 *  Returns an action that uses the iOS keyboard to input a string at a particular position.
 *
 *  @param text The text to be typed. For Objective-C, backspace is supported by using "\b" in the
 *              string and "\u{8}" in Swift strings. Return key is supported with "\n".
 *              For Example: @"Helpo\b\bloWorld" will type HelloWorld in Objective-C.
 *                           "Helpo\u{8}\u{8}loWorld" will type HelloWorld in Swift.
 *  @param position The index to insert the text. 0 indicates to insert text from the
 *                  beginning of input element. Reverse index is supported and -1 indicates
 *                  insert from the end of the input element.
 *
 *  @return A GREYAction to type a specific text string in a text field at a particular position.
 */
+ (id<GREYAction>)actionForTypeText:(NSString *)text atPosition:(NSInteger)position;

/**
 *  Returns an action that sets text on a UITextField or webview input directly.
 *
 *  @param text The text to be typed.
 *
 *  @return A GREYAction to type a specific text string in a text field.
 */
+ (id<GREYAction>)actionForReplaceText:(NSString *)text;

/**
 *  @return A GREYAction that clears a text field by injecting back-spaces.
 */
+ (id<GREYAction>)actionForClearText;

/**
 *  Returns an action that toggles a switch control. This action is applicable to all elements that
 *  implement the selector UISwitch::isOn and include UISwitch controls.
 *
 *  @param on The switch control state.
 *
 *  @return A GREYAction to toggle a UISwitch.
 */
+ (id<GREYAction>)actionForTurnSwitchOn:(BOOL)on;

/**
 *  Returns an action that injects dates/times into UIDatePickers.
 *
 *  @param date The date to set the UIDatePicker.
 *
 *  @return A GREYAction that sets a given date/time on a UIDatePicker.
 */
+ (id<GREYAction>)actionForSetDate:(NSDate *)date;

/**
 *  Returns an action that selects @c value on the given @c column of a UIPickerView.
 *
 *  @param column The UIPickerView column being set.
 *  @param value  The value to set the UIPickerView.
 *
 *  @return A GREYAction to set the value of a specified column of a UIPickerView.
 */
+ (id<GREYAction>)actionForSetPickerColumn:(NSInteger)column toValue:(NSString *)value;

/**
 *  Returns an action that executes JavaScript against a UIWebView / WKWebView and sets the return
 *  value to @c outResult if provided.
 *
 *  @param js        The Javascript code to be executed.
 *  @param outResult The result of the code execution, wrapped in an EDORemoteVariable.
 *
 *  @return A GREYAction that executes JavaScript code against a UIWebView / WKWebView.
 */
+ (id<GREYAction>)actionForJavaScriptExecution:(NSString *)js
                                        output:(EDORemoteVariable<NSString *> *)outResult;

/**
 *  Returns an action that takes a snapshot of the selected element.
 *
 *  @param outImage The UIImage where the image content is stored.
 *
 *  @return A GREYAction that takes a snapshot of an UI element.
 */
+ (id<GREYAction>)actionForSnapshot:(EDORemoteVariable<UIImage *> *)outImage;

@end
