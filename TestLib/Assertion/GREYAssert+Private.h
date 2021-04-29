//
// Copyright 2020 Google Inc.
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
 * @brief This file declares private portions of the implementation of the GREYAssert* macros.
 *
 * These entry points should not be referenced other than from those macros and their
 * supporting implementation. Comments are provided for future maintainers and should not
 * be taken as a guide to directly using these functions.
 */

#ifndef GREY_ASSERT_PRIVATE_H
#define GREY_ASSERT_PRIVATE_H

#import <Foundation/Foundation.h>

#import "GREYDefines.h"
#import "GREYDescribeVariable.h"

#pragma mark - Private support typedefs and functions

/**
 * This enum defines the type of assertion being made.
 */
typedef NS_ENUM(int32_t, GREYIAssertionType) {
  GREYIAssertionTypeFail,
  GREYIAssertionTypeTrue,
  GREYIAssertionTypeFalse,
  GREYIAssertionTypeNotNil,
  GREYIAssertionTypeNil,
  GREYIAssertionTypeEqual,
  GREYIAssertionTypeNotEqual,
  GREYIAssertionTypeGreaterThan,
  GREYIAssertionTypeGreaterThanOrEqual,
  GREYIAssertionTypeLessThan,
  GREYIAssertionTypeLessThanOrEqual,
  GREYIAssertionTypeEqualObjects,
  GREYIAssertionTypeNotEqualObjects
};

/**
 * Waits for the app to idle.
 *
 * @param assertionType The type of assertion macro this was called from. This determines the
 *                      format of the timeout message that will be printed if the app does not idle.
 * @param ...           The type and number of these arguments must match the format string in the
 *                      implementation.
 */
GREY_EXTERN void GREYIWaitForAppToIdle(GREYIAssertionType assertionType, ...);

/**
 * Returns a description of a failed assertion.
 *
 * @param assertionType The type of assertion that has failed.
 * @param ...           The arguments relevant to the assertion type.  For the either one or two
 *                      items involved in the assertion, this contains first the NSStrings
 *                      describing the value, then a const char * with the source code of the
 *                      argument.
 */
GREY_EXTERN NSString *_Nonnull GREYIFailureDescription(GREYIAssertionType assertionType, ...);

/**
 * Sets the current invocation location to the given file and line number.
 *
 * @param fileName   The file where the invocation which might fail occurs.
 * @param lineNumber The line number within that file where the invocation occurs.
 */
GREY_EXTERN void GREYISetFileLineAsFailable(const char *_Nonnull fileName, NSUInteger lineNumber);

/**
 * Internal function to create an exception and pass it to the failure handler.
 *
 * The exception created will be an assertion failed exception.
 *
 * @param descriptionFormat Format string for the description to assign to the exception. The
 *                          variadic arguments should provide the string format parameters.
 *                          The resulting string will be passed as both the description and
 *                          details string to the error handler.
 */
GREY_EXTERN void GREYIAssertionFail(NSString *_Nonnull descriptionFormat, ...)
    NS_FORMAT_FUNCTION(1, 2);

/**
 * Internal function to create an exception and pass it to the failure handler.
 *
 * The exception created will be an assertion failed exception.
 *
 * @param description   Description to assign to the exception.
 * @param detailsFormat If given, this should be a format string for NSString, and the
 *                      variadic arguments should provide the string format parameters.
 *                      The resulting string will be passed as the details string to the
 *                      error handler.
 */
GREY_EXTERN void GREYIAssertionFailure(NSString *_Nonnull description,
                                       NSString *_Nullable detailsFormat, ...)
    NS_FORMAT_FUNCTION(2, 3);

#pragma mark - Internal Macro Definitions

#define GREYIFail(description, ...)                 \
  ({                                                \
    GREYIWaitForAppToIdle(GREYIAssertionTypeFail);  \
    GREYIAssertionFail(description, ##__VA_ARGS__); \
  })

#define GREYIFailWithDetails(description, details, ...)         \
  ({                                                            \
    GREYIWaitForAppToIdle(GREYIAssertionTypeFail);              \
    GREYIAssertionFailure(description, details, ##__VA_ARGS__); \
  })

#define GREYIAssertTrue(__a1, ...)                                                    \
  ({                                                                                  \
    const char *a1Str__ = "" #__a1;                                                   \
    GREYIWaitForAppToIdle(GREYIAssertionTypeTrue, a1Str__);                           \
    __typeof__(__a1) a1Value__ = (__a1);                                              \
    if (!a1Value__) {                                                                 \
      GREYIAssertionFailure(GREYIFailureDescription(GREYIAssertionTypeTrue, a1Str__), \
                            @"" __VA_ARGS__);                                         \
    }                                                                                 \
  })

#define GREYIAssertFalse(__a1, ...)                                                    \
  ({                                                                                   \
    const char *a1Str__ = "" #__a1;                                                    \
    GREYIWaitForAppToIdle(GREYIAssertionTypeFalse, a1Str__);                           \
    __typeof__(__a1) a1Value__ = (__a1);                                               \
    if (a1Value__) {                                                                   \
      GREYIAssertionFailure(GREYIFailureDescription(GREYIAssertionTypeFalse, a1Str__), \
                            @"" __VA_ARGS__);                                          \
    }                                                                                  \
  })

#define GREYIAssertNotNil(__a1, ...)                                                    \
  ({                                                                                    \
    const char *a1Str__ = "" #__a1;                                                     \
    GREYIWaitForAppToIdle(GREYIAssertionTypeNotNil, a1Str__);                           \
    NSObject *_Nullable a1Value__ = (__a1);                                             \
    if (a1Value__ == nil) {                                                             \
      GREYIAssertionFailure(GREYIFailureDescription(GREYIAssertionTypeNotNil, a1Str__), \
                            @"" __VA_ARGS__);                                           \
    }                                                                                   \
  })

#define GREYIAssertNil(__a1, ...)                                                                 \
  ({                                                                                              \
    const char *a1Str__ = "" #__a1;                                                               \
    GREYIWaitForAppToIdle(GREYIAssertionTypeNil, a1Str__);                                        \
    NSObject *_Nullable a1Value__ = (__a1);                                                       \
    if (a1Value__) {                                                                              \
      GREYIAssertionFailure(                                                                      \
          GREYIFailureDescription(GREYIAssertionTypeNil, a1Str__, GREYDescribeObject(a1Value__)), \
          @"" __VA_ARGS__);                                                                       \
    }                                                                                             \
  })

#define GREYIAssertEqual(__a1, __a2, ...)                                                      \
  ({                                                                                           \
    const char *a1Str__ = "" #__a1;                                                            \
    const char *a2Str__ = "" #__a2;                                                            \
    GREYIWaitForAppToIdle(GREYIAssertionTypeEqual, a1Str__, a2Str__);                          \
    __typeof__(__a1) a1Value__ = (__a1);                                                       \
    __typeof__(__a2) a2Value__ = (__a2);                                                       \
    if (a1Value__ != a2Value__) {                                                              \
      GREYIAssertionFailure(GREYIFailureDescription(GREYIAssertionTypeEqual, a1Str__, a2Str__, \
                                                    GREYDescribeVariable(a1Value__),           \
                                                    GREYDescribeVariable(a2Value__)),          \
                            @"" __VA_ARGS__);                                                  \
    }                                                                                          \
  })

#define GREYIAssertNotEqual(__a1, __a2, ...)                                                      \
  ({                                                                                              \
    const char *a1Str__ = "" #__a1;                                                               \
    const char *a2Str__ = "" #__a2;                                                               \
    GREYIWaitForAppToIdle(GREYIAssertionTypeNotEqual, a1Str__, a2Str__);                          \
    __typeof__(__a1) a1Value__ = (__a1);                                                          \
    __typeof__(__a2) a2Value__ = (__a2);                                                          \
    if (a1Value__ == a2Value__) {                                                                 \
      GREYIAssertionFailure(GREYIFailureDescription(GREYIAssertionTypeNotEqual, a1Str__, a2Str__, \
                                                    GREYDescribeVariable(a1Value__),              \
                                                    GREYDescribeVariable(a2Value__)),             \
                            @"" __VA_ARGS__);                                                     \
    }                                                                                             \
  })

#define GREYIAssertGreaterThan(__a1, __a2, ...)                                               \
  ({                                                                                          \
    const char *a1Str__ = "" #__a1;                                                           \
    const char *a2Str__ = "" #__a2;                                                           \
    GREYIWaitForAppToIdle(GREYIAssertionTypeGreaterThan, a1Str__, a2Str__);                   \
    __typeof__(__a1) a1Value__ = (__a1);                                                      \
    __typeof__(__a2) a2Value__ = (__a2);                                                      \
    if (a1Value__ <= a2Value__) {                                                             \
      GREYIAssertionFailure(GREYIFailureDescription(GREYIAssertionTypeGreaterThan, a1Str__,   \
                                                    a2Str__, GREYDescribeVariable(a1Value__), \
                                                    GREYDescribeVariable(a2Value__)),         \
                            @"" __VA_ARGS__);                                                 \
    }                                                                                         \
  })

#define GREYIAssertGreaterThanOrEqual(__a1, __a2, ...)                                             \
  ({                                                                                               \
    const char *a1Str__ = "" #__a1;                                                                \
    const char *a2Str__ = "" #__a2;                                                                \
    GREYIWaitForAppToIdle(GREYIAssertionTypeGreaterThanOrEqual, a1Str__, a2Str__);                 \
    __typeof__(__a1) a1Value__ = (__a1);                                                           \
    __typeof__(__a2) a2Value__ = (__a2);                                                           \
    if (a1Value__ < a2Value__) {                                                                   \
      GREYIAssertionFailure(GREYIFailureDescription(GREYIAssertionTypeGreaterThanOrEqual, a1Str__, \
                                                    a2Str__, GREYDescribeVariable(a1Value__),      \
                                                    GREYDescribeVariable(a2Value__)),              \
                            @"" __VA_ARGS__);                                                      \
    }                                                                                              \
  })

#define GREYIAssertLessThan(__a1, __a2, ...)                                                      \
  ({                                                                                              \
    const char *a1Str__ = "" #__a1;                                                               \
    const char *a2Str__ = "" #__a2;                                                               \
    GREYIWaitForAppToIdle(GREYIAssertionTypeLessThan, a1Str__, a2Str__);                          \
    __typeof__(__a1) a1Value__ = (__a1);                                                          \
    __typeof__(__a2) a2Value__ = (__a2);                                                          \
    if (a1Value__ >= a2Value__) {                                                                 \
      GREYIAssertionFailure(GREYIFailureDescription(GREYIAssertionTypeLessThan, a1Str__, a2Str__, \
                                                    GREYDescribeVariable(a1Value__),              \
                                                    GREYDescribeVariable(a2Value__)),             \
                            @"" __VA_ARGS__);                                                     \
    }                                                                                             \
  })

#define GREYIAssertLessThanOrEqual(__a1, __a2, ...)                                             \
  ({                                                                                            \
    const char *a1Str__ = "" #__a1;                                                             \
    const char *a2Str__ = "" #__a2;                                                             \
    GREYIWaitForAppToIdle(GREYIAssertionTypeLessThanOrEqual, a1Str__, a2Str__);                 \
    __typeof__(__a1) a1Value__ = (__a1);                                                        \
    __typeof__(__a2) a2Value__ = (__a2);                                                        \
    if (a1Value__ > a2Value__) {                                                                \
      GREYIAssertionFailure(GREYIFailureDescription(GREYIAssertionTypeLessThanOrEqual, a1Str__, \
                                                    a2Str__, GREYDescribeVariable(a1Value__),   \
                                                    GREYDescribeVariable(a2Value__)),           \
                            @"" __VA_ARGS__);                                                   \
    }                                                                                           \
  })

#define GREYIAssertEqualObjects(__a1, __a2, ...)                                                 \
  ({                                                                                             \
    const char *a1Str__ = "" #__a1;                                                              \
    const char *a2Str__ = "" #__a2;                                                              \
    GREYIWaitForAppToIdle(GREYIAssertionTypeEqualObjects, a1Str__, a2Str__);                     \
    __typeof__(__a1) a1Value__ = (__a1);                                                         \
    __typeof__(__a2) a2Value__ = (__a2);                                                         \
    if (![a1Value__ isEqual:a2Value__]) {                                                        \
      GREYIAssertionFailure(                                                                     \
          GREYIFailureDescription(GREYIAssertionTypeEqualObjects, a1Str__, a2Str__,              \
                                  GREYDescribeObject(a1Value__), GREYDescribeObject(a2Value__)), \
          @"" __VA_ARGS__);                                                                      \
    }                                                                                            \
  })

#define GREYIAssertNotEqualObjects(__a1, __a2, ...)                                              \
  ({                                                                                             \
    const char *a1Str__ = "" #__a1;                                                              \
    const char *a2Str__ = "" #__a2;                                                              \
    GREYIWaitForAppToIdle(GREYIAssertionTypeNotEqualObjects, a1Str__, a2Str__);                  \
    __typeof__(__a1) a1Value__ = (__a1);                                                         \
    __typeof__(__a2) a2Value__ = (__a2);                                                         \
    if ([a1Value__ isEqual:a2Value__]) {                                                         \
      GREYIAssertionFailure(                                                                     \
          GREYIFailureDescription(GREYIAssertionTypeNotEqualObjects, a1Str__, a2Str__,           \
                                  GREYDescribeObject(a1Value__), GREYDescribeObject(a2Value__)), \
          @"" __VA_ARGS__);                                                                      \
    }                                                                                            \
  })

#pragma mark - One-time configuration

/** Type of exceptions the runtime support can register on behalf of the macros. */
typedef NS_ENUM(uint32_t, GREYIExceptionType) {
  GREYIExceptionTypeTimeout,
  GREYIExceptionTypeAssertionFailed
};

/** Block used by the implementation of the macros to pass on the current file and line. */
typedef void (^GREYISetFileLineBlock)(const char *_Nonnull, NSUInteger);

/** Block used by the implementation of the macros to wait for the app to idle. */
typedef NSError *_Nullable (^GREYIWaitForAppToIdleBlock)(void);

/** Block used by the implementation of the macros to register a failure. */
typedef void (^GREYIRegisterFailureBlock)(GREYIExceptionType, NSString *_Nonnull,
                                          NSString *_Nonnull);

/** Allows returning the configuration of the asserts, see GREYIRestoreConfiguration(). */
typedef struct {
  GREYISetFileLineBlock _Nullable setFileLineBlock;
  GREYIWaitForAppToIdleBlock _Nullable waitForAppToIdleBlock;
  GREYIRegisterFailureBlock _Nullable registerFailureBlock;
} GREYIAssertionsConfiguration;

/**
 * This function must be called once before any macros are invoked.
 *
 * In an EarlGrey test environment, rather than calling this function directly, call the
 * GREYIEarlGreyAssertionsConfiguration() function.
 *
 * This entry point is used in order to be able to unit test the assertions outside of the EarlGrey
 * environment.
 *
 * @return Returns the previous configuration, which may be nil if this is the first call.
 */
GREY_EXTERN GREYIAssertionsConfiguration
    GREYIConfigureAssertions(GREYISetFileLineBlock _Nonnull setFileLineBlock,
                             GREYIWaitForAppToIdleBlock _Nonnull waitForAppToIdleBlock,
                             GREYIRegisterFailureBlock _Nonnull registerFailureBlock);

/**
 * Restores a configuration returned from a previous call to GREYIConfigureAssertions().
 *
 * The meaning of GMS_VISIBLE_FOR_TESTING is that this entry point in only intended for use
 * when cleaning up a unit test of the macros.  When running EarlGrey tests, there is no need
 * to call this function.
 */
GREY_EXTERN void GREYIRestoreConfiguration(GREYIAssertionsConfiguration oldConfiguration)
    GREY_VISIBLE_FOR_INTERNAL_TESTING;

#endif  // GREY_ASSERT_PRIVATE_H
