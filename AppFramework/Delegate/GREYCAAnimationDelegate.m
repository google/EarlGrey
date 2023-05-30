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

#import "GREYCAAnimationDelegate.h"

#include <objc/message.h>
#include <objc/runtime.h>

#import "CAAnimation+GREYApp.h"
#import "GREYFatalAsserts.h"
#import "GREYLogger.h"
#import "GREYObjcRuntime.h"
#import "GREYSwizzler.h"

/**
 * Intercepts the CAAnimationDelegate::animationDidStart: call and directs it to the correct
 * implementation depending on the swizzled context.
 *
 * @param animation                   The animation the current class is the delegate off.
 * @param isInvokedFromSwizzledMethod @c YES if called from a swizzled method, @c NO otherwise.
 */
static void AnimationDidStart(id self, SEL _cmd, CAAnimation *animation,
                              BOOL isInvokedFromSwizzledMethod);

/**
 * Intercepts the CAAnimationDelegate::animationDidStop:finished: call and directs it to the
 * correct implementation depending on the swizzled context.
 *
 * @param animation                   The animation the current class is the delegate off.
 * @param finished                    @c YES if the animation has finished, @c NO if it stopped
 *                                    for other reasons.
 * @param isInvokedFromSwizzledMethod @c YES if called from a swizzled method, @c NO otherwise.
 */
static void AnimationDidStop(id self, SEL _cmd, CAAnimation *animation, BOOL finished,
                             BOOL isInvokedFromSwizzledMethod);

/**
 * Adds the @c originalSelector to the delegate's class if it does not respond to it.
 * If present, adds the @c swizzledSelector to the @c delegates's class and swizzles the
 * @originalSelector with the @c swizzledSelector for better tracking with EarlGrey
 * synchronization.
 *
 * @param delegate               The CAAnimationDelegate being swizzled.
 * @param originalSelector       The original selector method from CAAnimationDelegate to be
 *                               swizzled.
 * @param swizzledSelector       The custom EarlGrey selector for the @c originalSelector.
 * @param selfImplementation     The implementation of the @c originalSelector in the
 *                               GREYCAAnimationDelegate.
 * @param delegateImplementation The implementation for the @c originalSelector in the delegate
 *                               passed in.
 *
 * @return An id<CAAnimationDelegate> that has been appropriately instrumented for EarlGrey's
 *         synchronization.
 */
static id InstrumentSurrogateDelegate(id self, id delegate, SEL originalSelector,
                                      SEL swizzledSelector, IMP selfImplementation,
                                      IMP delegateImplementation);

@interface GREYCAAnimationDelegate : NSObject <CAAnimationDelegate>
@end

@implementation GREYCAAnimationDelegate

#pragma mark - CAAnimationDelegate

- (void)animationDidStart:(CAAnimation *)animation {
  AnimationDidStart(self, _cmd, animation, NO);
}

- (void)animationDidStop:(CAAnimation *)animation finished:(BOOL)finished {
  AnimationDidStop(self, _cmd, animation, finished, NO);
}

#pragma mark - Private

/**
 * Swizzled implementation of the CAAnimationDelegate::animationDidStart method.
 *
 * @param animation The animation the current class is the delegate off.
 */
- (void)greyswizzled_animationDidStart:(CAAnimation *)animation {
  AnimationDidStart(self, _cmd, animation, YES);
}

/**
 * Swizzled implementation of the CAAnimationDelegate::animationDidStop:finished: method.
 *
 * @param animation The animation the current class is the delegate off.
 * @param finished  @c YES if the animation has finished, @c NO if it stopped for other reasons.s
 */
- (void)greyswizzled_animationDidStop:(CAAnimation *)animation finished:(BOOL)finished {
  AnimationDidStop(self, _cmd, animation, finished, YES);
}

@end

static id InstrumentSurrogateDelegate(id self, id delegate, SEL originalSelector,
                                      SEL swizzledSelector, IMP selfImplementation,
                                      IMP delegateImplementation) {
  if (![delegate respondsToSelector:swizzledSelector]) {
    Class klass = [delegate class];
    // If the delegate's class does not implement the swizzled greyswizzled_animationDidStart:
    // method, then EarlGrey needs to swizzle it.
    if (![delegate respondsToSelector:originalSelector]) {
      // If animationDidStart: is not implemented by the delegate's class then we have to first
      // add it to the delegate class.
      [GREYObjcRuntime addInstanceMethodToClass:klass withSelector:originalSelector fromClass:self];

      // In case a delegate is passed in that has already been swizzled by EarlGrey, it needs to be
      // ensured that it is not re-swizzled. As a result, it is checked for the implementations of
      // the methods to be swizzled and if they are the same as those provided by EarlGrey on
      // swizzling.
    } else if (selfImplementation != delegateImplementation) {
      // Add the EarlGrey-implemented method to the delegate's class and swizzle it.
      [GREYObjcRuntime addInstanceMethodToClass:klass withSelector:swizzledSelector fromClass:self];
      BOOL swizzleSuccess = [[[GREYSwizzler alloc] init] swizzleClass:klass
                                                replaceInstanceMethod:originalSelector
                                                           withMethod:swizzledSelector];
      GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle %@",
                                 NSStringFromSelector(swizzledSelector));
    }
  }
  return delegate;
}

static void AnimationDidStart(id self, SEL _cmd, CAAnimation *animation,
                              BOOL isInvokedFromSwizzledMethod) {
  [animation grey_setAnimationState:kGREYAnimationStarted];
  if (isInvokedFromSwizzledMethod) {
    INVOKE_ORIGINAL_IMP1(void, @selector(greyswizzled_animationDidStart:), animation);
  }
}

static void AnimationDidStop(id self, SEL _cmd, CAAnimation *animation, BOOL finished,
                             BOOL isInvokedFromSwizzledMethod) {
  // Starting with iOS11, calling [UIViewPropertyAnimator stopAnimation:] calls into
  // [UIViewPropertyAnimator finalizeStoppedAnimationWithPosition:] with a block that will in turn
  // call the CAAnimation delegate's animationDidStop:finished: method with animation parameter
  // set to NSNull. This check is added in order to stop the unrecognized selector call.
  if ([animation isEqual:[NSNull null]]) {
    return;
  }
  [animation grey_setAnimationState:kGREYAnimationStopped];
  if (isInvokedFromSwizzledMethod) {
    INVOKE_ORIGINAL_IMP2(void, @selector(greyswizzled_animationDidStop:finished:), animation,
                         finished);
  }
}

id<CAAnimationDelegate> GREYSurrogateDelegateForCAAnimationDelegate(
    id<CAAnimationDelegate> delegate) {
  static SEL animationDidStartSelector;
  static SEL swizzledAnimationDidStartSelector;
  static SEL animationDidStopSelector;
  static SEL swizzledAnimationDidStopSelector;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    animationDidStartSelector = @selector(animationDidStart:);
    swizzledAnimationDidStartSelector = @selector(greyswizzled_animationDidStart:);
    animationDidStopSelector = @selector(animationDidStop:finished:);
    swizzledAnimationDidStopSelector = @selector(greyswizzled_animationDidStop:finished:);
  });

  id outDelegate;
  if (!delegate) {
    // If the delegate is nil then create and return a new delegate.
    outDelegate = [[GREYCAAnimationDelegate alloc] init];
  } else {
    NSObject *delegateObject = delegate;
    IMP animationDidStartInstance =
        [GREYCAAnimationDelegate instanceMethodForSelector:animationDidStartSelector];
    IMP delegateAnimationDidStartInstance =
        [delegateObject methodForSelector:animationDidStartSelector];
    IMP animationDidStopInstance =
        [GREYCAAnimationDelegate instanceMethodForSelector:animationDidStopSelector];
    IMP delegateAnimationDidStopInstance =
        [delegateObject methodForSelector:animationDidStopSelector];
    outDelegate =
        InstrumentSurrogateDelegate([GREYCAAnimationDelegate class], delegate,
                                    animationDidStartSelector, swizzledAnimationDidStartSelector,
                                    animationDidStartInstance, delegateAnimationDidStartInstance);
    outDelegate =
        InstrumentSurrogateDelegate([GREYCAAnimationDelegate class], outDelegate,
                                    animationDidStopSelector, swizzledAnimationDidStopSelector,
                                    animationDidStopInstance, delegateAnimationDidStopInstance);
  }
  return outDelegate;
}

/**
 * Adds empty implementation of CAAnimationDelegate to MDFSpritedAnimationView.
 *
 * Quartz Core caches the result of -respondsToSelector: at different timings based on the type of
 * the target, for example:
 *
 * 1. The UIView is initialized at `UIViewCommonInitWithFrame`.
 * 2. The CALayer delegate is assigned at `CALayer -setDelegate:`.
 * 3. The CAAnimation delegate at `CALLayer -addAnimation:forKey:`.
 *
 * It's hard to intercept the code that checks and caches the CAAnimationDelegate methods. Instead,
 * EarlGrey always let the check result to be `true`, so the surrogate delegate won't be ignored by
 * the cached result.
 */
__attribute__((constructor)) static void AddDefaultCAAnimationDelegateMethod(void) {
  // TODO(b/284322701): Change the class to NSObject and fix the existing test breakages.
  Class processedClass = NSClassFromString(@"MDFSpritedAnimationView");
  if (processedClass) {
    IMP animationDidStartImp = imp_implementationWithBlock(^(id delegate, CAAnimation *animation){
    });
    BOOL animationDidStartAdded = class_addMethod(processedClass, @selector(animationDidStart:),
                                                  animationDidStartImp, "v@:@");
    if (!animationDidStartAdded) {
      GREYLogVerbose(@"MDFSpritedAnimationView -animationDidStart: already exists.");
    }

    IMP animationDidStopImp =
        imp_implementationWithBlock(^(id delegate, CAAnimation *animation, BOOL finished){
        });
    BOOL animationDidStopAdded = class_addMethod(
        processedClass, @selector(animationDidStop:finished:), animationDidStopImp, "v@:@B");
    if (!animationDidStopAdded) {
      GREYLogVerbose(@"MDFSpritedAnimationView -animationDidStop:finished: already exists.");
    }
  }
}
