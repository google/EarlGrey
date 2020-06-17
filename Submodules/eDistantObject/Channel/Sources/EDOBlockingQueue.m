//
// Copyright 2019 Google LLC.
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

#import "Channel/Sources/EDOBlockingQueue.h"

@implementation EDOBlockingQueue {
  /** The dispatch queue used for the resource isolation/fast lock. */
  dispatch_queue_t _objectIsolationQueue;
  /** The objects in the pool. */
  NSMutableArray<id> *_objects;
  /** The object semaphore to signal. */
  dispatch_semaphore_t _numberOfObjects;
  /** Whether the queue is closed and will reject any new object. */
  BOOL _closed;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    NSString *queueName = [NSString stringWithFormat:@"com.google.edo.blockingqueue[%p]", self];
    _objectIsolationQueue = dispatch_queue_create(queueName.UTF8String, DISPATCH_QUEUE_SERIAL);
    _objects = [[NSMutableArray alloc] init];
    _numberOfObjects = dispatch_semaphore_create(0L);
  }
  return self;
}

- (BOOL)appendObject:(id)object {
  __block BOOL appended = NO;
  dispatch_sync(_objectIsolationQueue, ^{
    if (!self->_closed) {
      [self->_objects addObject:object];
      appended = YES;
    }
  });
  dispatch_semaphore_signal(_numberOfObjects);
  return appended;
}

- (id)firstObjectWithTimeout:(dispatch_time_t)timeout {
  if (![self shouldWaitMessage]) {
    return nil;
  }

  if (dispatch_semaphore_wait(_numberOfObjects, timeout) != 0) {
    return nil;
  }

  __block id object;
  dispatch_sync(_objectIsolationQueue, ^{
    if (self->_objects.count > 0) {
      object = self->_objects.firstObject;
      [self->_objects removeObjectAtIndex:0];
    }
  });
  return object;
}

- (id)lastObjectWithTimeout:(dispatch_time_t)timeout {
  if (![self shouldWaitMessage]) {
    return nil;
  }

  if (dispatch_semaphore_wait(_numberOfObjects, timeout) != 0) {
    return nil;
  }

  __block id object;
  dispatch_sync(_objectIsolationQueue, ^{
    if (self->_objects.count > 0) {
      object = self->_objects.lastObject;
      [self->_objects removeLastObject];
    }
  });
  return object;
}

- (BOOL)close {
  __block BOOL success = NO;
  dispatch_sync(_objectIsolationQueue, ^{
    if (!self->_closed) {
      self->_closed = YES;
      success = YES;
    }
  });
  if (success) {
    dispatch_semaphore_signal(_numberOfObjects);
  }
  return success;
}

- (BOOL)isEmpty {
  return self.count == 0;
}

- (NSUInteger)count {
  __block NSUInteger count;
  dispatch_sync(_objectIsolationQueue, ^{
    count = self->_objects.count;
  });
  return count;
}

- (BOOL)shouldWaitMessage {
  __block BOOL shouldWaitMessage = YES;
  dispatch_sync(_objectIsolationQueue, ^{
    if (self->_closed && self->_objects.count == 0) {
      shouldWaitMessage = NO;
    }
  });
  return shouldWaitMessage;
}

@end
