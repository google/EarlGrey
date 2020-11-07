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

#import "GREYSwipeAction.h"

#import "GREYPathGestureUtils.h"
#import "NSObject+GREYApp.h"
#import "GREYAppError.h"
#import "GREYSyntheticEvents.h"
#import "GREYAllOf.h"
#import "GREYMatchers.h"
#import "GREYSyncAPI.h"
#import "NSObject+GREYCommon.h"
#import "GREYThrowDefines.h"
#import "GREYErrorConstants.h"
#import "NSError+GREYCommon.h"

@implementation GREYSwipeAction {
  /**
   * The direction in which the content must be scrolled.
   */
  GREYDirection _direction;
  /**
   * The duration within which the swipe action must be complete.
   */
  CFTimeInterval _duration;
  /**
   * Start point for the swipe specified as percentage of swipped element's accessibility frame.
   */
  CGPoint _startPercents;
}

- (instancetype)initWithDirection:(GREYDirection)direction
                         duration:(CFTimeInterval)duration
                     percentPoint:(CGPoint)percents {
  GREYThrowOnFailedConditionWithMessage(percents.x > 0.0f && percents.x < 1.0f,
                                        @"xOriginStartPercentage must be between 0 and 1, "
                                        @"exclusively");
  GREYThrowOnFailedConditionWithMessage(percents.y > 0.0f && percents.y < 1.0f,
                                        @"yOriginStartPercentage must be between 0 and 1, "
                                        @"exclusively");

  NSString *name = [NSString
      stringWithFormat:@"Swipe %@ for duration %g", NSStringFromGREYDirection(direction), duration];
  id<GREYMatcher> systemAlertShownMatcher = [GREYMatchers matcherForSystemAlertViewShown];
  NSArray *constraintMatchers = @[
    [GREYMatchers matcherForInteractable],
    [GREYMatchers matcherForNegation:systemAlertShownMatcher],
    [GREYMatchers matcherForKindOfClass:[UIView class]],
    [GREYMatchers matcherForRespondsToSelector:@selector(accessibilityFrame)],
  ];
  self = [super initWithName:name
                 constraints:[[GREYAllOf alloc] initWithMatchers:constraintMatchers]];
  if (self) {
    _direction = direction;
    _duration = duration;
    _startPercents = percents;
  }
  return self;
}

- (instancetype)initWithDirection:(GREYDirection)direction duration:(CFTimeInterval)duration {
  // TODO: Pick a visible point instead of picking the center of the view.
  return [self initWithDirection:direction duration:duration percentPoint:CGPointMake(0.5, 0.5)];
}

- (instancetype)initWithDirection:(GREYDirection)direction
                         duration:(CFTimeInterval)duration
                    startPercents:(CGPoint)startPercents {
  return [self initWithDirection:direction duration:duration percentPoint:startPercents];
}

#pragma mark - GREYAction

- (BOOL)perform:(id)element error:(__strong NSError **)error {
  __block NSArray *touchPath = nil;
  __block UIWindow *window = nil;
  grey_dispatch_sync_on_main_thread(^{
    if (![self satisfiesConstraintsForElement:element error:error]) {
      return;
    }

    window = [element window];
    if (!window) {
      if ([element isKindOfClass:[UIWindow class]]) {
        window = (UIWindow *)element;
      } else {
        NSString *errorDescription =
            [NSString stringWithFormat:@"Cannot swipe on this view as it has no window and "
                                       @"isn't a window itself:\n%@",
                                       [element grey_description]];
        *error =
            GREYErrorMakeWithHierarchy(kGREYSyntheticEventInjectionErrorDomain,
                                       kGREYOrientationChangeFailedErrorCode, errorDescription);
        return;
      }
    }

    touchPath = [self touchPath:element forWindow:window];
  });

  if (touchPath) {
    [GREYSyntheticEvents touchAlongPath:touchPath relativeToWindow:window forDuration:_duration];
    return YES;
  } else {
    return NO;
  }
}

- (NSArray *)touchPath:(UIView *)element forWindow:(UIWindow *)window {
  CGRect accessibilityFrame = element.accessibilityFrame;
  CGPoint startPoint =
      CGPointMake(accessibilityFrame.origin.x + accessibilityFrame.size.width * _startPercents.x,
                  accessibilityFrame.origin.y + accessibilityFrame.size.height * _startPercents.y);

  return [GREYPathGestureUtils touchPathForGestureWithStartPoint:startPoint
                                                    andDirection:_direction
                                                     andDuration:_duration
                                                        inWindow:window];
}

- (BOOL)shouldRunOnMainThread {
  return NO;
}

#pragma mark - GREYDiagnosable

- (NSString *)diagnosticsID {
  return GREYCorePrefixedDiagnosticsID(@"swipe");
}

@end
