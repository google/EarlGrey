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

NS_ASSUME_NONNULL_BEGIN

/**
 *  A block for implementing GREYBaseMatcher::matches:.
 *
 *  @param element The element passed to the block for matching.
 *
 *  @return @c YES if the matcher's specified condition was matched by the element, else @c NO.
 */
typedef BOOL (^GREYMatchesBlock)(id element);

/**
 *  A block for implementing GREYBaseMatcher::describeTo:.
 *
 *  @param description The description for the matcher.
 */
typedef void (^GREYDescribeToBlock)(id<GREYDescription> description);

@protocol GREYDescription;

/**
 *  A block based implementation of GREYBaseMatcher. Enables custom implementation of protocol
 *  method using blocks.
 */
@interface GREYElementMatcherBlock : GREYBaseMatcher

/**
 *  The block which will be invoked for the GREYBaseMatcher::matches: method.
 */
@property(nonatomic, copy) GREYMatchesBlock matcherBlock;

/**
 *  The block which will be invoked for the GREYBaseMatcher::describeTo: method.
 */
@property(nonatomic, copy) GREYDescribeToBlock descriptionBlock;

/**
 *  Class method to instantiate a custom matcher.
 *
 *  @param matchBlock    A block for implementing GREYBaseMatcher::matches: method.
 *  @param describeBlock The block which will be invoked for the GREYBaseMatcher::describeTo:
 *                       method.
 *
 *  @return A GREYElementMatcherBlock instance, initialized with the required matching
 *          condition and description.
 */
+ (instancetype)matcherWithMatchesBlock:(GREYMatchesBlock)matchBlock
                       descriptionBlock:(GREYDescribeToBlock)describeBlock;

/**
 *  @remark init is not an available initializer. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 *  Initializes a custom matcher.
 *
 *  @param matchBlock    A block for implementing GREYBaseMatcher::matches: method.
 *  @param describeBlock The block which will be invoked for the GREYBaseMatcher::describeTo:
 *                       method.
 *
 *  @return A GREYElementMatcherBlock instance, initialized with the required matching
 *          condition and description.
 */
- (instancetype)initWithMatchesBlock:(GREYMatchesBlock)matchBlock
                    descriptionBlock:(GREYDescribeToBlock)describeBlock NS_DESIGNATED_INITIALIZER;
@end

NS_ASSUME_NONNULL_END
