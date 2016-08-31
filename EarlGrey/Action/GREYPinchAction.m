//
// Copyright 2016 Google Inc.
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

#import "Action/GREYPinchAction.h"

#import <OCHamcrest/HCStringDescription.h>
#include <tgmath.h>

#import "Additions/NSError+GREYAdditions.h"
#import "Additions/NSObject+GREYAdditions.h"
#import "Action/GREYPathGestureUtils.h"
#import "Assertion/GREYAssertionDefines.h"
#import "Event/GREYSyntheticEvents.h"
#import "Matcher/GREYAllOf.h"
#import "Matcher/GREYMatchers.h"
#import "Matcher/GREYNot.h"

/**
 *  The error domain for pinch action related errors.
 */
NSString *const kGREYPinchErrorDomain = @"com.google.earlgrey.PinchErrorDomain";
/**
 *  Reduce the magnitude of vector in the direction of pinch action to make sure that it is minimum
 *  of either height or width of the view.
 */
CGFloat const kPinchScale = (CGFloat)0.8;
/**
 * Angle of the vector in radians to which the pinch direction is pointing.
 * Using a default pinch angle of 30 degrees to closely match the average pinch angle of a natural
 * right handed pinch.
 */
CGFloat const kDefaultPinchAngle = (CGFloat)(30.0 * M_PI / 180.0);

@implementation GREYPinchAction {
  /**
   *  Pinch direction.
   */
  GREYPinchDirection _pinchDirection;
  /**
   *  The duration within which the pinch action must be completed.
   */
  CFTimeInterval _duration;
}

- (instancetype)initWithDirection:(GREYPinchDirection)pinchDirection
                         duration:(CFTimeInterval)duration {
  NSString *name = [NSString stringWithFormat:@"Pinch %@ for duration %g",
                        NSStringFromPinchDirection(pinchDirection), duration];
  self = [super initWithName:name
                 constraints:grey_allOf(grey_not(grey_systemAlertViewShown()),
                                        grey_interactable(),
                                        grey_respondsToSelector(@selector(accessibilityFrame)),
                                        nil)];
  if (self) {
    _pinchDirection = pinchDirection;
    _duration = duration;
  }
  return self;
}

#pragma mark - GREYAction

- (BOOL)perform:(id)element error:(__strong NSError **)errorOrNil {
  if (![self satisfiesConstraintsForElement:element error:errorOrNil]) {
    return NO;
  }
  UIView *viewToPinch = [element isKindOfClass:[UIView class]]
      ? element : [element grey_viewContainingSelf];

  UIWindow *window = [viewToPinch isKindOfClass:[UIWindow class]]
      ? (UIWindow *)viewToPinch : viewToPinch.window;

  if (!window) {
    NSString *errorDescription =
        @"Cannot pinch on view %@, as it has no window and it isn't a window itself.";
    [NSError grey_logOrSetOutReferenceIfNonNil:errorOrNil
                                    withDomain:kGREYPinchErrorDomain
                                          code:kGREYPinchFailedErrorCode
                          andDescriptionFormat:errorDescription, element];
    return NO;
  }

  CGRect pinchActionFrame = CGRectIntersection([element accessibilityFrame], window.bounds);
  NSAssert(!CGRectIsNull(pinchActionFrame), @"View frame to apply pinch, cannot be Null");

  // Outward pinch starts at the center of pinchActionFrame.
  // Inward pinch ends at the center of pinchActionFrame.
  CGPoint centerPoint = CGPointMake(CGRectGetMidX(pinchActionFrame),
                                    CGRectGetMidY(pinchActionFrame));

  // End and start points for the two pinch actions points.
  CGPoint endPoint1 = CGPointZero;
  CGPoint endPoint2 = CGPointZero;
  CGPoint startPoint1 = CGPointZero;
  CGPoint startPoint2 = CGPointZero;

  // Scale of the vector to obtain the start and end points from the center of the
  // pinchActionFrame. Make sure that the rotationVectorScale is minimum of the frame width and
  // height. Also decrease the scale length further.
  CGFloat rotationVectorScale = MIN(centerPoint.x, centerPoint.y) * kPinchScale;

  // Rotated points at the given pinch angle to determine start and end points.
  CGPoint rotatedPoint1 = [self grey_pointOnCircleAtAngle:kDefaultPinchAngle
                                                   center:centerPoint
                                                   radius:rotationVectorScale];
  CGPoint rotatedPoint2 = [self grey_pointOnCircleAtAngle:(kDefaultPinchAngle + (CGFloat)M_PI)
                                                   center:centerPoint
                                                   radius:rotationVectorScale];

  switch(_pinchDirection) {
    case kGREYPinchDirectionOutward:
      startPoint1 = centerPoint;
      startPoint2 = centerPoint;
      endPoint1 = rotatedPoint1;
      endPoint2 = rotatedPoint2;
      break;
    case kGREYPinchDirectionInward:
      startPoint1 = rotatedPoint1;
      startPoint2 = rotatedPoint2;
      endPoint1 = centerPoint;
      endPoint2 = centerPoint;
      break;
  }
  NSArray *touchPathInDirection1 =
      [GREYPathGestureUtils touchPathForPinchGestureWithStartPoint:startPoint1
                                                       andEndPoint:endPoint1];
  NSArray *touchPathInDirection2 =
      [GREYPathGestureUtils touchPathForPinchGestureWithStartPoint:startPoint2
                                                       andEndPoint:endPoint2];

  [GREYSyntheticEvents touchAlongMultiplePaths:@[ touchPathInDirection1, touchPathInDirection2 ]
                              relativeToWindow:window
                                   forDuration:_duration
                                    expendable:YES];
  return YES;
}

#pragma mark - private

/**
 *  Returns a point at an @c angle on a circle having @c center and @c radius.
 *
 *  @param angle   Angle to which a point is to be located on the given circle.
 *  @param center  Center of the circle.
 *  @param radius  Radius of the circle.
 */
- (CGPoint)grey_pointOnCircleAtAngle:(CGFloat)angle
                              center:(CGPoint)center
                              radius:(CGFloat)radius {
  return CGPointMake(center.x + (radius * cos(angle)),
                     center.y + (radius * sin(angle)));
}

@end
