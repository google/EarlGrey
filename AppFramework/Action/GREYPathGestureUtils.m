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

#import "GREYPathGestureUtils.h"

#include <objc/message.h>

#import "GREYThrowDefines.h"
#import "GREYConstants.h"
#import "CGGeometry+GREYUI.h"
#import "GREYUILibUtils.h"
#import "GREYVisibilityChecker.h"

/**
 * Refers to the minimum 10 points of scroll that is required for any scroll to be detected.
 * It is non-static to make it accessible to unit tests.
 */
const NSInteger kGREYScrollDetectionLength = 10;

/**
 * The minimum distance between any 2 adjacent points in the touch path.
 * In practice, this value seems to yield the best results by triggering the gestures more
 * accurately, even on slower machines.
 */
static const CGFloat kGREYDistanceBetweenTwoAdjacentPoints = 10.0f;

/**
 * The number of slow touches inserted between the next-to-last and last touch when canceling out
 * inertia.
 */
static const NSUInteger kNumSlowTouchesBetweenSecondLastAndLastTouch = 20;

/**
 * Returns whether the current direction is vertical or not.
 *
 * @param direction Current direction to be checked for verticalness.
 *
 * @return @c YES if the current direction is vertical, else @c NO.
 */
static BOOL GREYIsVerticalDirection(GREYDirection direction);

/**
 * Returns a point on the @c edge of the given @c rect.
 *
 * @param edge The edge of the given @c rect to get the point for.
 * @param rect The @c rect from which the point is being returned.
 *
 * @return A CGPoint on the chosen edge of the given @c rect.
 */
static CGPoint GREYPointOnEdgeOfRect(GREYContentEdge edge, CGRect rect);

/**
 * Standardizes the given @c rect and shrinks (or expands if inset is negative) the given @c rect
 * by the given @c insets. Note that if width/height is less than the required insets they are
 * set to zero.
 *
 * @param insets The insets to standardize the given @c rect.
 * @param rect   The rect to be standardized.
 *
 * @return The rect after being standardized.
 */
static CGRect GREYRectByAddingEdgeInsetsToRect(UIEdgeInsets insets, CGRect rect);

/**
 * Generates touch path between the given points with the option to cancel the inertia.
 *
 * @param startPoint    The start point of the touch path.
 * @param endPoint      The end point of the touch path.
 * @param duration      How long the gesture should last.
 *                      Can be NAN to indicate that path lengths of fixed magnitude should be used.
 * @param cancelInertia A check to nullify the inertia in the touch path.
 *
 * @return A touch path between the two points.
 */
static NSArray<NSValue *> *GREYGenerateTouchPath(CGPoint startPoint, CGPoint endPoint,
                                                 CFTimeInterval duration, BOOL cancelInertia);

#pragma mark - Public

NSArray<NSValue *> *GREYTouchPathForGestureInWindow(UIWindow *window,
                                                    CGPoint startPointInWindowCoordinates,
                                                    GREYDirection direction,
                                                    CFTimeInterval duration) {
  // Find an endpoint for gesture in window coordinates that gives us the longest path.
  CGPoint endPointInWindowCoords =
      GREYPointOnEdgeOfRect([GREYConstants edgeInDirectionFromCenter:direction],
                            [window convertRect:[GREYUILibUtils screen].bounds fromWindow:nil]);
  // Align the end point and create a touch path.
  if (GREYIsVerticalDirection(direction)) {
    endPointInWindowCoords.x = startPointInWindowCoordinates.x;
  } else {
    endPointInWindowCoords.y = startPointInWindowCoordinates.y;
  }
  return GREYGenerateTouchPath(startPointInWindowCoordinates, endPointInWindowCoords, duration, NO);
}

NSArray<NSValue *> *GREYTouchPathForDragGestureInScreen(CGPoint startPoint, CGPoint endPoint,
                                                        BOOL cancelInertia) {
  return GREYGenerateTouchPath(startPoint, endPoint, NAN, cancelInertia);
}

NSArray<NSValue *> *GREYTouchPathForGestureInView(UIView *view, CGPoint startPointPercents,
                                                  GREYDirection direction, CGFloat length,
                                                  CGFloat *outRemainingAmountOrNull) {
  GREYThrowInFunctionOnNilParameterWithMessage(
      isnan(startPointPercents.x) || (startPointPercents.x > 0 && startPointPercents.x < 1),
      @"startPointPercents must be NAN or in the range (0, 1) "
      @"exclusive");
  GREYThrowInFunctionOnNilParameterWithMessage(
      isnan(startPointPercents.y) || (startPointPercents.y > 0 && startPointPercents.y < 1),
      @"startPointPercents must be NAN or in the range (0, 1) "
      @"exclusive");
  GREYThrowInFunctionOnNilParameterWithMessage(
      length > 0, @"Scroll length must be positive and greater than zero.");

  // Pick a startPoint from the visible area of the given view.
  CGRect visibleArea = [GREYVisibilityChecker rectEnclosingVisibleAreaOfElement:view];
  visibleArea = [view.window convertRect:visibleArea fromWindow:nil];

  // Shave off the unsafe edges to ensure that we pick a valid starting point that is inside the
  // visible area.
  CGRect safeScreenBounds = [view.window convertRect:[GREYUILibUtils screen].bounds fromWindow:nil];
  if (CGRectIsEmpty(safeScreenBounds)) {
    return nil;
  }
  // In addition choose a rect that lies completely inside the visible area not on the edges.
  CGRect safeStartPointRect = GREYRectByAddingEdgeInsetsToRect(
      UIEdgeInsetsMake(1, 1, 1, 1), CGRectIntersection(visibleArea, safeScreenBounds));
  if (CGRectIsEmpty(safeStartPointRect)) {
    return nil;
  }
  GREYDirection reverseDirection = [GREYConstants reverseOfDirection:direction];
  GREYContentEdge edgeInReverseDirection =
      [GREYConstants edgeInDirectionFromCenter:reverseDirection];
  CGPoint startPoint = GREYPointOnEdgeOfRect(edgeInReverseDirection, safeStartPointRect);
  // Update start point if startPointPercents are provided.
  if (!isnan(startPointPercents.x)) {
    startPoint.x =
        safeStartPointRect.origin.x + safeStartPointRect.size.width * startPointPercents.x;
  }
  if (!isnan(startPointPercents.y)) {
    startPoint.y =
        safeStartPointRect.origin.y + safeStartPointRect.size.height * startPointPercents.y;
  }

  // Pick an end point that gives us maximum path length and align as per the direction.
  GREYContentEdge edgeClosestToEndPoint = [GREYConstants edgeInDirectionFromCenter:direction];
  CGPoint endPoint = GREYPointOnEdgeOfRect(edgeClosestToEndPoint, safeScreenBounds);
  CGFloat scrollAmountPossible;
  if (GREYIsVerticalDirection(direction)) {
    scrollAmountPossible = (CGFloat)fabs(endPoint.y - startPoint.y);
  } else {
    scrollAmountPossible = (CGFloat)fabs(endPoint.x - startPoint.x);
  }
  scrollAmountPossible -= kGREYScrollDetectionLength;
  if (scrollAmountPossible <= 0) {
    // Scroll view is narrow and it is too close to the edge.
    return nil;
  }

  CGFloat amountWillScroll = 0;
  CGFloat remainingAmount = 0;
  CGVector delta = [GREYConstants normalizedVectorFromDirection:direction];
  if (scrollAmountPossible > length) {
    // We have enough space to get the given amount of scroll by a single touch path.
    amountWillScroll = length;
    remainingAmount = 0;
  } else {
    // We will need multiple scrolls to get the required amount.
    amountWillScroll = scrollAmountPossible;
    remainingAmount = length - amountWillScroll;
  }

  if (outRemainingAmountOrNull) {
    *outRemainingAmountOrNull = remainingAmount;
  }
  endPoint = CGPointAddVector(startPoint,
                              CGVectorScale(delta, amountWillScroll + kGREYScrollDetectionLength));
  return GREYGenerateTouchPath(startPoint, endPoint, NAN, YES);
}

CGVector GREYDeviationBetweenTouchPathAndActualOffset(NSArray<NSValue *> *touchPath,
                                                      CGVector offset,
                                                      NSArray<NSValue *> *remainingTouchPath) {
  CGVector expectedTouchVector = CGVectorFromEndPoints(touchPath.firstObject.CGPointValue,
                                                       touchPath.lastObject.CGPointValue, NO);
  CGVector normalizedTouchVector = CGVectorNormalize(expectedTouchVector);
  // The original touch path has extra kGREYScrollDetectionLength movement that is not supposed to
  // contirbute to the scroll content offset.
  CGVector expectedEffectiveTouchVector = CGVectorAddVector(
      expectedTouchVector, CGVectorScale(normalizedTouchVector, -kGREYScrollDetectionLength));
  // The direction of the scroll content offset is the reverse of the effective touch.
  CGVector expectedScrollOffset = CGVectorScale(expectedEffectiveTouchVector, -1.0);

  // The scroll view already detected scroll gesture, so remaining touch path is always effective
  // to the scroll content offset, thus kGREYScrollDetectionLength is not applied here.
  CGVector remainingEffectiveTouchVector = CGVectorFromEndPoints(
      remainingTouchPath.firstObject.CGPointValue, remainingTouchPath.lastObject.CGPointValue, NO);
  CGVector remainingScrollOffset = CGVectorScale(remainingEffectiveTouchVector, -1.0);
  CGVector actualScrollOffset = CGVectorAddVector(offset, remainingScrollOffset);

  return CGVectorFromEndPoints(CGPointAddVector(CGPointZero, expectedScrollOffset),
                               CGPointAddVector(CGPointZero, actualScrollOffset), NO);
}

NSArray<NSValue *> *GREYFixTouchPathDeviation(NSArray<NSValue *> *touchPath, CGVector deviation,
                                              CGPoint currentTouchPoint, UIScrollView *scrollView) {
  CGPoint endPoint = touchPath.lastObject.CGPointValue;
  CGPoint adjustedEndPoint = CGPointAddVector(endPoint, deviation);

  CGRect safeScreenBounds = [scrollView.window convertRect:[GREYUILibUtils screen].bounds
                                                fromWindow:nil];
  if (!CGRectContainsPoint(safeScreenBounds, adjustedEndPoint)) {
    return nil;
  }

  return GREYGenerateTouchPath(currentTouchPoint, adjustedEndPoint, NAN, YES);
}

#pragma mark - Private

static BOOL GREYIsVerticalDirection(GREYDirection direction) {
  return direction == kGREYDirectionUp || direction == kGREYDirectionDown;
}

static CGPoint GREYPointOnEdgeOfRect(GREYContentEdge edge, CGRect rect) {
  CGVector vector =
      [GREYConstants normalizedVectorFromDirection:[GREYConstants directionFromCenterForEdge:edge]];
  return CGPointMake(CGRectCenter(rect).x + vector.dx * (rect.size.width / 2),
                     CGRectCenter(rect).y + vector.dy * (rect.size.height / 2));
}

static CGRect GREYRectByAddingEdgeInsetsToRect(UIEdgeInsets insets, CGRect rect) {
  rect = CGRectStandardize(rect);
  rect.origin.x += insets.left;
  rect.origin.y += insets.top;
  // Note that right edge and bottom edge must be adjusted for the change in origin along with
  // applying the given insets.
  if (rect.size.width > insets.right + insets.left) {
    rect.size.width -= insets.right + insets.left;
  } else {
    rect.size.width = 0;
  }
  if (rect.size.height > insets.bottom + insets.top) {
    rect.size.height -= insets.bottom + insets.top;
  } else {
    rect.size.height = 0;
  }
  return rect;
}

static NSArray<NSValue *> *GREYGenerateTouchPath(CGPoint startPoint, CGPoint endPoint,
                                                 CFTimeInterval duration, BOOL cancelInertia) {
  const CGVector deltaVector = CGVectorFromEndPoints(startPoint, endPoint, NO);
  const CGFloat pathLength = CGVectorLength(deltaVector);

  NSMutableArray *touchPath = [[NSMutableArray alloc] init];
  [touchPath addObject:[NSValue valueWithCGPoint:startPoint]];
  if (isnan(duration)) {
    // After the start point, rest of the path is divided into equal segments and a touch point is
    // created for each segment.
    NSUInteger totalPoints = (NSUInteger)(pathLength / kGREYDistanceBetweenTwoAdjacentPoints);

    if (totalPoints > 1) {
      // Compute delta for each point and create a path with it.
      CGFloat deltaX = (endPoint.x - startPoint.x) / totalPoints;
      CGFloat deltaY = (endPoint.y - startPoint.y) / totalPoints;
      // The first element of the touch point is already added outside of the loop. It's possible
      // that no additional touch point is added to the fast scroll path.
      for (NSUInteger i = 1; i < totalPoints; i++) {
        CGPoint touchPoint = CGPointMake(startPoint.x + (deltaX * i), startPoint.y + (deltaY * i));
        [touchPath addObject:[NSValue valueWithCGPoint:touchPoint]];
      }
    }
  } else {
    // Uses the kinematics equation for distance: d = a*t*t/2 + v*t
    const double initialVelocity = 0;
    const double initialDisplacement = (initialVelocity * duration);
    const double acceleration = (2 * (pathLength - initialDisplacement)) / (duration * duration);

    // Determine the angle which will be used for calculating individual x and y components of the
    // displacement.
    double angleFromXAxis;
    CGPoint deltaPoint = CGPointMake(endPoint.x - startPoint.x, endPoint.y - startPoint.y);
    if (deltaPoint.x == 0) {
      angleFromXAxis = deltaPoint.y > 0 ? M_PI_2 : -M_PI_2;
    } else if (deltaPoint.y == 0) {
      angleFromXAxis = deltaPoint.x > 0 ? 0 : -M_PI;
    } else {
      angleFromXAxis = atan2(deltaPoint.y, deltaPoint.x);
    }

    const double cosAngle = cos(angleFromXAxis);
    const double sinAngle = sin(angleFromXAxis);

    // Duration is divided into fixed intervals which depends on the frequency at which touches are
    // delivered. The first and last interval are always going to be the start and end touch points.
    // Through experiments, it was discovered that not all gestures trigger until there is a
    // minimum of kGREYDistanceBetweenTwoAdjacentPoints movement. For that reason, we find the
    // interval (after first touch point) at which displacement is at least
    // kGREYDistanceBetweenTwoAdjacentPoints and continue the gesture from there.
    // With this approach, touch points after first touch point is at least
    // kGREYDistanceBetweenTwoAdjacentPoints apart and gesture recognizers can detect them
    // correctly.
    const double interval = (1 / 60.0);
    // The last interval is always the last touch point so use 2nd to last as the end of loop below.
    const double interval_penultimate = (duration - interval);
    double interval_shift =
        sqrt(((2 * (kGREYDistanceBetweenTwoAdjacentPoints - initialDisplacement)) / acceleration));
    // Negative interval can't be shifted.
    if (interval_shift < 0) {
      interval_shift = 0;
    }
    // Boundary-align interval_shift to interval.
    interval_shift = ceil(interval_shift / interval) * interval;
    // interval_shift past 2nd last interval means only 2 touches will be injected.
    // Adjust it to the last interval.
    if (interval_shift > interval_penultimate) {
      interval_shift = interval_penultimate;
    }

    for (double time = interval_shift; time < interval_penultimate; time += interval) {
      double displacement = ((acceleration * time * time) / 2);
      displacement = displacement + (initialVelocity * time);

      double deltaX = displacement * cosAngle;
      double deltaY = displacement * sinAngle;
      CGPoint touchPoint =
          CGPointMake((CGFloat)(startPoint.x + deltaX), (CGFloat)(startPoint.y + deltaY));
      [touchPath addObject:[NSValue valueWithCGPoint:touchPoint]];
    }
  }

  NSValue *endPointValue = [NSValue valueWithCGPoint:endPoint];
  if (cancelInertia) {
    // To cancel inertia, slow down as approaching the end point. This is done by inserting a series
    // of points between the 2nd last and the last point.
    NSValue *secondLastValue = [touchPath lastObject];
    CGPoint secondLastPoint = [secondLastValue CGPointValue];
    CGVector secondLastToLastVector = CGVectorFromEndPoints(secondLastPoint, endPoint, NO);

    CGFloat slowTouchesVectorScale = (CGFloat)(1.0 / kNumSlowTouchesBetweenSecondLastAndLastTouch);
    CGVector slowTouchesVector = CGVectorScale(secondLastToLastVector, slowTouchesVectorScale);

    CGPoint slowTouchPoint = secondLastPoint;
    for (NSUInteger i = 0; i < (kNumSlowTouchesBetweenSecondLastAndLastTouch - 1); i++) {
      slowTouchPoint = CGPointAddVector(slowTouchPoint, slowTouchesVector);
      [touchPath addObject:[NSValue valueWithCGPoint:slowTouchPoint]];
    }
  }
  [touchPath addObject:endPointValue];
  return touchPath;
}

static NSArray<NSValue *> *GREYCircularTouchPath(CGPoint center, CGFloat radius, CGFloat startAngle,
                                                 CGFloat angleDelta, NSUInteger numberOfPoints) {
  NSMutableArray<NSValue *> *touchPath = [[NSMutableArray alloc] init];
  // The first element of the touch point is already added outside of the loop. It's possible
  // that no additional touch point is added to the fast scroll path.
  for (NSUInteger i = 0; i < numberOfPoints; i++) {
    CGFloat angleAtPoint = startAngle + (angleDelta * i);
    CGPoint touchPoint = CGPointOnCircle(angleAtPoint, center, radius);
    [touchPath addObject:[NSValue valueWithCGPoint:touchPoint]];
  }
  return touchPath;
}

#pragma mark - Public

NSArray<NSValue *> *GREYTouchPathForTwistGesture(CGPoint center, CGFloat radius, CGFloat startAngle,
                                                 CGFloat endAngle, CFTimeInterval duration,
                                                 BOOL cancelInertia) {
  // For an angle a = (2 * pi), the path length is (2 * pi * radius).  Thus, the
  // path length is equal to the radius times the difference in angle.
  const CGFloat arcAngle = endAngle - startAngle;
  const CGFloat pathLength = radius * fabs(arcAngle);

  NSMutableArray<NSValue *> *touchPath = [[NSMutableArray alloc] init];
  CGPoint startPoint = CGPointOnCircle(startAngle, center, radius);
  [touchPath addObject:[NSValue valueWithCGPoint:startPoint]];

  CGFloat semifinalArcAngle = startAngle;
  if (isnan(duration)) {
    // After the start point, rest of the path is divided into equal segments and a touch point is
    // created for each segment.
    NSUInteger totalPoints = (NSUInteger)(pathLength / kGREYDistanceBetweenTwoAdjacentPoints);

    if (totalPoints > 1) {
      // Compute delta for each point and create a path with it.
      CGFloat angleDelta = arcAngle / totalPoints;
      NSUInteger numberOfIntermediatePoints = totalPoints - 1;
      NSArray<NSValue *> *additionalPoints = GREYCircularTouchPath(
          center, radius, startAngle + angleDelta, angleDelta, numberOfIntermediatePoints);

      [touchPath addObjectsFromArray:additionalPoints];
      semifinalArcAngle = startAngle + (angleDelta * numberOfIntermediatePoints);
    }
  } else {
    // Uses the kinematics equation for distance: d = a*t*t/2 + v*t
    const double initialVelocity = 0;
    const double initialDisplacement = (initialVelocity * duration);
    const double acceleration = (2 * (arcAngle - initialDisplacement)) / (duration * duration);

    // Duration is divided into fixed intervals which depends on the frequency at which touches are
    // delivered. The first and last interval are always going to be the start and end touch points.
    // Through experiments, it was discovered that not all gestures trigger until there is a
    // minimum of kGREYDistanceBetweenTwoAdjacentPoints movement. For that reason, we find the
    // interval (after first touch point) at which displacement is at least
    // kGREYDistanceBetweenTwoAdjacentPoints and continue the gesture from there.
    // With this approach, touch points after first touch point is at least
    // kGREYDistanceBetweenTwoAdjacentPoints apart and gesture recognizers can detect them
    // correctly.
    const CFTimeInterval frameInterval = (1 / 60.0);
    // The last interval is always the last touch point so use 2nd to last as the end of loop below.
    const CFTimeInterval interval_penultimate = (duration - frameInterval);
    double interval_shift =
        sqrt(((2 * (kGREYDistanceBetweenTwoAdjacentPoints - initialDisplacement)) / acceleration));
    // Negative interval can't be shifted.
    if (interval_shift < 0) {
      interval_shift = 0;
    }
    // Boundary-align interval_shift to interval.
    interval_shift = ceil(interval_shift / frameInterval) * frameInterval;
    // interval_shift past 2nd last interval means only 2 touches will be injected.
    // Adjust it to the last interval.
    if (interval_shift > interval_penultimate) {
      interval_shift = interval_penultimate;
    }

    for (double time = interval_shift; time < interval_penultimate; time += frameInterval) {
      double displacement = ((acceleration * time * time) / 2);
      displacement = displacement + (initialVelocity * time);

      double angleDelta = displacement * arcAngle;
      CGFloat angleAtPoint = startAngle + angleDelta;
      CGPoint touchPoint = CGPointOnCircle(angleAtPoint, center, radius);
      [touchPath addObject:[NSValue valueWithCGPoint:touchPoint]];
      semifinalArcAngle = angleAtPoint;
    }
  }

  CGPoint endPoint = CGPointOnCircle(endAngle, center, radius);
  NSValue *endPointValue = [NSValue valueWithCGPoint:endPoint];
  if (cancelInertia) {
    // To cancel inertia, slow down as approaching the end point. This is done by inserting a series
    // of points between the 2nd last and the last point.
    NSUInteger numberOfIntermediatePoints = kNumSlowTouchesBetweenSecondLastAndLastTouch - 1;
    CGFloat angleDelta =
        (endAngle - semifinalArcAngle) / kNumSlowTouchesBetweenSecondLastAndLastTouch;
    NSArray<NSValue *> *additionalPoints = GREYCircularTouchPath(
        center, radius, semifinalArcAngle + angleDelta, angleDelta, numberOfIntermediatePoints);
    [touchPath addObjectsFromArray:additionalPoints];
  }
  [touchPath addObject:endPointValue];
  return touchPath;
}
