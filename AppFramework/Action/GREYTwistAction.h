//
// Copyright 2022 Google Inc.
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

#import "GREYBaseAction.h"
#import "GREYConstants.h"

/**
 * A @c GREYAction that performs the twist gesture on the view on which it is called.
 */
@interface GREYTwistAction : GREYBaseAction

/**
 * Performs a twist action with a given @c twistAngle over the specified @c duration.  Each
 * twist starts with two points equidistant from the view's center, moving along a circular
 * path in the appropriate direction for the specified angular distance.
 *
 * The points are spaced so that the circular path falls 80% of the way from the center point
 * to the closer of the view's bounds (horizontally or vertically).
 *
 * For a clockwise pinch, the points start out vertically aligned, to match a typical
 * thumb-and-middle-finger twist.
 *
 * For a counterclockwise pinch, the points start out horizontally aligned, to match a typical
 * index-finger-and-middle-finger twist.
 *
 * @param duration   The time interval over which the twist takes place.
 * @param twistAngle Angle of the rotation in radians.  A negative angle indicates a
 *                   clockwise twist.  A positive angle indicates a counterclockwise twist.
 *
 * @returns An instance of @c GREYTwistAction, initialized with a provided direction and
 *          duration and angle.
 */
- (instancetype)initWithDuration:(CFTimeInterval)duration twistAngle:(double)twistAngle;

@end
