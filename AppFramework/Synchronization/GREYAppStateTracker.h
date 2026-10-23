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

#import <Foundation/Foundation.h>

#import "GREYIdlingResource.h"
#import "GREYAppState.h"

@class GREYAppStateTrackerObject;

NS_ASSUME_NONNULL_BEGIN

/**
 * @file
 * @brief App state tracker header file.
 */

/**
 * Idling resource that tracks the application state.
 */
@interface GREYAppStateTracker : NSObject <GREYIdlingResource>

/**
 * @return The unique shared instance of the GREYAppStateTracker.
 */
+ (instancetype)sharedInstance;

/**
 * @remark init is not an available initializer. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 * @return The state that the App is in currently.
 */
- (GREYAppState)currentState;

/**
 * Updates the state of the object, including the provided @c state and updating the overall state
 * of the application. If @c object is already being tracked with for a different state, the
 * object's state will be updated to a XOR of the current state and @c state.
 *
 * @param state  The state that should be tracked for the object.
 * @param object The object that should have its tracked state updated.
 *
 * @return The GREYAppStateTracker that was assigned to the object by the state tracker, or @c nil
 *         if @c object is @c nil. Future calls for the same object will return the same
 *         identifier until the object is untracked.
 */
- (GREYAppStateTrackerObject *_Nullable)trackState:(GREYAppState)state forObject:(id)object;

/**
 * Tracks @c state for @c object and schedules a single coalesced @c dispatch_async on the main
 * queue to untrack @c state on the next main runloop/queue drain. Repeated calls for the same
 * @c state and @c object before the main queue drains are coalesced so at most one main-queue
 * untrack block is pending per state bit per object.
 *
 * @param state  The state that should be tracked until the next main-queue drain.
 * @param object The object that should have its tracked state updated.
 *
 * @return The GREYAppStateTrackerObject associated with @c object, or @c nil if @c object is @c
 * nil.
 */
- (GREYAppStateTrackerObject *_Nullable)trackStateUntilNextMainQueueDrain:(GREYAppState)state
                                                                forObject:(id)object;

/**
 * Tracks @c kGREYPendingDrawLayoutPass for @c object until the next main-queue drain and returns
 * whether the caller should forward the synchronous layout invalidation to the original
 * implementation.
 *
 * When an object enters a synchronous layout/observation feedback loop inside
 * @c CA::Layer::layout_if_needed (where @c viewDidLayoutSubviews or @c layoutSubviews repeatedly
 * calls @c setNeedsLayout without returning to the runloop), this method returns @c NO once the
 * object exceeds the per-turn synchronous pass threshold, allowing @c CA::Layer::layout_if_needed
 * to exit cleanly and drain the main runloop.
 *
 * @param object The view or layer requesting a layout pass.
 *
 * @return @c YES if the original implementation should be invoked synchronously; @c NO if the
 *         object has exceeded the per-turn synchronous invalidation threshold.
 */
- (BOOL)trackDrawLayoutPassUntilNextMainQueueDrainForObject:(id)object;

/**
 * Untracks the state for the object with the specified id. For untracking, it does not matter
 * if the state has been added to being ignored.
 *
 * @param state  The state that should be untracked.
 * @param object The GREYAppStateTrackerObject associated with the object whose state should be
 *               untracked.
 */
- (void)untrackState:(GREYAppState)state forObject:(GREYAppStateTrackerObject *)object;

/**
 * Clears all states that are tracked by the GREYAppStateTracker singleton.
 *
 * @remark This is available only for internal testing purposes.
 */
- (void)clearState;

@end

/**
 * Utility macro for tracking the state of an object.
 *
 * @param state  The state that should be tracked for the object.
 * @param object The object that should have its tracked state updated.
 *
 * @return The GREYAppStateTracker that was assigned to the object by the state tracker, or @c nil
 *         if @c object is @c nil. Future calls for the same object will return the same
 *         identifier until the object is untracked.
 */
#define TRACK_STATE_FOR_OBJECT(state_, object_) \
  [[GREYAppStateTracker sharedInstance] trackState:(state_) forObject:(object_)]

/**
 * Utility macro for tracking the state of an object until the next main-queue drain, coalescing
 * duplicate main-queue untrack dispatches while the state is already pending untrack.
 *
 * @param state_  The state that should be tracked for the object until the next main-queue drain.
 * @param object_ The object that should have its tracked state updated.
 */
#define TRACK_STATE_UNTIL_NEXT_MAIN_QUEUE_DRAIN_FOR_OBJECT(state_, object_)        \
  [[GREYAppStateTracker sharedInstance] trackStateUntilNextMainQueueDrain:(state_) \
                                                                forObject:(object_)]

/**
 * Utility macro for tracking a draw/layout pass until the next main-queue drain and checking
 * whether the synchronous invalidation should be forwarded to the original implementation.
 */
#define TRACK_DRAW_LAYOUT_PASS_UNTIL_NEXT_MAIN_QUEUE_DRAIN_FOR_OBJECT(object_) \
  [[GREYAppStateTracker sharedInstance]                                        \
      trackDrawLayoutPassUntilNextMainQueueDrainForObject:(object_)]

/**
 * Utility macro for untracking the state of an object.
 *
 * @param state  The state that should be untracked.
 * @param object The GREYAppStateTrackerObject associated with the object whose state should be
 *               untracked.
 */
#define UNTRACK_STATE_FOR_OBJECT(state_, object_) \
  [[GREYAppStateTracker sharedInstance] untrackState:(state_) forObject:(object_)]

NS_ASSUME_NONNULL_END
