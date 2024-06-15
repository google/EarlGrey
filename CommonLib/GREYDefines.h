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
 * @file GREYDefines.h
 * @brief Miscellaneous defines and macros for EarlGrey.
 */

#ifndef GREY_DEFINES_H
#define GREY_DEFINES_H

#import <UIKit/UIKit.h>

#define GREY_EXPORT FOUNDATION_EXPORT __used
#define GREY_EXTERN FOUNDATION_EXTERN
#define GREY_UNUSED_VARIABLE __attribute__((unused))

#define iOS11_OR_ABOVE() ([UIDevice currentDevice].systemVersion.intValue >= 11)
#define iOS12_OR_ABOVE() ([UIDevice currentDevice].systemVersion.intValue >= 12)
#define iOS13() ([UIDevice currentDevice].systemVersion.intValue == 13)
#define iOS13_OR_ABOVE() ([UIDevice currentDevice].systemVersion.intValue >= 13)
#define iOS13_7_OR_ABOVE() ([UIDevice currentDevice].systemVersion.doubleValue >= 13.7)
#define iOS14_OR_ABOVE() ([UIDevice currentDevice].systemVersion.intValue >= 14)
#define iOS17_OR_ABOVE() ([UIDevice currentDevice].systemVersion.intValue >= 17)
#define iOS17_4_OR_ABOVE() ([UIDevice currentDevice].systemVersion.doubleValue >= 17.4)
#define iOS18_OR_ABOVE() ([UIDevice currentDevice].systemVersion.intValue >= 18)

/** A macro for declaring intentional fallthrough in switch statements. */
#if defined(__clang__)
#if __has_attribute(fallthrough)
#define GREY_FALLTHROUGH_INTENDED __attribute__((fallthrough))
#else  // No attribute is available.
#define GREY_FALLTHROUGH_INTENDED
#endif
#else  // defined(__clang__)
#define GREY_FALLTHROUGH_INTENDED
#endif  // defined(__clang__)

/**
 * A macro for marking entry points that have increased visibility only for the sake
 * of internal unit tests. These entry points should not be used by tests written against
 * EarlGrey.
 */
#define GREY_VISIBLE_FOR_INTERNAL_TESTING

#pragma mark - Math

/**
 * @return The smallest @c int following the @c double @c x. This macro is needed to avoid
 *         rounding errors when "modules" project setting is enabled causing math functions to
 *         map from tgmath.h to math.h.
 */
#define grey_ceil(x) ((CGFloat)ceil(x))

/**
 * @return The largest @c int less than the @c double @c x. This macro is needed to avoid
 *         rounding errors when "modules" project setting is enabled causing math functions to
 *         map from tgmath.h to math.h.
 */
#define grey_floor(x) ((CGFloat)floor(x))

/** @return Sanitizers are enabled for EarlGrey. */
#if defined(__has_feature)
#define SANITIZERS_ENABLED                                               \
  __has_feature(address_sanitizer) || __has_feature(thread_sanitizer) || \
      __has_feature(undefined_behavior_sanitizer) || __has_feature(memory_sanitizer)
#else
#define SANITIZERS_ENABLED NO
#endif

#endif  // GREY_DEFINES_H
