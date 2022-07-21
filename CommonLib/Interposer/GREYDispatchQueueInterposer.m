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

#include <stdatomic.h>

#import "GREYConfigKey.h"
#import "GREYConfiguration.h"
#import "GREYInterposer.h"

/**
 * Used to find the @c GREYDispatchQueueTracker instance corresponding to a dispatch queue, if
 * one exists.
 */
static NSMapTable *gTrackedDispatchQueueToInterposer;

/**
 * A reference to the GREYConfiguration class to use when checking the delay for dispatch_after(_f).
 */
static id gConfiguration;

@interface GREYDispatchQueueInterposer ()
/**
 * @return An initialized GREYDispatchQueueInterposer for the specific queue.
 *
 * @param queue The dispatch queue to be interposed. Cannot be nil. A weak reference is kept for
 *              this queue.
 */
- (instancetype)initWithDispatchQueue:(nonnull dispatch_queue_t)queue;
- (void)dispatchAfterCallWithTime:(dispatch_time_t)when block:(dispatch_block_t)block;
- (void)dispatchAsyncCallWithBlock:(dispatch_block_t)block;
- (void)dispatchSyncCallWithBlock:(dispatch_block_t)block;
- (void)dispatchAfterCallWithTime:(dispatch_time_t)when
                          context:(void *)context
                             work:(dispatch_function_t)work;
- (void)dispatchAsyncCallWithContext:(void *)context work:(dispatch_function_t)work;
- (void)dispatchSyncCallWithContext:(void *)context work:(dispatch_function_t)work;
@end

/**
 * @return Synchronously get the @c GREYDispatchQueueInterposer associated with @c queue or @c nil
 *         if there is none i.e. the queue is not tracked. If @c createIfNeeded is passed in, a new
 *         instance of GREYDispatchQueueInterposer is created and returned.
 *
 * @param queue          The dispatch_queue_t that is to be tracked.
 * @param createIfNeeded If @c YES, a new instance of GREYDispatchQueueInterposer is instantiated.
 */
__unused static GREYDispatchQueueInterposer *InterposerForQueue(dispatch_queue_t queue,
                                                                BOOL createIfNeeded) {
  GREYDispatchQueueInterposer *interposer = nil;
  static dispatch_once_t token = 0;
  dispatch_once(&token, ^{
    NSCAssert(!gTrackedDispatchQueueToInterposer,
              @"Queue-interposer MapTable cannot be created outside of the designated initializer");
    gTrackedDispatchQueueToInterposer = [NSMapTable weakToWeakObjectsMapTable];
  });
  @synchronized(gTrackedDispatchQueueToInterposer) {
    interposer = [gTrackedDispatchQueueToInterposer objectForKey:queue];
    if (!interposer && createIfNeeded) {
      interposer = [[GREYDispatchQueueInterposer alloc] initWithDispatchQueue:queue];
      // Register this tracker with dispatch queue. Both entries are weakly held.
      [gTrackedDispatchQueueToInterposer setObject:interposer forKey:queue];
    }
    return interposer;
  }
}

__unused static void DispatchAfter(dispatch_time_t when, dispatch_queue_t queue,
                                   dispatch_block_t block) {
  GREYDispatchQueueInterposer *interposer = InterposerForQueue(queue, NO);
  if (interposer) {
    [interposer dispatchAfterCallWithTime:when block:block];
  } else {
    dispatch_after(when, queue, block);
  }
}

__unused static void DispatchAsync(dispatch_queue_t queue, dispatch_block_t block) {
  GREYDispatchQueueInterposer *interposer = InterposerForQueue(queue, NO);
  if (interposer) {
    [interposer dispatchAsyncCallWithBlock:block];
  } else {
    dispatch_async(queue, block);
  }
}

__unused static void DispatchSync(dispatch_queue_t queue, dispatch_block_t block) {
  GREYDispatchQueueInterposer *interposer = InterposerForQueue(queue, NO);
  if (interposer) {
    [interposer dispatchSyncCallWithBlock:block];
  } else {
    dispatch_sync(queue, block);
  }
}

__unused static void DispatchAfterF(dispatch_time_t when, dispatch_queue_t queue, void *context,
                                    dispatch_function_t work) {
  GREYDispatchQueueInterposer *interposer = InterposerForQueue(queue, NO);
  if (interposer) {
    [interposer dispatchAfterCallWithTime:when context:context work:work];
  } else {
    dispatch_after_f(when, queue, context, work);
  }
}

__unused static void DispatchAsyncF(dispatch_queue_t queue, void *context,
                                    dispatch_function_t work) {
  GREYDispatchQueueInterposer *interposer = InterposerForQueue(queue, NO);
  if (interposer) {
    [interposer dispatchAsyncCallWithContext:context work:work];
  } else {
    dispatch_async_f(queue, context, work);
  }
}

__unused static void DispatchSyncF(dispatch_queue_t queue, void *context,
                                   dispatch_function_t work) {
  GREYDispatchQueueInterposer *interposer = InterposerForQueue(queue, NO);
  if (interposer) {
    [interposer dispatchSyncCallWithContext:context work:work];
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

@implementation GREYDispatchQueueInterposer {
  __weak dispatch_queue_t _interposedQueue;
  atomic_int _pendingDispatchCalls;
}

- (instancetype)initWithDispatchQueue:(dispatch_queue_t)queue {
  self = [super init];
  if (self) {
    _interposedQueue = queue;
  }
  return self;
}

+ (instancetype)interposeDispatchQueue:(dispatch_queue_t)queue {
  return InterposerForQueue(queue, YES);
}

- (NSString *)description {
  return [NSString stringWithFormat:@"Calls are still being tracked (unfulfilled) on the dispatch"
                                    @"queue: %@.\n"
                                    @"dispatch_sync, dispatch_sync_f, dispatch_async, "
                                    @"dispatch_async_f, dispatch_after, dispatch_after_f",
                                    _interposedQueue];
}

- (BOOL)isIdleNow {
  int expectedCount = 0;
  return atomic_compare_exchange_strong(&_pendingDispatchCalls, &expectedCount, 0);
}

- (BOOL)isTrackingALiveQueue {
  return _interposedQueue != nil;
}

- (void)dispatchAfterCallWithTime:(dispatch_time_t)when block:(dispatch_block_t)block {
  if ([self maxTrackableTime] >= when) {
    atomic_fetch_add(&_pendingDispatchCalls, 1);
    dispatch_after(when, _interposedQueue, ^{
      block();
      atomic_fetch_sub(&self->_pendingDispatchCalls, 1);
    });
  } else {
    dispatch_after(when, _interposedQueue, block);
  }
}

- (void)dispatchAsyncCallWithBlock:(dispatch_block_t)block {
  atomic_fetch_add(&_pendingDispatchCalls, 1);
  dispatch_async(_interposedQueue, ^{
    block();
    atomic_fetch_sub(&self->_pendingDispatchCalls, 1);
  });
}

- (void)dispatchSyncCallWithBlock:(dispatch_block_t)block {
  atomic_fetch_add(&_pendingDispatchCalls, 1);
  dispatch_sync(_interposedQueue, ^{
    block();
    atomic_fetch_sub(&self->_pendingDispatchCalls, 1);
  });
}

- (void)dispatchAfterCallWithTime:(dispatch_time_t)when
                          context:(void *)context
                             work:(dispatch_function_t)work {
  if ([self maxTrackableTime] >= when) {
    atomic_fetch_add(&_pendingDispatchCalls, 1);
    dispatch_after(when, _interposedQueue, ^{
      work(context);
      atomic_fetch_sub(&self->_pendingDispatchCalls, 1);
    });
  } else {
    dispatch_after_f(when, _interposedQueue, context, work);
  }
}

- (void)dispatchAsyncCallWithContext:(void *)context work:(dispatch_function_t)work {
  atomic_fetch_add(&_pendingDispatchCalls, 1);
  dispatch_async(_interposedQueue, ^{
    work(context);
    atomic_fetch_sub(&self->_pendingDispatchCalls, 1);
  });
}

- (void)dispatchSyncCallWithContext:(void *)context work:(dispatch_function_t)work {
  atomic_fetch_add(&_pendingDispatchCalls, 1);
  dispatch_sync(_interposedQueue, ^{
    work(context);
    atomic_fetch_sub(&self->_pendingDispatchCalls, 1);
  });
}

/**
 * @return A dispatch_time_t specifying the max trackable dispatch after duration from the global
 *         EarlGrey configuration.
 **/
- (dispatch_time_t)maxTrackableTime {
  if (!gConfiguration) {
    gConfiguration = [NSClassFromString(@"GREYConfiguration") sharedConfiguration];
  }
  CFTimeInterval maxDelay =
      [gConfiguration doubleValueForConfigKey:kGREYConfigKeyDispatchAfterMaxTrackableDelay];
  return dispatch_time(DISPATCH_TIME_NOW, (int64_t)(maxDelay * NSEC_PER_SEC));
}

@end
