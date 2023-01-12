//
// Copyright 2023 Google Inc.
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

#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>

/** Enable the type to be the value type so it will be passed by copy. */
#define EDO_ENABLE_VALUETYPE(__class) \
  @implementation __class (EDOValue)  \
  -(BOOL)edo_isEDOValueType {         \
    return YES;                       \
  }                                   \
  @end

/**
 * These are classes that are value types in the testing process, and are reference types in the app
 * process. It guarantees these classes are always real objects in the app process, while allows
 * them to be created locally or with GREY_REMOTE_CLASS_IN_APP in the testing process.
 *
 * @note Methods that return these classes from the app still return reference types. Please use
 *       -returnByValue on the proxy to get the value type objects.
 */
EDO_ENABLE_VALUETYPE(NSAttributedString)
