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

#import "GREYBaseMatcher.h"

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Matcher for combining multiple matchers with a logical @c OR operator, so that a match occurs
 *  when any of the matchers match the element. The invocation of the matchers is in the same
 *  order in which they are passed. As soon as one of the matchers succeeds, the rest are
 *  not invoked.
 */
@interface GREYAnyOf : GREYBaseMatcher

/**
 *  @remark init is not an available initializer. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 *  Designated initializer to add all the matchers to be checked.
 *
 *  @param matchers The matchers, one of which is required to be matched by the matcher.
 *                  They are invoked in the order that they are passed in.
 *
 *  @return An instance of GREYAnyOf, initialized with the provided matchers.
 */
- (instancetype)initWithMatchers:(NSArray<__kindof id<GREYMatcher>> *)matchers
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
