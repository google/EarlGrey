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

#import "GREYMultiFingerSwipeAction.h"

#import "GREYPathGestureUtils.h"
#import "NSObject+GREYApp.h"
#import "GREYAppError.h"
#import "GREYSyntheticEvents.h"
#import "GREYAllOf.h"
#import "GREYMatchers.h"
#import "GREYSyncAPI.h"
#import "NSObject+GREYCommon.h"
#import "GREYFatalAsserts.h"
#import "GREYErrorConstants.h"
#import "NSError+GREYCommon.h"

@implementation GREYMultiFingerSwipeAction {
  /**
   * The direction in which the content must be scrolled.
   */
  GREYDirection _direction;
  /**
   * The duration within which the swipe action must be complete.
   */
  CFTimeInterval _duration;
  /**
   * Start point for the swipe specified as a percentage of the swipped element's accessibility
   * frame.
   */
  CGPoint _startPercents;
  /**
   * Number of parallel swipes.
   */
  NSUInteger _numberOfFingers;
}

- (instancetype)initWithDirection:(GREYDirection)direction
                         duration:(CFTimeInterval)duration
                  numberOfFingers:(NSUInteger)numberOfFingers {
  return [self initWithDirection:direction
                        duration:duration
                 numberOfFingers:numberOfFingers
                   startPercents:CGPointMake(0.5, 0.5)];
}

- (instancetype)initWithDirection:(GREYDirection)direction
                         duration:(CFTimeInterval)duration
                  numberOfFingers:(NSUInteger)numberOfFingers
                    startPercents:(CGPoint)startPercents {
  GREYFatalAssertWithMessage(startPercents.x > 0.0f && startPercents.x < 1.0f,
                             @"percents.x must be between 0 and 1, exclusive.");
  GREYFatalAssertWithMessage(startPercents.y > 0.0f && startPercents.y < 1.0f,
                             @"percents.y must be between 0 and 1, exclusive.");
  GREYFatalAssertWithMessage(numberOfFingers > 1 && numberOfFingers <= 4,
                             @"numberOfFingers must be between 2 and 4 inclusive. "
                             @"For single touch use the single touch APIs "
                             @"(grey_swipeFastInDirection etc).");

  NSString *name = [NSString
      stringWithFormat:@"Swipe %@ for duration %g", NSStringFromGREYDirection(direction), duration];
  id<GREYMatcher> systemAlertShownMatcher = [GREYMatchers matcherForSystemAlertViewShown];
  NSArray *constraintMatchers = @[
    [GREYMatchers matcherForInteractable],
    [GREYMatchers matcherForNegation:systemAlertShownMatcher],
    [GREYMatchers matcherForKindOfClass:[UIView class]],
    [GREYMatchers matcherForRespondsToSelector:@selector(accessibilityFrame)]
  ];
  self = [super initWithName:name
                 constraints:[[GREYAllOf alloc] initWithMatchers:constraintMatchers]];
  if (self) {
    _direction = direction;
    _duration = duration;
    _numberOfFingers = numberOfFingers;
    _startPercents = startPercents;
  }
  return self;
}

#pragma mark - GREYAction

- (BOOL)perform:(id)element error:(__strong NSError **)error {
  __block UIWindow *window = nil;
  NSMutableArray *multiTouchPaths = [[NSMutableArray alloc] init];
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
            [NSString stringWithFormat:
                          @"Cannot perform multi-finger swipe on the following view, as it has "
                          @"no window and it isn't a window itself:"
                          @"%@", [element grey_description]];
        I_GREYPopulateError(error, kGREYSyntheticEventInjectionErrorDomain,
                                 kGREYOrientationChangeFailedErrorCode, errorDescription);
        return;
      }
    }

    CGRect accessibilityFrame = [element accessibilityFrame];

    for (NSUInteger i = 0; i < self->_numberOfFingers; i++) {
      CGFloat xOffset, yOffset;
      switch (self->_direction) {
        case kGREYDirectionDown:
        case kGREYDirectionUp:
          xOffset = (CGFloat)i * 10;
          yOffset = 0.0;
          break;

        case kGREYDirectionLeft:
        case kGREYDirectionRight:
          xOffset = 0.0;
          yOffset = (CGFloat)i * 10;
          break;
      }

      CGFloat xStartPoint = xOffset + CGRectGetMaxX(accessibilityFrame) * self->_startPercents.x;
      CGFloat yStartPoint = yOffset + CGRectGetMaxY(accessibilityFrame) * self->_startPercents.y;
      CGPoint startPoint = CGPointMake(xStartPoint, yStartPoint);
      NSArray *touchPath = [GREYPathGestureUtils touchPathForGestureWithStartPoint:startPoint
                                                                      andDirection:self->_direction
                                                                       andDuration:self->_duration
                                                                          inWindow:window];

      [multiTouchPaths addObject:touchPath];
    }
  });

  if (multiTouchPaths.count > 0) {
    [GREYSyntheticEvents touchAlongMultiplePaths:multiTouchPaths
                                relativeToWindow:window
                                     forDuration:_duration];
    return YES;
  } else {
    return NO;
  }
}

#pragma mark - GREYDiagnosable

- (NSString *)diagnosticsID {
  return GREYCorePrefixedDiagnosticsID(@"multiFingerSwipe");
}

@end
