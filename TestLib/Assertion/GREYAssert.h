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
 *
 * @brief GREYAssert* macros are patterned after the macros from XCTest and
 * provide convenient ways to assert conditions in an EarlGrey test.
 *
 * All of the GREYAssert* macros wait for the application under test to idle
 * before making the assertion.
 *
 * All the assert macros provide a default error message, which will print out
 * both the actual values of the expression(s) provided, as well as the source
 * code used to generate the expression.
 *
 * The printing of values is fully implemented for POD data types. If C++ types
 * are passed to the GREYAssert{Not}Equal macros, the value printed isn't
 * meaningful, so code passing C++ types to those macros should provide a custom
 * format string and arguments to print a more meaningful error message.
 *
 * The printing of values for Objective-C objects uses the -description method
 * of NSObject.
 */

#ifndef GREY_ASSERT_H
#define GREY_ASSERT_H

/**
 * These macros will replace the original EG assert macros found in
 * GREYAssertionDefines. In order to support the transition period, the
 * preprocessor symbol GREY_MESSAGE_OPTIONAL_ASSERTS can be defined in order to
 * use the new, message-optional asserts found in this file.
 */
#ifdef GREY_MESSAGE_OPTIONAL_ASSERTS

#import <Foundation/Foundation.h>

// NOLINTNEXTLINE
#import "GREYAssert+Private.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Public Assert Macros

/**
 * Generates a failure unconditionally.
 *
 * @param description A format string defining the reasons for the failure. For
 *                    GREYFail() an explanatory string must be supplied.
 * @param ...         Subsequent arguments should be the format parameters for
 *                    the description.
 */
#define GREYFail(description, ...) \
  GREYFailAtFileLine(description, __FILE__, __LINE__, ##__VA_ARGS__)

/**
 * Generates a failure if the expression @c __a1 evaluates to @c NO.
 *
 * @param __a1 The expression that should be evaluated.
 * @param ...  If provided, the first argument should be a format string and the
 *             subsequent arguments should be the format parameters.
 */
#define GREYAssert(__a1, ...) \
  GREYAssertTrueAtFileLine(__a1, __FILE__, __LINE__, ##__VA_ARGS__)

/**
 * Generates a failure if the expression @c __a1 evaluates to @c NO.
 *
 * @param __a1 The expression that should be evaluated.
 * @param ...  If provided, the first argument should be a format string and the
 *             subsequent arguments should be the format parameters.
 */
#define GREYAssertTrue(__a1, ...) \
  GREYAssertTrueAtFileLine(__a1, __FILE__, __LINE__, ##__VA_ARGS__)

/**
 * Generates a failure if the expression @c __a1 evaluates to @c YES.
 *
 * @param __a1 The expression that should be evaluated.
 * @param ...  If provided, the first argument should be a format string and the
 *             subsequent arguments should be the format parameters.
 */
#define GREYAssertFalse(__a1, ...) \
  GREYAssertFalseAtFileLine(__a1, __FILE__, __LINE__, ##__VA_ARGS__)

/**
 * Generates a failure if the expression @c __a1 is @c nil.
 *
 * @param __a1 The expression that should be evaluated.
 * @param ...  If provided, the first argument should be a format string and the
 *             subsequent arguments should be the format parameters.
 */
#define GREYAssertNotNil(__a1, ...) \
  GREYAssertNotNilAtFileLine(__a1, __FILE__, __LINE__, ##__VA_ARGS__)

/**
 * Generates a failure if the expression @c __a1 is not @c nil.
 *
 * @param __a1 The expression that should be evaluated.
 * @param ...  If provided, the first argument should be a format string and the
 *             subsequent arguments should be the format parameters.
 */
#define GREYAssertNil(__a1, ...) \
  GREYAssertNilAtFileLine(__a1, __FILE__, __LINE__, ##__VA_ARGS__)

/**
 * Generates a failure if the expression @c __a1 and the expression @c __a2 are
 * not equal.
 *
 * @c __a1 and @c __a2 must be comparable with the != operator.
 *
 * @param __a1 The left hand scalar value on the equality operation.
 * @param __a2 The right hand scalar value on the equality operation.
 * @param ...  If provided, the first argument should be a format string and the
 *             subsequent arguments should be the format parameters.
 *
 * @note As is true of the XCTest macros, this assertion may behave
 * unexpectedley if the type of the two arguments differs at all, including
 * minor differences such as signed/unsigned.
 */
#define GREYAssertEqual(__a1, __a2, ...) \
  GREYAssertEqualAtFileLine(__a1, __a2, __FILE__, __LINE__, ##__VA_ARGS__)

/**
 * Generates a failure if the expression @c __a1 and the expression @c __a2 are
 * equal.
 *
 * @c __a1 and @c __a2 must be comparable with the == operator.
 *
 * @param __a1 The left hand scalar value on the equality operation.
 * @param __a2 The right hand scalar value on the equality operation.
 * @param ...  If provided, the first argument should be a format string and the
 *             subsequent arguments should be the format parameters.
 *
 * @note As is true of the XCTest macros, this assertion may behave
 * unexpectedley if the type of the two arguments differs at all, including
 * minor differences such as signed/unsigned.
 */
#define GREYAssertNotEqual(__a1, __a2, ...) \
  GREYAssertNotEqualAtFileLine(__a1, __a2, __FILE__, __LINE__, ##__VA_ARGS__)

/**
 * Generates a failure if the expression @c __a1 is less than or equal to the
 * expression @c __a2.
 *
 * @c __a1 and @c __a2 must be comparable with the <= operator.
 *
 * @param __a1 The left hand scalar value on the comparison operation.
 * @param __a2 The right hand scalar value on the comparison operation.
 * @param ...  If provided, the first argument should be a format string and the
 *             subsequent arguments should be the format parameters.
 *
 * @note As is true of the XCTest macros, this assertion may behave
 * unexpectedley if the type of the two arguments differs at all, including
 * minor differences such as signed/unsigned.
 */
#define GREYAssertGreaterThan(__a1, __a2, ...) \
  GREYAssertGreaterThanAtFileLine(__a1, __a2, __FILE__, __LINE__, ##__VA_ARGS__)

/**
 * Generates a failure if the expression @c __a1 is less than the expression @c
 * __a2.
 *
 * @c __a1 and @c __a2 must be comparable with the < operator.
 *
 * @param __a1 The left hand scalar value on the comparison operation.
 * @param __a2 The right hand scalar value on the comparison operation.
 * @param ...  If provided, the first argument should be a format string and the
 *             subsequent arguments should be the format parameters.
 *
 * @note As is true of the XCTest macros, this assertion may behave
 * unexpectedley if the type of the two arguments differs at all, including
 * minor differences such as signed/unsigned.
 */
#define GREYAssertGreaterThanOrEqual(__a1, __a2, ...)                    \
  GREYAssertGreaterThanOrEqualAtFileLine(__a1, __a2, __FILE__, __LINE__, \
                                         ##__VA_ARGS__)

/**
 * Generates a failure if the expression @c __a1 is greater than or equal to the
 * expression @c __a2.
 *
 * @c __a1 and @c __a2 must be comparable with the >= operator.
 *
 * @param __a1 The left hand scalar value on the comparison operation.
 * @param __a2 The right hand scalar value on the comparison operation.
 * @param ...  If provided, the first argument should be a format string and the
 *             subsequent arguments should be the format parameters.
 *
 * @note As is true of the XCTest macros, this assertion may behave
 * unexpectedley if the type of the two arguments differs at all, including
 * minor differences such as signed/unsigned.
 */
#define GREYAssertLessThan(__a1, __a2, ...) \
  GREYAssertLessThanAtFileLine(__a1, __a2, __FILE__, __LINE__, ##__VA_ARGS__)

/**
 * Generates a failure if the expression @c __a1 is greater than the expression
 * @c __a2.
 *
 * @c __a1 and @c __a2 must be comparable with the > operator.
 *
 * @param __a1 The left hand scalar value on the comparison operation.
 * @param __a2 The right hand scalar value on the comparison operation.
 * @param ...  If provided, the first argument should be a format string and the
 *             subsequent arguments should be the format parameters.
 *
 * @note As is true of the XCTest macros, this assertion may behave
 * unexpectedley if the type of the two arguments differs at all, including
 * minor differences such as signed/unsigned.
 */
#define GREYAssertLessThanOrEqual(__a1, __a2, ...)                    \
  GREYAssertLessThanOrEqualAtFileLine(__a1, __a2, __FILE__, __LINE__, \
                                      ##__VA_ARGS__)

/**
 * Generates a failure if the expression @c __a1 and the expression @c __a2 are
 * not equal.
 *
 * @c __a1 and @c __a2 must be descendants of NSObject and will be compared with
 * method isEqual.
 *
 * @param __a1 The left hand object on the equality operation.
 * @param __a2 The right hand object on the equality operation.
 * @param ...  If provided, the first argument should be a format string and the
 *             subsequent arguments should be the format parameters.
 */
#define GREYAssertEqualObjects(__a1, __a2, ...)                    \
  GREYAssertEqualObjectsAtFileLine(__a1, __a2, __FILE__, __LINE__, \
                                   ##__VA_ARGS__)

/**
 * Generates a failure if the expression @c __a1 and the expression @c __a2 are
 * equal.
 *
 * @c __a1 and @c __a2 must be descendants of NSObject and will be compared with
 * method isEqual.
 *
 * @param __a1 The left hand object on the equality operation.
 * @param __a2 The right hand object on the equality operation.
 * @param ...  If provided, the first argument should be a format string and the
 *             subsequent arguments should be the format parameters.
 */
#define GREYAssertNotEqualObjects(__a1, __a2, ...)                    \
  GREYAssertNotEqualObjectsAtFileLine(__a1, __a2, __FILE__, __LINE__, \
                                      ##__VA_ARGS__)

#pragma mark - Alternate macro versions for use in assertion helper functions

/**
 * This file defines alternate versions of the GREYAssert* macros which take the
 * file name and line number as parameters. There's no need to do this from
 * EarlGrey test code.
 *
 * However, if your project has substantial helper functions which make
 * assertions internally, these versions of the macro can be used in order to
 * correctly report the error at the line in the test where the failure
 * occurred.
 *
 * Here's a brief example. Suppose your application's TestCase subclass
 * supports a helper method like:
 * - (void)assertAspectsClear:(MyObject *myObject) {
 *   GREYAssertNil(myObject.firstAspect);
 *   GREYAssertNil(myObject.secondAspect);
 * }
 *
 * If either of these assertions fail, the file name and line number will be
 * that of the utility method. It's typically more useful to report the failure
 * at the line in the test, especially since in most environments EarlGrey test
 * failures do not produce a line-number-referenced stack dump. To do that,
 * change your helper method to be private, and take the file name and line
 * number as arguments:
 *
 * <pre>@code{
 * - (void)_assertAspectsClear:(MyObject *)myObject
 *                        file:(const char *)file
 *                        line:(NSUinteger)line {
 *   GREYAssertNilAtFileLine(myObject.firstAspect, file, line);
 *   GREYAssertNilAtFileLine(myObject.secondAspect, file, line);
 * }
 * }</pre>
 *
 * Then, wrap your helper method in a macro to make things straightforward for
 * developers writing tests:
 * #define AssertAspectsClearFor(object) \
 *   [self _assertAspectsClear:object file:__FILE__ line:__LINE__]
 *
 * Now failures will be accurately attributed to the line in the test. If you'd
 * like you can also use the optional format strings to also print the file and
 * line number within the helper method.
 *
 * Other than the file and line arguments, all of these macros work exactly like
 * the macros above. See those descriptions for the details of each macro.
 */

#define GREYFailAtFileLine(description, fileName, lineNumber, ...) \
  GREYISetFileLineAsFailable(fileName, lineNumber);                \
  GREYIFail(description, ##__VA_ARGS__)

#define GREYAssertTrueAtFileLine(__a1, fileName, lineNumber, ...) \
  GREYISetFileLineAsFailable(fileName, lineNumber);               \
  GREYIAssertTrue(__a1, ##__VA_ARGS__)

#define GREYAssertFalseAtFileLine(__a1, fileName, lineNumber, ...) \
  GREYISetFileLineAsFailable(fileName, lineNumber);                \
  GREYIAssertFalse(__a1, ##__VA_ARGS__)

#define GREYAssertNotNilAtFileLine(__a1, fileName, lineNumber, ...) \
  GREYISetFileLineAsFailable(fileName, lineNumber);                 \
  GREYIAssertNotNil(__a1, ##__VA_ARGS__)

#define GREYAssertNilAtFileLine(__a1, fileName, lineNumber, ...) \
  GREYISetFileLineAsFailable(fileName, lineNumber);              \
  GREYIAssertNil(__a1, ##__VA_ARGS__)

#define GREYAssertEqualAtFileLine(__a1, __a2, fileName, lineNumber, ...) \
  GREYISetFileLineAsFailable(fileName, lineNumber);                      \
  GREYIAssertEqual(__a1, __a2, ##__VA_ARGS__)

#define GREYAssertNotEqualAtFileLine(__a1, __a2, fileName, lineNumber, ...) \
  GREYISetFileLineAsFailable(fileName, lineNumber);                         \
  GREYIAssertNotEqual(__a1, __a2, ##__VA_ARGS__)

#define GREYAssertGreaterThanAtFileLine(__a1, __a2, fileName, lineNumber, ...) \
  GREYISetFileLineAsFailable(fileName, lineNumber);                            \
  GREYIAssertGreaterThan(__a1, __a2, ##__VA_ARGS__)

#define GREYAssertGreaterThanOrEqualAtFileLine(__a1, __a2, fileName, \
                                               lineNumber, ...)      \
  GREYISetFileLineAsFailable(fileName, lineNumber);                  \
  GREYIAssertGreaterThanOrEqual(__a1, __a2, ##__VA_ARGS__)

#define GREYAssertLessThanAtFileLine(__a1, __a2, fileName, lineNumber, ...) \
  GREYISetFileLineAsFailable(fileName, lineNumber);                         \
  GREYIAssertLessThan(__a1, __a2, ##__VA_ARGS__)

#define GREYAssertLessThanOrEqualAtFileLine(__a1, __a2, fileName, lineNumber, \
                                            ...)                              \
  GREYISetFileLineAsFailable(fileName, lineNumber);                           \
  GREYIAssertLessThanOrEqual(__a1, __a2, ##__VA_ARGS__)

#define GREYAssertEqualObjectsAtFileLine(__a1, __a2, fileName, lineNumber, \
                                         ...)                              \
  GREYISetFileLineAsFailable(fileName, lineNumber);                        \
  GREYIAssertEqualObjects(__a1, __a2, ##__VA_ARGS__)

#define GREYAssertNotEqualObjectsAtFileLine(__a1, __a2, fileName, lineNumber, \
                                            ...)                              \
  GREYISetFileLineAsFailable(fileName, lineNumber);                           \
  GREYIAssertNotEqualObjects(__a1, __a2, ##__VA_ARGS__)

NS_ASSUME_NONNULL_END

#endif  // GREY_MESSAGE_OPTIONAL_ASSERTS

#endif  // GREY_ASSERT_H
