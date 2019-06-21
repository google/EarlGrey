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
 *  @file
 *  @brief Private helper macros for performing assertions and throwing assertion failure
 *  exceptions. On failure, these macros delegate the tasks such as printing failure details,
 *  taking screenshots and logging the full view hierarchy to the provided failure handler.
 *  Barring the marked public macros here, these should only be called privately, from within
 *  the framework. The public version of these macros, which waits for the app to idle is
 *  provided in the GREYAssertionDefines file.
 */

#ifndef COMMON_GREY_ASSERTION_DEFINES_H
#define COMMON_GREY_ASSERTION_DEFINES_H

#import "GREYFailureHandler.h"
#import "GREYFrameworkException.h"
#import "GREYDefines.h"

#pragma mark - Private Macros

// Key used to fetch failure handler from thread object's dictionary.
GREY_EXTERN NSString *const GREYFailureHandlerKey;

// No private macro should call this.
#define I_GREYSetCurrentAsFailable()                                                             \
  ({                                                                                             \
    id<GREYFailureHandler> failureHandler__ =                                                    \
        [NSThread currentThread].threadDictionary[GREYFailureHandlerKey];                        \
    if ([failureHandler__ respondsToSelector:@selector(setInvocationFile:andInvocationLine:)]) { \
      NSString *invocationFile = [NSString stringWithUTF8String:__FILE__];                       \
      if (invocationFile) {                                                                      \
        [failureHandler__ setInvocationFile:invocationFile andInvocationLine:__LINE__];          \
      }                                                                                          \
    }                                                                                            \
  })

// TODO: Manually format until better support for pragma's is provided..
// clang-format off
#define I_GREYFormattedString(__var, __format, ...)                                              \
  ({                                                                                             \
    /* clang warns us about a leak in formatting but we don't care as we are about to fail. */   \
    _Pragma("clang diagnostic push")                                                             \
    _Pragma("clang diagnostic ignored \"-Wformat-nonliteral\"")                                  \
    _Pragma("clang diagnostic ignored \"-Wformat-security\"")                                    \
    (__var) =  [NSString stringWithFormat:(__format), ##__VA_ARGS__];                            \
    _Pragma("clang diagnostic pop")                                                              \
  })
// clang-format on

#define I_GREYRegisterFailure(__exceptionName, __description, __details, ...)                    \
  ({                                                                                             \
    NSString *details__;                                                                         \
    I_GREYFormattedString(details__, __details, ##__VA_ARGS__);                                  \
    id<GREYFailureHandler> failureHandler__ =                                                    \
        [NSThread currentThread].threadDictionary[GREYFailureHandlerKey];                        \
    [failureHandler__ handleException:[GREYFrameworkException exceptionWithName:__exceptionName  \
                                                                         reason:(__description)] \
                              details:(details__)];                                              \
  })

#define I_GREYAssertTrue(__a1, __description, ...)                                          \
  ({                                                                                        \
    if (!(__a1)) {                                                                          \
      NSString *formattedDescription__;                                                     \
      I_GREYFormattedString(formattedDescription__, (__description), ##__VA_ARGS__);        \
      I_GREYRegisterFailure(kGREYAssertionFailedException, @"((" #__a1 ") is true) failed", \
                            formattedDescription__);                                        \
    }                                                                                       \
  })

#define I_GREYAssertFalse(__a1, __description, ...)                                          \
  ({                                                                                         \
    if ((__a1)) {                                                                            \
      NSString *formattedDescription__;                                                      \
      I_GREYFormattedString(formattedDescription__, (__description), ##__VA_ARGS__);         \
      I_GREYRegisterFailure(kGREYAssertionFailedException, @"((" #__a1 ") is false) failed", \
                            formattedDescription__);                                         \
    }                                                                                        \
  })

#define I_GREYAssertNotNil(__a1, __description, ...)                                 \
  ({                                                                                 \
    if ((__a1) == nil) {                                                             \
      NSString *formattedDescription__;                                              \
      I_GREYFormattedString(formattedDescription__, (__description), ##__VA_ARGS__); \
      I_GREYRegisterFailure(kGREYNotNilException, @"((" #__a1 ") != nil) failed",    \
                            formattedDescription__);                                 \
    }                                                                                \
  })

#define I_GREYAssertNil(__a1, __description, ...)                                    \
  ({                                                                                 \
    if ((__a1) != nil) {                                                             \
      NSString *formattedDescription__;                                              \
      I_GREYFormattedString(formattedDescription__, (__description), ##__VA_ARGS__); \
      I_GREYRegisterFailure(kGREYNilException, @"((" #__a1 ") == nil) failed",       \
                            formattedDescription__);                                 \
    }                                                                                \
  })

#define I_GREYAssertEqual(__a1, __a2, __description, ...)                                          \
  ({                                                                                               \
    if ((__a1) != (__a2)) {                                                                        \
      NSString *formattedDescription__;                                                            \
      I_GREYFormattedString(formattedDescription__, (__description), ##__VA_ARGS__);               \
      I_GREYRegisterFailure(kGREYAssertionFailedException, @"((" #__a1 ") == (" #__a2 ")) failed", \
                            formattedDescription__);                                               \
    }                                                                                              \
  })

#define I_GREYAssertNotEqual(__a1, __a2, __description, ...)                                       \
  ({                                                                                               \
    if ((__a1) == (__a2)) {                                                                        \
      NSString *formattedDescription__;                                                            \
      I_GREYFormattedString(formattedDescription__, (__description), ##__VA_ARGS__);               \
      I_GREYRegisterFailure(kGREYAssertionFailedException, @"((" #__a1 ") != (" #__a2 ")) failed", \
                            formattedDescription__);                                               \
    }                                                                                              \
  })

#define I_GREYAssertEqualObjects(__a1, __a2, __description, ...)                                  \
  ({                                                                                              \
    if (![(__a1) isEqual:(__a2)]) {                                                               \
      NSString *formattedDescription__;                                                           \
      I_GREYFormattedString(formattedDescription__, (__description), ##__VA_ARGS__);              \
      I_GREYRegisterFailure(kGREYAssertionFailedException,                                        \
                            @"[(" #__a1 ") isEqual:(" #__a2 ")] failed", formattedDescription__); \
    }                                                                                             \
  })

#define I_GREYAssertNotEqualObjects(__a1, __a2, __description, ...)                                \
  ({                                                                                               \
    if ([(__a1) isEqual:(__a2)]) {                                                                 \
      NSString *formattedDescription__;                                                            \
      I_GREYFormattedString(formattedDescription__, (__description), ##__VA_ARGS__);               \
      I_GREYRegisterFailure(kGREYAssertionFailedException,                                         \
                            @"![(" #__a1 ") isEqual:(" #__a2 ")] failed", formattedDescription__); \
    }                                                                                              \
  })

#define I_GREYFail(__description, ...)                                                \
  ({                                                                                  \
    NSString *formattedDescription__;                                                 \
    I_GREYFormattedString(formattedDescription__, __description, ##__VA_ARGS__);      \
    I_GREYRegisterFailure(kGREYGenericFailureException, formattedDescription__, @""); \
  })

#define I_GREYFailWithDetails(__description, __details, ...) \
  I_GREYRegisterFailure(kGREYGenericFailureException, __description, __details, ##__VA_ARGS__)

#define I_GREYTimeout(__description, __details, ...) \
  I_GREYRegisterFailure(kGREYTimeoutException, __description, __details, ##__VA_ARGS__)

#define I_GREYActionFail(__description, __details, ...) \
  I_GREYRegisterFailure(kGREYActionFailedException, __description, __details, ##__VA_ARGS__)

#endif  // COMMON_GREY_ASSERTION_DEFINES_H
