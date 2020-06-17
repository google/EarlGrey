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

#import <XCTest/XCTest.h>

#import "Channel/Sources/EDOBlockingQueue.h"

@interface EDOBlockingQueueTest : XCTestCase
@end

@implementation EDOBlockingQueueTest

- (void)testAddAndFetchOneObjectFromHead {
  EDOBlockingQueue<NSObject *> *blockingQueue = [[EDOBlockingQueue alloc] init];
  NSObject *object = [[NSObject alloc] init];

  [blockingQueue appendObject:object];
  XCTAssertFalse(blockingQueue.empty);
  XCTAssertEqual([blockingQueue firstObjectWithTimeout:DISPATCH_TIME_FOREVER], object);
  XCTAssertTrue(blockingQueue.empty);
}

- (void)testAddAndFetchOneObjectFromTail {
  EDOBlockingQueue<NSObject *> *blockingQueue = [[EDOBlockingQueue alloc] init];
  NSObject *object = [[NSObject alloc] init];

  [blockingQueue appendObject:object];
  XCTAssertFalse(blockingQueue.empty);
  XCTAssertEqual([blockingQueue lastObjectWithTimeout:DISPATCH_TIME_FOREVER], object);
  XCTAssertTrue(blockingQueue.empty);
}

- (void)testAddAndFetchObjectsInOrder {
  EDOBlockingQueue<NSObject *> *blockingQueue = [[EDOBlockingQueue alloc] init];
  NSArray<NSObject *> *objects = [self objects];

  for (NSObject *object in objects) {
    [blockingQueue appendObject:object];
  }
  for (NSObject *object in objects) {
    XCTAssertEqual([blockingQueue firstObjectWithTimeout:DISPATCH_TIME_FOREVER], object);
  }

  for (NSObject *object in objects) {
    [blockingQueue appendObject:object];
  }
  for (NSObject *object in [objects reverseObjectEnumerator].allObjects) {
    XCTAssertEqual([blockingQueue lastObjectWithTimeout:DISPATCH_TIME_FOREVER], object);
  }
}

- (void)testAddAndFetchObjectsInOrderInDifferentQueue {
  EDOBlockingQueue<NSObject *> *blockingQueue = [[EDOBlockingQueue alloc] init];
  NSArray<NSObject *> *objects = [self objects];

  dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
    for (NSObject *object in objects) {
      [blockingQueue appendObject:object];
    }
  });

  for (NSObject *object in objects) {
    XCTAssertEqual([blockingQueue firstObjectWithTimeout:DISPATCH_TIME_FOREVER], object);
  }
}

- (void)testAddAndFetchObjectsConcurrently {
  EDOBlockingQueue<NSObject *> *blockingQueue = [[EDOBlockingQueue alloc] init];
  NSArray<NSObject *> *objects = [self objects];

  NSMutableArray<NSObject *> *fetchedObjects = [[NSMutableArray alloc] init];
  // Add the placeholders first.
  for (NSUInteger i = 0; i < objects.count; ++i) {
    [fetchedObjects addObject:NSNull.null];
  }

  XCTestExpectation *expectFetchAll = [self expectationWithDescription:@"All objects are fetched."];
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
    dispatch_apply(objects.count, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^(size_t idx) {
      if (idx % 2) {
        fetchedObjects[idx] = [blockingQueue firstObjectWithTimeout:DISPATCH_TIME_FOREVER];
      } else {
        fetchedObjects[idx] = [blockingQueue lastObjectWithTimeout:DISPATCH_TIME_FOREVER];
      }
    });
    [expectFetchAll fulfill];
  });

  dispatch_apply(objects.count, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^(size_t idx) {
    [blockingQueue appendObject:objects[idx]];
  });

  [self waitForExpectationsWithTimeout:1 handler:nil];
  XCTAssertEqualObjects([NSSet setWithArray:fetchedObjects], [NSSet setWithArray:objects]);
}

- (void)testFetchObjectTimeout {
  EDOBlockingQueue<NSObject *> *blockingQueue = [[EDOBlockingQueue alloc] init];
  XCTAssertNil([blockingQueue firstObjectWithTimeout:dispatch_time(DISPATCH_TIME_NOW, 0)]);
  XCTAssertNil([blockingQueue lastObjectWithTimeout:dispatch_time(DISPATCH_TIME_NOW, 0)]);
  ({
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, 200 * NSEC_PER_MSEC);
    XCTAssertNil([blockingQueue firstObjectWithTimeout:timeout]);
    XCTAssertGreaterThanOrEqual(CFAbsoluteTimeGetCurrent() - startTime, 0.2);
  });
  ({
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, 200 * NSEC_PER_MSEC);
    XCTAssertNil([blockingQueue lastObjectWithTimeout:timeout]);
    XCTAssertGreaterThanOrEqual(CFAbsoluteTimeGetCurrent() - startTime, 0.2);
  });
}

- (void)testCloseQueueWithObjects {
  EDOBlockingQueue<NSObject *> *blockingQueue = [[EDOBlockingQueue alloc] init];
  XCTAssertTrue([blockingQueue appendObject:[[NSObject alloc] init]]);
  XCTAssertTrue([blockingQueue close]);
  XCTAssertFalse([blockingQueue close], @"The queue should only be closed once.");

  XCTAssertNotNil([blockingQueue lastObjectWithTimeout:DISPATCH_TIME_FOREVER]);
  XCTAssertNil([blockingQueue lastObjectWithTimeout:DISPATCH_TIME_FOREVER]);
  XCTAssertFalse([blockingQueue appendObject:[[NSObject alloc] init]],
                 @"No new messages should be enqueued after it is closed");
}

- (void)testCloseQueueWithoutObjects {
  EDOBlockingQueue<NSObject *> *blockingQueue = [[EDOBlockingQueue alloc] init];
  XCTAssertTrue([blockingQueue close]);
  XCTAssertFalse([blockingQueue close]);
  XCTAssertNil([blockingQueue lastObjectWithTimeout:DISPATCH_TIME_FOREVER]);
}

#pragma mark - Helper methods

/** Gets a number of objects. */
- (NSArray<NSObject *> *)objects {
  NSMutableArray<NSObject *> *objects = [[NSMutableArray alloc] init];
  for (int i = 100; i >= 0; --i) {
    [objects addObject:[[NSObject alloc] init]];
  }
  return objects;
}

@end
