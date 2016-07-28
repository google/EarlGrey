//
// Copyright 2016 Google Inc.
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

#import "Synchronization/GREYDispatchQueueTracker.h"

#include <libkern/OSAtomic.h>
#include <pthread.h>

#import "Common/GREYConfiguration.h"
#import "Common/GREYInterposer.h"

/**
 *  A pointer to the original implementation of @c dispatch_after.
 */
static void (*grey_original_dispatch_after)(dispatch_time_t when,
                                            dispatch_queue_t queue,
                                            dispatch_block_t block) = NULL;
/**
 *  A pointer to the original implementation of @c dispatch_async.
 */
static void (*grey_original_dispatch_async)(dispatch_queue_t queue, dispatch_block_t block) = NULL;
/**
 *  A pointer to the original implementation of @c dispatch_sync.
 */
static void (*grey_original_dispatch_sync)(dispatch_queue_t queue, dispatch_block_t block) = NULL;
/**
 *  A pointer to the original implementation of @c dispatch_after_f.
 */
static void (*grey_original_dispatch_after_f)(dispatch_time_t when,
                                              dispatch_queue_t queue,
                                              void *context,
                                              dispatch_function_t work) = NULL;
/**
 *  A pointer to the original implementation of @c dispatch_async_f.
 */
static void (*grey_original_dispatch_async_f)(dispatch_queue_t queue,
                                              void *context,
                                              dispatch_function_t work) = NULL;
/**
 *  A pointer to the original implementation of @c dispatch_sync_f.
 */
static void (*grey_original_dispatch_sync_f)(dispatch_queue_t queue,
                                             void *context,
                                             dispatch_function_t work) = NULL;

/**
 *  Used to find the @c GREYDispatchQueueTracker instance corresponding to a dispatch queue, if
 *  one exists.
 */
static NSMapTable *gDispatchQueueToTracker;

/*
 * Lock used to synchronize checking original pointer for NULL and assigning the default value.
 */
pthread_mutex_t gNullOriginalPointerLock = PTHREAD_RECURSIVE_MUTEX_INITIALIZER;

@interface GREYDispatchQueueTracker ()

- (void)grey_dispatchAfterCallWithTime:(dispatch_time_t)when block:(dispatch_block_t)block;
- (void)grey_dispatchAsyncCallWithBlock:(dispatch_block_t)block;
- (void)grey_dispatchSyncCallWithBlock:(dispatch_block_t)block;

- (void)grey_dispatchAfterCallWithTime:(dispatch_time_t)when
                               context:(void *)context
                                  work:(dispatch_function_t)work;
- (void)grey_dispatchAsyncCallWithContext:(void *)context work:(dispatch_function_t)work;
- (void)grey_dispatchSyncCallWithContext:(void *)context work:(dispatch_function_t)work;

@end

/**
 * @return The @c GREYDispatchQueueTracker associated with @c queue or @c nil if there is none.
 */
static GREYDispatchQueueTracker *grey_getTrackerForQueue(dispatch_queue_t queue) {
  GREYDispatchQueueTracker *tracker = nil;
  @synchronized(gDispatchQueueToTracker) {
    tracker = [gDispatchQueueToTracker objectForKey:queue];
  }
  return tracker;
}

/**
 *  Overriden implementation of @c dispatch_after that calls into the tracker, if one is found for
 *  the dispatch queue passed in.
 *
 *  @param when  Same as @c dispatch_after @c when.
 *  @param queue Same as @c dispatch_after @c queue.
 *  @param block Same as @c dispatch_after @c block.
 */
static void grey_dispatch_after(dispatch_time_t when,
                                dispatch_queue_t queue,
                                dispatch_block_t block) {
  [[GREYInterposer sharedInstance] acquireReadLock];
  pthread_mutex_lock(&gNullOriginalPointerLock);
  if (grey_original_dispatch_after == NULL) {
    grey_original_dispatch_after = dispatch_after;
  }
  pthread_mutex_unlock(&gNullOriginalPointerLock);
  GREYDispatchQueueTracker *tracker = grey_getTrackerForQueue(queue);
  if (tracker) {
    [tracker grey_dispatchAfterCallWithTime:when block:block];
  } else {
    grey_original_dispatch_after(when, queue, block);
  }
  [[GREYInterposer sharedInstance] releaseReadLock];
}

/**
 *  Overriden implementation of @c dispatch_async that calls into the tracker, if one is found for
 *  the dispatch queue passed in.
 *
 *  @param queue Same as @c dispatch_async @c queue.
 *  @param block Same as @c dispatch_async @c block.
 */
static void grey_dispatch_async(dispatch_queue_t queue, dispatch_block_t block) {
  [[GREYInterposer sharedInstance] acquireReadLock];
  pthread_mutex_lock(&gNullOriginalPointerLock);
  if (grey_original_dispatch_async == NULL) {
    grey_original_dispatch_async = dispatch_async;
  }
  pthread_mutex_unlock(&gNullOriginalPointerLock);
  GREYDispatchQueueTracker *tracker = grey_getTrackerForQueue(queue);
  if (tracker) {
    [tracker grey_dispatchAsyncCallWithBlock:block];
  } else {
    grey_original_dispatch_async(queue, block);
  }
  [[GREYInterposer sharedInstance] releaseReadLock];
}

/**
 *  Overriden implementation of @c dispatch_sync that calls into the tracker, if one is found for
 *  the dispatch queue passed in.
 *
 *  @param queue Same as @c dispatch_sync @c queue.
 *  @param block Same as @c dispatch_sync @c block.
 */
static void grey_dispatch_sync(dispatch_queue_t queue, dispatch_block_t block) {
  [[GREYInterposer sharedInstance] acquireReadLock];
  pthread_mutex_lock(&gNullOriginalPointerLock);
  if (grey_original_dispatch_sync == NULL) {
    grey_original_dispatch_sync = dispatch_sync;
  }
  pthread_mutex_unlock(&gNullOriginalPointerLock);
  GREYDispatchQueueTracker *tracker = grey_getTrackerForQueue(queue);
  if (tracker) {
    [tracker grey_dispatchSyncCallWithBlock:block];
  } else {
    grey_original_dispatch_sync(queue, block);
  }
  [[GREYInterposer sharedInstance] releaseReadLock];
}

/**
 *  Overriden implementation of @c dispatch_after_f that calls into the tracker, if one is found
 *  for the dispatch queue passed in.
 *
 *  @param when    Same as @c dispatch_after_f @c when.
 *  @param queue   Same as @c dispatch_after_f @c queue.
 *  @param context Same as @c dispatch_after_f @c context.
 *  @param work    Same as @c dispatch_after_f @c work.
 */
static void grey_dispatch_after_f(dispatch_time_t when,
                                  dispatch_queue_t queue,
                                  void *context,
                                  dispatch_function_t work) {
  [[GREYInterposer sharedInstance] acquireReadLock];
  pthread_mutex_lock(&gNullOriginalPointerLock);
  if (grey_original_dispatch_after_f == NULL) {
    grey_original_dispatch_after_f = dispatch_after_f;
  }
  pthread_mutex_unlock(&gNullOriginalPointerLock);
  GREYDispatchQueueTracker *tracker = grey_getTrackerForQueue(queue);
  if (tracker) {
    [tracker grey_dispatchAfterCallWithTime:when context:context work:work];
  } else {
    grey_original_dispatch_after_f(when, queue, context, work);
  }
  [[GREYInterposer sharedInstance] releaseReadLock];
}

/**
 *  Overriden implementation of @c dispatch_async_f that calls into the tracker, if one is found
 *  for the dispatch queue passed in.
 *
 *  @param queue   Same as @c dispatch_async_f @c queue.
 *  @param context Same as @c dispatch_async_f @c context.
 *  @param work    Same as @c dispatch_async_f @c work.
 */
static void grey_dispatch_async_f(dispatch_queue_t queue, void *context, dispatch_function_t work) {
  [[GREYInterposer sharedInstance] acquireReadLock];
  pthread_mutex_lock(&gNullOriginalPointerLock);
  if (grey_original_dispatch_async_f == NULL) {
    grey_original_dispatch_async_f = dispatch_async_f;
  }
  pthread_mutex_unlock(&gNullOriginalPointerLock);
  GREYDispatchQueueTracker *tracker = grey_getTrackerForQueue(queue);
  if (tracker) {
    [tracker grey_dispatchAsyncCallWithContext:context work:work];
  } else {
    grey_original_dispatch_async_f(queue, context, work);
  }
  [[GREYInterposer sharedInstance] releaseReadLock];
}

/**
 *  Overriden implementation of @c dispatch_sync_f that calls into the tracker, if one is found
 *  for the dispatch queue passed in.
 *
 *  @param queue   Same as @c dispatch_sync_f @c queue.
 *  @param context Same as @c dispatch_sync_f @c context.
 *  @param work    Same as @c dispatch_sync_f @c work.
 */
static void grey_dispatch_sync_f(dispatch_queue_t queue, void *context, dispatch_function_t work) {
  [[GREYInterposer sharedInstance] acquireReadLock];
  pthread_mutex_lock(&gNullOriginalPointerLock);
  if (grey_original_dispatch_sync_f == NULL) {
    grey_original_dispatch_sync_f = dispatch_sync_f;
  }
  pthread_mutex_unlock(&gNullOriginalPointerLock);
  GREYDispatchQueueTracker *tracker = grey_getTrackerForQueue(queue);
  if (tracker) {
    [tracker grey_dispatchSyncCallWithContext:context work:work];
  } else {
    grey_original_dispatch_sync_f(queue, context, work);
  }
  [[GREYInterposer sharedInstance] releaseReadLock];
}

#if !__has_feature(address_sanitizer)
// Static interpose is used only when Address Sanitizer is not used, because DYLD interpose chaining
// (2 or more libraries interposing the same function) is broken. Address Sanitizer interposes
// over 200 functions, including most of the functions we need to interpose.
__attribute__((used)) __attribute__((section("__DATA,__interpose")))
static const dyld_interpose_tuple grey_static_interpose_tuples[] = {
  { grey_dispatch_after, dispatch_after },
  { grey_dispatch_async, dispatch_async },
  { grey_dispatch_sync, dispatch_sync },
  { grey_dispatch_after_f, dispatch_after_f },
  { grey_dispatch_async_f, dispatch_async_f },
  { grey_dispatch_sync_f, dispatch_sync_f }
};
#endif

@implementation GREYDispatchQueueTracker {
  __weak dispatch_queue_t _dispatchQueue;
  __block int32_t _pendingBlocks;
}

+ (void)load {
  @autoreleasepool {
    gDispatchQueueToTracker = [NSMapTable weakToWeakObjectsMapTable];

    pthread_mutex_lock(&gNullOriginalPointerLock);
    if (grey_original_dispatch_after == NULL) {
      grey_original_dispatch_after = dispatch_after;
    }
    if (grey_original_dispatch_async == NULL) {
      grey_original_dispatch_async = dispatch_async;
    }
    if (grey_original_dispatch_sync == NULL) {
      grey_original_dispatch_sync = dispatch_sync;
    }
    if (grey_original_dispatch_after_f == NULL) {
      grey_original_dispatch_after_f = dispatch_after_f;
    }
    if (grey_original_dispatch_async_f == NULL) {
      grey_original_dispatch_async_f = dispatch_async_f;
    }
    if (grey_original_dispatch_sync_f == NULL) {
      grey_original_dispatch_sync_f = dispatch_sync_f;
    }
    pthread_mutex_unlock(&gNullOriginalPointerLock);

    [[GREYInterposer sharedInstance] interposeSymbol:dispatch_after
                                     withReplacement:grey_dispatch_after
                              storeOriginalInPointer:(void **)&grey_original_dispatch_after];
    [[GREYInterposer sharedInstance] interposeSymbol:dispatch_async
                                     withReplacement:grey_dispatch_async
                              storeOriginalInPointer:(void **)&grey_original_dispatch_async];
    [[GREYInterposer sharedInstance] interposeSymbol:dispatch_sync
                                     withReplacement:grey_dispatch_sync
                              storeOriginalInPointer:(void **)&grey_original_dispatch_sync];
    [[GREYInterposer sharedInstance] interposeSymbol:dispatch_after_f
                                     withReplacement:grey_dispatch_after_f
                              storeOriginalInPointer:(void **)&grey_original_dispatch_after_f];
    [[GREYInterposer sharedInstance] interposeSymbol:dispatch_async_f
                                     withReplacement:grey_dispatch_async_f
                              storeOriginalInPointer:(void **)&grey_original_dispatch_async_f];
    [[GREYInterposer sharedInstance] interposeSymbol:dispatch_sync_f
                                     withReplacement:grey_dispatch_sync_f
                              storeOriginalInPointer:(void **)&grey_original_dispatch_sync_f];
    [[GREYInterposer sharedInstance] commit];

    dispatch_sync(dispatch_get_global_queue(0, 0), ^{
      NSArray *symbols = [NSThread callStackSymbols];
      // Check if dispatch_sync is interposed.
      BOOL found = NO;
      for (NSString *s in symbols) {
        if ([s rangeOfString:@"grey_dispatch_sync"].location != NSNotFound) {
          found = YES;
          break;
        }
      }
      NSAssert(found, @"dispatch_sync is not interposed");
    });
  }
}

#pragma mark -

+ (instancetype)trackerForDispatchQueue:(dispatch_queue_t)queue {
  NSParameterAssert(queue);

  @synchronized(gDispatchQueueToTracker) {
    GREYDispatchQueueTracker *tracker = grey_getTrackerForQueue(queue);
    if (!tracker) {
      tracker = [[GREYDispatchQueueTracker alloc] initWithDispatchQueue:queue];
      // Register this tracker with dispatch queue to tracker map.
      [gDispatchQueueToTracker setObject:tracker forKey:queue];
    }
    return tracker;
  }
}

- (instancetype)initWithDispatchQueue:(dispatch_queue_t)queue {
  NSParameterAssert(queue);

  self = [super init];
  if (self) {
    _dispatchQueue = queue;
  }
  return self;
}

- (BOOL)isIdleNow {
  NSAssert(_pendingBlocks >= 0, @"_pendingBlocks must not be negative");
  BOOL isIdle = OSAtomicCompareAndSwap32Barrier(0, 0, &_pendingBlocks);
  return isIdle;
}

- (BOOL)isTrackingALiveQueue {
  return _dispatchQueue != nil;
}

#pragma mark - Private

- (void)grey_dispatchAfterCallWithTime:(dispatch_time_t)when block:(dispatch_block_t)block {
  CFTimeInterval maxDelay = GREY_CONFIG_DOUBLE(kGREYConfigKeyDispatchAfterMaxTrackableDelay);
  dispatch_time_t trackDelay = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(maxDelay * NSEC_PER_SEC));

  if (trackDelay >= when) {
    OSAtomicIncrement32Barrier(&_pendingBlocks);
    grey_original_dispatch_after(when, _dispatchQueue, ^{
      block();
      OSAtomicDecrement32Barrier(&_pendingBlocks);
    });
  } else {
    grey_original_dispatch_after(when, _dispatchQueue, block);
  }
}

- (void)grey_dispatchAsyncCallWithBlock:(dispatch_block_t)block {
  OSAtomicIncrement32Barrier(&_pendingBlocks);
  grey_original_dispatch_async(_dispatchQueue, ^{
    block();
    OSAtomicDecrement32Barrier(&_pendingBlocks);
  });
}

- (void)grey_dispatchSyncCallWithBlock:(dispatch_block_t)block {
  OSAtomicIncrement32Barrier(&_pendingBlocks);
  grey_original_dispatch_sync(_dispatchQueue, ^{
    block();
    OSAtomicDecrement32Barrier(&_pendingBlocks);
  });
}

- (void)grey_dispatchAfterCallWithTime:(dispatch_time_t)when
                               context:(void *)context
                                  work:(dispatch_function_t)work {
  CFTimeInterval maxDelay = GREY_CONFIG_DOUBLE(kGREYConfigKeyDispatchAfterMaxTrackableDelay);
  dispatch_time_t trackDelay = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(maxDelay * NSEC_PER_SEC));
  if (trackDelay >= when) {
    OSAtomicIncrement32Barrier(&_pendingBlocks);
    grey_original_dispatch_after(when, _dispatchQueue, ^{
      work(context);
      OSAtomicDecrement32Barrier(&_pendingBlocks);
    });
  } else {
    grey_original_dispatch_after_f(when, _dispatchQueue, context, work);
  }
}

- (void)grey_dispatchAsyncCallWithContext:(void *)context work:(dispatch_function_t)work {
  OSAtomicIncrement32Barrier(&_pendingBlocks);
  grey_original_dispatch_async(_dispatchQueue, ^{
    work(context);
    OSAtomicDecrement32Barrier(&_pendingBlocks);
  });
}

- (void)grey_dispatchSyncCallWithContext:(void *)context work:(dispatch_function_t)work {
  OSAtomicIncrement32Barrier(&_pendingBlocks);
  grey_original_dispatch_sync(_dispatchQueue, ^{
    work(context);
    OSAtomicDecrement32Barrier(&_pendingBlocks);
  });
}

@end
