//
// Copyright 2021 Google Inc.
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

#import "GREYMatcher.h"

/**
 * @return A BOOL signifying if a matcher is related to visibility or not.
 *
 * @param matcher The matcher to be checked.
 **/
BOOL GREYIsVisibilityMatcher(id<GREYMatcher> matcher);

/**
 * @throw A kGREYImproperMatcherOrderingException with the provided matcherList.
 *
 * @param matcherList The list of matchers that is improperly ordered.
 **/
void GREYThrowImproperOrderException(NSArray<id<GREYMatcher>> *matcherList);

/**
 * @return An NSMutableArray with usability matchers in the @c matcherList moved to the end.
 *
 * @param matcherList A list of matchers, provided from GREYAnyOf or GREYAllOf matchers.
 */
NSArray<id<GREYMatcher>> *GREYMatchersCheckedForImproperOrdering(
    NSArray<id<GREYMatcher>> *matcherList);
