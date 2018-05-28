//
// Copyright 2018 Google Inc.
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

#import "Action/GREYPreciseSwipeAction.h"

#import "Action/GREYPathGestureUtils.h"
#import "Additions/NSError+GREYAdditions.h"
#import "Additions/NSObject+GREYAdditions.h"
#import "Additions/NSString+GREYAdditions.h"
#import "Assertion/GREYAssertionDefines.h"
#import "Assertion/GREYAssertions+Internal.h"
#import "Common/GREYError.h"
#import "Common/GREYThrowDefines.h"
#import "Event/GREYSyntheticEvents.h"
#import "Matcher/GREYAllOf.h"
#import "Matcher/GREYMatcher.h"
#import "Matcher/GREYMatchers.h"
#import "Matcher/GREYNot.h"

@implementation GREYPreciseSwipeAction {
  /**
   *  The point where the swipe should begin.
   */
  CGPoint _startPoint;
  /**
   *  The point where the swipe should end.
   */
  CGPoint _endPoint;
  /**
   *  The duration within which the swipe action must be complete.
   */
  CFTimeInterval _duration;
}

- (instancetype)initWithStartPoint:(CGPoint)startPoint
                          endpoint:(CGPoint)endPoint
                          duration:(CFTimeInterval)duration {

    NSString *name =
        [NSString stringWithFormat:@"Precise swipe from %@ to %@ for duration %g",
                               NSStringFromCGPoint(startPoint),
                               NSStringFromCGPoint(endPoint),
                               duration];
    self = [super initWithName:name
                   constraints:grey_allOf(grey_interactable(),
                                          grey_not(grey_systemAlertViewShown()),
                                          grey_kindOfClass([UIView class]),
                                          grey_respondsToSelector(@selector(accessibilityFrame)),
                                          nil)];
    if (self) {
      _startPoint = startPoint;
      _endPoint = endPoint;
      _duration = duration;
    }
    return self;
}

#pragma mark - GREYAction

- (BOOL)perform:(id)element error:(__strong NSError **)errorOrNil {
  if (![self satisfiesConstraintsForElement:element error:errorOrNil]) {
    return NO;
  }
  CGRect accessibilityFrame = [element accessibilityFrame];
  CGPoint startPoint =
      CGPointMake(_startPoint.x + accessibilityFrame.origin.x,
                  _startPoint.y + accessibilityFrame.origin.y);
  CGPoint endPoint =
      CGPointMake(_endPoint.x + accessibilityFrame.origin.x,
                  _endPoint.y + accessibilityFrame.origin.y);

  UIWindow *window = [element window];
  if (!window) {
    if ([element isKindOfClass:[UIWindow class]]) {
      window = (UIWindow *)element;
    } else {
      NSString *errorDescription =
          [NSString stringWithFormat:@"Cannot swipe on view [V], as it has no window and "
                                     @"it isn't a window itself."];
      NSDictionary *glossary = @{ @"V" : [element grey_description]};
      GREYError *error;
      error = GREYErrorMake(kGREYSyntheticEventInjectionErrorDomain,
                            kGREYOrientationChangeFailedErrorCode,
                            errorDescription);
      error.descriptionGlossary = glossary;
      if (errorOrNil) {
        *errorOrNil = error;
      } else {
        [GREYAssertions grey_raiseExceptionNamed:kGREYGenericFailureException
                                exceptionDetails:@""
                                       withError:error];
      }

      return NO;
    }
  }
  NSArray *touchPath = [GREYPathGestureUtils touchPathForDragGestureWithStartPoint:startPoint
                                                                          endPoint:endPoint
                                                                     cancelInertia:NO];

  [GREYSyntheticEvents touchAlongPath:touchPath
                     relativeToWindow:window
                          forDuration:_duration
                           expendable:YES];
  return YES;
}

@end
