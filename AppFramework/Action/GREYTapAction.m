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

#import "GREYTapAction.h"

#import "GREYBaseAction.h"
#import "GREYTapper.h"
#import "NSObject+GREYApp.h"
#import "GREYAppError.h"
#import "GREYFailureScreenshotter.h"
#import "GREYAllOf.h"
#import "GREYAnyOf.h"
#import "GREYMatchers.h"
#import "GREYSyncAPI.h"
#import "NSObject+GREYCommon.h"
#import "GREYFatalAsserts.h"
#import "GREYThrowDefines.h"
#import "GREYError.h"
#import "GREYErrorConstants.h"
#import "GREYConstants.h"
#import "GREYDiagnosable.h"
#import "GREYLogger.h"
#import "GREYMatcher.h"
#import "CGGeometry+GREYUI.h"
#import "GREYElementHierarchy.h"
#import "GREYVisibilityChecker.h"

@implementation GREYTapAction {
  /**
   * The type of tap action being performed.
   */
  GREYTapType _type;
  /**
   * The number of taps constituting the action.
   */
  NSUInteger _numberOfTaps;
  /**
   * The duration of the tap action.
   */
  CFTimeInterval _duration;
  /**
   * The location for the tap action to happen.
   */
  CGPoint _tapLocation;
}

- (instancetype)initWithType:(GREYTapType)tapType {
  return [self initWithType:tapType numberOfTaps:1 duration:0.0f];
}

- (instancetype)initWithType:(GREYTapType)tapType numberOfTaps:(NSUInteger)numberOfTaps {
  return [self initWithType:tapType numberOfTaps:numberOfTaps duration:0.0f];
}

- (instancetype)initWithType:(GREYTapType)tapType
                numberOfTaps:(NSUInteger)numberOfTaps
                    location:(CGPoint)tapLocation {
  return [self initWithType:tapType numberOfTaps:numberOfTaps duration:0.0f location:tapLocation];
}

- (instancetype)initLongPressWithDuration:(CFTimeInterval)duration {
  return [self initLongPressWithDuration:duration location:GREYCGPointNull];
}

- (instancetype)initLongPressWithDuration:(CFTimeInterval)duration location:(CGPoint)location {
  return [self initWithType:kGREYTapTypeLong numberOfTaps:1 duration:duration location:location];
}

- (instancetype)initWithType:(GREYTapType)tapType
                numberOfTaps:(NSUInteger)numberOfTaps
                    duration:(CFTimeInterval)duration {
  return [self initWithType:tapType
               numberOfTaps:numberOfTaps
                   duration:duration
                   location:GREYCGPointNull];
}

- (instancetype)initWithType:(GREYTapType)tapType
                numberOfTaps:(NSUInteger)numberOfTaps
                    duration:(CFTimeInterval)duration
                    location:(CGPoint)tapLocation {
  GREYThrowOnFailedConditionWithMessage(numberOfTaps > 0,
                                        @"You cannot initialize a tap action with zero taps.");

  NSString *name = [GREYTapAction grey_actionNameWithTapType:tapType
                                                    duration:duration
                                                numberOfTaps:numberOfTaps];
  NSArray<id<GREYMatcher>> *anyOfMatchers = @[
    [GREYMatchers matcherForAccessibilityElement],
    [GREYMatchers matcherForKindOfClass:[UIView class]],
  ];
  id<GREYMatcher> systemAlertShownMatcher = [GREYMatchers matcherForSystemAlertViewShown];
  id<GREYMatcher> systemAlertNotShownMatcher =
      [GREYMatchers matcherForNegation:systemAlertShownMatcher];
  NSArray<id<GREYMatcher>> *constraintMatchers = @[
    systemAlertNotShownMatcher,
    [[GREYAnyOf alloc] initWithMatchers:anyOfMatchers],
  ];
  self = [super initWithName:name
                 constraints:[[GREYAllOf alloc] initWithMatchers:constraintMatchers]];
  if (self) {
    _type = tapType;
    _numberOfTaps = numberOfTaps;
    _duration = duration;
    _tapLocation = tapLocation;
  }
  return self;
}

#pragma mark - GREYAction protocol

#if TARGET_OS_IOS
- (BOOL)satisfiesConstraintsForElement:(id)element error:(__strong NSError **)error {
  if (![super satisfiesConstraintsForElement:element error:error]) {
    return NO;
  }

  if ([element isKindOfClass:[UISwitch class]]) {
    GREYLog(
        @"Warning: Use grey_turnSwitchOn(BOOL) to enable/disable UISwitch instead of grey_tap(). "
        @"Using grey_tap() on UISwitch could lead to flaky result.");
  }
  return YES;
}
#endif

- (BOOL)perform:(id)element error:(__strong NSError **)error {
  __block BOOL satisfiesContraints = NO;
  grey_dispatch_sync_on_main_thread(^{
    satisfiesContraints = [self satisfiesConstraintsForElement:element error:error];
  });
  if (!satisfiesContraints) {
    return NO;
  }
  switch (_type) {
    case kGREYTapTypeShort:
    case kGREYTapTypeMultiple: {
      return [GREYTapper tapOnElement:element
                         numberOfTaps:_numberOfTaps
                             location:[self grey_resolvedTapLocationForElement:element]
                                error:error];
    }
    case kGREYTapTypeKBKey: {
      // Retrieving the accessibility activation point for a keyboard key is tricky due to window
      // transforms. Sending the tap directly to its windows is overall simpler.
      __block UIWindow *window = nil;
      grey_dispatch_sync_on_main_thread(^{
        window = [element grey_viewContainingSelf].window;
      });
      if (!window) {
        NSString *description =
            [NSString stringWithFormat:@"Element is not attached to a window:\n%@",
                                       [element grey_description]];
        I_GREYPopulateError(error, kGREYInteractionErrorDomain,
                            kGREYInteractionActionFailedErrorCode, description);
        return NO;
      }
      return [GREYTapper tapOnWindow:window
                             element:element
                        numberOfTaps:_numberOfTaps
                            location:[element grey_accessibilityActivationPointInWindowCoordinates]
                               error:error];
    }
    case kGREYTapTypeLong: {
      return [GREYTapper longPressOnElement:element
                                   location:[self grey_resolvedTapLocationForElement:element]
                                   duration:_duration
                                      error:error];
    }
  }

  NSString *description = [NSString stringWithFormat:@"Unknown tap type: %ld", (long)_type];

  I_GREYPopulateError(error, kGREYInteractionErrorDomain, kGREYInteractionActionFailedErrorCode,
                      description);

  return NO;
}

#pragma mark - Private

+ (NSString *)grey_actionNameWithTapType:(GREYTapType)tapType
                                duration:(CFTimeInterval)duration
                            numberOfTaps:(NSUInteger)numberOfTaps {
  switch (tapType) {
    case kGREYTapTypeShort:
      return @"Tap";
    case kGREYTapTypeMultiple:
      return [NSString stringWithFormat:@"Tap %ld times", (long)numberOfTaps];
    case kGREYTapTypeLong:
      return [NSString stringWithFormat:@"Long Press for %f seconds", duration];
    case kGREYTapTypeKBKey:
      return [NSString stringWithFormat:@"Tap on keyboard key"];
  }
  GREYFatalAssertWithMessage(NO, @"Unknown tapType %ld was provided", (long)tapType);
  return nil;
}

/**
 * @return A tappable location as usable by this action for the given @c element.
 */
- (CGPoint)grey_resolvedTapLocationForElement:(id)element {
  __block CGPoint tapPoint = _tapLocation;
  if (CGPointIsNull(_tapLocation)) {
    grey_dispatch_sync_on_main_thread(^{
      tapPoint = GREYVisibleInteractionPointForElement(element);
    });
  }
  return tapPoint;
}

#pragma mark - GREYDiagnosable

- (NSString *)diagnosticsID {
  return GREYCorePrefixedDiagnosticsID(@"tap");
}

@end
