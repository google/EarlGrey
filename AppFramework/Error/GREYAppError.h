//
// Copyright 2019 Google Inc.
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

#import "GREYFailureScreenshotter.h"
#import "GREYError.h"
#import "GREYElementHierarchy.h"

/**
 *  Creates a @c GREYError object on the app side with given @c domain, @c code and
 *  @c description. The description is accessible by querying
 *  error's @c userInfo with @c NSLocalizedDescriptionKey.
 *
 *  @param domain      The error domain.
 *  @param code        The error code.
 *  @param description The error's localized description.
 *
 *  @return A @c GREYError object with the given input.
 */
#define GREYErrorMakeWithHierarchy(domain, code, description)                          \
  I_GREYErrorMake((domain), (code), @{NSLocalizedDescriptionKey : (description)},      \
                  [NSString stringWithUTF8String:__FILE__], __LINE__,                  \
                  [NSString stringWithUTF8String:__PRETTY_FUNCTION__], nil,            \
                  [NSThread callStackSymbols], [GREYElementHierarchy hierarchyString], \
                  [GREYFailureScreenshotter screenshots])

/**
 *  If @c errorRef is not @c NULL, it is set to a @c GREYError object that is created with
 *  the given @c domain, @c code and @c description.
 *  The description is accessible by querying error's @c userInfo with
 *  @c NSLocalizedDescriptionKey.
 *
 *  @param[out] errorRef    A @c GREYError reference for retrieving the created
 *                          error object.
 *  @param      domain      The error domain.
 *  @param      code        The error code.
 *  @param      description The error's localized description.
 *
 */
#define I_GREYPopulateError(errorRef, domain, code, description)                \
  ({                                                                            \
    GREYError *e = GREYErrorMakeWithHierarchy((domain), (code), (description)); \
    if (errorRef) {                                                             \
      *errorRef = e;                                                            \
    }                                                                           \
  })

/**
 *  If @c errorRef is not @c NULL, it is set to a @c GREYError object that is created with
 *  the given @c domain, @c code, @c description and @c note.
 *  The description is accessible by querying error's @c userInfo with
 *  @c NSLocalizedDescriptionKey.
 *
 *  @param[out] errorRef    A @c GREYError reference for retrieving the created
 *                          error object.
 *  @param      domain      The error domain.
 *  @param      code        The error code.
 *  @param      description The error's localized description.
 *  @param      glossary    A glossary dictionary that is going to be populated with the error.
 *
 */
#define I_GREYPopulateErrorNoted(errorRef, domain, code, description, glossary) \
  ({                                                                            \
    GREYError *e = GREYErrorMakeWithHierarchy((domain), (code), (description)); \
    e.descriptionGlossary = (glossary);                                         \
    if (errorRef) {                                                             \
      *errorRef = e;                                                            \
    }                                                                           \
  })
