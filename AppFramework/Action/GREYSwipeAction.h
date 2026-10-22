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

#import "GREYBaseAction.h"
#import "GREYConstants.h"

/**
 * A GREYAction that swipes/flicks the matched element.
 */
@interface GREYSwipeAction : GREYBaseAction

/**
 * @remark init is not an available initializer. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 * @remark initWithName::constraints: is overridden from its superclass.
 */
- (instancetype)initWithName:(NSString *)name
                 constraints:(id<GREYMatcher>)constraints NS_UNAVAILABLE;

/**
 * Performs a swipe in the given @c direction in the given @c duration, the start of swipe is
 * chosen to achieve maximum swipe, such as a point close to bottom edge of the element is chosen
 * in case of a swipe in up direction
 *
 * @param direction The direction of the swipe.
 * @param duration  The time interval for which the swipe takes place.
 *
 * @return An instance of GREYSwipeAction, initialized with the provided direction and duration.
 */
- (instancetype)initWithDirection:(GREYDirection)direction duration:(CFTimeInterval)duration;

/**
 * Performs a swipe in the given @c direction in the given @c duration, the start of swipe is
 * chosen based on @c startPercents. Since swipes must begin inside the element and not
 * on the edge of it x/y startPercents must be in the range (0,1) exclusive.
 *
 * @param direction     The direction of the swipe.
 * @param duration      The time interval for which the swipe takes place.
 * @param startPercents @c startPercents.x sets the value of the x-coordinate of the start point
 *                      by interpolating between left(for 0.0) and right(for 1.0) edge similarly
 *                      @c startPercents.y determines the y coordinate.
 *
 * @return An instance of GREYSwipeAction, initialized with the provided direction, duration
 *         and information for the start point.
 */
- (instancetype)initWithDirection:(GREYDirection)direction
                         duration:(CFTimeInterval)duration
                    startPercents:(CGPoint)startPercents;

/**
 * Initializes an action that swipes in @c direction over @c duration, starting at the point given
 * by @c startPercents, and calls the given handlers while the touch is down. Because a swipe must
 * begin inside the element rather than on its edge, both coordinates of @c startPercents must be
 * strictly between 0 and 1.
 *
 * Use the handlers to observe app state at precise points in the gesture, for example, to verify
 * that the app does not finish an operation until the touch is lifted. Each handler runs
 * synchronously, and touch delivery pauses until it returns. touchesBeganHandler runs on the
 * thread performing the action (a background thread in the app process), so the app's main run
 * loop keeps running meanwhile. touchesWillEndHandler runs on the main thread immediately before
 * the touch-ended event is injected, so the app's main thread is blocked while it runs. If a
 * handler is a block created in the test process, EarlGrey invokes it in the test process over
 * eDistantObject. Handlers must not perform EarlGrey interactions, because the swipe is still in
 * progress.
 *
 * Handlers should return quickly, because EarlGrey timestamps each touch event with the real time
 * at which it is delivered. A slow touchesBeganHandler delays the first touch-moved event, which
 * can make swipe gesture recognizers fail or trigger long-press gesture recognizers. A slow
 * touchesWillEndHandler holds the touch stationary before it is lifted, which reduces the release
 * velocity and can suppress scroll or pan deceleration.
 *
 * If a handler raises an exception, the rest of the swipe still runs and the exception propagates
 * after the touch is lifted. If touchesBeganHandler raises, touchesWillEndHandler is not called.
 *
 * @param direction             The direction of the swipe.
 * @param duration              The time interval for which the swipe takes place.
 * @param startPercents         @c startPercents.x sets the value of the x-coordinate of the start
 *                              point by interpolating between left(for 0.0) and right(for 1.0)
 *                              edge similarly @c startPercents.y determines the y coordinate.
 * @param touchesBeganHandler   If non-nil, called after the touch-began event is delivered and
 *                              before any touch-moved events are delivered.
 * @param touchesWillEndHandler If non-nil, called after the last touch-moved event is delivered
 *                              and immediately before the touch-ended event is delivered.
 *
 * @return An instance of GREYSwipeAction, initialized with the provided direction, duration,
 *         information for the start point, and handlers.
 */
- (instancetype)initWithDirection:(GREYDirection)direction
                         duration:(CFTimeInterval)duration
                    startPercents:(CGPoint)startPercents
              touchesBeganHandler:(dispatch_block_t)touchesBeganHandler
            touchesWillEndHandler:(dispatch_block_t)touchesWillEndHandler;
@end
