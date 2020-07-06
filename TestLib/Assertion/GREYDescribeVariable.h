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

#import <Foundation/Foundation.h>

#import "GREYDefines.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Returns a human-readable string displaying the value of the data.
 * Only intended for use with the macro below.
 *
 * @param     encoding     The Objective-C @encode value for the data.
 * @param[in] valuePointer A pointer to the data.
 *
 * This function must be used on data stored in a variable (not an expression). Typical
 * usage would be:
 *      int64_t sum = CalculateSum();
 *      NSLog(@"%@", GREYDescribeValue(@encode(int64_t), &sum);
 *
 * In practice the only reason this function is needed is so values can be printed
 * from macros, where the type of the parameters is unknown. See the
 * GREYDescribeVariable macro below.
 *
 * @note This function does not display meaningful results for structs, unions,
 *       or C++ classes (it will return "class/struct <Name>" or a similar string).
 * @note There's no need to access the function from Swift code. In Swift, an even
 *       better description of any data value can be obtained from String(describing: item).
 */
GREY_EXTERN NSString *_Nonnull GREYDescribeValue(const char *_Nonnull encoding,
                                                 void *_Nonnull valuePointer);

/**
 * Given a variable, returns a string describing the variable's value.
 *
 * See the function description above for limitations.
 */
#define GREYDescribeVariable(a) GREYDescribeValue(@encode(__typeof__(a)), (void *)&a)

/**
 * Given an NSObject, returns a human-readable description of the object.
 *
 * This will be based on the -description method unless the object is @c nil.
 */
GREY_EXTERN NSString *_Nonnull GREYDescribeObject(NSObject *_Nullable object);

NS_ASSUME_NONNULL_END
