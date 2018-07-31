//
// Copyright 2018 Google Inc.
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

#import <EarlGrey/GREYBaseAction.h>
#import <EarlGrey/GREYConstants.h>

/**
 *  A GREYAction that swipes/flicks the matched element from a concrete start point to an end point.
 */
@interface GREYPreciseSwipeAction : GREYBaseAction

/**
 *  @remark init is not an available initializer. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 *  @remark initWithName:constraints: is overridden from its superclass.
 */
- (instancetype)initWithName:(NSString *)name
                 constraints:(id<GREYMatcher>)constraints NS_UNAVAILABLE;

/**
 *  Performs a swipe from the given @c startPoint to the given @c endPoint.
 *
 *  @param startPoint The point where the swipe should begin. Relative to the matched view's origin.
 *  @param endPoint   The point where the swipe should end. Relative to the matched view's origin.
 *  @param duration   The time interval for which the swipe takes place.
 *
 *  @return An instance of GREYPreciseSwipeAction, initialized with the provided start point,
 *  end point and duration.
 */
- (instancetype)initWithStartPoint:(CGPoint)startPoint
                          endPoint:(CGPoint)endPoint
                          duration:(CFTimeInterval)duration;

@end
