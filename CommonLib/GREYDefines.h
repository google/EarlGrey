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
 *  @file GREYDefines.h
 *  @brief Miscellaneous defines and macros for EarlGrey.
 */

#ifndef GREY_DEFINES_H
#define GREY_DEFINES_H

#import <UIKit/UIKit.h>

#define GREY_EXPORT FOUNDATION_EXPORT __used
#define GREY_EXTERN FOUNDATION_EXTERN
#define GREY_UNUSED_VARIABLE __attribute__((unused))

#define iOS11_OR_ABOVE() ([UIDevice currentDevice].systemVersion.intValue >= 11)
#define iOS13_OR_ABOVE() ([UIDevice currentDevice].systemVersion.intValue >= 13)

#pragma mark - Math

/**
 *  @return The smallest @c int following the @c double @c x. This macro is needed to avoid
 *          rounding errors when "modules" project setting is enabled causing math functions to
 *          map from tgmath.h to math.h.
 */
#define grey_ceil(x) ((CGFloat)ceil(x))

/**
 *  @return The largest @c int less than the @c double @c x. This macro is needed to avoid
 *          rounding errors when "modules" project setting is enabled causing math functions to
 *          map from tgmath.h to math.h.
 */
#define grey_floor(x) ((CGFloat)floor(x))

#endif  // GREY_DEFINES_H
