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

#import <EarlGrey/GREYOperationQueueIdlingResource.h>

#import "GREYBaseTest.h"

@interface GREYOperationQueueIdlingResourceTest : GREYBaseTest
@end

@implementation GREYOperationQueueIdlingResourceTest  {
  NSOperationQueue *_backgroundOperationQ;
}

- (void)setUp {
  [super setUp];
  _backgroundOperationQ = [[NSOperationQueue alloc] init];
}

- (void)tearDown {
  [_backgroundOperationQ cancelAllOperations];
  [_backgroundOperationQ waitUntilAllOperationsAreFinished];
  [super tearDown];
}

- (void)testQueueName {
  NSString *queueName = @"queueName";
  GREYOperationQueueIdlingResource *idlingRes = [GREYOperationQueueIdlingResource
                                                  resourceWithNSOperationQueue:_backgroundOperationQ
                                                                          name:queueName];
  XCTAssertEqual(queueName, [idlingRes idlingResourceName], @"Name differs");
}

- (void)testIsInitiallyIdle {
  GREYOperationQueueIdlingResource *idlingRes = [GREYOperationQueueIdlingResource
                                                  resourceWithNSOperationQueue:_backgroundOperationQ
                                                                          name:@"test"];
  XCTAssertTrue([idlingRes isIdleNow], @"Empty queue should be in idle state.");
}

- (void)testOccupiedQueueNotIdle {
  GREYOperationQueueIdlingResource *idlingRes = [GREYOperationQueueIdlingResource
                                                  resourceWithNSOperationQueue:_backgroundOperationQ
                                                                          name:@"test"];
  [_backgroundOperationQ addOperationWithBlock:^(void) {
    NSLog(@"Should not execute until runloop is fast forwarded.");
  }];
  XCTAssertFalse([idlingRes isIdleNow], @"Non-empty queue should not be in idle state.");
}

- (void)testOccupiedQueueIdleAfterTaskCompletion {
  GREYOperationQueueIdlingResource *idlingRes = [GREYOperationQueueIdlingResource
                                                  resourceWithNSOperationQueue:_backgroundOperationQ
                                                                          name:@"test"];
  __block BOOL executed = NO;
  [_backgroundOperationQ addOperationWithBlock:^(void) {
    executed = YES;
  }];

  XCTAssertFalse([idlingRes isIdleNow], @"Non-empty queue should not be in idle state.");

  do {
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, true);
  } while (!executed);

  XCTAssertTrue([idlingRes isIdleNow], @"Queue should be idle after executing the only task.");
}

@end
