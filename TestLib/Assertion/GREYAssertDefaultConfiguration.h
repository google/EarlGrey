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

#ifndef GREY_ASSERT_DEFAULT_CONFIGURATION_H
#define GREY_ASSERT_DEFAULT_CONFIGURATION_H

#import <Foundation/Foundation.h>

#import "GREYDefines.h"

/**
 * Initializes the GREYAssert macros runtime.
 *
 * In order to use the GREYAssert macros in an EarlGrey test, this function
 * should be called once before any macro is invoked.
 */
GREY_EXTERN void GREYIAssertDefaultConfiguration(void);

#endif  // GREY_ASSERT_DEFAULT_CONFIGURATION_H
