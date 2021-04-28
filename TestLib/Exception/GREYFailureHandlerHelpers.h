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

@class GREYFrameworkException;

/**
 * @return The hierarchy string of all the windows. Does not include the legend.
 *
 * @param exception The exception containing the raw UI Hierarchy in its userInfo dictionary.
 * @param details   The exception details to check for certain keys being present.
 */
NSString *GREYAppUIHierarchyFromException(GREYFrameworkException *exception, NSString *details);

/**
 * @return The stack trace if the failure happened in an Objective-C test failure.
 */
NSString *GREYTestStackTrace(void);
