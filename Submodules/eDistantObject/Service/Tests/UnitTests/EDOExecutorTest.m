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

#import <XCTest/XCTest.h>

#import "Service/Sources/EDOExecutor.h"
#import "Service/Sources/EDOServiceError.h"

@interface EDOExecutorTest : XCTestCase

@property(readonly) void (^emptyBlock)(void);

@end

@implementation EDOExecutorTest

- (void)testExecutorNotRunningToHandleMessageWithoutQueue {
  EDOExecutor *executor = [[EDOExecutor alloc] initWithQueue:nil];

  NSError *error;
  XCTAssertFalse([executor handleBlock:self.emptyBlock error:&error]);
  XCTAssertEqualObjects(error.domain, EDOServiceErrorDomain);
  XCTAssertEqual(error.code, EDOServiceErrorRequestNotHandled);
  XCTAssertTrue([error.userInfo.description containsString:@"execution queue is already released"]);
}

- (void)testExecutorNotRunningToHandleMessageWithQueue {
  dispatch_queue_t queue = [self testQueue];
  EDOExecutor *executor = [[EDOExecutor alloc] initWithQueue:queue];
  __block BOOL executed = NO;
  [executor
      handleBlock:^{
        executed = YES;
      }
            error:nil];
  XCTAssertTrue(executed);
}

- (void)testExecutorFinishRunningAfterClosingMessageQueue {
  dispatch_queue_t queue = [self testQueue];
  EDOExecutor *executor = [[EDOExecutor alloc] initWithQueue:queue];

  XCTestExpectation *expectFinish = [self expectationWithDescription:@"The executor is finished."];
  dispatch_async(queue, ^{
    [executor loopWithBlock:self.emptyBlock];
    // Only fulfills the exepectation after the executor finishes the run.
    [expectFinish fulfill];
  });

  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testExecutorHandleMessageAfterClosingQueue {
  dispatch_queue_t queue = [self testQueue];
  EDOExecutor *executor = [[EDOExecutor alloc] initWithQueue:queue];

  XCTestExpectation *expectClose = [self expectationWithDescription:@"The queue is closed."];
  dispatch_async(queue, ^{
    [executor loopWithBlock:^{
      [expectClose fulfill];
    }];
  });

  [self waitForExpectationsWithTimeout:1 handler:nil];
  [executor handleBlock:self.emptyBlock error:nil];
}

- (void)testSendRequestWithExecutorProcessingStressfully {
  NS_VALID_UNTIL_END_OF_SCOPE dispatch_queue_t queue = [self testQueue];
  EDOExecutor *executor = [[EDOExecutor alloc] initWithQueue:queue];

  XCTestExpectation *expectFinish = [self expectationWithDescription:@"The executor is finished."];
  expectFinish.expectedFulfillmentCount = 3;
  __block NSInteger numIncrements = 0;
  NSInteger numRuns = 1000;
  dispatch_async(queue, ^{
    for (NSInteger i = 0; i < numRuns; ++i) {
      [executor loopWithBlock:^{
        ++numIncrements;
      }];
    }
    [expectFinish fulfill];
  });

  // Generate requests from differnt QoS queues so it can cover cases:
  // 1. the request is received before the executor starts
  // 2. the request is received after the executor starts but before the while-loop starts
  // 3. the request is received after the while-loop tarts.
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    for (NSInteger i = 0; i < numRuns; ++i) {
      [executor
          handleBlock:^{
            ++numIncrements;
          }
                error:nil];
    }
    [expectFinish fulfill];
  });
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
    for (NSInteger i = 0; i < numRuns; ++i) {
      [executor
          handleBlock:^{
            ++numIncrements;
          }
                error:nil];
    }
    [expectFinish fulfill];
  });
  [self waitForExpectationsWithTimeout:0.1 * numRuns handler:nil];
  XCTAssertEqual(numIncrements, 3 * numRuns);
}

- (void)testSendRequestWithNestedExecutorProcessingStressfully {
  NS_VALID_UNTIL_END_OF_SCOPE dispatch_queue_t queue = [self testQueue];
  XCTestExpectation *expectFinish = [self expectationWithDescription:@"The executor is finished."];
  const NSInteger numThreadsHighQos = 6;
  const NSInteger numThreadsLowQos = 3;
  const NSInteger numRuns = 100;
  expectFinish.expectedFulfillmentCount = numThreadsHighQos + numThreadsLowQos;

  EDOExecutor *executor = [[EDOExecutor alloc] initWithQueue:queue];
  void (^handlerBlock)(void) = ^{
    [executor loopWithBlock:^{
    }];
  };

  dispatch_async(queue, ^{
    [executor loopWithBlock:^{
      dispatch_group_t requestsGroup = dispatch_group_create();
      for (NSInteger i = 0; i < numThreadsHighQos; ++i) {
        dispatch_group_enter(requestsGroup);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
          for (NSInteger j = 0; j < numRuns; ++j) {
            [executor handleBlock:handlerBlock error:nil];
          }
          dispatch_group_leave(requestsGroup);
          [expectFinish fulfill];
        });
      }
      for (NSInteger i = 0; i < numThreadsLowQos; ++i) {
        dispatch_group_enter(requestsGroup);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
          for (NSInteger j = 0; j < numRuns; ++j) {
            [executor handleBlock:handlerBlock error:nil];
          }
          dispatch_group_leave(requestsGroup);
          [expectFinish fulfill];
        });
      }
      dispatch_group_wait(requestsGroup, DISPATCH_TIME_FOREVER);
    }];
  });
  [self waitForExpectationsWithTimeout:0.1 * numRuns * (numThreadsHighQos + numThreadsLowQos)
                               handler:nil];
}

#pragma mark - Test helper methods

- (void (^)(void))emptyBlock {
  return ^{
  };
}

/** Create a dispatch queue with the current testname. */
- (dispatch_queue_t)testQueue {
  NSString *queueName = [NSString stringWithFormat:@"com.google.edo.Executor[%@]", self.name];
  return dispatch_queue_create(queueName.UTF8String, DISPATCH_QUEUE_SERIAL);
}

@end
