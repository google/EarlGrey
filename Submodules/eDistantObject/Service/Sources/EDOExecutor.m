//
// Copyright 2018 Google LLC.
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

#import "Service/Sources/EDOExecutor.h"

#import "Channel/Sources/EDOBlockingQueue.h"
#import "Service/Sources/EDOExecutorMessage.h"
#import "Service/Sources/EDOServiceError.h"

@interface EDOExecutor ()
// The message queues to process the requests that are attached to this executor.
@property NSMutableArray<EDOBlockingQueue<EDOExecutorMessage *> *> *messageQueueStack;
// The isolation queue for synchronization.
@property(readonly) dispatch_queue_t isolationQueue;
@end

@implementation EDOExecutor

+ (instancetype)executorWithQueue:(dispatch_queue_t)queue {
  return [[self alloc] initWithQueue:queue];
}

/**
 *  Initialize with the request @c handlers for the dispatch @c queue.
 *
 *  The executor is associated with the dispatch queue and saved to its context. It shares the same
 *  life cycle as the dispatch queue and it only holds the weak reference of the designated queue.
 *
 *  @param queue The dispatch queue to associate with the executor.
 */
- (instancetype)initWithQueue:(dispatch_queue_t)queue {
  self = [super init];
  if (self) {
    NSString *queueName = [NSString stringWithFormat:@"com.google.edo.executor[%p]", self];
    _isolationQueue = dispatch_queue_create(queueName.UTF8String, DISPATCH_QUEUE_SERIAL);
    _executionQueue = queue;
    _messageQueueStack = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)loopWithBlock:(void (^)(void))executeBlock {
  // Create the waited queue so it can also process the requests while waiting for the response
  // when the incoming request is dispatched to the same queue.
  EDOBlockingQueue<EDOExecutorMessage *> *messageQueue = [[EDOBlockingQueue alloc] init];

  // Set the message queue to process the request that will be received and dispatched to this
  // queue while waiting for the response to come back.
  dispatch_sync(self.isolationQueue, ^{
    [self.messageQueueStack addObject:messageQueue];
  });

  // Schedule the handler in the background queue so it won't block the current thread. After the
  // handler closes the messageQueue, before or after the while loop starts, it will trigger the
  // while loop to exit.
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    executeBlock();
    [messageQueue close];
  });

  while (true) {
    // Block the current queue and wait for the new message. It will unset the
    // messageQueue if it receives a response so there is no race condition where it has some
    // messages left in the queue to be processed after the queue is unset.
    // ready to pop
    EDOExecutorMessage *message = [messageQueue firstObjectWithTimeout:DISPATCH_TIME_FOREVER];
    if (!message) {
      break;
    }
    [message executeBlock];
  }

  dispatch_sync(self.isolationQueue, ^{
    // If messageQueue has not been popped out from stack yet, pop it out here to avoid memleak.
    NSMutableArray<EDOBlockingQueue<EDOExecutorMessage *> *> *stack = self.messageQueueStack;
    if (stack.lastObject == messageQueue) {
      [stack removeLastObject];
    }
  });
  NSAssert(messageQueue.empty, @"The message queue contains stale requests.");
}

- (BOOL)handleBlock:(void (^)(void))executeBlock error:(NSError *_Nullable *_Nullable)errorOrNil {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  // TODO(haowoo): Replace with dispatch_assert_queue once the minimum support is iOS 10+.
  NSAssert(dispatch_get_current_queue() != self.executionQueue,
           @"Only enqueue a request from a non-tracked queue.");
#pragma clang diagnostic pop

  EDOExecutorMessage *message = [[EDOExecutorMessage alloc] initWithBlock:executeBlock];
  if (![self enqueueMessage:message]) {
    dispatch_queue_t executionQueue = self.executionQueue;
    if (executionQueue) {
      dispatch_async(self.executionQueue, ^{
        [message executeBlock];
      });
    } else {
      if (errorOrNil) {
        NSString *reason =
            @"The message is not handled because the execution queue is already released.";
        *errorOrNil = [NSError errorWithDomain:EDOServiceErrorDomain
                                          code:EDOServiceErrorRequestNotHandled
                                      userInfo:@{@"reason" : reason}];
      }
      return NO;
    }
  }
  [message waitForCompletion];
  return YES;
}

#pragma mark - Private

/**
 *  Append @c message to a message queue that will be executed on the execution queue.
 *
 *  @param message The message to be enqueued.
 *
 *  @return @c YES if message is enqueued to a message queue; @c NO if no message queue is
 *          available.
 */
- (BOOL)enqueueMessage:(EDOExecutorMessage *)message {
  __block BOOL messageEnqueued = NO;
  dispatch_sync(self.isolationQueue, ^{
    NSMutableArray<EDOBlockingQueue<EDOExecutorMessage *> *> *stack = self.messageQueueStack;
    while (stack.count > 0 && ![stack.lastObject appendObject:message]) {
      [stack removeLastObject];
    }
    messageEnqueued = stack.count > 0;
  });
  return messageEnqueued;
}

@end
