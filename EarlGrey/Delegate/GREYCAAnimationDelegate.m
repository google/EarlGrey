//
// Copyright 2016 Google Inc.
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

#import "Delegate/GREYCAAnimationDelegate.h"

#include <objc/message.h>
#include <objc/runtime.h>

#import "Additions/CAAnimation+GREYAdditions.h"
#import "Common/GREYDefines.h"
#import "Common/GREYFatalAsserts.h"
#import "Common/GREYLogger.h"
#import "Common/GREYSwizzler.h"

/**
 *  Intercepts the CAAnimationDelegate::animationDidStart: call and directs it to the correct
 *  implementation depending on the swizzled context.
 *
 *  @param animation                   The animation the current class is the delegate off.
 *  @param isInvokedFromSwizzledMethod @c YES if called from a swizzled method, @c NO otherwise.
 */
static void AnimationDidStart(id self,
                              SEL _cmd,
                              CAAnimation *animation,
                              BOOL isInvokedFromSwizzledMethod);

/**
 *  Intercepts the CAAnimationDelegate::animationDidStop:finished: call and directs it to the
 *  correct implementation depending on the swizzled context.
 *
 *  @param animation                   The animation the current class is the delegate off.
 *  @param finished                    @c YES if the animation has finished, @c NO if it stopped
 *                                     for other reasons.
 *  @param isInvokedFromSwizzledMethod @c YES if called from a swizzled method, @c NO otherwise.
 */
static void AnimationDidStop(id self,
                             SEL _cmd,
                             CAAnimation *animation,
                             BOOL finished,
                             BOOL isInvokedFromSwizzledMethod);

/**
 *  Adds the @c originalSelector to the delegate's class if it does not respond to it.
 *  If present, adds the @c swizzledSelector to the @c delegates's class and swizzles the
 *  @originalSelector with the @c swizzledSelector for better tracking with EarlGrey
 *  synchronization.
 *
 *  @param delegate               The CAAnimationDelegate being swizzled.
 *  @param originalSelector       The original selector method from CAAnimationDelegate to be
 *                                swizzled.
 *  @param swizzledSelector       The custom EarlGrey selector for the @c originalSelector.
 *  @param originalImplementation The implementation for the @c originalSelector.
 *  @param swizzledImplementation The implementation for the @c swizzledSelector.
 *
 *  @return An id<CAAnimationDelegate> that has been appropriately instrumented for EarlGrey's
 *          synchronization.
 */
static id<CAAnimationDelegate> InstrumentSurrogateDelegate(id self,
                                                           id<CAAnimationDelegate> delegate,
                                                           SEL originalSelector,
                                                           SEL swizzledSelector,
                                                           IMP originalImplementation,
                                                           IMP swizzledImplementation);

@implementation GREYCAAnimationDelegate

+ (id<CAAnimationDelegate>)surrogateDelegateForDelegate:(id<CAAnimationDelegate>)delegate {
  id<CAAnimationDelegate> outDelegate = nil;
  if (!delegate) {
    // If the delegate is nil then wrap it in a new surrogate delegate for the CAAnimation
    // delegate provided.
    outDelegate = [[self alloc] initWithOriginalDelegate:delegate isWeak:NO];
  } else {
    SEL animationDidStartSEL = @selector(animationDidStart:);
    SEL greyAnimationDidStartSEL = @selector(greyswizzled_animationDidStart:);
    SEL animationDidStopSEL = @selector(animationDidStop:finished:);
    SEL greyAnimationDidStopSEL = @selector(greyswizzled_animationDidStop:finished:);
    IMP animationDidStartInstance = [self instanceMethodForSelector:animationDidStartSEL];
    IMP greyAnimationDidStartInstance = [self instanceMethodForSelector:greyAnimationDidStartSEL];
    IMP animationDidStopInstance = [self instanceMethodForSelector:animationDidStopSEL];
    IMP greyAnimationDidStopInstance = [self instanceMethodForSelector:greyAnimationDidStopSEL];
    outDelegate = InstrumentSurrogateDelegate(self,
                                              delegate,
                                              animationDidStartSEL,
                                              greyAnimationDidStartSEL,
                                              animationDidStartInstance,
                                              greyAnimationDidStartInstance);
    outDelegate = InstrumentSurrogateDelegate(self,
                                              delegate,
                                              animationDidStopSEL,
                                              greyAnimationDidStopSEL,
                                              animationDidStopInstance,
                                              greyAnimationDidStopInstance);
  }
  return outDelegate;
}

- (void)animationDidStart:(CAAnimation *)animation {
  AnimationDidStart(self, _cmd, animation, NO);
  if ([[self superclass] instancesRespondToSelector:_cmd]) {
    struct objc_super superClassStruct = { self, [self superclass] };
    ((void (*)(struct objc_super *, SEL, CAAnimation *))objc_msgSendSuper)(&superClassStruct,
                                                                           _cmd,
                                                                           animation);
  }
}

- (void)animationDidStop:(CAAnimation *)animation finished:(BOOL)finished {
  AnimationDidStop(self, _cmd, animation, finished, NO);
  if ([[self superclass] instancesRespondToSelector:_cmd]) {
    struct objc_super superClassStruct = { self, [self superclass] };
    ((void (*)(struct objc_super *, SEL, CAAnimation *, BOOL))objc_msgSendSuper)(&superClassStruct,
                                                                                 _cmd,
                                                                                 animation,
                                                                                 finished);
  }
}

#pragma mark - GREYPrivate

/**
 *  Swizzled implementation of the CAAnimationDelegate::animationDidStart method.
 *
 *  @param animation The animation the current class is the delegate off.
 */
- (void)greyswizzled_animationDidStart:(CAAnimation *)animation {
  AnimationDidStart(self, _cmd, animation, YES);
}

/**
 *  Swizzled implementation of the CAAnimationDelegate::animationDidStop:finished: method.
 *
 *  @param animation The animation the current class is the delegate off.
 *  @param finished  @c YES if the animation has finished, @c NO if it stopped for other reasons.s
 */
- (void)greyswizzled_animationDidStop:(CAAnimation *)animation finished:(BOOL)finished {
  AnimationDidStop(self, _cmd, animation, finished, YES);
}

/**
 *  Adds @c methodSelector contained in @c source class to the @c destination class.
 *  No swizzling is done of the @c methodSelector after and therefore no implementation is
 *  required.
 *
 *  @param destination    The class to which @c method selector is to be added.
 *  @param methodSelector The selector, implemented in @c source to be added to @c destination.
 *  @param source         The class which currently implements @c methodSelector.
 *
 *  @return @c YES if the give method could be successfully added, @c NO otherwise.
 */
+ (BOOL)grey_addInstanceMethodToClass:(Class)destination
                         withSelector:(SEL)methodSelector
                            fromClass:(Class)source {
  GREYFatalAssert(destination);
  GREYFatalAssert(methodSelector);
  GREYFatalAssert(source);

  Method instanceMethod = class_getInstanceMethod(source, methodSelector);
  GREYFatalAssertWithMessage(instanceMethod,
                             @"Instance method: %@ does not exist in the class %@.",
                             NSStringFromSelector(methodSelector),
                             source);

  const char *typeEncoding = method_getTypeEncoding(instanceMethod);
  if (!typeEncoding) {
    GREYLogVerbose(@"Failed to get method description.");
    return NO;
  }
  if (!class_addMethod(destination,
                       methodSelector,
                       method_getImplementation(instanceMethod),
                       typeEncoding)) {
    GREYFatalAssertWithMessage(NO, @"Failed to add class method.");
    return NO;
  }
  return YES;
}

@end

static id<CAAnimationDelegate> InstrumentSurrogateDelegate(id self,
                                                           id<CAAnimationDelegate> delegate,
                                                           SEL originalSelector,
                                                           SEL swizzledSelector,
                                                           IMP originalImplementation,
                                                           IMP swizzledImplementation) {
  Class klass = [delegate class];
  if (![delegate respondsToSelector:swizzledSelector]) {
    // If the delegate's class does not implement the swizzled greyswizzled_animationDidStart:
    // method, then EarlGrey needs to swizzle it.
    if (![delegate respondsToSelector:originalSelector]) {
      // If animationDidStart: is not implemented by the delegate's class then we have to first
      // add it to the delegate class.
      BOOL addInstanceSuccess = [self grey_addInstanceMethodToClass:klass
                                                       withSelector:originalSelector
                                                          fromClass:self];
      GREYFatalAssertWithMessage(addInstanceSuccess,
                                 @"Cannot add %@", NSStringFromSelector(originalSelector));
    } else if (originalImplementation != swizzledImplementation) {
      // Add the EarlGrey-implemented method to the delegate's class and swizzle it.
      BOOL addInstanceSuccess = [self grey_addInstanceMethodToClass:klass
                                                       withSelector:swizzledSelector
                                                          fromClass:self];
      GREYFatalAssertWithMessage(addInstanceSuccess,
                                 @"Cannot add %@", NSStringFromSelector(swizzledSelector));
      BOOL swizzleSuccess = [[[GREYSwizzler alloc] init] swizzleClass:klass
                                                replaceInstanceMethod:originalSelector
                                                           withMethod:swizzledSelector];
      GREYFatalAssertWithMessage(swizzleSuccess,
                                 @"Cannot swizzle %@", NSStringFromSelector(swizzledSelector));
    }
  }
  return delegate;
}

static void AnimationDidStart(id self,
                              SEL _cmd,
                              CAAnimation *animation,
                              BOOL isInvokedFromSwizzledMethod) {
  [animation grey_setAnimationState:kGREYAnimationStarted];
  if (isInvokedFromSwizzledMethod) {
    INVOKE_ORIGINAL_IMP1(void, @selector(greyswizzled_animationDidStart:), animation);
  }
}

static void AnimationDidStop(id self,
                             SEL _cmd,
                             CAAnimation *animation,
                             BOOL finished,
                             BOOL isInvokedFromSwizzledMethod) {
  [animation grey_setAnimationState:kGREYAnimationStopped];
  if (isInvokedFromSwizzledMethod) {
    INVOKE_ORIGINAL_IMP2(void,
                         @selector(greyswizzled_animationDidStop:finished:),
                         animation,
                         finished);
  }
}

