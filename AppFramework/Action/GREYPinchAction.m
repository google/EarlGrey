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

#import "GREYPinchAction.h"

#include <tgmath.h>

#import "GREYPathGestureUtils.h"
#import "GREYAppError.h"
#import "GREYFailureScreenshotter.h"
#import "GREYSyntheticEvents.h"
#import "GREYAllOf.h"
#import "GREYMatchers.h"
#import "GREYSyncAPI.h"
#import "NSObject+GREYCommon.h"
#import "GREYConfigKey.h"
#import "GREYConfiguration.h"
#import "GREYError.h"
#import "GREYErrorConstants.h"
#import "GREYConstants.h"
#import "GREYDiagnosable.h"
#import "GREYElementHierarchy.h"

/**
 * Reduce the magnitude of vector in the direction of pinch action to make sure that it is minimum
 * of either height or width of the view.
 */
static CGFloat const kPinchScale = (CGFloat)0.8;

@implementation GREYPinchAction {
  /**
   * Pinch direction.
   */
  GREYPinchDirection _pinchDirection;
  /**
   * The duration within which the pinch action must be completed.
   */
  CFTimeInterval _duration;
  /**
   * The angle in which in the pinch direction in pointing.
   */
  double _pinchAngle;
}

- (instancetype)initWithDirection:(GREYPinchDirection)pinchDirection
                         duration:(CFTimeInterval)duration
                       pinchAngle:(double)pinchAngle {
  NSString *name = [NSString stringWithFormat:@"Pinch %@ for duration %g and angle %f degree",
                                              NSStringFromPinchDirection(pinchDirection), duration,
                                              (pinchAngle * 180.0 / M_PI)];
  id<GREYMatcher> systemAlertShownMatcher = [GREYMatchers matcherForSystemAlertViewShown];
  NSArray *constraintMatchers = @[
    [GREYMatchers matcherForNegation:systemAlertShownMatcher],
    [GREYMatchers matcherForRespondsToSelector:@selector(accessibilityFrame)],
    [GREYMatchers matcherForUserInteractionEnabled],
    [GREYMatchers matcherForInteractable],
  ];
  self = [super initWithName:name
                 constraints:[[GREYAllOf alloc] initWithMatchers:constraintMatchers]];
  if (self) {
    _pinchDirection = pinchDirection;
    _duration = duration;
    _pinchAngle = pinchAngle;
  }
  return self;
}

#pragma mark - GREYAction

- (BOOL)perform:(id)element error:(__strong NSError **)error {
  __block UIWindow *window = nil;
  __block NSArray *touchPaths = nil;
  grey_dispatch_sync_on_main_thread(^{
    if (![self satisfiesConstraintsForElement:element error:error]) {
      return;
    }

    UIView *viewToPinch =
        [element isKindOfClass:[UIView class]] ? element : [element grey_viewContainingSelf];

    window =
        [viewToPinch isKindOfClass:[UIWindow class]] ? (UIWindow *)viewToPinch : viewToPinch.window;

    if (!window) {
      NSString *errorDescription =
          [NSString stringWithFormat:@"Cannot pinch on this view as it has no window "
                                     @"and it isn't a window itself:\n%@",
                                     element];
      I_GREYPopulateError(error, kGREYPinchErrorDomain, kGREYPinchFailedErrorCode,
                          errorDescription);
      return;
    }

    touchPaths = [self calculateTouchPaths:element window:window error:error];
  });

  if (touchPaths) {
    CFTimeInterval interactionTimeout =
        GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration);
    [GREYSyntheticEvents touchAlongMultiplePaths:touchPaths
                                relativeToWindow:window
                                     forDuration:_duration
                                         timeout:interactionTimeout];
  }

  return touchPaths != nil;
}

- (NSArray *)calculateTouchPaths:(UIView *)view
                          window:(UIWindow *)window
                           error:(__strong NSError **)error {
  CGRect pinchActionFrame = CGRectIntersection(view.accessibilityFrame, window.bounds);
  if (CGRectIsNull(pinchActionFrame)) {
    NSMutableString *errorDetails;
    [errorDetails appendFormat:@"\n%@: %@", kErrorDetailActionNameKey, self.name];
    [errorDetails appendFormat:@"\n%@: %@", kErrorDetailElementKey, [view grey_description]];
    [errorDetails appendFormat:@"\n%@: %@", kErrorDetailWindowKey, window.description];
    [errorDetails appendFormat:@"\n%@: %@", kErrorDetailRecoverySuggestionKey,
                               @"Make sure the element lies in the window"];

    NSString *reason =
        [NSString stringWithFormat:@"Cannot apply pinch action on the element.\nError Details: %@",
                                   errorDetails];
    I_GREYPopulateError(error, kGREYPinchErrorDomain, kGREYPinchFailedErrorCode, reason);

    return nil;
  }

  // Outward pinch starts at the center of pinchActionFrame.
  // Inward pinch ends at the center of pinchActionFrame.
  CGPoint centerPoint =
      CGPointMake(CGRectGetMidX(pinchActionFrame), CGRectGetMidY(pinchActionFrame));

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
  CGPoint rotatedPoint1 =
      [self grey_pointOnCircleAtAngle:_pinchAngle center:centerPoint radius:rotationVectorScale];
  CGPoint rotatedPoint2 = [self grey_pointOnCircleAtAngle:(_pinchAngle + M_PI)
                                                   center:centerPoint
                                                   radius:rotationVectorScale];

  switch (_pinchDirection) {
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

  // Based on the @c GREYPinchDirection two touch paths are required to generate a pinch gesture
  // If the pinch direction is @c kGREYPinchDirectionOutward then the two touch paths have their
  // starting points as the center of the view for the gesture and the ending points are on the
  // circle having the touch path as the radius. Similarly when pinch direction is
  // @c kGREYPinchDirectionInward then the two touch paths have starting points on the circle
  // having the touch path as the radius and ending points are the center of the view under
  // test.
  NSArray<NSValue *> *touchPathInDirection1 =
      GREYTouchPathForDragGestureInScreen(startPoint1, endPoint1, NO);
  NSArray<NSValue *> *touchPathInDirection2 =
      GREYTouchPathForDragGestureInScreen(startPoint2, endPoint2, NO);
  return @[ touchPathInDirection1, touchPathInDirection2 ];
}

#pragma mark - private

/**
 * Returns a point at an @c angle on a circle having @c center and @c radius.
 *
 * @param angle  Angle to which a point is to be located on the given circle.
 * @param center Center of the circle.
 * @param radius Radius of the circle.
 */
- (CGPoint)grey_pointOnCircleAtAngle:(double)angle center:(CGPoint)center radius:(CGFloat)radius {
  return CGPointMake(center.x + (CGFloat)(radius * cos(angle)),
                     center.y + (CGFloat)(radius * sin(angle)));
}

#pragma mark - GREYDiagnosable

- (NSString *)diagnosticsID {
  return GREYCorePrefixedDiagnosticsID(@"pinch");
}

@end
