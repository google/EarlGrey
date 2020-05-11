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

/**
 * @file
 * @brief Helper macros for performing assertions and throwing assertion failure exceptions.
 * On failure, these macros take screenshots and log full view hierarchy. They wait for app to idle
 * before performing the assertion.
 */

#ifndef GREY_ASSERTION_DEFINES_H
#define GREY_ASSERTION_DEFINES_H

#import "GREYAssertionDefinesPrivate.h"

#import "GREYUIThreadExecutor.h"
#import "GREYFailureHandler.h"
#import "GREYFrameworkException.h"
#import "GREYDefines.h"
#import "GREYWaitFunctions.h"

/**
 * These Macros are safe to call from anywhere within a testcase.
 */
#pragma mark - Public Macros

/**
 * Generates a failure unconditionally, with the provided @c __description.
 *
 * @param __description Description to print. May be a format string, in which case the variable
 *                      args will be required.
 * @param ...           Variable args for @c __description if it is a format string.
 */
#define GREYFail(__description, ...)            \
  ({                                            \
    I_GREYSetCurrentAsFailable();               \
    I_GREYFail((__description), ##__VA_ARGS__); \
  })

/**
 * Generates a failure unconditionally, with the provided @c __description and @c __details.


 *
 * @param __description  Description to print.
 * @param __details      The failure details. May be a format string, in which case the variable
 *                       args will be required.
 * @param ...            Variable args for @c __description if it is a format string.
 */
#define GREYFailWithDetails(__description, __details, ...)              \
  ({                                                                    \
    I_GREYSetCurrentAsFailable();                                       \
    I_GREYFailWithDetails((__description), (__details), ##__VA_ARGS__); \
  })

/**
 * Generates a failure with the provided @c __description if the expression @c __a1 evaluates to


 * @c NO.
 *
 * @param __a1          The expression that should be evaluated.
 * @param __description Description to print if @c __a1 evaluates to @c NO. May be a format
 *                      string, in which case the variable args will be required.
 * @param ...           Variable args for @c __description if it is a format string.
 */
#define GREYAssert(__a1, __description, ...)                                  \
  ({                                                                          \
    I_GREYSetCurrentAsFailable();                                             \
    NSString *timeoutString__ = @"Couldn't assert that (" #__a1 ") is true."; \
    GREYWaitForAppToIdle(timeoutString__);                                    \
    I_GREYAssertTrue((__a1), (__description), ##__VA_ARGS__);                 \
  })

/**
 * Generates a failure with the provided @c __description if the expression @c __a1 evaluates to


 * @c NO.
 *
 * @param __a1          The expression that should be evaluated.
 * @param __description Description to print if @c __a1 evaluates to @c NO. May be a format
 *                      string, in which case the variable args will be required.
 * @param ...           Variable args for @c __description if it is a format string.
 */
#define GREYAssertTrue(__a1, __description, ...)                              \
  ({                                                                          \
    I_GREYSetCurrentAsFailable();                                             \
    NSString *timeoutString__ = @"Couldn't assert that (" #__a1 ") is true."; \
    GREYWaitForAppToIdle(timeoutString__);                                    \
    I_GREYAssertTrue((__a1), (__description), ##__VA_ARGS__);                 \
  })

/**
 * Generates a failure with the provided @c __description if the expression @c __a1 evaluates to


 * @c YES.
 *
 * @param __a1          The expression that should be evaluated.
 * @param __description Description to print if @c __a1 evaluates to @c NO. May be a format
 *                      string, in which case the variable args will be required.
 * @param ...           Variable args for @c __description if it is a format string.
 */
#define GREYAssertFalse(__a1, __description, ...)                              \
  ({                                                                           \
    I_GREYSetCurrentAsFailable();                                              \
    NSString *timeoutString__ = @"Couldn't assert that (" #__a1 ") is false."; \
    GREYWaitForAppToIdle(timeoutString__);                                     \
    I_GREYAssertFalse((__a1), (__description), ##__VA_ARGS__);                 \
  })

/**
 * Generates a failure with the provided @c __description if the expression @c __a1 is @c nil.


 *
 * @param __a1          The expression that should be evaluated.
 * @param __description Description to print if @c __a1 is @c nil. May be a format
 *                      string, in which case the variable args will be required.
 * @param ...           Variable args for @c __description if it is a format string.
 */
#define GREYAssertNotNil(__a1, __description, ...)                               \
  ({                                                                             \
    I_GREYSetCurrentAsFailable();                                                \
    NSString *timeoutString__ = @"Couldn't assert that (" #__a1 ") is not nil."; \
    GREYWaitForAppToIdle(timeoutString__);                                       \
    I_GREYAssertNotNil((__a1), (__description), ##__VA_ARGS__);                  \
  })

/**
 * Generates a failure with the provided @c __description if the expression @c __a1 is not @c nil.



 *
 * @param __a1          The expression that should be evaluated.
 * @param __description Description to print if @c __a1 is not @c nil. May be a format
 *                      string, in which case the variable args will be required.
 * @param ...           Variable args for @c __description if it is a format string.
 */
#define GREYAssertNil(__a1, __description, ...)                              \
  ({                                                                         \
    I_GREYSetCurrentAsFailable();                                            \
    NSString *timeoutString__ = @"Couldn't assert that (" #__a1 ") is nil."; \
    GREYWaitForAppToIdle(timeoutString__);                                   \
    I_GREYAssertNil((__a1), (__description), ##__VA_ARGS__);                 \
  })

/**
 * Generates a failure with the provided @c __description if the expression @c __a1 and
 * the expression @c __a2 are not equal.

 * @c __a1 and @c __a2 must be scalar types.
 *
 * @param __a1          The left hand scalar value on the equality operation.
 * @param __a2          The right hand scalar value on the equality operation.
 * @param __description Description to print if @c __a1 and @c __a2 are not equal. May be a format
 *                      string, in which case the variable args will be required.
 * @param ...           Variable args for @c __description if it is a format string.
 */
#define GREYAssertEqual(__a1, __a2, __description, ...)                                         \
  ({                                                                                            \
    I_GREYSetCurrentAsFailable();                                                               \
    NSString *timeoutString__ = @"Couldn't assert that (" #__a1 ") and (" #__a2 ") are equal."; \
    GREYWaitForAppToIdle(timeoutString__);                                                      \
    I_GREYAssertEqual((__a1), (__a2), (__description), ##__VA_ARGS__);                          \
  })

/**
 * Generates a failure with the provided @c __description if the expression @c __a1 and
 * the expression @c __a2 are equal.



 * @c __a1 and @c __a2 must be scalar types.
 *
 * @param __a1          The left hand scalar value on the equality operation.
 * @param __a2          The right hand scalar value on the equality operation.
 * @param __description Description to print if @c __a1 and @c __a2 are equal. May be a format
 *                      string, in which case the variable args will be required.
 * @param ...           Variable args for @c __description if it is a format string.
 */
#define GREYAssertNotEqual(__a1, __a2, __description, ...)                  \
  ({                                                                        \
    I_GREYSetCurrentAsFailable();                                           \
    NSString *timeoutString__ =                                             \
        @"Couldn't assert that (" #__a1 ") and (" #__a2 ") are not equal."; \
    GREYWaitForAppToIdle(timeoutString__);                                  \
    I_GREYAssertNotEqual((__a1), (__a2), (__description), ##__VA_ARGS__);   \
  })

/**
 * Generates a failure with the provided @c __description if the expression @c __a1 and
 * the expression @c __a2 are not equal.
 * @c __a1 and @c __a2 must be descendants of NSObject and will be compared with method isEqual.


 *
 * @param __a1          The left hand object on the equality operation.
 * @param __a2          The right hand object on the equality operation.
 * @param __description Description to print if @c __a1 and @c __a2 are not equal. May be a format
 *                      string, in which case the variable args will be required.
 * @param ...           Variable args for @c __description if it is a format string.
 */
#define GREYAssertEqualObjects(__a1, __a2, __description, ...)                  \
  ({                                                                            \
    I_GREYSetCurrentAsFailable();                                               \
    NSString *timeoutString__ =                                                 \
        @"Couldn't assert that (" #__a1 ") and (" #__a2 ") are equal objects."; \
    GREYWaitForAppToIdle(timeoutString__);                                      \
    I_GREYAssertEqualObjects((__a1), (__a2), __description, ##__VA_ARGS__);     \
  })

/**
 * Generates a failure with the provided @c __description if the expression @c __a1 and
 * the expression @c __a2 are equal.
 * @c __a1 and @c __a2 must be descendants of NSObject and will be compared with method isEqual.



 *
 * @param __a1          The left hand object on the equality operation.
 * @param __a2          The right hand object on the equality operation.
 * @param __description Description to print if @c __a1 and @c __a2 are equal. May be a format
 *                      string, in which case the variable args will be required.
 * @param ...           Variable args for @c __description if it is a format string.
 */
#define GREYAssertNotEqualObjects(__a1, __a2, __description, ...)                   \
  ({                                                                                \
    I_GREYSetCurrentAsFailable();                                                   \
    NSString *timeoutString__ =                                                     \
        @"Couldn't assert that (" #__a1 ") and (" #__a2 ") are not equal objects."; \
    GREYWaitForAppToIdle(timeoutString__);                                          \
    I_GREYAssertNotEqualObjects((__a1), (__a2), (__description), ##__VA_ARGS__);    \
  })

/**
 * Waits for the application to idle without blocking the test's main thread.
 *
 * @param __timeoutDescription The description to print if the idling errors out.
 */
#define GREYWaitForAppToIdle(__timeoutDescription)                                            \
  ({                                                                                          \
    NSError *error__;                                                                         \
    BOOL success__ = GREYWaitForAppToIdleWithError(&error__);                                 \
    if (!success__) {                                                                         \
      I_GREYTimeout(__timeoutDescription, @"Timed out waiting for app to idle. %@", error__); \
    }                                                                                         \
  })

/**
 * Waits for the application to idle without blocking the test's main thread within the specified
 * timeout.
 *
 * @param __timeout            The seconds for which the application will be waited on to be idle.
 * @param __timeoutDescription The description to print if the idling errors out.
 */
#define GREYWaitForAppToIdleWithTimeout(__timeout, __timeoutDescription)                   \
  ({                                                                                       \
    NSError *error__;                                                                      \
    BOOL success__ = GREYWaitForAppToIdleWithTimeoutAndError(__timeout, &error__);         \
    if (!success__) {                                                                      \
      I_GREYTimeout(__timeoutDescription,                                                  \
                    @"Timed out waiting for app to idle within %f seconds: %@", __timeout, \
                    error__);                                                              \
    }                                                                                      \
  })

#endif  // GREY_ASSERTION_DEFINES_H
