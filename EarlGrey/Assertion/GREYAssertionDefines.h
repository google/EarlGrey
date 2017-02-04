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

/**
 * @file
 * @brief Helper macros for performing assertions and throwing assertion failure exceptions.
 */

#ifndef GREY_ASSERTION_DEFINES_H
#define GREY_ASSERTION_DEFINES_H

#import <EarlGrey/GREYDefines.h>
#import <EarlGrey/GREYFailureHandler.h>
#import <EarlGrey/GREYFrameworkException.h>

GREY_EXPORT id<GREYFailureHandler> getFailureHandler();

#pragma mark - Public

// Safe to call from anywhere within EarlGrey test.

/**
 *  Generates a failure with the provided @c __description if the expression @c __a1 evaluates to
 *  @c NO.
 *
 *  @param __a1          The expression that should be evaluated.
 *  @param __description Description to print if @c __a1 evaluates to @c NO. May be a format
 *                       string, in which case the variable args will be required.
 *  @param ...           Variable args for @c __description if it is a format string.
 */
#define GREYAssert(__a1, __description, ...) \
({ \
  I_GREYSetCurrentAsFailable(); \
  I_GREYAssertTrue((__a1), (__description), ##__VA_ARGS__); \
})

/**
 *  Generates a failure with the provided @c __description if the expression @c __a1 evaluates to
 *  @c NO.
 *
 *  @param __a1          The expression that should be evaluated.
 *  @param __description Description to print if @c __a1 evaluates to @c NO. May be a format
 *                       string, in which case the variable args will be required.
 *  @param ...           Variable args for @c __description if it is a format string.
 */
#define GREYAssertTrue(__a1, __description, ...) \
({ \
  I_GREYSetCurrentAsFailable(); \
  I_GREYAssertTrue((__a1), (__description), ##__VA_ARGS__); \
})

/**
 *  Generates a failure with the provided @c __description if the expression @c __a1 evaluates to
 *  @c YES.
 *
 *  @param __a1          The expression that should be evaluated.
 *  @param __description Description to print if @c __a1 evaluates to @c NO. May be a format
 *                       string, in which case the variable args will be required.
 *  @param ...           Variable args for @c __description if it is a format string.
 */
#define GREYAssertFalse(__a1, __description, ...) \
({ \
  I_GREYSetCurrentAsFailable(); \
  I_GREYAssertFalse((__a1), (__description), ##__VA_ARGS__); \
})

/**
 *  Generates a failure with the provided @c __description if the expression @c __a1 is @c nil.
 *
 *  @param __a1          The expression that should be evaluated.
 *  @param __description Description to print if @c __a1 is @c nil. May be a format
 *                       string, in which case the variable args will be required.
 *  @param ...           Variable args for @c __description if it is a format string.
 */
#define GREYAssertNotNil(__a1, __description, ...) \
({ \
  I_GREYSetCurrentAsFailable(); \
  I_GREYAssertNotNil((__a1), (__description), ##__VA_ARGS__); \
})

/**
 *  Generates a failure with the provided @c __description if the expression @c __a1 is not @c nil.
 *
 *  @param __a1          The expression that should be evaluated.
 *  @param __description Description to print if @c __a1 is not @c nil. May be a format
 *                       string, in which case the variable args will be required.
 *  @param ...           Variable args for @c __description if it is a format string.
 */
#define GREYAssertNil(__a1, __description, ...) \
({ \
  I_GREYSetCurrentAsFailable(); \
  I_GREYAssertNil((__a1), (__description), ##__VA_ARGS__); \
})

/**
 *  Generates a failure with the provided @c __description if the expression @c __a1 and
 *  the expression @c __a2 are not equal.
 *  @c __a1 and @c __a2 must be scalar types.
 *
 *  @param __a1          The left hand scalar value on the equality operation.
 *  @param __a2          The right hand scalar value on the equality operation.
 *  @param __description Description to print if @c __a1 and @c __a2 are not equal. May be a format
 *                       string, in which case the variable args will be required.
 *  @param ...           Variable args for @c __description if it is a format string.
 */
#define GREYAssertEqual(__a1, __a2, __description, ...) \
({ \
  I_GREYSetCurrentAsFailable(); \
  I_GREYAssertEqual((__a1), (__a2), (__description), ##__VA_ARGS__); \
})

/**
 *  Generates a failure with the provided @c __description if the expression @c __a1 and
 *  the expression @c __a2 are equal.
 *  @c __a1 and @c __a2 must be scalar types.
 *
 *  @param __a1          The left hand scalar value on the equality operation.
 *  @param __a2          The right hand scalar value on the equality operation.
 *  @param __description Description to print if @c __a1 and @c __a2 are equal. May be a format
 *                       string, in which case the variable args will be required.
 *  @param ...           Variable args for @c __description if it is a format string.
 */
#define GREYAssertNotEqual(__a1, __a2, __description, ...) \
({ \
  I_GREYSetCurrentAsFailable(); \
  I_GREYAssertNotEqual((__a1), (__a2), (__description), ##__VA_ARGS__); \
})

/**
 *  Generates a failure with the provided @c __description if the expression @c __a1 and
 *  the expression @c __a2 are not equal.
 *  @c __a1 and @c __a2 must be descendants of NSObject and will be compared with method isEqual.
 *
 *  @param __a1          The left hand object on the equality operation.
 *  @param __a2          The right hand object on the equality operation.
 *  @param __description Description to print if @c __a1 and @c __a2 are not equal. May be a format
 *                       string, in which case the variable args will be required.
 *  @param ...           Variable args for @c __description if it is a format string.
 */
#define GREYAssertEqualObjects(__a1, __a2, __description, ...) \
({ \
  I_GREYSetCurrentAsFailable(); \
  I_GREYAssertEqualObjects((__a1), (__a2), __description, ##__VA_ARGS__); \
})

/**
 *  Generates a failure with the provided @c __description if the expression @c __a1 and
 *  the expression @c __a2 are equal.
 *  @c __a1 and @c __a2 must be descendants of NSObject and will be compared with method isEqual.
 *
 *  @param __a1          The left hand object on the equality operation.
 *  @param __a2          The right hand object on the equality operation.
 *  @param __description Description to print if @c __a1 and @c __a2 are equal. May be a format
 *                       string, in which case the variable args will be required.
 *  @param ...           Variable args for @c __description if it is a format string.
 */
#define GREYAssertNotEqualObjects(__a1, __a2, __description, ...) \
({ \
  I_GREYSetCurrentAsFailable(); \
  I_GREYAssertNotEqualObjects((__a1), (__a2), (__description), ##__VA_ARGS__); \
})

/**
 *  Generates a failure unconditionally, with the provided @c __description.
 *
 *  @param __description Description to print. May be a format string, in which case the variable
 *                       args will be required.
 *  @param ...           Variable args for @c __description if it is a format string.
 */
#define GREYFail(__description, ...) \
({ \
    I_GREYSetCurrentAsFailable(); \
    I_GREYFail((__description), ##__VA_ARGS__); \
})

/**
 *  Generates a failure unconditionally, with the provided @c __description and @c __details.
 *
 *  @param __description  Description to print.
 *  @param __details      The failure details. May be a format string, in which case the variable
 *                        args will be required.
 *  @param ...            Variable args for @c __description if it is a format string.
 */
#define GREYFailWithDetails(__description, __details, ...)  \
({ \
  I_GREYSetCurrentAsFailable(); \
  I_GREYFailWithDetails((__description), (__details), ##__VA_ARGS__); \
})

/**
 *  Generates a failure unconditionally for when the constraints for performing an action fail,
 *  with the provided @c __description and @c __details.
 *
 *  @param __description  Description to print.
 *  @param __details      The failure details. May be a format string, in which case the variable
 *                        args will be required.
 *  @param ...            Variable args for @c __description if it is a format string.
 */
#define GREYConstraintsFailedWithDetails(__description, __details, ...)  \
({ \
  I_GREYSetCurrentAsFailable(); \
  I_GREYConstraintsFailedWithDetails((__description), (__details), ##__VA_ARGS__); \
})

#pragma mark - Private Use By Framework Only

// THESE ARE METHODS TO BE CALLED BY THE FRAMEWORK ONLY.
// DO NOT CALL OUTSIDE FRAMEWORK

/// @cond INTERNAL

#define I_GREYFormattedString(__var, __format, ...) \
({ \
  /* clang warns us about a leak in formatting but we don't care as we are about to fail. */ \
  _Pragma("clang diagnostic push") \
  _Pragma("clang diagnostic ignored \"-Wformat-nonliteral\"") \
  _Pragma("clang diagnostic ignored \"-Wformat-security\"") \
  (__var) = [NSString stringWithFormat:(__format), ##__VA_ARGS__]; \
  _Pragma("clang diagnostic pop") \
})

#define I_GREYRegisterFailure(__exceptionName, __description, __details, ...) \
({ \
  NSString *details__; \
  I_GREYFormattedString(details__, __details, ##__VA_ARGS__); \
  id<GREYFailureHandler> failureHandler__ = getFailureHandler(); \
  [failureHandler__ handleException:[GREYFrameworkException exceptionWithName:__exceptionName \
                                                                       reason:(__description)] \
                            details:(details__)]; \
})

// No private macro should call this.
#define I_GREYSetCurrentAsFailable() \
({ \
  id<GREYFailureHandler> failureHandler__ = getFailureHandler(); \
  if ([failureHandler__ respondsToSelector:@selector(setInvocationFile:andInvocationLine:)]) { \
    [failureHandler__ setInvocationFile:[NSString stringWithUTF8String:__FILE__] \
                      andInvocationLine:__LINE__]; \
  } \
})

#define I_GREYAssertTrue(__a1, __description, ...) \
({ \
  if (!(__a1)) { \
    NSString *formattedDescription__; \
    I_GREYFormattedString(formattedDescription__, (__description), ##__VA_ARGS__); \
    I_GREYRegisterFailure(kGREYAssertionFailedException, \
                          @"((" #__a1 ") is true) failed", \
                          formattedDescription__); \
  } \
})

#define I_GREYAssertFalse(__a1, __description, ...) \
({ \
  if ((__a1)) { \
    NSString *formattedDescription__; \
    I_GREYFormattedString(formattedDescription__, (__description), ##__VA_ARGS__); \
    I_GREYRegisterFailure(kGREYAssertionFailedException, \
                          @"((" #__a1 ") is false) failed", \
                          formattedDescription__); \
  } \
})

#define I_GREYAssertNotNil(__a1, __description, ...) \
({ \
  if ((__a1) == nil) { \
    NSString *formattedDescription__; \
    I_GREYFormattedString(formattedDescription__, (__description), ##__VA_ARGS__); \
    I_GREYRegisterFailure(kGREYNotNilException, \
                          @"((" #__a1 ") != nil) failed", \
                          formattedDescription__); \
  } \
})

#define I_GREYAssertNil(__a1, __description, ...) \
({ \
  if ((__a1) != nil) { \
    NSString *formattedDescription__; \
    I_GREYFormattedString(formattedDescription__, (__description), ##__VA_ARGS__); \
    I_GREYRegisterFailure(kGREYNilException, \
                          @"((" #__a1 ") == nil) failed", \
                          formattedDescription__); \
  } \
})

#define I_GREYAssertEqual(__a1, __a2, __description, ...) \
({ \
  if ((__a1) != (__a2)) { \
    NSString *formattedDescription__; \
    I_GREYFormattedString(formattedDescription__, (__description), ##__VA_ARGS__); \
    I_GREYRegisterFailure(kGREYAssertionFailedException, \
                          @"((" #__a1 ") == (" #__a2 ")) failed", \
                          formattedDescription__); \
  } \
})

#define I_GREYAssertNotEqual(__a1, __a2, __description, ...) \
({ \
  if ((__a1) == (__a2)) { \
    NSString *formattedDescription__; \
    I_GREYFormattedString(formattedDescription__, (__description), ##__VA_ARGS__); \
    I_GREYRegisterFailure(kGREYAssertionFailedException, \
                          @"((" #__a1 ") != (" #__a2 ")) failed", \
                          formattedDescription__); \
    } \
})

#define I_GREYAssertEqualObjects(__a1, __a2, __description, ...) \
({ \
  if (![(__a1) isEqual:(__a2)]) { \
    NSString *formattedDescription__; \
    I_GREYFormattedString(formattedDescription__, (__description), ##__VA_ARGS__); \
    I_GREYRegisterFailure(kGREYAssertionFailedException, \
                          @"[(" #__a1 ") isEqual:(" #__a2 ")] failed", \
                          formattedDescription__); \
  } \
})

#define I_GREYAssertNotEqualObjects(__a1, __a2, __description, ...) \
({ \
  if ([(__a1) isEqual:(__a2)]) { \
    NSString *formattedDescription__; \
    I_GREYFormattedString(formattedDescription__, (__description), ##__VA_ARGS__); \
    I_GREYRegisterFailure(kGREYAssertionFailedException, \
                          @"![(" #__a1 ") isEqual:(" #__a2 ")] failed", \
                          formattedDescription__); \
  } \
})

#define I_GREYFail(__description, ...) \
({ \
  NSString *formattedDescription__; \
  I_GREYFormattedString(formattedDescription__, __description, ##__VA_ARGS__); \
  I_GREYRegisterFailure(kGREYGenericFailureException, formattedDescription__, @""); \
})

#define I_GREYFailWithDetails(__description, __details, ...)  \
  I_GREYRegisterFailure(kGREYGenericFailureException, __description, __details, ##__VA_ARGS__)

#define I_GREYConstraintsFailedWithDetails(__description, __details, ...)  \
  I_GREYRegisterFailure(kGREYConstraintFailedException, __description, __details, ##__VA_ARGS__)

#define I_GREYTimeout(__description, __details, ...) \
  I_GREYRegisterFailure(kGREYTimeoutException, __description, __details, ##__VA_ARGS__)

#define I_GREYActionFail(__description, __details, ...) \
  I_GREYRegisterFailure(kGREYActionFailedException, __description, __details, ##__VA_ARGS__)

#define I_GREYAssertionFail(__description, __details, ...) \
  I_GREYRegisterFailure(kGREYAssertionFailedException, __description, __details, ##__VA_ARGS__)

#define I_GREYElementNotFound(__description, __details, ...) \
  I_GREYRegisterFailure(kGREYNoMatchingElementException, __description, __details, ##__VA_ARGS__)

#define I_GREYMultipleElementsFound(__description, __details, ...) \
  I_GREYRegisterFailure(kGREYMultipleElementsFoundException, \
                        __description, \
                        __details, \
                        ##__VA_ARGS__)

#define I_CHECK_MAIN_THREAD() \
  I_GREYAssertTrue([NSThread isMainThread], @"Must be on the main thread.")

/// @endcond

#endif  // GREY_ASSERTION_DEFINES_H
