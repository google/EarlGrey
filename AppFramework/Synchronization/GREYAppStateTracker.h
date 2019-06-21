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
 *  Idling resource that tracks the application state.
 */
@interface GREYAppStateTracker : NSObject <GREYIdlingResource>

/**
 *  @return The unique shared instance of the GREYAppStateTracker.
 */
+ (instancetype)sharedInstance;

/**
 *  @remark init is not an available initializer. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 *  @return The state that the App is in currently.
 */
- (GREYAppState)currentState;

/**
 *  Updates the state of the object, including the provided @c state and updating the overall state
 *  of the application. If @c object is already being tracked with for a different state, the
 *  object's state will be updated to a XOR of the current state and @c state.
 *
 *  @param state  The state that should be tracked for the object.
 *  @param object The object that should have its tracked state updated.
 *
 *  @return The GREYAppStateTracker that was assigned to the object by the state tracker, or @c nil
 *          if @c object is @c nil. Future calls for the same object will return the same
 *          identifier until the object is untracked.
 */
- (GREYAppStateTrackerObject *_Nullable)trackState:(GREYAppState)state forObject:(id)object;

/**
 *  Untracks the state for the object with the specified id. For untracking, it does not matter
 *  if the state has been added to being ignored.
 *
 *  @param state  The state that should be untracked.
 *  @param object The GREYAppStateTrackerObject associated with the object whose state should be
 *                untracked.
 */
- (void)untrackState:(GREYAppState)state forObject:(GREYAppStateTrackerObject *)object;

/**
 *  Clears all states that are tracked by the GREYAppStateTracker singleton.
 *
 *  @remark This is available only for internal testing purposes.
 */
- (void)grey_clearState;

@end

/**
 *  Utility macro for tracking the state of an object.
 *
 *  @param state  The state that should be tracked for the object.
 *  @param object The object that should have its tracked state updated.
 *
 *  @return The GREYAppStateTracker that was assigned to the object by the state tracker, or @c nil
 *          if @c object is @c nil. Future calls for the same object will return the same
 *          identifier until the object is untracked.
 */
#define TRACK_STATE_FOR_OBJECT(state_, object_) \
  [[GREYAppStateTracker sharedInstance] trackState:(state_) forObject:(object_)]

/**
 *  Utility macro for untracking the state of an object.
 *
 *  @param state  The state that should be untracked.
 *  @param object The GREYAppStateTrackerObject associated with the object whose state should be
 *                untracked.
 */
#define UNTRACK_STATE_FOR_OBJECT(state_, object_) \
  [[GREYAppStateTracker sharedInstance] untrackState:(state_) forObject:(object_)]

NS_ASSUME_NONNULL_END
