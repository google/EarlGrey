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

#import "GREYDispatchQueueTracker.h"

#include <dlfcn.h>
#include <fishhook.h>
#include <libkern/OSAtomic.h>
#include <stdatomic.h>

#import "GREYFatalAsserts.h"
#import "GREYThrowDefines.h"
#import "GREYConfigKey.h"
#import "GREYConfiguration.h"


/**
 * A pointer to the original implementation of @c dispatch_after.
 */
static void (*gOriginalDispatchAfter)(dispatch_time_t when, dispatch_queue_t queue,
                                      dispatch_block_t block);
/**
 * A pointer to the original implementation of @c dispatch_async.
 */
static void (*gOriginalDispatchAsync)(dispatch_queue_t queue, dispatch_block_t block);
/**
 * A pointer to the original implementation of @c dispatch_sync.
 */
static void (*gOriginalDispatchSync)(dispatch_queue_t queue, dispatch_block_t block);

/**
 * A pointer to the original implementation of @c dispatch_after_f.
 */
static void (*gOriginalDispatchAfterF)(dispatch_time_t when, dispatch_queue_t queue, void *context,
                                       dispatch_function_t work);
/**
 * A pointer to the original implementation of @c dispatch_async_f.
 */
static void (*gOriginalDispatchAsyncF)(dispatch_queue_t queue, void *context,
                                       dispatch_function_t work);
/**
 * A pointer to the original implementation of @c dispatch_sync_f.
 */
static void (*gOriginalDispatchSyncF)(dispatch_queue_t queue, void *context,
                                      dispatch_function_t work);

/**
 * Used to find the @c GREYDispatchQueueTracker instance corresponding to a dispatch queue, if
 * one exists.
 */
static NSMapTable *gDispatchQueueToTracker;

@interface GREYDispatchQueueTracker ()
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
 * @return The @c GREYDispatchQueueTracker associated with @c queue or @c nil if there is none.
 */
static GREYDispatchQueueTracker *GetTrackerForQueue(dispatch_queue_t queue) {
  GREYDispatchQueueTracker *tracker = nil;
  @synchronized(gDispatchQueueToTracker) {
    tracker = [gDispatchQueueToTracker objectForKey:queue];
  }
  return tracker;
}

/**
 * Overridden implementation of @c dispatch_after that calls into the tracker, if one is found for
 * the dispatch queue passed in.
 *
 * @param when  Same as @c dispatch_after @c when.
 * @param queue Same as @c dispatch_after @c queue.
 * @param block Same as @c dispatch_after @c block.
 */
static void GREYDispatchAfter(dispatch_time_t when, dispatch_queue_t queue,
                              dispatch_block_t block) {
  GREYDispatchQueueTracker *tracker = GetTrackerForQueue(queue);
  if (tracker) {
    [tracker dispatchAfterCallWithTime:when block:block];
  } else {
    gOriginalDispatchAfter(when, queue, block);
  }
}

/**
 * Overridden implementation of @c dispatch_async that calls into the tracker, if one is found for
 * the dispatch queue passed in.
 *
 * @param queue Same as @c dispatch_async @c queue.
 * @param block Same as @c dispatch_async @c block.
 */
static void GREYDispatchAsync(dispatch_queue_t queue, dispatch_block_t block) {
  GREYDispatchQueueTracker *tracker = GetTrackerForQueue(queue);
  if (tracker) {
    [tracker dispatchAsyncCallWithBlock:block];
  } else {
    gOriginalDispatchAsync(queue, block);
  }
}

/**
 * Overridden implementation of @c dispatch_sync that calls into the tracker, if one is found for
 * the dispatch queue passed in.
 *
 * @param queue Same as @c dispatch_sync @c queue.
 * @param block Same as @c dispatch_sync @c block.
 */
static void GREYDispatchSync(dispatch_queue_t queue, dispatch_block_t block) {
  GREYDispatchQueueTracker *tracker = GetTrackerForQueue(queue);
  if (tracker) {
    [tracker dispatchSyncCallWithBlock:block];
  } else {
    gOriginalDispatchSync(queue, block);
  }
}

/**
 * Overridden implementation of @c dispatch_after_f that calls into the tracker, if one is found
 * for the dispatch queue passed in.
 *
 * @param when    Same as @c dispatch_after_f @c when.
 * @param queue   Same as @c dispatch_after_f @c queue.
 * @param context Same as @c dispatch_after_f @c context.
 * @param work    Same as @c dispatch_after_f @c work.
 */
static void GREYDispatchAfterF(dispatch_time_t when, dispatch_queue_t queue, void *context,
                               dispatch_function_t work) {
  GREYDispatchQueueTracker *tracker = GetTrackerForQueue(queue);
  if (tracker) {
    [tracker dispatchAfterCallWithTime:when context:context work:work];
  } else {
    gOriginalDispatchAfterF(when, queue, context, work);
  }
}

/**
 * Overridden implementation of @c dispatch_async_f that calls into the tracker, if one is found
 * for the dispatch queue passed in.
 *
 * @param queue   Same as @c dispatch_async_f @c queue.
 * @param context Same as @c dispatch_async_f @c context.
 * @param work    Same as @c dispatch_async_f @c work.
 */
static void GREYDispatchAsyncF(dispatch_queue_t queue, void *context, dispatch_function_t work) {
  GREYDispatchQueueTracker *tracker = GetTrackerForQueue(queue);
  if (tracker) {
    [tracker dispatchAsyncCallWithContext:context work:work];
  } else {
    gOriginalDispatchAsyncF(queue, context, work);
  }
}

/**
 * Overridden implementation of @c dispatch_sync_f that calls into the tracker, if one is found
 * for the dispatch queue passed in.
 *
 * @param queue   Same as @c dispatch_sync_f @c queue.
 * @param context Same as @c dispatch_sync_f @c context.
 * @param work    Same as @c dispatch_sync_f @c work.
 */
static void GREYDispatchSyncF(dispatch_queue_t queue, void *context, dispatch_function_t work) {
  GREYDispatchQueueTracker *tracker = GetTrackerForQueue(queue);
  if (tracker) {
    [tracker dispatchSyncCallWithContext:context work:work];
  } else {
    gOriginalDispatchSyncF(queue, context, work);
  }
}

/**
 * The GREYDispatchQueueInterposer class, if present. If not-nil, then this dispatch queue tracker
 * class will not track any dispatch queues or related calls.
 */
static Class gInterposerClass;

@implementation GREYDispatchQueueTracker {
  __weak dispatch_queue_t _dispatchQueue;
  __block atomic_int _pendingBlocks;
}

+ (void)load {
  gInterposerClass = NSClassFromString(@"GREYDispatchQueueInterposer");
  // GREYDispatchQueueInterposer is present only for a test run with sanitizers, we will not use
  // fishhook's dispatch_queue tracking then.
  if (!gInterposerClass) {
    gDispatchQueueToTracker = [NSMapTable weakToWeakObjectsMapTable];

    dispatch_queue_t dummyQueue = dispatch_queue_create("GREYDummyQueue", DISPATCH_QUEUE_SERIAL);
    GREYFatalAssertWithMessage(dummyQueue, @"dummmyQueue must not be nil");

    // Use dlsym to get the original pointer because of
    // https://github.com/facebook/fishhook/issues/21
    gOriginalDispatchAfter = dlsym(RTLD_DEFAULT, "dispatch_after");
    gOriginalDispatchAsync = dlsym(RTLD_DEFAULT, "dispatch_async");
    gOriginalDispatchSync = dlsym(RTLD_DEFAULT, "dispatch_sync");
    gOriginalDispatchAfterF = dlsym(RTLD_DEFAULT, "dispatch_after_f");
    gOriginalDispatchAsyncF = dlsym(RTLD_DEFAULT, "dispatch_async_f");
    gOriginalDispatchSyncF = dlsym(RTLD_DEFAULT, "dispatch_sync_f");
    GREYFatalAssertWithMessage(gOriginalDispatchAfter,
                               @"Pointer to dispatch_after must not be NULL");
    GREYFatalAssertWithMessage(gOriginalDispatchAsync,
                               @"Pointer to dispatch_async must not be NULL");
    GREYFatalAssertWithMessage(gOriginalDispatchSync, @"Pointer to dispatch_sync must not be NULL");
    GREYFatalAssertWithMessage(gOriginalDispatchAfterF,
                               @"Pointer to dispatch_after_f must not be NULL");
    GREYFatalAssertWithMessage(gOriginalDispatchAsyncF,
                               @"Pointer to dispatch_async_f must not be NULL");
    GREYFatalAssertWithMessage(gOriginalDispatchSyncF,
                               @"Pointer to dispatch_sync_f must not be NULL");

    // Rebind symbols dispatch_* to point to our own implementation.
    struct rebinding rebindings[] = {
        {"dispatch_after", GREYDispatchAfter, NULL},
        {"dispatch_async", GREYDispatchAsync, NULL},
        {"dispatch_sync", GREYDispatchSync, NULL},
        {"dispatch_after_f", GREYDispatchAfterF, NULL},
        {"dispatch_async_f", GREYDispatchAsyncF, NULL},
        {"dispatch_sync_f", GREYDispatchSyncF, NULL},
    };
    int failure = rebind_symbols(rebindings, sizeof(rebindings) / sizeof(rebindings[0]));
    GREYFatalAssertWithMessage(!failure, @"rebinding symbols failed");
  }
}

#pragma mark -

+ (instancetype)trackerForDispatchQueue:(dispatch_queue_t)queue {
  GREYThrowOnNilParameter(queue);
  // GREYDispatchQueueTracker uses fishhook for tracking dispatch_ calls. There is an infinite
  // recursion issue with fishhook and sanitizers - https://github.com/facebook/fishhook/issues/47
  // For sanitizers we track using GREYDispatchQueueInterposer instead which uses DYLD_INTERPOSE.
  if (gInterposerClass) {
    return [gInterposerClass interposeDispatchQueue:queue];
  } else {
    @synchronized(gDispatchQueueToTracker) {
      GREYDispatchQueueTracker *tracker = GetTrackerForQueue(queue);
      if (!tracker) {
        tracker = [[GREYDispatchQueueTracker alloc] initWithDispatchQueue:queue];
        // Register this tracker with dispatch queue. Both entries are weakly held.
        [gDispatchQueueToTracker setObject:tracker forKey:queue];
      }
      return tracker;
    }
  }
}

- (instancetype)initWithDispatchQueue:(dispatch_queue_t)queue {
  GREYThrowOnNilParameter(queue);

  self = [super init];
  if (self) {
    _dispatchQueue = queue;
  }
  return self;
}

- (BOOL)isIdleNow {
  GREYFatalAssertWithMessage(_pendingBlocks >= 0, @"_pendingBlocks must not be negative");
  int expectedCount = 0;
  BOOL isIdle = atomic_compare_exchange_strong(&_pendingBlocks, &expectedCount, 0);
  return isIdle;
}

- (BOOL)isTrackingALiveQueue {
  return _dispatchQueue != nil;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"Calls are still being tracked (unfulfilled) on the dispatch"
                                    @"queue: %@.\n"
                                    @"dispatch_sync, dispatch_sync_f, dispatch_async, "
                                    @"dispatch_async_f, dispatch_after, dispatch_after_f",
                                    _dispatchQueue];
}

#pragma mark - Private

- (void)dispatchAfterCallWithTime:(dispatch_time_t)when block:(dispatch_block_t)block {
  CFTimeInterval maxDelay = GREY_CONFIG_DOUBLE(kGREYConfigKeyDispatchAfterMaxTrackableDelay);
  dispatch_time_t trackDelay = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(maxDelay * NSEC_PER_SEC));

  if (trackDelay >= when) {
    atomic_fetch_add(&_pendingBlocks, 1);
    gOriginalDispatchAfter(when, _dispatchQueue, ^{
      block();
      atomic_fetch_sub(&self->_pendingBlocks, 1);
    });
  } else {
    gOriginalDispatchAfter(when, _dispatchQueue, block);
  }
}

- (void)dispatchAsyncCallWithBlock:(dispatch_block_t)block {
  atomic_fetch_add(&_pendingBlocks, 1);
  gOriginalDispatchAsync(_dispatchQueue, ^{
    block();
    atomic_fetch_sub(&self->_pendingBlocks, 1);
  });
}

- (void)dispatchSyncCallWithBlock:(dispatch_block_t)block {
  atomic_fetch_add(&_pendingBlocks, 1);
  gOriginalDispatchSync(_dispatchQueue, ^{
    block();
    atomic_fetch_sub(&self->_pendingBlocks, 1);
  });
}

- (void)dispatchAfterCallWithTime:(dispatch_time_t)when
                          context:(void *)context
                             work:(dispatch_function_t)work {
  CFTimeInterval maxDelay = GREY_CONFIG_DOUBLE(kGREYConfigKeyDispatchAfterMaxTrackableDelay);
  dispatch_time_t trackDelay = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(maxDelay * NSEC_PER_SEC));
  if (trackDelay >= when) {
    atomic_fetch_add(&_pendingBlocks, 1);
    gOriginalDispatchAfter(when, _dispatchQueue, ^{
      work(context);
      atomic_fetch_sub(&self->_pendingBlocks, 1);
    });
  } else {
    gOriginalDispatchAfterF(when, _dispatchQueue, context, work);
  }
}

- (void)dispatchAsyncCallWithContext:(void *)context work:(dispatch_function_t)work {
  atomic_fetch_add(&_pendingBlocks, 1);
  gOriginalDispatchAsync(_dispatchQueue, ^{
    work(context);
    atomic_fetch_sub(&self->_pendingBlocks, 1);
  });
}

- (void)dispatchSyncCallWithContext:(void *)context work:(dispatch_function_t)work {
  atomic_fetch_add(&_pendingBlocks, 1);
  gOriginalDispatchSync(_dispatchQueue, ^{
    work(context);
    atomic_fetch_sub(&self->_pendingBlocks, 1);
  });
}

@end
