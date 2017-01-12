//
// Copyright 2016 Google Inc.
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
 *  @file GREYAssertions+Internal.h
 *  @brief Exposes GREYAssertions' interfaces and methods that are otherwise private for
 *  testing purposes.
 */

#import <EarlGrey/GREYAssertion.h>
@protocol GREYMatcher;

@interface GREYAssertions (Internal)

/**
*  Create a GREYAssertion with the provided @c matcher to check assertions on elements.
*
*  @param matcher The GREYMatcher object to be matched by the assertion.
*
*  @return A GREYAssertion object that can be used to match an object with the provided @c matcher.
*
*  @remark This is available only for internal testing purposes.
*/
+ (id<GREYAssertion>)grey_createAssertionWithMatcher:(id<GREYMatcher>)matcher;

@end
