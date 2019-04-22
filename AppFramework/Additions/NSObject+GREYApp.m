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

#import "AppFramework/Additions/NSObject+GREYApp.h"

#include <objc/runtime.h>

#import "AppFramework/IdlingResources/GREYTimedIdlingResource.h"
#import "AppFramework/Synchronization/GREYSyncAPI.h"
#import "CommonLib/Additions/NSObject+GREYCommon.h"
#import "CommonLib/Assertion/GREYFatalAsserts.h"
#import "CommonLib/Config/GREYConfiguration.h"
#import "CommonLib/GREYConstants.h"
#import "CommonLib/GREYSwizzler.h"
#import "UILib/GREYElementHierarchy.h"

@implementation NSObject (GREYApp)

+ (void)load {
  GREYSwizzler *swizzler = [[GREYSwizzler alloc] init];
  BOOL swizzleSuccess =
      [swizzler swizzleClass:self
          replaceClassMethod:@selector(cancelPreviousPerformRequestsWithTarget:)
                  withMethod:@selector(greyswizzled_cancelPreviousPerformRequestsWithTarget:)];
  GREYFatalAssertWithMessage(swizzleSuccess,
                             @"Cannot swizzle NSObject::"
                             @"cancelPreviousPerformRequestsWithTarget:");

  SEL swizzledSEL =
      @selector(greyswizzled_cancelPreviousPerformRequestsWithTarget:selector:object:);
  swizzleSuccess =
      [swizzler swizzleClass:self
          replaceClassMethod:@selector(cancelPreviousPerformRequestsWithTarget:selector:object:)
                  withMethod:swizzledSEL];
  GREYFatalAssertWithMessage(swizzleSuccess,
                             @"Cannot swizzle NSObject::"
                             @"cancelPreviousPerformRequestsWithTarget:selector:object:");

  swizzledSEL = @selector(greyswizzled_performSelector:withObject:afterDelay:inModes:);
  swizzleSuccess = [swizzler swizzleClass:self
                    replaceInstanceMethod:@selector(performSelector:withObject:afterDelay:inModes:)
                               withMethod:swizzledSEL];
  GREYFatalAssertWithMessage(swizzleSuccess,
                             @"Cannot swizzle "
                             @"NSObject::performSelector:withObject:afterDelay:inModes");
}

- (NSString *)grey_stateTrackerDescription {
  return [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self];
}

- (NSString *)grey_recursiveDescription {
  if ([self grey_isWebAccessibilityElement]) {
    return [GREYElementHierarchy hierarchyStringForElement:[self grey_viewContainingSelf]];
  } else if ([self isKindOfClass:[UIView class]] ||
             [self respondsToSelector:@selector(accessibilityContainer)]) {
    return [GREYElementHierarchy hierarchyStringForElement:self];
  } else {
    GREYFatalAssertWithMessage(NO,
                               @"grey_recursiveDescription made on an element that is not a valid "
                               @"UI element: %@",
                               self);
    return nil;
  }
}

- (CGPoint)grey_accessibilityActivationPointInWindowCoordinates {
  UIView *view =
      [self isKindOfClass:[UIView class]] ? (UIView *)self : [self grey_viewContainingSelf];
  GREYFatalAssertWithMessage(view, @"Corresponding UIView could not be found for UI element %@",
                             self);

  // Convert activation point from screen coordinates to window coordinates.
  if ([view isKindOfClass:[UIWindow class]]) {
    return [(UIWindow *)view convertPoint:self.accessibilityActivationPoint fromWindow:nil];
  } else {
    __block CGPoint returnPoint = CGPointZero;
    grey_dispatch_sync_on_main_thread(^{
      returnPoint = [view.window convertPoint:self.accessibilityActivationPoint fromWindow:nil];
    });
    return returnPoint;
  }
}

- (CGPoint)grey_accessibilityActivationPointRelativeToFrame {
  CGRect axFrame = [self accessibilityFrame];
  CGPoint axPoint = [self accessibilityActivationPoint];
  return CGPointMake(axPoint.x - axFrame.origin.x, axPoint.y - axFrame.origin.y);
}

#pragma mark - Swizzled Implementation

+ (void)greyswizzled_cancelPreviousPerformRequestsWithTarget:(id)aTarget {
  if ([NSThread isMainThread]) {
    [aTarget grey_unmapAllTrackersForAllPerformSelectorArguments];
  }

  SEL swizzledSEL = @selector(greyswizzled_cancelPreviousPerformRequestsWithTarget:);
  INVOKE_ORIGINAL_IMP1(void, swizzledSEL, aTarget);
}

+ (void)greyswizzled_cancelPreviousPerformRequestsWithTarget:(id)aTarget
                                                    selector:(SEL)aSelector
                                                      object:(id)anArgument {
  SEL swizzledSEL =
      @selector(greyswizzled_cancelPreviousPerformRequestsWithTarget:selector:object:);
  if ([NSThread isMainThread]) {
    NSArray *arguments = [self grey_arrayWithSelector:aSelector argument:anArgument];
    [aTarget grey_unmapAllTrackersForPerformSelectorArguments:arguments];

    SEL customPerformSEL = @selector(grey_customPerformSelectorWithParameters:);
    INVOKE_ORIGINAL_IMP3(void, swizzledSEL, aTarget, customPerformSEL, arguments);
  } else {
    INVOKE_ORIGINAL_IMP3(void, swizzledSEL, aTarget, aSelector, anArgument);
  }
}

#pragma mark - Package Internal

- (void)greyswizzled_performSelector:(SEL)aSelector
                          withObject:(id)anArgument
                          afterDelay:(NSTimeInterval)delay
                             inModes:(NSArray *)modes {
  if ([NSThread isMainThread]) {
    NSArray *arguments = [self grey_arrayWithSelector:aSelector argument:anArgument];
    // Track delayed executions on main thread that fall within a trackable duration.
    CFTimeInterval maxDelayToTrack =
        GREY_CONFIG_DOUBLE(kGREYConfigKeyDelayedPerformMaxTrackableDuration);
    if (maxDelayToTrack >= delay) {
      // As a safeguard, track the pending call for twice the amount incase the execution is
      // *really* delayed (due to cpu trashing) for more than the expected execution-time.
      // The custom selector will stop tracking as soon as it is triggered.
      NSString *trackerName = [NSString stringWithFormat:@"performSelector @selector(%@) on %@",
                                                         NSStringFromSelector(aSelector),
                                                         NSStringFromClass([self class])];
      // For negative delays use 0.
      NSTimeInterval nonNegativeDelay = MAX(0, 2 * delay);
      GREYTimedIdlingResource *tracker =
          [GREYTimedIdlingResource resourceForObject:@"Delayed performSelector"
                               thatIsBusyForDuration:nonNegativeDelay
                                                name:trackerName];
      // Setup custom selector to be called after delay.
      [self grey_mapPerformSelectorArguments:arguments toTracker:tracker];
    }
    INVOKE_ORIGINAL_IMP4(
        void, @selector(greyswizzled_performSelector:withObject:afterDelay:inModes:),
        @selector(grey_customPerformSelectorWithParameters:), arguments, delay, modes);
  } else {
    INVOKE_ORIGINAL_IMP4(void,
                         @selector(greyswizzled_performSelector:withObject:afterDelay:inModes:),
                         aSelector, anArgument, delay, modes);
  }
}

#pragma mark - Private

/**
 *  A custom performSelector that peforms the selector specified in @c arguments on itself.
 *  @c arguments[0] must be the selector to forward to the call to. If a non @c nil object was
 *  passed to NSObject::performSelector:withObject: @c arguments[2] must point to it.
 *
 *  @param arguments An array of arguments that include a selector, an object (on which to invoke
 *                   the selector) optionally followed by the arguments to be passed to the
 *                   selector.
 */
- (void)grey_customPerformSelectorWithParameters:(NSArray *)arguments {
  GREYFatalAssertWithMessage(arguments.count >= 1,
                             @"at the very least, an entry to selector must be present.");
  SEL selector = [arguments[0] pointerValue];
  id objectParam = (arguments.count > 1) ? arguments[1] : nil;

  [self grey_unmapSingleTrackerForPerformSelectorArguments:arguments];
  NSMethodSignature *methodSignature = [self methodSignatureForSelector:selector];
  // First two arguments are always self and _cmd.
  if (methodSignature.numberOfArguments > 2) {
    void (*originalFunc)(id, SEL, id) = (void (*)(id, SEL, id))[self methodForSelector:selector];
    originalFunc(self, selector, objectParam);
  } else {
    void (*originalFunc)(id, SEL) = (void (*)(id, SEL))[self methodForSelector:selector];
    originalFunc(self, selector);
  }
}

/**
 *  Returns an array containing @c target, @c selector and @c argumentOrNil combination. Always use
 *  this when adding an entry to the dictionary for consistent key hashing.
 *
 *  @param selector      Selector to be added to the array.
 *  @param argumentOrNil Argument to be added to the array.
 *
 *  @return Array containing @c target, @c selector and @c argumentOrNil combination.
 */
- (NSArray *)grey_arrayWithSelector:(SEL)selector argument:(id)argumentOrNil {
  return [NSArray arrayWithObjects:[NSValue valueWithPointer:selector], argumentOrNil, nil];
}

/**
 *  Creates an entry in the global dictionary with (@c arguments, @c tracker) pair to track a single
 *  NSObject::performSelector:withObject:afterDelay:inModes: call.
 *
 *  @param arguments The arguments that were originally passed to
 *                   NSObject::performSelector:withObject:afterDelay:inModes: call.
 *  @param tracker   The idling resource that is tracking the
 *                   NSObject::performSelector:withObject:afterDelay:inModes: call.
 */
- (void)grey_mapPerformSelectorArguments:(NSArray *)arguments
                               toTracker:(GREYTimedIdlingResource *)tracker {
  @synchronized(self) {
    NSMutableDictionary *argsToTrackers = [self grey_performSelectorArgumentsToTrackerMap];
    NSMutableArray *trackers = argsToTrackers[arguments];
    if (!trackers) {
      trackers = [[NSMutableArray alloc] init];
    }
    [trackers addObject:tracker];
    argsToTrackers[arguments] = trackers;
  }
}

/**
 *  Removes a single tracker associated with the
 *  NSObject::performSelector:withObject:afterDelay:inModes: call having the given @c arguments.
 *
 *  @param arguments The arguments that whose tracker is to be removed.
 */
- (void)grey_unmapSingleTrackerForPerformSelectorArguments:(NSArray *)arguments {
  @synchronized(self) {
    NSMutableDictionary *argsToTrackers = [self grey_performSelectorArgumentsToTrackerMap];
    NSMutableArray *trackers = argsToTrackers[arguments];
    [[trackers lastObject] stopMonitoring];
    [trackers removeLastObject];
    if (trackers.count > 0) {
      argsToTrackers[arguments] = trackers;
    } else {
      [argsToTrackers removeObjectForKey:arguments];
    }
  }
}

/**
 *  Removes all trackers associated with the
 *  NSObject::performSelector:withObject:afterDelay:inModes: call having the given @c arguments.
 *
 *  @param arguments The arguments that whose tracker is to be removed.
 */
- (void)grey_unmapAllTrackersForPerformSelectorArguments:(NSArray *)arguments {
  @synchronized(self) {
    NSMutableDictionary *argsToTrackers = [self grey_performSelectorArgumentsToTrackerMap];
    NSMutableArray *trackers = argsToTrackers[arguments];
    while (trackers.count > 0) {
      [[trackers lastObject] stopMonitoring];
      [trackers removeLastObject];
    }
    [argsToTrackers removeObjectForKey:arguments];
  }
}

/**
 *  Clears all the performSelector entries tracked for self.
 */
- (void)grey_unmapAllTrackersForAllPerformSelectorArguments {
  @synchronized(self) {
    NSMutableDictionary *argsToTrackers = [self grey_performSelectorArgumentsToTrackerMap];
    for (NSArray *arguments in [[argsToTrackers allKeys] copy]) {
      [self grey_unmapAllTrackersForPerformSelectorArguments:arguments];
    }
    objc_setAssociatedObject(self, @selector(grey_customPerformSelectorWithParameters:), nil,
                             OBJC_ASSOCIATION_ASSIGN);
  }
}

/**
 *  @return A mutable dictionary for storing all tracked performSelector calls.
 */
- (NSMutableDictionary *)grey_performSelectorArgumentsToTrackerMap {
  @synchronized(self) {
    NSMutableDictionary *dictionary =
        objc_getAssociatedObject(self, @selector(grey_customPerformSelectorWithParameters:));
    if (!dictionary) {
      dictionary = [[NSMutableDictionary alloc] init];
      objc_setAssociatedObject(self, @selector(grey_customPerformSelectorWithParameters:),
                               dictionary, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return dictionary;
  }
}

@end
