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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  The executor to handle other tasks while waiting for an asynchronous task to complete.
 *
 *  The executor is running a while-loop and handling other tasks using the message queue. When a
 *  task is to be handled by the executor, it will enqueue the task to the message queue,
 *  which will be picked up by the executor when it is running a while-loop; if it is not running
 *  a while-loop, it will be dispatch to the execution queue to process it.
 */
@interface EDOExecutor : NSObject

/** The dispatch queue to handle the request if it is not running. */
@property(readonly, nonatomic, weak) dispatch_queue_t executionQueue;

- (instancetype)init NS_UNAVAILABLE;

/**
 *  Initializes the executor with the given dispatch queue.
 *
 *  The executor will keep track of the dispatch queue weakly, and assigned itself to its context
 *  under the key "com.google.executorkey"; the dispatch queue holds its reference so it shares the
 *  same lifecycle as the queue (you can safely discard the returned value).
 *
 *  @remark If the dispatch queue is already assigned one executor, it will be replaced.
 *  @param queue    The dispatch queue to associate with the executor.
 *
 *  @return The @c EDOExecutor associated with the dispatch queue.
 */
- (instancetype)initWithQueue:(nullable dispatch_queue_t)queue NS_DESIGNATED_INITIALIZER;

/**
 *  Runs the while-loop to handle exeuctions from EDOExecutor::handleBlock: until the execution
 *  of @c excuteBlock completes.
 *
 *  @note The executor keep waiting on the messages until the @c executeBlock is finished.
 *  @param executeBlock The block to execute in the background queue.
 */
- (void)loopWithBlock:(void (^)(void))executeBlock;

/**
 *  Attaches @c executeBlock for execution and waits for execution completes.
 *
 *  @note If the executor is running the while-loop, the request will be enqueued to process,
 *        or it will dispatch to the @c executionQueue to process.
 *  @param      executeBlock   The block to be handled and executed.
 *  @param[out] error          Error that will be populated on failure.
 *
 *  @return @c YES if the block is successfully executed by the executor; @c NO otherwise, in which
 *          case the block won't get invoked.
 */
- (BOOL)handleBlock:(void (^)(void))executeBlock error:(NSError *_Nullable *_Nullable)errorOrNil;

@end

NS_ASSUME_NONNULL_END
