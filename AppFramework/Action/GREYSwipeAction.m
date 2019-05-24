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

#import "AppFramework/Action/GREYSwipeAction.h"

#import "AppFramework/Action/GREYPathGestureUtils.h"
#import "AppFramework/Additions/NSException+GREYApp.h"
#import "AppFramework/Additions/NSObject+GREYApp.h"
#import "AppFramework/Error/GREYAppError.h"
#import "AppFramework/Error/GREYAppFailureHandler.h"
#import "AppFramework/Event/GREYSyntheticEvents.h"
#import "AppFramework/Matcher/GREYAllOf.h"
#import "AppFramework/Matcher/GREYMatchers.h"
#import "AppFramework/Matcher/GREYNot.h"
#import "AppFramework/Synchronization/GREYSyncAPI.h"
#import "CommonLib/Additions/NSObject+GREYCommon.h"
#import "CommonLib/Additions/NSString+GREYCommon.h"
#import "CommonLib/Assertion/GREYThrowDefines.h"
#import "CommonLib/Error/GREYErrorConstants.h"
#import "CommonLib/Error/NSError+GREYCommon.h"
#import "CommonLib/Exceptions/GREYFrameworkException.h"

@implementation GREYSwipeAction {
  /**
   *  The direction in which the content must be scrolled.
   */
  GREYDirection _direction;
  /**
   *  The duration within which the swipe action must be complete.
   */
  CFTimeInterval _duration;
  /**
   *  Start point for the swipe specified as percentage of swipped element's accessibility frame.
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
    [[GREYNot alloc] initWithMatcher:systemAlertShownMatcher],
    [GREYMatchers matcherForKindOfClass:[UIView class]],
    [GREYMatchers matcherForRespondsToSelector:@selector(accessibilityFrame)],
  ];
  self =
      [super initWithName:name constraints:[[GREYAllOf alloc] initWithMatchers:constraintMatchers]];
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
            [NSString stringWithFormat:
                          @"Cannot swipe on view [V], as it has no window and "
                          @"it isn't a window itself."];
        NSDictionary *glossary = @{@"V" : [element grey_description]};
        GREYError *injectionError =
            GREYErrorMakeWithHierarchy(kGREYSyntheticEventInjectionErrorDomain,
                                       kGREYOrientationChangeFailedErrorCode, errorDescription);
        injectionError.descriptionGlossary = glossary;
        *error = injectionError;
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

@end
