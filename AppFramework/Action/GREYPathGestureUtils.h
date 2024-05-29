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

#import <UIKit/UIKit.h>

#import "GREYConstants.h"

/**
 * Generates a touch path in the @c window from the start point, in the given direction to the
 * max possible extent.
 *
 * @param window                        The window in which the touch path is generated.
 * @param startPointInWindowCoordinates The start point within the given @c window
 * @param direction                     The direction of the touch path.
 * @param duration                      How long the gesture should last (in seconds).
 *
 * @return NSArray of CGPoints that denote the points in the touch path.
 */
NSArray<NSValue *> *GREYTouchPathForGestureInWindow(UIWindow *window,
                                                    CGPoint startPointInWindowCoordinates,
                                                    GREYDirection direction,
                                                    CFTimeInterval duration);

/**
 * Generates a touch path in the @c window starting from a given @c view in a particular direction
 * for a certain amount in the window coordinates of the @c view. The start point of the path is
 * controlled by @c startPointPercents, which if specified as @c NAN, the start point will be
 * chosen to provide longest possible touch path, otherwise start point will be set to the percents
 * specified in the visible area of the given @c view. Note that the percent values must lie within
 * (0, 1) exclusive and the x and y axis are always the bottom and the left edge respectively of
 * the visible rect.
 *
 * @param view                          The view from which the touch path originates.
 * @param startPointPercents            The start point of the touch path specified as percents in
 *                                      the visible area of the @c view. Must be (0, 1) exclusive.
 * @param direction                     The direction of the touch.
 * @param length                        The length of the touch path. The length of the touch path
 *                                      is restricted by the screen dimensions, position of the
 *                                      view and the minimum scroll detection length (10 points as
 *                                      of iOS 8.0).
 * @param[out] outRemainingAmountOrNull The difference of the length and the amount,
 *                                      if the length falls short.
 *
 * @return Array of CGPoints that denote the points in the touch path. The touch path's length
 *         will be at least the minimum scroll detection length, when that is not possible
 *         (due to @c view position and/or size) @c nil is returned.
 */
NSArray<NSValue *> *GREYTouchPathForGestureInView(UIView *view, CGPoint startPointPercents,
                                                  GREYDirection direction, CGFloat length,
                                                  CGFloat *outRemainingAmountOrNull);

/**
 * Generates a touch path in the given @c view from @c startPoint to @c endPoint in view-relative
 * coordinates.
 *
 * @param window                        The window in which the touch path is generated.
 * @param startPointInWindowCoordinates The start point in screen coordinates.
 * @param endPointInWindowCoordinates   The end point in screen coordinates.
 * @param duration                      How long the gesture should last (in seconds).
 *
 * @return NSArray of CGPoints that denote the points in the touch path.
 */
NSArray<NSValue *> *GREYTouchPathForGestureBetweenPoints(CGPoint startPointInScreenCoordinates,
                                                         CGPoint endPointInScreenCoordinates,
                                                         CFTimeInterval duration);

/**
 * Generates a touch path in the @c window from the given @c startPoint and the given @c
 * endPoint.
 *
 * @param startPoint    The starting point for touch path.
 * @param endPoint      The end point for touch path.
 * @param cancelInertia A BOOL value indicating whether inertial movement should be cancelled.
 *
 * @return NSArray of CGPoints that denote the points in the touch path.
 */
NSArray<NSValue *> *GREYTouchPathForDragGestureInScreen(CGPoint startPoint, CGPoint endPoint,
                                                        BOOL cancelInertia);

/**
 * Generates a touch path rotating along a curved path along a circle of radius @c radius centered
 * at the specified @c center point, moving from angle @c startAngle to @c endAngle over the
 * specified @c duration.
 *
 * @param center        The point representing the enter of the circular path.
 * @param radius        The radius of the circular path (in screen points).
 * @param startAngle    The starting angle (in radians) measured counterclockwise from the
 *                      positive X axis.
 * @param endAngle      The end angle (in radians) measured similarly.
 * @param duration      The duration of the gesture.
 * @param cancelInertia A BOOL value indicating whether inertial movement should be cancelled.
 *
 * @return NSArray of CGPoints that denote the points in the touch path.
 */
NSArray<NSValue *> *GREYTouchPathForTwistGesture(CGPoint center, CGFloat radius, CGFloat startAngle,
                                                 CGFloat endAngle, CFTimeInterval duration,
                                                 BOOL cancelInertia);

/**
 * Calculates the deviation of a touch path generated by this util by comparing to the actual
 * trigerred scroll offset plus the remaining touch path. Specifically:
 *
 * Scroll Deviation = Generated Touch Path - (Acutal Scroll Content-offset +
 *                    Remaining Touch Path)
 *
 * Since iOS 15, the amount of the touch movement before the scroll being detected became variable,
 * which was seen more when keyboards were brought up. Once the scroll is detected, the remaining
 * touch movement still has precise effect on the scroll offset. This method is used to calculate
 * the deviation after the scroll being detected.
 *
 * @param touchPath          The touch path calculated by this util.
 * @param offset             The scroll view's content offset when the scroll is detected.
 * @param remainingTouchPath The suffix of @c touchPath that is not yet executed when the scroll
 *                           is detected.
 *
 * @return A CGVector representing the deviation of the scroll when @c remainingTouchPath is
 *         executed. The direction of the vector is from the expected content offset of the scroll
 *         view to the actual content offset of the scroll view.
 */
CGVector GREYDeviationBetweenTouchPathAndActualOffset(NSArray<NSValue *> *touchPath,
                                                      CGVector offset,
                                                      NSArray<NSValue *> *remainingTouchPath);

/**
 * Generates a new touch path based on the deviation of the current touch path.
 *
 * @note This method should be called for the @c touchPath, which already started by calling
 *       [GREYSyntheticEvents -beginTouchAtPoint:] but has not yet called [GREYSyntheticEvents
 *       -endTouchWithTimeout:]. By passing in the last injected touch point to @c currentTouchPoint
 *       and the deviation, this function produces a new touch path. See the documentation of the
 *       return value for usage.
 *
 * @param touchPath         The touch path calculated by this util.
 * @param deviation         The vector that represents the deviation of the scroll offset calculated
 *                          by this util.
 * @param currentTouchPoint The last completed touch point which is among the @c touchPath.
 * @param scrollView        The targeted UIScrollView for scroll action.
 *
 * @return NSArray of CGPoints as the new touch path. By dropping @c touchPath and injecting the new
 *         touch path, the deviation of the scroll offset will be eliminated. Note the first element
 *         of the result is always @c currentTouchPoint, so the next touch point should be the
 *         second element of this array. The result can be @c nil, when the new touch path cannot be
 *         adjusted to meet the safe green bounds. In this case, the caller should use a new touch
 *         injection to fix the deviation.
 */
NSArray<NSValue *> *GREYFixTouchPathDeviation(NSArray<NSValue *> *touchPath, CGVector deviation,
                                              CGPoint currentTouchPoint, UIScrollView *scrollView);
