//
// Copyright 2020 Google LLC.
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

#import "GREYDispatchQueueInterposer.h"

#import <Block.h>
#import <stdlib.h>

#import "stdatomic.h"  // IWYU pragma: keep
#import "GREYConfigKey.h"
#import "GREYConfiguration.h"
#import "GREYInterposer.h"

// The dispatch_* replacements in this file are interposed into every image of the process, so they
// can be called with any lock held. That includes dyld's loader lock, which dyld holds while it
// runs _dyld_register_func_for_add_image callbacks, and some system frameworks call dispatch_async
// from those callbacks. libobjc's map_images holds the Objective-C runtime lock while it calls into
// dyld. So these functions must never take the runtime lock. They can't send Objective-C messages,
// which take the lock on a method cache miss, and they can't retain or release Objective-C objects
// such as dispatch queues and blocks, whose custom retain and release are Objective-C messages too.
// Otherwise the process can deadlock: one thread holds the dyld lock and waits for the runtime
// lock, while another holds the runtime lock and waits for the dyld lock. This has been seen when
// XCTest loads its automation support library while the accessibility image monitor registers its
// dyld callback during app launch.
//
// For that reason:
//   * Queue and block parameters are __unsafe_unretained, so that ARC never retains them.
//   * Tracked queues are found with dispatch_queue_get_specific (or, for global queues, a fixed
//     table of raw pointers) instead of an NSMapTable.
//   * Tracking state is a reference-counted C struct, and the work to run is wrapped in a malloc'd
//     C struct that is run with the dispatch_*_f functions, instead of an Objective-C block.
// Objective-C is only used when a queue starts being tracked, from the GREYDispatchQueueInterposer
// class, and when dispatch_after(_f) targets a tracked queue (to read the max trackable delay).

/**
 * The tracking state of an interposed dispatch queue: the number of tracked calls that are still
 * pending on it. It is reference counted. The queue holds one reference (for global queues, the
 * reference is never released), each GREYDispatchQueueInterposer for the queue holds one, and each
 * pending tracked call holds one until its work has run.
 */
typedef struct {
  atomic_int pendingCalls;
  atomic_int referenceCount;
} GREYQueueTrackingState;

/** The key under which a GREYQueueTrackingState is attached to a non-global queue. */
static const void *const kGREYQueueTrackingStateKey = &kGREYQueueTrackingStateKey;

/**
 * The maximum number of global queues that can be tracked. Global queues don't support
 * dispatch_queue_set_specific, so their tracking state is kept in a fixed table instead. There are
 * fewer global queues than this (one per QoS class, with and without overcommit).
 */
#define GREY_MAX_TRACKED_GLOBAL_QUEUES 32

/** Raw pointers to the tracked global queues. Entries are only ever appended, never removed. */
static _Atomic(void *) gTrackedGlobalQueues[GREY_MAX_TRACKED_GLOBAL_QUEUES];

/** The tracking states of the queues in @c gTrackedGlobalQueues, at the same indexes. */
static _Atomic(GREYQueueTrackingState *) gTrackedGlobalQueueStates[GREY_MAX_TRACKED_GLOBAL_QUEUES];

/** The number of entries in @c gTrackedGlobalQueues that are fully published. */
static atomic_int gTrackedGlobalQueueCount;

/**
 * A reference to the GREYConfiguration class to use when checking the delay for dispatch_after(_f).
 */
static id gConfiguration;

static GREYQueueTrackingState *RetainTrackingState(GREYQueueTrackingState *state) {
  atomic_fetch_add_explicit(&state->referenceCount, 1, memory_order_relaxed);
  return state;
}

/** Releases a GREYQueueTrackingState. Also used as the queue-specific destructor. */
static void ReleaseTrackingState(void *context) {
  GREYQueueTrackingState *state = (GREYQueueTrackingState *)context;
  if (atomic_fetch_sub_explicit(&state->referenceCount, 1, memory_order_acq_rel) == 1) {
    free(state);
  }
}

/**
 * @return The tracking state of @c queue, or @c NULL if the queue is not tracked. This never takes
 *         the Objective-C runtime lock or touches an Objective-C object. The returned state stays
 *         valid at least as long as the caller keeps @c queue alive.
 */
static GREYQueueTrackingState *TrackingStateForQueue(__unsafe_unretained dispatch_queue_t queue) {
  GREYQueueTrackingState *state =
      (GREYQueueTrackingState *)dispatch_queue_get_specific(queue, kGREYQueueTrackingStateKey);
  if (state) {
    return state;
  }
  int globalCount = atomic_load_explicit(&gTrackedGlobalQueueCount, memory_order_acquire);
  void *rawQueue = (__bridge void *)queue;
  for (int i = 0; i < globalCount; i++) {
    if (atomic_load_explicit(&gTrackedGlobalQueues[i], memory_order_relaxed) == rawQueue) {
      state = atomic_load_explicit(&gTrackedGlobalQueueStates[i], memory_order_relaxed);
      break;
    }
  }
  return state;
}

/** @return @c YES if @c queue is a global (root) queue, which doesn't support queue specifics. */
static BOOL IsGlobalQueue(dispatch_queue_t queue) {
  static const char kGlobalQueueLabelPrefix[] = "com.apple.root.";
  const char *label = dispatch_queue_get_label(queue);
  return label && strncmp(label, kGlobalQueueLabelPrefix, sizeof(kGlobalQueueLabelPrefix) - 1) == 0;
}

/**
 * Starts tracking @c queue if it isn't tracked yet. Must be called with the lock that serializes
 * GREYDispatchQueueInterposer creation held.
 *
 * @return The tracking state of @c queue, or @c NULL if it can't be tracked.
 */
static GREYQueueTrackingState *StartTrackingQueue(dispatch_queue_t queue) {
  GREYQueueTrackingState *state = TrackingStateForQueue(queue);
  if (state) {
    return state;
  }
  if (!IsGlobalQueue(queue)) {
    state = (GREYQueueTrackingState *)calloc(1, sizeof(GREYQueueTrackingState));
    // The queue's reference is released by the queue-specific destructor when the queue is
    // destroyed.
    atomic_init(&state->referenceCount, 1);
    dispatch_queue_set_specific(queue, kGREYQueueTrackingStateKey, state, ReleaseTrackingState);
    return state;
  }
  int index = atomic_load_explicit(&gTrackedGlobalQueueCount, memory_order_relaxed);
  if (index < GREY_MAX_TRACKED_GLOBAL_QUEUES) {
    state = (GREYQueueTrackingState *)calloc(1, sizeof(GREYQueueTrackingState));
    // The table's reference is never released, because global queues are never destroyed.
    atomic_init(&state->referenceCount, 1);
    atomic_store_explicit(&gTrackedGlobalQueueStates[index], state, memory_order_relaxed);
    atomic_store_explicit(&gTrackedGlobalQueues[index], (__bridge void *)queue,
                          memory_order_relaxed);
    atomic_store_explicit(&gTrackedGlobalQueueCount, index + 1, memory_order_release);
  } else {
    NSLog(@"EarlGrey can't track more than %d global dispatch queues. Not tracking %s.",
          GREY_MAX_TRACKED_GLOBAL_QUEUES, dispatch_queue_get_label(queue));
  }
  return state;
}

/**
 * @return @c YES if a dispatch_after(_f) call that runs at @c when is within the max trackable
 *         delay from the global EarlGrey configuration.
 *
 * @note This sends Objective-C messages, so it must only be called for tracked queues.
 */
static BOOL IsTrackableDispatchAfterTime(dispatch_time_t when) {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    gConfiguration = [NSClassFromString(@"GREYConfiguration") sharedConfiguration];
  });
  CFTimeInterval maxDelay =
      [gConfiguration doubleValueForConfigKey:kGREYConfigKeyDispatchAfterMaxTrackableDelay];
  return dispatch_time(DISPATCH_TIME_NOW, (int64_t)(maxDelay * NSEC_PER_SEC)) >= when;
}

#pragma mark - Tracked calls

/** The work of a tracked dispatch call: either a block or a function and its context. */
typedef struct {
  GREYQueueTrackingState *state;
  /** A raw pointer to the block to run, or @c NULL to run @c work with @c context instead. */
  void *block;
  dispatch_function_t work;
  void *context;
} GREYTrackedCall;

/** Counts a call as pending on @c state, until EndTrackedCall is called with the same state. */
static GREYQueueTrackingState *BeginTrackedCall(GREYQueueTrackingState *state) {
  atomic_fetch_add(&state->pendingCalls, 1);
  return RetainTrackingState(state);
}

static void EndTrackedCall(GREYQueueTrackingState *state) {
  atomic_fetch_sub(&state->pendingCalls, 1);
  ReleaseTrackingState(state);
}

/** Runs the work of @c call and ends its tracking. Doesn't free @c call or its block. */
static void RunTrackedCallWork(GREYTrackedCall *call) {
  if (call->block) {
    // This runs on the target queue, not in the caller of dispatch_*, so Objective-C is fine here.
    __unsafe_unretained dispatch_block_t block = (__bridge dispatch_block_t)call->block;
    block();
  } else {
    call->work(call->context);
  }
  EndTrackedCall(call->state);
}

/** A dispatch_function_t that runs a GREYTrackedCall created by NewAsyncTracked*Call. */
static void RunAsyncTrackedCall(void *context) {
  GREYTrackedCall *call = (GREYTrackedCall *)context;
  RunTrackedCallWork(call);
  if (call->block) {
    _Block_release(call->block);
  }
  free(call);
}

/** A dispatch_function_t that runs a GREYTrackedCall on the caller's stack (for dispatch_sync). */
static void RunSyncTrackedCall(void *context) { RunTrackedCallWork((GREYTrackedCall *)context); }

/**
 * @return A heap-allocated GREYTrackedCall that runs @c block, to be run and freed by
 *         RunAsyncTrackedCall. The block is copied with _Block_copy, which is plain C.
 */
static GREYTrackedCall *NewAsyncTrackedBlockCall(GREYQueueTrackingState *state,
                                                 __unsafe_unretained dispatch_block_t block) {
  GREYTrackedCall *call = (GREYTrackedCall *)calloc(1, sizeof(GREYTrackedCall));
  call->state = BeginTrackedCall(state);
  call->block = _Block_copy((__bridge const void *)block);
  return call;
}

/**
 * @return A heap-allocated GREYTrackedCall that runs @c work with @c context, to be run and freed
 *         by RunAsyncTrackedCall.
 */
static GREYTrackedCall *NewAsyncTrackedFunctionCall(GREYQueueTrackingState *state,
                                                    dispatch_function_t work, void *context) {
  GREYTrackedCall *call = (GREYTrackedCall *)calloc(1, sizeof(GREYTrackedCall));
  call->state = BeginTrackedCall(state);
  call->work = work;
  call->context = context;
  return call;
}

#pragma mark - Interposed dispatch functions

__unused static void DispatchAfter(dispatch_time_t when, __unsafe_unretained dispatch_queue_t queue,
                                   __unsafe_unretained dispatch_block_t block) {
  GREYQueueTrackingState *state = TrackingStateForQueue(queue);
  if (state && IsTrackableDispatchAfterTime(when)) {
    dispatch_after_f(when, queue, NewAsyncTrackedBlockCall(state, block), RunAsyncTrackedCall);
  } else {
    dispatch_after(when, queue, block);
  }
}

__unused static void DispatchAsync(__unsafe_unretained dispatch_queue_t queue,
                                   __unsafe_unretained dispatch_block_t block) {
  GREYQueueTrackingState *state = TrackingStateForQueue(queue);
  if (state) {
    dispatch_async_f(queue, NewAsyncTrackedBlockCall(state, block), RunAsyncTrackedCall);
  } else {
    dispatch_async(queue, block);
  }
}

__unused static void DispatchSync(__unsafe_unretained dispatch_queue_t queue,
                                  __unsafe_unretained dispatch_block_t block) {
  GREYQueueTrackingState *state = TrackingStateForQueue(queue);
  if (state) {
    // dispatch_sync doesn't return until the block has run, so it doesn't need to be copied.
    GREYTrackedCall call = {
        .state = BeginTrackedCall(state),
        .block = (__bridge void *)block,
    };
    dispatch_sync_f(queue, &call, RunSyncTrackedCall);
  } else {
    dispatch_sync(queue, block);
  }
}

__unused static void DispatchAfterF(dispatch_time_t when,
                                    __unsafe_unretained dispatch_queue_t queue, void *context,
                                    dispatch_function_t work) {
  GREYQueueTrackingState *state = TrackingStateForQueue(queue);
  if (state && IsTrackableDispatchAfterTime(when)) {
    dispatch_after_f(when, queue, NewAsyncTrackedFunctionCall(state, work, context),
                     RunAsyncTrackedCall);
  } else {
    dispatch_after_f(when, queue, context, work);
  }
}

__unused static void DispatchAsyncF(__unsafe_unretained dispatch_queue_t queue, void *context,
                                    dispatch_function_t work) {
  GREYQueueTrackingState *state = TrackingStateForQueue(queue);
  if (state) {
    dispatch_async_f(queue, NewAsyncTrackedFunctionCall(state, work, context), RunAsyncTrackedCall);
  } else {
    dispatch_async_f(queue, context, work);
  }
}

__unused static void DispatchSyncF(__unsafe_unretained dispatch_queue_t queue, void *context,
                                   dispatch_function_t work) {
  GREYQueueTrackingState *state = TrackingStateForQueue(queue);
  if (state) {
    GREYTrackedCall call = {
        .state = BeginTrackedCall(state),
        .work = work,
        .context = context,
    };
    dispatch_sync_f(queue, &call, RunSyncTrackedCall);
  } else {
    dispatch_sync_f(queue, context, work);
  }
}

/** Statically interpose the symbols for dispatch queues. Must be done like this inside a dylib. */
DYLD_INTERPOSE(DispatchAfter, dispatch_after);
DYLD_INTERPOSE(DispatchAsync, dispatch_async);
DYLD_INTERPOSE(DispatchSync, dispatch_sync);
DYLD_INTERPOSE(DispatchAfterF, dispatch_after_f);
DYLD_INTERPOSE(DispatchAsyncF, dispatch_async_f);
DYLD_INTERPOSE(DispatchSyncF, dispatch_sync_f);

#pragma mark - GREYDispatchQueueInterposer

@interface GREYDispatchQueueInterposer ()
/**
 * @return An initialized GREYDispatchQueueInterposer for the specific queue.
 *
 * @param queue The dispatch queue to be interposed. Cannot be nil. A weak reference is kept for
 *              this queue.
 * @param state The tracking state of @c queue. The interposer takes a reference to it.
 */
- (instancetype)initWithDispatchQueue:(nonnull dispatch_queue_t)queue
                        trackingState:(GREYQueueTrackingState *)state;
@end

@implementation GREYDispatchQueueInterposer {
  __weak dispatch_queue_t _interposedQueue;
  GREYQueueTrackingState *_trackingState;
}

+ (instancetype)interposeDispatchQueue:(dispatch_queue_t)queue {
  // Used to return the same GREYDispatchQueueInterposer for a queue while it is alive. Both entries
  // are weakly held. This is only used here, never from the interposed dispatch functions.
  static NSMapTable *interposers;
  static dispatch_once_t token = 0;
  dispatch_once(&token, ^{
    interposers = [NSMapTable weakToWeakObjectsMapTable];
  });
  @synchronized(interposers) {
    GREYDispatchQueueInterposer *interposer = [interposers objectForKey:queue];
    if (!interposer) {
      GREYQueueTrackingState *state = StartTrackingQueue(queue);
      if (!state) {
        // The queue can't be tracked. Callers expect a non-nil interposer (a nil one would never
        // report idle), so give it a tracking state that isn't attached to the queue. It always
        // reports idle, and it is freed when the interposer releases its reference.
        state = (GREYQueueTrackingState *)calloc(1, sizeof(GREYQueueTrackingState));
      }
      interposer = [[GREYDispatchQueueInterposer alloc] initWithDispatchQueue:queue
                                                                trackingState:state];
      [interposers setObject:interposer forKey:queue];
    }
    return interposer;
  }
}

- (instancetype)initWithDispatchQueue:(dispatch_queue_t)queue
                        trackingState:(GREYQueueTrackingState *)state {
  self = [super init];
  if (self) {
    _interposedQueue = queue;
    _trackingState = RetainTrackingState(state);
  }
  return self;
}

- (void)dealloc {
  ReleaseTrackingState(_trackingState);
}

- (NSString *)description {
  return [NSString stringWithFormat:@"Calls are still being tracked (unfulfilled) on the dispatch"
                                    @"queue: %@.\n"
                                    @"dispatch_sync, dispatch_sync_f, dispatch_async, "
                                    @"dispatch_async_f, dispatch_after, dispatch_after_f",
                                    _interposedQueue];
}

- (BOOL)isIdleNow {
  return atomic_load(&_trackingState->pendingCalls) == 0;
}

- (BOOL)isTrackingALiveQueue {
  return _interposedQueue != nil;
}

@end
