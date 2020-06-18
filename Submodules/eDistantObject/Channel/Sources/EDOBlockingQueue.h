//
// Copyright 2019 Google LLC
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

NS_ASSUME_NONNULL_BEGIN

/**
 *  The simple double-ended queue that provides synchronized append and remove operations.
 *
 *  Elements can be appended to the blocking queue and retrieved from either end. The retrieval can
 *  be synchronized in the way that it waits until there is an element. This is primarily for
 *  producer-consumer use cases.
 *
 *  After the queue is closed, no more objects can be appended but one can still fetch objects
 *  until it is empty, in such case, the timeout will not affect and return @c nil immediately.
 */
@interface EDOBlockingQueue<ObjectType> : NSObject

/** Whether the queue has any objects. */
@property(readonly, getter=isEmpty) BOOL empty;

/** The number of objects in the queue. */
@property(readonly) NSUInteger count;

/** Appends the @c object to the end of the queue.
 *
 *  @return YES if the object is appended; NO, if the queue is closed already and the message
 *          will not be enqueued.
 */
- (BOOL)appendObject:(ObjectType)object;

/**
 *  Fetches an object from the head of the queue.
 *
 *  @note This will block the current thread until an object has been added to the queue.
 *
 *  @param timeout The timeout to wait until the element is available.
 *  @return The object in the queue, or @c nil if timing out.
 */
- (nullable ObjectType)firstObjectWithTimeout:(dispatch_time_t)timeout;

/**
 *  Fetches an object from the tail of the queue.
 *
 *  @note This will block the current thread until an object has been added to the queue.
 *
 *  @param timeout The timeout to wait until the element is available.
 *  @return The object in the queue, or @c nil if timing out.
 */
- (nullable ObjectType)lastObjectWithTimeout:(dispatch_time_t)timeout;

/**
 *  Closes the queue so no more messages can be appended.
 *
 *  @note The closed queue can still fetch objects but will not wait if the queue is empty.
 *  @return YES if the queue is just closed; NO if the queue is already closed.
 */
- (BOOL)close;

@end

NS_ASSUME_NONNULL_END
