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

#import "GREYElementMatcherBlock.h"

NS_ASSUME_NONNULL_BEGIN

/** Private category for diagnostics purpose. */
@interface GREYElementMatcherBlock (Private)

/**
 *  Internal initializer for GREYElementMatcherBlock to incorporate with Diagnostics.
 *  @remark Do NOT use this externally.
 *
 *  @param name          Identifier for internally created matcher.
 *  @param matchBlock    A block for implementing GREYBaseMatcher::matches: method.
 *  @param describeBlock The block which will be invoked for the GREYBaseMatcher::describeTo:
 *                       method.
 *
 *  @return A GREYElementMatcherBlock instance, initialized with the required matching
 *          condition, description and its name.
 */
- (instancetype)initWithName:(NSString *)name
                matchesBlock:(GREYMatchesBlock)matchBlock
            descriptionBlock:(GREYDescribeToBlock)describeBlock;

@end

NS_ASSUME_NONNULL_END
