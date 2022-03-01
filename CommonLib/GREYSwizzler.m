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

#import "GREYSwizzler.h"

#include <dlfcn.h>
#include <objc/runtime.h>

typedef NS_ENUM(NSUInteger, GREYMethodType) { GREYMethodTypeClass, GREYMethodTypeInstance };

static NSString *const gGREYSwizzlerException = @"gGREYSwizzlerException";

#pragma mark - GREYResetter

/**
 * Utility class to hold original implementation of a method of a class for the purpose of
 * resetting.
 */
@interface GREYResetter : NSObject

/**
 * @remark init is not an available initializer. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 * Designated initializer.
 *
 * @param method         Method being swizzled
 * @param implementation Implementation of the method being swizzled
 * @param counterpart    The Method that @c method is being swizzled with.
 */
- (instancetype)initWithMethod:(Method)method
                implementation:(IMP)implementation
                   counterpart:(Method)counterpart;

/**
 * Reset the original method selector to its unmodified/vanilla implementations.
 */
- (void)reset;

/**
 * The swizzled method's swizzling counterpart i.e. the method it is replaced with or replacing.
 */
- (Method)counterpart;

@end

@implementation GREYResetter {
  /** The Method that is to be reset using the resetter. */
  Method _method;
  /** The implementation (IMP) for the Method being swizzled. */
  IMP _implementation;
  /**
   * The swizzled method's swizzling counterpart method that is used to identify the method it is
   * being swizzled with.
   */
  Method _counterpart;
}

- (instancetype)initWithMethod:(Method)method
                implementation:(IMP)implementation
                   counterpart:(Method)counterpart {
  self = [super init];
  if (self) {
    _method = method;
    _implementation = implementation;
    _counterpart = counterpart;
  }
  return self;
}

- (Method)counterpart {
  return _counterpart;
}

- (void)reset {
  method_setImplementation(_method, _implementation);
}

@end

#pragma mark - GREYSwizzler

@implementation GREYSwizzler {
  NSMutableDictionary<NSString *, GREYResetter *> *_resetters;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _resetters = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (BOOL)resetClassMethod:(SEL)methodSelector class:(Class)klass {
  if (!klass || !methodSelector) {
    NSLog(@"Nil Parameter(s) found when swizzling.");
    return NO;
  }

  NSString *key =
      [[self class] grey_keyForClass:klass selector:methodSelector type:GREYMethodTypeClass];
  GREYResetter *resetter = _resetters[key];
  if (resetter) {
    [resetter reset];
    [_resetters removeObjectForKey:key];
    Method counterpart = resetter.counterpart;
    SEL counterpartSEL = method_getName(counterpart);
    NSString *counterpartKey = [[self class] grey_keyForClass:klass
                                                     selector:counterpartSEL
                                                         type:GREYMethodTypeClass];
    if (_resetters[counterpartKey]) {
      return [self resetClassMethod:counterpartSEL class:klass];
    }
    return YES;
  } else {
    NSLog(@"Resetter was nil for class: %@ and class selector: %@", NSStringFromClass(klass),
          NSStringFromSelector(methodSelector));
    return NO;
  }
}

- (BOOL)resetInstanceMethod:(SEL)methodSelector class:(Class)klass {
  if (!klass || !methodSelector) {
    NSLog(@"Nil Parameter(s) found when swizzling.");
    return NO;
  }

  NSString *key =
      [[self class] grey_keyForClass:klass selector:methodSelector type:GREYMethodTypeInstance];
  GREYResetter *resetter = _resetters[key];
  if (resetter) {
    [resetter reset];
    [_resetters removeObjectForKey:key];
    Method counterpart = resetter.counterpart;
    SEL counterpartSEL = method_getName(counterpart);
    NSString *counterpartKey = [[self class] grey_keyForClass:klass
                                                     selector:counterpartSEL
                                                         type:GREYMethodTypeInstance];
    if (_resetters[counterpartKey]) {
      return [self resetInstanceMethod:counterpartSEL class:klass];
    }
    return YES;
  } else {
    NSLog(@"Resetter was nil for class: %@ and instance selector: %@", NSStringFromClass(klass),
          NSStringFromSelector(methodSelector));
    return NO;
  }
}

- (void)resetAll {
  for (GREYResetter *resetter in [_resetters allValues]) {
    [resetter reset];
  }
  [_resetters removeAllObjects];
}

- (BOOL)swizzleClass:(Class)klass
    replaceClassMethod:(SEL)methodSelector1
            withMethod:(SEL)methodSelector2 {
  if (!klass || !methodSelector1 || !methodSelector2) {
    NSLog(@"Nil Parameter(s) found when swizzling.");
    return NO;
  }

  Method method1 = class_getClassMethod(klass, methodSelector1);
  Method method2 = class_getClassMethod(klass, methodSelector2);
  // Only swizzle if both methods are found.
  if (method1 && method2) {
    // Save the current implementations
    IMP imp1 = method_getImplementation(method1);
    IMP imp2 = method_getImplementation(method2);
    [self grey_saveOriginalMethod:method1
                   implementation:imp1
                    originalClass:klass
                   swizzledMethod:method2
                      swizzledIMP:imp2
                    swizzledClass:klass
                       methodType:GREYMethodTypeClass];

    // To add a class method, we need to get the class meta first.
    // http://stackoverflow.com/questions/9377840/how-to-dynamically-add-a-class-method
    Class classMeta = object_getClass(klass);
    if (class_addMethod(classMeta, methodSelector1, imp2, method_getTypeEncoding(method2))) {
      class_replaceMethod(classMeta, methodSelector2, imp1, method_getTypeEncoding(method1));
    } else {
      method_exchangeImplementations(method1, method2);
    }

    return YES;
  } else {
    NSLog(@"Swizzling Method(s) not found while swizzling class %@.", NSStringFromClass(klass));
    return NO;
  }
}

- (BOOL)swizzleClass:(Class)klass
    replaceInstanceMethod:(SEL)methodSelector1
               withMethod:(SEL)methodSelector2 {
  if (!klass || !methodSelector1 || !methodSelector2) {
    NSLog(@"Nil Parameter(s) found when swizzling.");
    return NO;
  }

  Method method1 = class_getInstanceMethod(klass, methodSelector1);
  Method method2 = class_getInstanceMethod(klass, methodSelector2);
  // Only swizzle if both methods are found.
  if (method1 && method2) {
    // Save the current implementations
    IMP imp1 = method_getImplementation(method1);
    IMP imp2 = method_getImplementation(method2);
    [self grey_saveOriginalMethod:method1
                   implementation:imp1
                    originalClass:klass
                   swizzledMethod:method2
                      swizzledIMP:imp2
                    swizzledClass:klass
                       methodType:GREYMethodTypeInstance];

    if (class_addMethod(klass, methodSelector1, imp2, method_getTypeEncoding(method2))) {
      class_replaceMethod(klass, methodSelector2, imp1, method_getTypeEncoding(method1));
    } else {
      method_exchangeImplementations(method1, method2);
    }
    return YES;
  } else {
    NSLog(@"Swizzling Method(s) not found while swizzling class %@.", NSStringFromClass(klass));
    return NO;
  }
}

- (BOOL)swizzleClass:(Class)klass
               addInstanceMethod:(SEL)addSelector
              withImplementation:(IMP)addIMP
    andReplaceWithInstanceMethod:(SEL)instanceSelector {
  if (!klass || !addSelector || !addIMP || !instanceSelector) {
    NSLog(@"Nil Parameter(s) found when swizzling.");
    return NO;
  }

  // Check for whether an implementation forwards to a nil selector or not.
  // This is caused when you use the incorrect methodForSelector call in order
  // to get the implementation for a selector.
  void *messageForwardingIMP = dlsym(RTLD_DEFAULT, "_objc_msgForward");
  if (addIMP == messageForwardingIMP) {
    NSLog(@"Wrong Type of Implementation obtained for selector %@", NSStringFromClass(klass));
    return NO;
  }

  Method instanceMethod = class_getInstanceMethod(klass, instanceSelector);
  if (instanceMethod) {
    struct objc_method_description *desc = method_getDescription(instanceMethod);
    if (!desc || desc->name == NULL) {
      NSLog(@"Failed to get method description.");
      return NO;
    }

    if (!class_addMethod(klass, addSelector, addIMP, desc->types)) {
      NSLog(@"Failed to add class method.");
      return NO;
    }
    return [self swizzleClass:klass replaceInstanceMethod:instanceSelector withMethod:addSelector];
  } else {
    NSLog(@"Instance method: %@ does not exist in the class %@.",
          NSStringFromSelector(instanceSelector), NSStringFromClass(klass));
    return NO;
  }
}

#pragma mark - Private

+ (NSString *)grey_keyForClass:(Class)klass selector:(SEL)sel type:(GREYMethodType)methodType {
  NSParameterAssert(klass);
  NSParameterAssert(sel);

  NSString *methodTypeString;
  if (methodType == GREYMethodTypeClass) {
    methodTypeString = @"+";
  } else {
    methodTypeString = @"-";
  }
  return [NSString stringWithFormat:@"%@[%@ %@]", methodTypeString, NSStringFromClass(klass),
                                    NSStringFromSelector(sel)];
}

- (void)grey_saveOriginalMethod:(Method)method
                 implementation:(IMP)implementation
                  originalClass:(Class)originalClass
                 swizzledMethod:(Method)swizzledMethod
                    swizzledIMP:(IMP)swizzledIMP
                  swizzledClass:(Class)swizzledClass
                     methodType:(GREYMethodType)methodType {
  NSParameterAssert(method);
  NSParameterAssert(implementation);
  NSParameterAssert(originalClass);
  NSParameterAssert(swizzledMethod);
  NSParameterAssert(swizzledIMP);

  SEL methodSEL = method_getName(method);
  SEL swizzledMethodSEL = method_getName(swizzledMethod);
  NSString *keyForOriginal = [[self class] grey_keyForClass:originalClass
                                                   selector:methodSEL
                                                       type:methodType];
  NSString *keyForSwizzled = [[self class] grey_keyForClass:swizzledClass
                                                   selector:swizzledMethodSEL
                                                       type:methodType];
  if (!_resetters[keyForOriginal]) {
    GREYResetter *resetter = [[GREYResetter alloc] initWithMethod:method
                                                   implementation:implementation
                                                      counterpart:swizzledMethod];
    _resetters[keyForOriginal] = resetter;
  } else {
    [NSException  // NOLINTNEXTLINE(google-objc-avoid-throwing-exception)
         raise:gGREYSwizzlerException
        format:@"You are re-swizzling a method which is already swizzled elsewhere using the same "
               @"GREYSwizzler instance. Please refrain from doing this, or at least do not use the "
               @"same GREYSwizzler instance, as it will cause resetting issues. Stack Trace:\n%@",
               [NSThread callStackSymbols]];
  }

  if (!_resetters[keyForSwizzled]) {
    GREYResetter *resetter = [[GREYResetter alloc] initWithMethod:swizzledMethod
                                                   implementation:swizzledIMP
                                                      counterpart:method];
    _resetters[keyForSwizzled] = resetter;
  } else {
    [NSException  // NOLINTNEXTLINE(google-objc-avoid-throwing-exception)
         raise:gGREYSwizzlerException
        format:@"You are swizzling with a method which is already being used to swizzle another "
               @"method with the same "
               @"GREYSwizzler instance. Please refrain from doing this, or at least do not use the "
               @"same GREYSwizzler instance, as it will cause resetting issues. Stack Trace:\n%@",
               [NSThread callStackSymbols]];
  }
}

@end
