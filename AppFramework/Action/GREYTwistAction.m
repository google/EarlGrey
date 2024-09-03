//
// Copyright 2022 Google Inc.
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

#import "GREYTwistAction.h"

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
 * Reduce the magnitude of vector in the direction of twist action to make sure that it is minimum
 * of either height or width of the view.
 */
static CGFloat const kTwistScale = (CGFloat)0.8;

@implementation GREYTwistAction {
  /**
   * The duration within which the twist action must be completed.
   */
  CFTimeInterval _duration;
  /**
   * The angle of the end of the twist relative to its start. (Positive is
   * counterclockwise, to conform with iOS coordinate system norms.)
   */
  double _twistAngle;
}

- (instancetype)initWithDuration:(CFTimeInterval)duration twistAngle:(double)twistAngle {
  NSString *name = [NSString stringWithFormat:@"Twist for duration %g and angle %f degree",
                                              duration, (twistAngle * 180.0 / M_PI)];
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
    _duration = duration;
    _twistAngle = twistAngle;
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

    UIView *viewToTwist =
        [element isKindOfClass:[UIView class]] ? element : [element grey_viewContainingSelf];

    window =
        [viewToTwist isKindOfClass:[UIWindow class]] ? (UIWindow *)viewToTwist : viewToTwist.window;

    if (!window) {
      NSString *errorDescription =
          [NSString stringWithFormat:@"Cannot twist on this view as it has no window "
                                     @"and it isn't a window itself:\n%@",
                                     element];
      I_GREYPopulateError(error, kGREYTwistErrorDomain, kGREYTwistFailedErrorCode,
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
  CGRect twistActionFrame = CGRectIntersection(view.accessibilityFrame, window.bounds);
  if (CGRectIsNull(twistActionFrame)) {
    NSMutableString *errorDetails;
    [errorDetails appendFormat:@"\n%@: %@", kErrorDetailActionNameKey, self.name];
    [errorDetails appendFormat:@"\n%@: %@", kErrorDetailElementKey, [view grey_description]];
    [errorDetails appendFormat:@"\n%@: %@", kErrorDetailWindowKey, window.description];
    [errorDetails appendFormat:@"\n%@: %@", kErrorDetailRecoverySuggestionKey,
                               @"Make sure the element lies in the window"];

    NSString *reason =
        [NSString stringWithFormat:@"Cannot apply twist action on the element.\nError Details: %@",
                                   errorDetails];
    I_GREYPopulateError(error, kGREYTwistErrorDomain, kGREYTwistFailedErrorCode, reason);

    return nil;
  }

  // The center of the circle is computed from the center of the view.
  CGPoint centerPoint =
      CGPointMake(CGRectGetMidX(twistActionFrame), CGRectGetMidY(twistActionFrame));

  // Compute the radius of the circle as 80% (twistScale) of the distance from the center
  // point to the nearest edge of the view or screen, whichever is closer.
  CGFloat radius = MIN(twistActionFrame.size.width, twistActionFrame.size.height) * kTwistScale / 2.0;

  // If rotation is counterclockwise, start with fingers horizontally.  Otherwise, start with
  // fingers vertically.  This approximates how a right-handed person would perform the gesture.
  BOOL clockwise = (_twistAngle < 0);
  CGFloat startAngle1 = clockwise ? 0 : (M_PI / 2.0);           // right of center or above.
  CGFloat startAngle2 = clockwise ? M_PI : ((3 * M_PI) / 2.0);  // left of center or below.
  CGFloat endAngle1 = startAngle1 + _twistAngle;
  CGFloat endAngle2 = startAngle2 + _twistAngle;

  NSArray<NSValue *> *touchPathForUpperFinger =
      GREYTouchPathForTwistGesture(centerPoint, radius, startAngle1, endAngle1, _duration, YES);
  NSArray<NSValue *> *touchPathForLowerFinger =
      GREYTouchPathForTwistGesture(centerPoint, radius, startAngle2, endAngle2, _duration, YES);

  return @[ touchPathForUpperFinger, touchPathForLowerFinger ];
}

- (GREYActionType)type {
  return GREYActionTypeTwist;
}

#pragma mark - GREYDiagnosable

- (NSString *)diagnosticsID {
  return GREYCorePrefixedDiagnosticsID(@"twist");
}

@end
