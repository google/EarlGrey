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

#import "GREYTapper.h"

#import "GREYAppError.h"
#import "GREYFailureScreenshotter.h"
#import "GREYSyntheticEvents.h"
#import "GREYSyncAPI.h"
#import "NSObject+GREYCommon.h"
#import "GREYThrowDefines.h"
#import "GREYConfigKey.h"
#import "GREYConfiguration.h"
#import "GREYError.h"
#import "GREYErrorConstants.h"
#import "CGGeometry+GREYUI.h"
#import "GREYElementHierarchy.h"

/**
 * Protocol for accessing _HitTestContext's private contextWithPoint:radius: method.
 * Required to access the UIResponder that should be used for touch injection for SwiftUI elements
 * in iOS 18+.
 */
@protocol _PrivateHitTestContext
+ (id)contextWithPoint:(struct CGPoint)arg1 radius:(double)arg2;
@end

/**
 * Protocol for accessing the UIResponder's private hitTest method.
 * Required to access the UIResponder that should be used for touch injection for SwiftUI elements
 * in iOS 18+.
 */
@protocol _PrivateUIResponder
- (id)_hitTestWithContext:(id)arg1;
@end

@implementation GREYTapper

+ (BOOL)tapOnElement:(id)element
        numberOfTaps:(NSUInteger)numberOfTaps
            location:(CGPoint)location
               error:(__strong NSError **)errorOrNil {
  GREYThrowOnFailedCondition(numberOfTaps > 0);

  __block UIView *viewToTap = nil;
  __block UIWindow *window = nil;
  grey_dispatch_sync_on_main_thread(^{
    viewToTap =
        ([element isKindOfClass:[UIView class]] ? element : [element grey_viewContainingSelf]);
    window = [viewToTap isKindOfClass:[UIWindow class]] ? (UIWindow *)viewToTap : viewToTap.window;
  });

  return [self tapOnWindow:window
                   element:element
              numberOfTaps:numberOfTaps
                  location:[self grey_tapPointForElement:element relativeLocation:location]
                     error:errorOrNil];
}

+ (BOOL)tapOnWindow:(UIWindow *)window
            element:(id)element
       numberOfTaps:(NSUInteger)numberOfTaps
           location:(CGPoint)location
              error:(__strong NSError **)errorOrNil {
  if (![GREYTapper grey_checkLocation:location
                     inBoundsOfWindow:window
                              element:element
                       forActionNamed:@"tap"
                                error:errorOrNil]) {
    return NO;
  }

  CFTimeInterval interactionTimeout = GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration);
  UIResponder *responder = [self grey_gestureContainer:element atLocation:location];
  for (NSUInteger i = 1; i <= numberOfTaps; i++) {
    @autoreleasepool {
      GREYPerformMultipleTap(location, window, i, interactionTimeout, responder);
    }
  }
  return YES;
}

+ (BOOL)longPressOnElement:(id)element
                  location:(CGPoint)location
                  duration:(CFTimeInterval)duration
                     error:(__strong NSError **)errorOrNil {
  __block UIView *view =
      [element isKindOfClass:[UIView class]] ? element : [element grey_viewContainingSelf];
  __block UIWindow *window = nil;
  grey_dispatch_sync_on_main_thread(^{
    window = [view isKindOfClass:[UIWindow class]] ? (UIWindow *)view : view.window;
  });
  CGPoint resolvedLocation = [self grey_tapPointForElement:element relativeLocation:location];

  if (![GREYTapper grey_checkLocation:resolvedLocation
                     inBoundsOfWindow:window
                              element:element
                       forActionNamed:@"long press"
                                error:errorOrNil]) {
    return NO;
  }

  CFTimeInterval interactionTimeout = GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration);
  NSArray<NSValue *> *touchPath = @[ [NSValue valueWithCGPoint:resolvedLocation] ];
  [GREYSyntheticEvents touchAlongPath:touchPath
                     relativeToWindow:window
                          forDuration:duration
                              timeout:interactionTimeout];
  return YES;
}

#pragma mark - Private

/**
 * Returns the SwiftUI specific @c UIResponder for @c element.
 *
 * For iOS 18+ Swift UI, the responder needs to be set to the UITouch event that's not always
 * the view. Using private _hitTestWithContext: method to retrieve the responder.
 *
 * See b/347429266 for more details.
 * @param element The element to retrieve the responder for.
 * @param location The location of the tap.
 *
 * @return The @c UIResponder&GestureRecognizerContainer for a given @c element at @c location.
 */
+ (UIResponder *)grey_gestureContainer:(id)element atLocation:(CGPoint)location {
  UIResponder *responder;
#if defined(__IPHONE_18_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_18_0
  static NSString *const kSwiftUIAccessiblityNodeClassName = @"SwiftUI.AccessibilityNode";
  if (![element isKindOfClass:NSClassFromString(kSwiftUIAccessiblityNodeClassName)]) {
    return nil;
  }
  if (![element respondsToSelector:@selector(accessibilityContainer)]) {
    return nil;
  }
  id container = [element accessibilityContainer];
  // _UIHitTestContext is a private class for an object used in UIResponder's
  // method that can retreive the UIResponder for a given point:
  // `_hitTestWithContext:` returning @c UIResponder&UIGestureRecognizerContainer.
  id context = [NSClassFromString(@"_UIHitTestContext") contextWithPoint:location radius:1.0];
  // We need to walk up the accessibility container chain until we find the one that
  // can retrieve the responder.
  while (!responder && container) {
    if ([container respondsToSelector:NSSelectorFromString(@"_hitTestWithContext:")]) {
      responder = [container _hitTestWithContext:context];
    }
    container = [container accessibilityContainer];
  }
#endif
  return responder;
}

/**
 * @return A tappable point that has the given @c location relative to the window of the
 *         @c element.
 */
+ (CGPoint)grey_tapPointForElement:(id)element relativeLocation:(CGPoint)location {
  __block CGPoint tapPoint;
  grey_dispatch_sync_on_main_thread(^{
    UIView *viewToTap =
        ([element isKindOfClass:[UIView class]] ? element : [element grey_viewContainingSelf]);
    UIWindow *window =
        ([viewToTap isKindOfClass:[UIWindow class]] ? (UIWindow *)viewToTap : viewToTap.window);

    if (viewToTap != element) {
      // Convert elementOrigin to parent's coordinates.
      CGPoint elementOrigin = [element accessibilityFrame].origin;
      elementOrigin = [window convertPoint:elementOrigin fromWindow:nil];
      elementOrigin = [viewToTap convertPoint:elementOrigin fromView:nil];
      elementOrigin.x += location.x;
      elementOrigin.y += location.y;
      tapPoint = [viewToTap convertPoint:elementOrigin toView:nil];
    } else {
      tapPoint = [viewToTap convertPoint:location toView:nil];
    }
  });
  return tapPoint;
}

/**
 * If the specified @c location is not in the bounds of the specified @c window for performing the
 * specified action, the mthod will return @c NO and if @ errorOrNil is provided, it is populated
 * with appropriate error information. Otherwise @c YES is returned.
 *
 * @param location        The location of the touch.
 * @param window          The window in which the action is being performed.
 * @param name            The name of the action causing the touch.
 * @param[out] errorOrNil The error set on failure. The error returned can be @c nil, signifying
 *                        success.
 *
 * @return @c YES if the @c location is in the bounds of the @c window, @c NO otherwise.
 */
+ (BOOL)grey_checkLocation:(CGPoint)location
          inBoundsOfWindow:(UIWindow *)window
                   element:(id)element
            forActionNamed:(NSString *)name
                     error:(__strong NSError **)errorOrNil {
  // Don't use frame because if transform property isn't identity matrix, the frame property is
  // undefined.
  __block NSString *windowBoundsString;
  grey_dispatch_sync_on_main_thread(^{
    if (!CGRectContainsPoint(window.bounds, location)) {
      windowBoundsString = NSStringFromCGRect(window.bounds);
    }
  });

  if (windowBoundsString) {
    NSString *nullLocationReason = @"";
    if (CGPointIsNull(location)) {
      nullLocationReason =
          @"The {nan, nan} point means that the element's frame does not have a point within "
          @"itself that a touch can be injected in as it is obscured. Consider adding the "
          @"grey_interactable() matcher to the selection matcher";
    }
    NSString *description =
        [NSString stringWithFormat:@"Cannot perform %@ at %@ as it is outside window's bounds %@. "
                                   @"%@.\n\nElement being tapped:\n%@",
                                   name, NSStringFromCGPoint(location), windowBoundsString,
                                   nullLocationReason, element];

    I_GREYPopulateError(errorOrNil, kGREYInteractionErrorDomain,
                        kGREYInteractionActionFailedErrorCode, description);

    return NO;
  }
  return YES;
}

@end
