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

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "Service/Sources/EDOClientService+Private.h"
#import "Service/Sources/EDODeallocationTracker.h"
#import "Service/Sources/EDOHostService+Private.h"
#import "Service/Sources/EDOObjectReleaseMessage.h"
#import "Service/Sources/EDOServiceException.h"
#import "Service/Sources/EDOServicePort.h"
#import "Service/Sources/EDOWeakObject.h"
#import "Service/Sources/NSObject+EDOValueObject.h"
#import "Service/Sources/NSObject+EDOWeakObject.h"
#import "Service/Tests/TestsBundle/EDOTestDummy.h"
#import "Service/Tests/TestsBundle/EDOTestValueType.h"

static const NSTimeInterval kTestTimeoutInterval = 10.0;

@interface EDOWeakReferenceTest : XCTestCase
@end

@implementation EDOWeakReferenceTest

/**
 * Tests EDOWeakObject is an NSProxy that forwards inovcation to the underlying object that both
 * EDOWeakObject and underlying object behaves the same.
 */
- (void)testWeakObjectBehavesTheSameAsUnderlyingObject {
  EDOTestDummy *testDummy = [[EDOTestDummy alloc] init];
  // Cast to EDOTestDummy to test that weakObject is correctly forwarded using same class of
  // functions.
  EDOTestDummy *weakObject = (EDOTestDummy *)[[EDOWeakObject alloc] initWithWeakObject:testDummy];
  XCTAssertEqual([weakObject returnSelf], [testDummy returnSelf]);
}

/**
 * Tests EDOWeakObject is an NSProxy that forwards inovcation to the underlying object that both
 * EDOWeakObject and underlying object behaves the same for multiple objects with the same
 * underlying object.
 */
- (void)testMultipleWeakObjectBehavesTheSameAsUnderlyingObject {
  int numWeakObjects = 10;
  EDOTestDummy *testDummy = [[EDOTestDummy alloc] init];
  // Cast to EDOTestDummy to test that weakObject is correctly forwarded using same class of
  // functions.
  NSArray<EDOTestDummy *> *weakObjects =
      [self weakObjectsArrayWithNumberOfWeakObjects:numWeakObjects localObject:testDummy];
  for (EDOTestDummy *weakObject in weakObjects) {
    XCTAssertEqual([weakObject returnSelf], [testDummy returnSelf]);
  }
}

/**
 * Tests EDOWeakObject is an NSProxy that forwards inovcation to the underlying object.
 */
- (void)testWeakObjectCanForwardToUnderlyingObject {
  EDOTestDummy *dummy = [[EDOTestDummy alloc] init];
  id testDummyMock = OCMPartialMock(dummy);
  // Cast to EDOTestDummy to test that weakObject is correctly forwarded using same class of
  // functions.
  EDOTestDummy *weakObject =
      (EDOTestDummy *)[[EDOWeakObject alloc] initWithWeakObject:testDummyMock];

  // Tests that invoking weakObject actually invokes the underlying object.
  [testDummyMock returnData];
  OCMVerify([weakObject returnData]);
  [testDummyMock returnSelf];
  OCMVerify([weakObject returnSelf]);

  [testDummyMock stopMocking];
}

/**
 * Tests multiple EDOWeakObject can forward inovcation to the same underlying object.
 */
- (void)testMultipleWeakObjectCanForwardToTheUnderlyingObject {
  EDOTestDummy *dummy = [[EDOTestDummy alloc] init];
  id testDummyMock = OCMPartialMock(dummy);

  int numWeakObjects = 10;
  NSArray<EDOTestDummy *> *weakObjects =
      [self weakObjectsArrayWithNumberOfWeakObjects:numWeakObjects localObject:testDummyMock];

  // Tests that invoking weakObject actually invokes the underlying object.
  for (EDOTestDummy *weakObject in weakObjects) {
    [testDummyMock returnData];
    OCMVerify([weakObject returnData]);
    [testDummyMock returnSelf];
    OCMVerify([weakObject returnSelf]);
  }

  [testDummyMock stopMocking];
}

/**
 * Tests when the underlying object is released, weakObject throws the right exception
 * (EDOWeakObjectWeakReleaseException).
 */
- (void)testWeakObjectThrowWhenUnderlyingObjectIsReleased {
  EDOTestDummy *weakObject;
  @autoreleasepool {
    EDOTestDummy *testDummy = [[EDOTestDummy alloc] init];
    weakObject = (EDOTestDummy *)[[EDOWeakObject alloc] initWithWeakObject:testDummy];
  }
  XCTAssertThrowsSpecificNamed([weakObject returnSelf], NSException,
                               EDOWeakObjectWeakReleaseException);
}

/**
 * Tests when the underlying object is released, underlying object becomes nil.
 */
- (void)testWeakObjectBecomeNilWhenUnderlyingObjectIsReleased {
  EDOWeakObject *weakObject;
  @autoreleasepool {
    EDOTestDummy *testDummy = [[EDOTestDummy alloc] init];
    weakObject = [[EDOWeakObject alloc] initWithWeakObject:testDummy];
  }
  XCTAssertNil(weakObject.weakObject);
}

/**
 * Tests multiple weak object with the same underlying object should behave similarly.
 */
- (void)testMultipleWeakObjectWithSameUnderlyingObject {
  int numWeakObjects = 10;
  NSArray<EDOTestDummy *> *weakObjects;
  @autoreleasepool {
    EDOTestDummy *testDummy = [[EDOTestDummy alloc] init];
    weakObjects = [self weakObjectsArrayWithNumberOfWeakObjects:numWeakObjects
                                                    localObject:testDummy];
  }

  for (EDOTestDummy *weakObject in weakObjects) {
    XCTAssertNil(((EDOWeakObject *)weakObject).weakObject);
    XCTAssertThrowsSpecificNamed([weakObject returnSelf], NSException,
                                 EDOWeakObjectWeakReleaseException);
  }
}

/**
 * Tests weak object sends release messsage when underlying object is out of scope.
 * EDODeallocationTracker tracks the object and sends object release request when object is out of
 * scope.
 */
// TODO(b/155329379): Reenable
- (void)disabled_testWeakObjectSendReleaseMessageWhenUnderlyingObjectIsReleased {
  EDOWeakObject *weakObject;
  NSString *queueName = [NSString stringWithFormat:@"com.google.edotest.%@", self.name];
  dispatch_queue_t queue = dispatch_queue_create(queueName.UTF8String, DISPATCH_QUEUE_SERIAL);

  EDOHostService *hostService = [self serviceForQueue:queue];

  id releaseMock = OCMClassMock([EDOObjectReleaseRequest class]);
  @autoreleasepool {
    EDOTestDummy *testDummy = [[EDOTestDummy alloc] init];
    weakObject = [[EDOWeakObject alloc] initWithWeakObject:testDummy];
    [EDODeallocationTracker enableTrackingForObject:weakObject hostPort:hostService.port.hostPort];
    // Verify that release message is not sent if the object is in scope.
    OCMReject([releaseMock requestWithWeakRemoteAddress:(EDOPointerType)weakObject]);
  }
  // Verify that when object is out of scope, the release message is sent.
  OCMVerify([releaseMock requestWithWeakRemoteAddress:(EDOPointerType)weakObject]);

  [releaseMock stopMocking];
  [hostService invalidate];
}

/**
 * Tests weak object sends release messsage when underlying object is out of scope. When multiple
 * EDOWeakObjects exist, the release of the underlying object will lead to multiple release requests
 * being sent.
 */
// TODO(b/155329379): Reenable
- (void)disabled_testMultipleWeakObjectSendReleaseMessageWhenUnderlyingObjectIsReleased {
  int numWeakObjects = 10;
  NSArray<EDOTestDummy *> *weakObjects;

  NSString *queueName = [NSString stringWithFormat:@"com.google.edotest.%@", self.name];
  dispatch_queue_t queue = dispatch_queue_create(queueName.UTF8String, DISPATCH_QUEUE_SERIAL);

  EDOHostService *hostService = [self serviceForQueue:queue];

  id clientMock = OCMClassMock([EDOClientService class]);
  for (int i = 0; i < numWeakObjects; i++) {
    OCMExpect([clientMock sendSynchronousRequest:[OCMArg checkWithBlock:^BOOL(id value) {
                            return [[value class] isEqual:[EDOObjectReleaseRequest class]];
                          }]
                                          onPort:hostService.port.hostPort]);
  }

  @autoreleasepool {
    EDOTestDummy *testDummy = [[EDOTestDummy alloc] init];
    weakObjects = [self weakObjectsArrayWithNumberOfWeakObjects:numWeakObjects
                                                    localObject:testDummy];
    for (EDOWeakObject *weakObject in weakObjects) {
      [EDODeallocationTracker enableTrackingForObject:weakObject
                                             hostPort:hostService.port.hostPort];
    }
    // Verify that release message is not sent if the object is in scope.
    for (EDOWeakObject *weakObject in weakObjects) {
      OCMReject([EDOObjectReleaseRequest requestWithWeakRemoteAddress:(EDOPointerType)weakObject]);
    }
  }

  // Verify that when underlying object is out of scope, the release message is sent.
  // kTestTimeoutInterval is the maximum time that OCMVerify will wait.
  OCMVerifyAllWithDelay(clientMock, kTestTimeoutInterval);

  [hostService invalidate];
  [clientMock stopMocking];
}

/**
 * Tests weak object sends release messsage when underlying object is out of scope with multiple
 * host ports. EDODeallocationTracker tracks the object and sends object release request when object
 * is out of scope.
 */
// TODO(b/155329379): Reenable
- (void)
    disabled_testWeakObjectSendReleaseMessageWhenUnderlyingObjectIsReleasedWithMultipleHostPort {
  int numWeakObjects = 10;
  NSArray<EDOTestDummy *> *weakObjects;
  NSMutableArray<EDOHostService *> *hostServices =
      [[NSMutableArray alloc] initWithCapacity:numWeakObjects];

  for (int i = 0; i < numWeakObjects; i++) {
    NSString *queueName = [NSString stringWithFormat:@"com.google.edotest.%@%d", self.name, i];
    dispatch_queue_t queue = dispatch_queue_create(queueName.UTF8String, DISPATCH_QUEUE_SERIAL);
    [hostServices addObject:[self serviceForQueue:queue]];
  }

  id clientMock = OCMClassMock([EDOClientService class]);
  for (int i = 0; i < numWeakObjects; i++) {
    OCMExpect([clientMock sendSynchronousRequest:[OCMArg checkWithBlock:^BOOL(id value) {
                            return [[value class] isEqual:[EDOObjectReleaseRequest class]];
                          }]
                                          onPort:hostServices[i].port.hostPort]);
  }

  @autoreleasepool {
    EDOTestDummy *testDummy = [[EDOTestDummy alloc] init];
    weakObjects = [self weakObjectsArrayWithNumberOfWeakObjects:numWeakObjects
                                                    localObject:testDummy];
    for (int i = 0; i < numWeakObjects; i++) {
      [EDODeallocationTracker enableTrackingForObject:(EDOWeakObject *)weakObjects[i]
                                             hostPort:hostServices[i].port.hostPort];
    }
    // Verify that release message is not sent if the object is in scope.
    for (EDOWeakObject *weakObject in weakObjects) {
      OCMReject([EDOObjectReleaseRequest requestWithWeakRemoteAddress:(EDOPointerType)weakObject]);
    }
  }
  // Verify that when object is out of scope, the release message is sent, the object has been
  // removed and exception will throw when it is called.
  for (EDOWeakObject *weakObject in weakObjects) {
    XCTAssertThrowsSpecificNamed([(EDOTestDummy *)weakObject returnSelf], NSException,
                                 EDOWeakObjectWeakReleaseException);
    XCTAssert(weakObject.weakObject == nil);
  }

  // Verify that when underlying object is out of scope, the release message is sent.
  // kTestTimeoutInterval is the maximum time that OCMVerify will wait.
  OCMVerifyAllWithDelay(clientMock, kTestTimeoutInterval);

  for (int i = 0; i < numWeakObjects; i++) {
    [hostServices[i] invalidate];
  }
  [clientMock stopMocking];
}

/**
 * Tests weak object sends release messsage when underlying object is out of scope on different
 * queues for concurrency.
 */
// TODO(b/155329379): Reenable
- (void)disabled_testWeakObjectSendReleaseMessageWhenUnderlyingObjectIsReleasedOnDifferentQueues {
  int numWeakObjects = 100;
  NSArray<EDOTestDummy *> *weakObjects;

  NSString *queueName = [NSString stringWithFormat:@"com.google.edotest.%@", self.name];
  dispatch_queue_t concurrentQueue =
      dispatch_queue_create(queueName.UTF8String, DISPATCH_QUEUE_CONCURRENT);

  EDOHostService *hostService = [self serviceForQueue:concurrentQueue];
  id releaseMock = OCMClassMock([EDOObjectReleaseRequest class]);

  @autoreleasepool {
    EDOTestDummy *testDummy = [[EDOTestDummy alloc] init];
    weakObjects = [self weakObjectsArrayWithNumberOfWeakObjects:numWeakObjects
                                                    localObject:testDummy];

    for (EDOWeakObject *weakObject in weakObjects) {
      dispatch_async(concurrentQueue, ^{
        [EDODeallocationTracker enableTrackingForObject:weakObject
                                               hostPort:hostService.port.hostPort];
      });
    }

    // Wait for the concurrentQueue to finish before testing its behaviors.
    dispatch_barrier_sync(concurrentQueue, ^{
                          });

    // Verify that release message is not sent if the object is in scope.
    for (EDOWeakObject *weakObject in weakObjects) {
      OCMReject([releaseMock requestWithWeakRemoteAddress:(EDOPointerType)weakObject]);
    }
  }

  // Verify that when object is out of scope, the release message is sent, the object has been
  // removed and exception will throw when it is called.
  for (EDOWeakObject *weakObject in weakObjects) {
    OCMVerify([releaseMock requestWithWeakRemoteAddress:(EDOPointerType)weakObject]);
    XCTAssertThrowsSpecificNamed([(EDOTestDummy *)weakObject returnSelf], NSException,
                                 EDOWeakObjectWeakReleaseException);
    XCTAssertTrue(weakObject.weakObject == nil);
  }

  [releaseMock stopMocking];
  [hostService invalidate];
}

/**
 * Tests API for weak object reference that remoteWeak invocation and nested invocation works.
 */
- (void)testRemoteWeakAPI {
  EDOTestDummy *object = [[EDOTestDummy alloc] init];
  XCTAssertTrue([[[object remoteWeak] class] isEqual:[EDOWeakObject class]]);
  XCTAssertEqual(((EDOWeakObject *)[object remoteWeak]).weakObject, object);
  XCTAssertEqual(((EDOWeakObject *)[[object remoteWeak] remoteWeak]).weakObject, object);
}

/**
 * Tests API for weak object reference that remoteWeak invocation works with EDOValueObject.
 */
- (void)testRemoteWeakWrapsWithEDOValueObject {
  EDOTestValueType *object = [[EDOTestValueType alloc] init];
  EDOTestValueType *valueObject = [object passByValue];

  XCTAssertTrue([[[valueObject remoteWeak] class] isEqual:[EDOWeakObject class]]);
  XCTAssertEqual(((EDOWeakObject *)[valueObject remoteWeak]).weakObject, object);
}

/**
 * Tests API for weak object reference that remoteWeak works with PassByValue.
 */
- (void)testPassByValueWithRemoteWeak {
  EDOTestDummy *dummyOnBackground = [[EDOTestDummy alloc] init];
  NSArray<NSNumber *> *array = [dummyOnBackground returnArray];
  XCTAssertEqual([dummyOnBackground returnCountWithArray:[[array remoteWeak] passByValue]], 4);
  XCTAssertEqual([dummyOnBackground returnCountWithArray:[[array passByValue] remoteWeak]], 4);
}

/**
 * Tests API for weak object reference that remoteWeak works with nested PassByValue.
 */
- (void)testPassByValueNestedWithRemoteWeak {
  EDOTestDummy *dummyOnBackground = [[EDOTestDummy alloc] init];
  NSArray<NSNumber *> *array = [dummyOnBackground returnArray];
  XCTAssertEqual(
      [dummyOnBackground returnCountWithArray:[[[array passByValue] passByValue] remoteWeak]], 4);
  XCTAssertEqual(
      [dummyOnBackground returnCountWithArray:[[[array remoteWeak] passByValue] passByValue]], 4);
  XCTAssertEqual(
      [dummyOnBackground returnCountWithArray:[[[array passByValue] remoteWeak] passByValue]], 4);
  XCTAssertEqual(
      [dummyOnBackground returnCountWithArray:[[[array remoteWeak] passByValue] remoteWeak]], 4);
  XCTAssertEqual(
      [dummyOnBackground returnCountWithArray:[[[array passByValue] remoteWeak] remoteWeak]], 4);
  XCTAssertEqual(
      [dummyOnBackground returnCountWithArray:[[[array remoteWeak] remoteWeak] passByValue]], 4);
}

/** Tests when the remoteWeak function is called on weakly referenced block object, an exception is
 * thrown. */
- (void)testWeakObjectReferenceBlockObjectCatchesException {
  void (^localBlock)(void) = ^{
    [self awakeFromNib];
  };
  XCTAssertThrowsSpecificNamed([localBlock remoteWeak], NSException,
                               EDOWeakReferenceBlockObjectException);
}

#pragma mark - Helper methods

- (NSArray<EDOTestDummy *> *)weakObjectsArrayWithNumberOfWeakObjects:(int)numberOfWeakObjects
                                                         localObject:(EDOTestDummy *)testDummy {
  NSMutableArray<EDOTestDummy *> *weakObjects =
      [NSMutableArray arrayWithCapacity:numberOfWeakObjects];
  for (int i = 0; i < numberOfWeakObjects; i++) {
    [weakObjects addObject:(EDOTestDummy *)[[EDOWeakObject alloc] initWithWeakObject:testDummy]];
  }
  return weakObjects;
}

- (EDOHostService *)serviceForQueue:(dispatch_queue_t)queue {
  return [EDOHostService serviceWithPort:0 rootObject:[[EDOTestDummy alloc] init] queue:queue];
}
@end
