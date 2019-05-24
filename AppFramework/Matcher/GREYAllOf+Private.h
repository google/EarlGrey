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

#import "AppFramework/Matcher/GREYAllOf.h"
#import "CommonLib/Matcher/GREYBaseMatcher+Private.h"
NS_ASSUME_NONNULL_BEGIN

/** Private category for diagnostics purpose. */
@interface GREYAllOf ()

/**
 *  Internal initializer for GREYAllOf to incorporate with Diagnostics.
 *  @remark Do NOT use this externally.
 *
 *  @param matchers   Matchers that conform to GREYMatcher and will be combined together with
 *                    a logical AND in the order they are passed in.
 *  @param name       Identifier for an internally created matcher.
 *
 *  @return An instance of GREYAllOf, initialized with the provided @c matchers and name.
 */
- (instancetype)initWithMatchers:(NSArray<__kindof id<GREYMatcher>> *)matchers
                            name:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
