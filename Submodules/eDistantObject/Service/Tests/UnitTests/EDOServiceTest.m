//
// Copyright 2018 Google Inc.
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

#import "Channel/Sources/EDOHostPort.h"
#import "Service/Sources/EDOClientService+Private.h"
#import "Service/Sources/EDOClientService.h"
#import "Service/Sources/EDOHostNamingService+Private.h"
#import "Service/Sources/EDOHostService+Private.h"
#import "Service/Sources/EDOObjectMessage.h"
#import "Service/Sources/EDORemoteException.h"
#import "Service/Sources/EDOServiceError.h"
#import "Service/Sources/EDOServicePort.h"
#import "Service/Sources/EDOServiceRequest.h"
#import "Service/Sources/NSObject+EDOValueObject.h"
#import "Service/Tests/TestsBundle/EDOTestClassDummy.h"
#import "Service/Tests/TestsBundle/EDOTestDummy.h"
#import "Service/Tests/TestsBundle/EDOTestNonNSCodingType.h"
#import "Service/Tests/TestsBundle/EDOTestProtocol.h"
#import "Service/Tests/TestsBundle/EDOTestValueType.h"

static NSString *const kTestServiceName = @"com.google.edotest.service";

@interface EDOServiceTest : XCTestCase
@property(readonly) id serviceBackgroundMock;
@property(readonly) id serviceMainMock;
@property(readonly) EDOHostService *serviceOnBackground;
@property(readonly) EDOHostService *serviceOnMain;
@property(readonly) EDOTestDummy *rootObject;
@property(readonly) dispatch_queue_t executionQueue;
@property(readonly) EDOTestDummy *rootObjectOnBackground;
@property(weak) EDOHostService *weakService;
@property(weak) dispatch_queue_t weakQueue;
@end

@implementation EDOServiceTest

- (void)setUp {
  [super setUp];

  NSString *queueName = [NSString stringWithFormat:@"com.google.edotest.%@", self.name];
  _executionQueue = dispatch_queue_create(queueName.UTF8String, DISPATCH_QUEUE_SERIAL);
  _rootObject = [[EDOTestDummy alloc] init];

  _serviceOnMain = [EDOHostService serviceWithRegisteredName:kTestServiceName
                                                  rootObject:[[EDOTestDummy alloc] init]
                                                       queue:dispatch_get_main_queue()];
  _serviceMainMock = OCMPartialMock(_serviceOnMain);
  OCMStub([_serviceMainMock isObjectAlive:OCMOCK_ANY]).andReturn(NO);
  [self resetBackgroundService];
}

- (void)tearDown {
  [self.serviceOnMain invalidate];
  [self.serviceOnBackground invalidate];
  _executionQueue = nil;
  _serviceOnMain = nil;
  _serviceOnBackground = nil;
  _rootObject = nil;

  [self.serviceMainMock stopMocking];
  [self.serviceBackgroundMock stopMocking];
  _serviceMainMock = nil;
  _serviceBackgroundMock = nil;

  [super tearDown];
}

- (void)testServiceAssociatedQueue {
  dispatch_queue_t testQueue = dispatch_queue_create("com.google.edotest", DISPATCH_QUEUE_SERIAL);
  EDOHostService *hostService = [EDOHostService serviceWithPort:0 rootObject:self queue:testQueue];
  dispatch_sync(testQueue, ^{
    XCTAssertEqual(hostService, [EDOHostService serviceForCurrentOriginatingQueue]);
    XCTAssertEqual(hostService, [EDOHostService serviceForOriginatingQueue:testQueue]);
  });
  XCTAssertEqual(hostService, [EDOHostService serviceForOriginatingQueue:testQueue]);
}

- (void)testServiceWithNonassignedeExecutingQueue {
  EDOHostService *hostService = [EDOHostService serviceWithPort:0 rootObject:self queue:nil];
  // TODO(haowoo): This should be 1 once we fix the ownership.
  XCTAssertEqual(hostService.originatingQueues.count, 0);
}

- (void)testExecutingQueueIsOriginatingQueue {
  dispatch_queue_t testQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);
  EDOHostService *hostService = [EDOHostService serviceWithPort:0 rootObject:self queue:testQueue];
  XCTAssertTrue([hostService.originatingQueues containsObject:testQueue]);
}

- (void)testServiceCanHaveOtherExecutingQueue {
  dispatch_queue_t testQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);
  EDOHostService *hostService = [EDOHostService serviceWithPort:0 rootObject:self queue:testQueue];

  @autoreleasepool {
    dispatch_queue_t testQueue2 = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);
    hostService.originatingQueues = @[ testQueue2 ];
    XCTAssertTrue([hostService.originatingQueues containsObject:testQueue]);
    XCTAssertTrue([hostService.originatingQueues containsObject:testQueue2]);
  }

  // Service doesn't hold the originating queue.
  XCTAssertEqual(hostService.originatingQueues.count, 1);
}

- (void)testServiceCanGetFromOriginatingQueue {
  dispatch_queue_t testQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);
  dispatch_queue_t testQueue2 = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);

  EDOHostService *hostService = [EDOHostService serviceWithPort:0 rootObject:self queue:testQueue];
  XCTAssertEqual(hostService, [EDOHostService serviceForOriginatingQueue:testQueue]);

  hostService.originatingQueues = @[ testQueue2 ];
  XCTAssertEqual(hostService, [EDOHostService serviceForOriginatingQueue:testQueue]);
  XCTAssertEqual(hostService, [EDOHostService serviceForOriginatingQueue:testQueue2]);
  dispatch_sync(testQueue2, ^{
    XCTAssertEqual(hostService, [EDOHostService serviceForCurrentOriginatingQueue]);
  });
}

- (void)testServiceCanGetFromExecutingQueue {
  dispatch_queue_t testQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);

  EDOHostService *hostService = [EDOHostService serviceWithPort:0 rootObject:self queue:testQueue];
  dispatch_sync(testQueue, ^{
    XCTAssertEqual(hostService, [EDOHostService serviceForCurrentOriginatingQueue]);
    XCTAssertEqual(hostService, [EDOHostService serviceForCurrentExecutingQueue]);
  });
}

- (void)testServiceLifecycleIsBoundToQueue {
  dispatch_queue_t testQueue = dispatch_queue_create("com.google.edotest", DISPATCH_QUEUE_SERIAL);
  self.weakQueue = testQueue;
  self.weakService = [EDOHostService serviceWithPort:0 rootObject:self queue:testQueue];
  XCTAssertNotNil([EDOHostService serviceForOriginatingQueue:testQueue]);
  XCTAssertEqual(self.weakService, [EDOHostService serviceForOriginatingQueue:testQueue]);

  // The dispatch queue library may delegate its dealloc and callback to a different queue/thread.
  XCTKVOExpectation *expectServiceNil = [[XCTKVOExpectation alloc] initWithKeyPath:@"weakService"
                                                                            object:self
                                                                     expectedValue:nil];
  XCTKVOExpectation *expectQueueNil = [[XCTKVOExpectation alloc] initWithKeyPath:@"weakQueue"
                                                                          object:self
                                                                   expectedValue:nil];
  [self waitForExpectations:@[ expectServiceNil, expectQueueNil ] timeout:10];
}

- (void)testTemporaryServiceLazilyCreatedIfNoServiceAvailable {
  dispatch_queue_t testQueue = dispatch_queue_create("com.google.edotest", DISPATCH_QUEUE_SERIAL);
  EDOTestDummy *dummyOnBackground = self.rootObjectOnBackground;

  EDOHostService *service = [EDOHostService serviceWithPort:0 rootObject:nil queue:nil];
  XCTAssertFalse(service.valid);
  id serviceMock = OCMPartialMock(service);
  [serviceMock setExpectationOrderMatters:YES];
  OCMStub([[serviceMock classMethod] serviceWithPort:0 rootObject:nil queue:nil])
      .andReturn(serviceMock);
  OCMExpect([serviceMock distantObjectForLocalObject:OCMOCK_ANY hostPort:[OCMArg isNil]])
      .andForwardToRealObject();
  OCMExpect([(EDOHostService *)serviceMock port]).andForwardToRealObject();

  dispatch_sync(testQueue, ^{
    XCTAssertNil([EDOHostService serviceForCurrentOriginatingQueue]);
    // eDO will wrap the block into a remote object which would create a temporary service.
    // The service shouldn't initialize the listen socket (by calling -port), until it is later to
    // wrap the block object (by calling -distantObjectForLocalObject:hostPort:), in the
    // respective order.
    [dummyOnBackground voidWithBlock:^{
    }];
  });
  XCTAssertTrue(service.valid);

  OCMVerifyAll(serviceMock);
  [serviceMock stopMocking];
}

- (void)testTemporaryServiceNotListenedIfNoRemoteObject {
  dispatch_queue_t testQueue = dispatch_queue_create("com.google.edotest", DISPATCH_QUEUE_SERIAL);
  EDOTestDummy *dummyOnBackground = self.rootObjectOnBackground;

  EDOHostService *service = [EDOHostService serviceWithPort:0 rootObject:nil queue:nil];
  id serviceMock = OCMPartialMock(service);
  OCMStub([[serviceMock classMethod] serviceWithPort:0 rootObject:nil queue:nil])
      .andReturn(serviceMock);
  OCMReject([(EDOHostService *)serviceMock port]);

  dispatch_sync(testQueue, ^{
    XCTAssertNil([EDOHostService serviceForCurrentOriginatingQueue]);
    // Whether eDO creates a temporary service or not, it shouldn't initialize the listen socket by
    // calling -port.
    [dummyOnBackground voidWithInt:0];
  });

  OCMVerifyAll(serviceMock);
  [serviceMock stopMocking];
}

- (void)testClassMethodsAndInit {
  Class remoteClass = EDO_REMOTE_CLASS(EDOTestDummy, self.serviceOnBackground.port.hostPort.port);

  EDOTestDummy *dummy;
  @autoreleasepool {
    EDOTestDummy *dummyAlloc;
    XCTAssertNoThrow(dummyAlloc = [remoteClass alloc]);
    XCTAssertNoThrow(dummy = [dummyAlloc initWithValue:10]);
    XCTAssertEqual(dummy, dummyAlloc);
    XCTAssertEqual(dummy.value, 10);
  }

  @autoreleasepool {
    XCTAssertNoThrow(dummy = [remoteClass classMethodWithNumber:@10]);
    XCTAssertEqual(dummy.value, 10);
  }
}

- (void)testEDOBlock {
  EDOTestDummy *dummyOnBackground = self.rootObjectOnBackground;

  double doubleReturn = [dummyOnBackground returnWithBlockDouble:^double {
    return 100.0;
  }];
  XCTAssertEqual(doubleReturn, 100.0);
  EDOTestDummyStruct dummyStruct =
      [dummyOnBackground returnStructWithBlockStret:^EDOTestDummyStruct {
        return (EDOTestDummyStruct){.value = 100, .a = 30.0, .x = 50, .z = 200};
      }];
  XCTAssertEqual(dummyStruct.value, 100);
  XCTAssertEqual(dummyStruct.a, 30);
  XCTAssertEqual(dummyStruct.x, 50);
  XCTAssertEqual(dummyStruct.z, 200);

  dummyOnBackground.value = 10;
  EDOTestDummy *returnDummy = [dummyOnBackground returnWithBlockObject:^id(EDOTestDummy *dummy) {
    dummy.value += 10;
    return dummy;
  }];
  XCTAssertEqual(returnDummy.value, 20);

  EDOTestDummy * (^complexBlock)(EDOTestDummyStruct, int, EDOTestDummy *) =
      ^(EDOTestDummyStruct dummy, int i, EDOTestDummy *test) {
        test.value = i + dummy.value + 4;
        return test;
      };
  returnDummy = [dummyOnBackground returnWithInt:5
                                     dummyStruct:(EDOTestDummyStruct){.value = 150}
                                    blockComplex:complexBlock];
  ;
  XCTAssertEqual(returnDummy.value, 159);
}

- (void)testReturnUniqueEDOForSameUnderlyingObjects {
  EDOTestDummy *dummyOnBackground = self.rootObjectOnBackground;
  Class remoteClass = EDO_REMOTE_CLASS(EDOTestDummy, self.serviceOnBackground.port.hostPort.port);

  XCTAssertEqual([dummyOnBackground returnClass], [dummyOnBackground returnClass]);
  XCTAssertEqual([dummyOnBackground returnClass], remoteClass);

  EDOTestDummy *dummySelf = [dummyOnBackground returnSelf];
  XCTAssertEqual(dummySelf, dummyOnBackground);
  XCTAssertEqual([self class], [dummyOnBackground classsWithClass:[self class]]);
  XCTAssertEqual(remoteClass, [dummyOnBackground classsWithClass:remoteClass]);

  XCTAssertEqual(remoteClass,
                 EDO_REMOTE_CLASS(EDOTestDummy, self.serviceOnBackground.port.hostPort.port));
  [self resetBackgroundService];
  // Even the underlying objects are the same, it should return a different remote object because
  // the old service is gone, and the local cache should be invalidated.
  XCTAssertNotEqual(remoteClass,
                    EDO_REMOTE_CLASS(EDOTestDummy, self.serviceOnBackground.port.hostPort.port));

  // Update the background object after resetting the service.
  dummyOnBackground = self.rootObjectOnBackground;

  EDOTestDummy *dummyOut;
  self.rootObject.value = 19;
  XCTAssertNoThrow([dummyOnBackground voidWithValue:23 outSelf:&dummyOut]);
  XCTAssertEqual(dummyOut, dummyOnBackground);
  XCTAssertEqual(dummyOut.value, 42);

  self.rootObject.value = 19;
  XCTAssertNoThrow([dummyOnBackground voidWithValue:11 outSelf:&dummyOut]);
  XCTAssertEqual(dummyOut, dummyOnBackground);
  XCTAssertEqual(dummyOut.value, 49);

  EDOTestDummy *dummyOutAgain;
  dummyOut = nil;
  // voidWithOutObject: returns
  // 1) a new object if dummyOut is nil
  // 2) the same object if dummyOut is already pointing to something
  XCTAssertNoThrow([dummyOnBackground voidWithOutObject:&dummyOut]);
  XCTAssertNoThrow([dummyOnBackground voidWithOutObject:&dummyOutAgain]);
  XCTAssertNotEqual(dummyOutAgain, dummyOut);
  XCTAssertEqual(dummyOut.value, dummyOutAgain.value);

  EDOTestDummy *dummyOutOriginal = dummyOut;
  XCTAssertNoThrow([dummyOnBackground voidWithOutObject:&dummyOut]);
  XCTAssertEqual(dummyOutOriginal, dummyOut);
}

- (void)testUnderlyingObjectShouldReturnFromBackgroundQueueInTheSameProcess {
  dispatch_queue_t testQueue = dispatch_queue_create("com.google.edotest", DISPATCH_QUEUE_SERIAL);
  dispatch_sync(testQueue, ^{
    XCTAssertNotEqual([[self.rootObjectOnBackground returnSelf] class], [EDOTestDummy class],
                      @"The returned object should be a remote object.");
  });

  // The service on the background queue will resolve to the local address.
  [self.serviceBackgroundMock stopMocking];

  dispatch_sync(testQueue, ^{
    XCTAssertEqual([[self.rootObjectOnBackground returnSelf] class], [EDOTestDummy class],
                   @"The returned object should be a local object.");
  });
}

- (void)testResolveToSameUnderlyingObjectInArgument {
  EDOTestDummy *dummyOnBackground = self.rootObjectOnBackground;

  // The argument dummyOnBackground should be resolved to the same remote object.
  XCTAssertEqual([dummyOnBackground memoryAddressFromObject:dummyOnBackground],
                 [dummyOnBackground memoryAddressFromObject:dummyOnBackground]);
  XCTAssertEqual([dummyOnBackground memoryAddressFromObjectRef:&dummyOnBackground],
                 [dummyOnBackground memoryAddressFromObjectRef:&dummyOnBackground]);
}

- (void)testResolveToUnderlyingInstanceIfInTheSameProcess {
  EDOTestDummy *dummyOut;
  EDOTestDummy *dummyOnBackground = self.rootObjectOnBackground;

  // The service on the background queue will resolve to the local address.
  [self.serviceBackgroundMock stopMocking];
  XCTAssertEqual([[dummyOnBackground returnSelf] class], [EDOTestDummy class]);
  XCTAssertEqualObjects([dummyOnBackground returnClassNameWithObject:self], @"EDOObject");
  XCTAssertNoThrow(({
    dummyOut = nil;
    [dummyOnBackground voidWithOutObject:&dummyOut];
  }));
  XCTAssertEqual([dummyOut class], [EDOTestDummy class]);

  // The services on both the main queue and the background queue will resolve to the local address.
  [self.serviceMainMock stopMocking];
  XCTAssertEqual([[dummyOnBackground returnSelf] class], [EDOTestDummy class]);
  XCTAssertEqualObjects([dummyOnBackground returnClassNameWithObject:self],
                        NSStringFromClass([self class]));
  XCTAssertNoThrow(({
    dummyOut = nil;
    [dummyOnBackground voidWithOutObject:&dummyOut];
  }));
  XCTAssertEqual([dummyOut class], [EDOTestDummy class]);

  // The service on the main queue will resolve to the local address.
  _serviceBackgroundMock = OCMPartialMock(self.serviceOnBackground);
  OCMStub([_serviceBackgroundMock isObjectAlive:OCMOCK_ANY]).andReturn(NO);

  XCTAssertEqual([[dummyOnBackground returnSelf] class], NSClassFromString(@"EDOObject"));
  XCTAssertEqualObjects([dummyOnBackground returnClassNameWithObject:self],
                        NSStringFromClass([self class]));
  XCTAssertNoThrow(({
    dummyOut = nil;
    [dummyOnBackground voidWithOutObject:&dummyOut];
  }));
  XCTAssertEqual([dummyOut class], NSClassFromString(@"EDOObject"));
}

- (void)testVoidReturnWithParametersOfDifferentKinds {
  EDOTestDummy *dummyOnBackground = self.rootObjectOnBackground;

  self.rootObject.value = 10;

  XCTAssertNoThrow([dummyOnBackground voidWithValuePlusOne]);
  XCTAssertEqual(self.rootObject.value, 11);

  XCTAssertNoThrow([dummyOnBackground voidWithInt:5]);
  XCTAssertEqual(self.rootObject.value, 16);

  XCTAssertNoThrow([dummyOnBackground voidWithNumber:@(7)]);
  XCTAssertEqual(self.rootObject.value, 23);

  XCTAssertNoThrow([dummyOnBackground voidWithString:@"12345" data:NSData.data]);
  XCTAssertEqual(self.rootObject.value, 28);

  XCTAssertNoThrow([dummyOnBackground voidWithStruct:(EDOTestDummyStruct){.value = 11}]);
  XCTAssertEqual(self.rootObject.value, 39);

  XCTAssertThrowsSpecificNamed([dummyOnBackground voidWithId:nil], EDORemoteException,
                               @"Dummy NilArg 39");

  XCTAssertNoThrow([dummyOnBackground voidWithClass:self.class]);

  XCTAssertEqualObjects([[dummyOnBackground returnDictionary] class],
                        NSClassFromString(@"EDOObject"));
  XCTAssertEqualObjects([[dummyOnBackground returnArray] class], NSClassFromString(@"EDOObject"));
  XCTAssertEqualObjects([[dummyOnBackground returnSet] class], NSClassFromString(@"EDOObject"));

  XCTAssertEqualObjects([self fastEnumerateDictionary:dummyOnBackground],
                        [self fastEnumerateDictionary:self.rootObject]);
  XCTAssertEqualObjects([self fastEnumerateArray:dummyOnBackground],
                        [self fastEnumerateArray:self.rootObject]);
  XCTAssertEqualObjects([self fastEnumerateSet:dummyOnBackground],
                        [self fastEnumerateSet:self.rootObject]);
  XCTAssertNoThrow([self fastEnumerateCustom:self.rootObject]);
  XCTAssertThrowsSpecificNamed([self fastEnumerateCustom:dummyOnBackground], NSException,
                               NSInternalInconsistencyException);

  XCTAssertNoThrow([dummyOnBackground voidWithBlock:nil]);
  XCTAssertNoThrow([dummyOnBackground voidWithBlock:^{
  }]);
}

- (void)testOutParameterCanResolveToLocalWhenDereferencing {
  EDOTestDummy *dummyOnBackground = self.rootObjectOnBackground;
  EDOTestDummy *remoteDummy = [dummyOnBackground returnSelf];
  EDOTestDummy *localDummy = [[EDOTestDummy alloc] initWithValue:5];
  EDOTestDummy *emptyDummy;

  XCTAssertNil([dummyOnBackground returnClassNameWithObjectRef:nil]);
  XCTAssertEqualObjects([dummyOnBackground returnClassNameWithObjectRef:&emptyDummy], @"");
  XCTAssertEqualObjects([dummyOnBackground returnClassNameWithObjectRef:&localDummy], @"EDOObject");
  XCTAssertEqualObjects([dummyOnBackground returnClassNameWithObjectRef:&remoteDummy],
                        @"EDOTestDummy");
}

- (void)testOutParameters {
  EDOTestDummy *dummyOnBackground = self.rootObjectOnBackground;

  self.rootObject.value = 13;
  NSNumber *numberOut;
  XCTAssertNoThrow([dummyOnBackground voidWithValueOut:&numberOut]);
  XCTAssertEqualObjects(numberOut, @(13));
  XCTAssertNoThrow([dummyOnBackground voidWithValueOut:&numberOut]);
  XCTAssertEqualObjects(numberOut, @(26));

  NSError *errorOut;
  XCTAssertNoThrow([dummyOnBackground voidWithErrorOut:&errorOut]);
  XCTAssertEqualObjects([errorOut class], NSClassFromString(@"EDOObject"));

  EDOTestDummy *dummyOut;
  XCTAssertNoThrow([dummyOnBackground voidWithOutObject:&dummyOut]);
  XCTAssertEqual(dummyOut.value, 18);

  XCTAssertEqualObjects([dummyOut class], NSClassFromString(@"EDOObject"));
  XCTAssertNoThrow([dummyOnBackground voidWithOutObject:&dummyOut]);
  XCTAssertEqual(dummyOut.value, 23);

  dummyOut = [[EDOTestDummy alloc] initWithValue:17];
  EDOTestDummy *dummyOriginal = dummyOut;
  XCTAssertNoThrow([dummyOnBackground voidWithOutObject:&dummyOut]);
  XCTAssertEqual(dummyOut, dummyOriginal);
  XCTAssertEqual(dummyOut.value, 22);

  self.rootObject.value = 13;
  XCTAssertNoThrow([dummyOnBackground voidWithValue:5 outSelf:&dummyOut]);
  XCTAssertEqualObjects([dummyOut class], NSClassFromString(@"EDOObject"));
  XCTAssertEqual(dummyOut.value, 40);
}

- (void)testDifferentThrows {
  EDOTestDummy *dummyOnBackground = self.rootObjectOnBackground;

  self.rootObject.value = 13;
  XCTAssertThrowsSpecificNamed([dummyOnBackground selWithThrow], EDORemoteException,
                               @"Dummy Just Throw 13");
  XCTAssertThrowsSpecificNamed([dummyOnBackground voidWithId:nil], EDORemoteException,
                               @"Dummy NilArg 13");
  XCTAssertThrowsSpecificNamed([dummyOnBackground voidWithId:dummyOnBackground], EDORemoteException,
                               @"Dummy NonNilArg 13");
  XCTAssertThrowsSpecificNamed([dummyOnBackground voidWithId:self.rootObject], EDORemoteException,
                               @"Dummy EDOArg 13");
  XCTAssertThrowsSpecificNamed([dummyOnBackground voidWithValueOut:nil], EDORemoteException,
                               @"Dummy NilOutArg 13");
  XCTAssertThrowsSpecificNamed([dummyOnBackground voidWithErrorOut:nil], EDORemoteException,
                               @"Dummy NilErrorOut 13");
  XCTAssertThrowsSpecificNamed([dummyOnBackground voidWithOutObject:nil], EDORemoteException,
                               @"Dummy dummyOut is nil 13");
}

- (void)testNoParametersWithReturnsOfDifferentKinds {
  EDOTestDummy *dummyOnBackground = self.rootObjectOnBackground;

  self.rootObject.value = 17;
  XCTAssertEqualObjects([dummyOnBackground class], NSClassFromString(@"EDOObject"));
  XCTAssertEqual([dummyOnBackground returnInt], [self.rootObject returnInt]);
  XCTAssertEqual([dummyOnBackground returnStruct].value, [self.rootObject returnStruct].value);
  XCTAssertEqualObjects([dummyOnBackground returnNumber], [self.rootObject returnNumber]);
  XCTAssertEqualObjects([dummyOnBackground returnString], [self.rootObject returnString]);
  XCTAssertEqualObjects([dummyOnBackground returnData], [self.rootObject returnData]);
  XCTAssertEqual([dummyOnBackground returnSelf].value, self.rootObject.value);
  XCTAssertNil([dummyOnBackground returnIdNil]);
  XCTAssertNoThrow([dummyOnBackground returnClass]);
}

- (void)testReturnsWithParameters {
  EDOTestDummy *dummyOnBackground = self.rootObjectOnBackground;

  self.rootObject.value = 23;
  XCTAssertEqual([dummyOnBackground structWithStruct:(EDOTestDummyStruct){.value = 7}].value, 30);
  XCTAssertEqual(self.rootObject.value, 30);
  XCTAssertEqual([dummyOnBackground returnIdWithInt:11].value, 41);
  XCTAssertEqualObjects([dummyOnBackground classsWithClass:self.class], self.class);
  XCTAssertEqualObjects([dummyOnBackground returnNumberWithInt:3 value:@5],
                        @(self.rootObject.value + 8));
  XCTAssertFalse([dummyOnBackground returnBoolWithError:nil]);

  NSError *errorOut;
  XCTAssertTrue([dummyOnBackground returnBoolWithError:&errorOut]);
  XCTAssertEqual(self.rootObject.error.code, errorOut.code);
  XCTAssertEqualObjects(self.rootObject.error.domain, errorOut.domain);
}

- (void)testSelectorParameterAndReturns {
  EDOTestDummy *dummyOnBackground = self.rootObjectOnBackground;
  XCTAssertEqual([dummyOnBackground selectorFromName:nil], nil);
  XCTAssertEqual([dummyOnBackground selectorFromName:@"selectorFromName:"],
                 @selector(selectorFromName:));

  XCTAssertEqualObjects([dummyOnBackground nameFromSelector:@selector(nameFromSelector:)],
                        @"nameFromSelector:");
  XCTAssertNil([dummyOnBackground nameFromSelector:nil]);
}

- (void)testMockAndNSProxyParameters {
  EDOTestDummy *dummyOnBackground = self.rootObjectOnBackground;

  // The real object on the background queue.
  EDOTestDummy *objectMock = OCMPartialMock(self.rootObject);
  [(OCMockObject *)objectMock setExpectationOrderMatters:YES];

  XCTAssertEqualObjects([dummyOnBackground returnClassNameWithObject:objectMock], @"EDOObject");
  XCTAssertNoThrow(dummyOnBackground.value);
  XCTAssertNoThrow([dummyOnBackground voidWithInt:10]);

  OCMVerify([objectMock returnClassNameWithObject:[OCMArg isNotNil]]);
  OCMVerify([objectMock value]);
  OCMVerify([objectMock voidWithInt:10]);

  Class helperClass =
      EDO_REMOTE_CLASS(EDOProtocolMockTestHelper, self.serviceOnBackground.port.hostPort.port);
  Class ocmArgClass = EDO_REMOTE_CLASS(OCMArg, self.serviceOnBackground.port.hostPort.port);

  id testProtocol = [helperClass createTestProtocol];
  [[testProtocol expect] methodWithNothing];
  [[testProtocol expect] methodWithObject:[ocmArgClass isNil]];
  [[testProtocol expect] returnWithNothing];
  [[testProtocol expect] returnWithObject:[ocmArgClass isNotNil]];
  [helperClass invokeMethodsWithProtocol:testProtocol];

  OCMVerifyAll(testProtocol);
  // Let it resolve otherwise -[isEqual:] causes infinite loop from mocking.
  [self.serviceBackgroundMock stopMocking];
  [self.serviceMainMock stopMocking];
}

- (void)testEDODescription {
  EDOTestDummy *dummyOnBackground = self.rootObjectOnBackground;
  // Assign an arbitrary non-zero number to avoid test flakiness.
  dummyOnBackground.value = 19;
  XCTAssertEqualObjects(dummyOnBackground.description, @"Test Dummy 19");
}

- (void)testEDOEqual {
  EDOTestDummy *dummyOnBackground = self.rootObjectOnBackground;
  NSSet<NSNumber *> *returnSetA = [dummyOnBackground returnSet];
  NSSet<NSNumber *> *returnSetB = [dummyOnBackground returnSet];
  XCTAssertEqual([returnSetA class], NSClassFromString(@"EDOObject"));
  XCTAssertEqual([returnSetB class], NSClassFromString(@"EDOObject"));

  XCTAssertTrue([returnSetA isEqual:returnSetB]);
  XCTAssertTrue([returnSetA isEqual:returnSetA]);
  XCTAssertEqual(returnSetB.hash, returnSetA.hash);
  XCTAssertEqual([dummyOnBackground returnSelf].hash, [dummyOnBackground returnSelf].hash);
  XCTAssertEqual(returnSetB.hash, [dummyOnBackground returnArray].hash);
  XCTAssertFalse([returnSetA isEqual:[self.rootObject returnSet]]);
}

- (void)testEDOAsDictKey {
  EDOTestDummy *dummyOnBackground = self.rootObjectOnBackground;
  NSSet *returnSet = [dummyOnBackground returnSet];
  NSArray *returnArray = [dummyOnBackground returnArray];
  NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];

  XCTAssertNil(dictionary[returnSet]);
  XCTAssertNoThrow(dictionary[returnSet] = @1);
  XCTAssertNil(dictionary[returnArray]);
  XCTAssertEqualObjects(dictionary[returnSet], @1);
  XCTAssertNoThrow([dictionary removeObjectForKey:returnSet]);
  XCTAssertNil(dictionary[returnSet]);
}

- (void)testEDOAsCFDictKey {
  EDOTestDummy *dummyOnBackground = self.rootObjectOnBackground;
  NSSet *returnSet = [dummyOnBackground returnSet];
  NSArray *returnArray = [dummyOnBackground returnArray];
  CFMutableDictionaryRef cfDictionary = CFDictionaryCreateMutable(
      NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);

  CFDictionarySetValue(cfDictionary, (void *)returnSet, CFSTR("Set"));
  XCTAssertNoThrow(XCTAssertNotNil(CFDictionaryGetValue(cfDictionary, (void *)returnSet)));

  NSMutableDictionary *tolledDict = (__bridge NSMutableDictionary *)cfDictionary;
  XCTAssertNoThrow(tolledDict[returnArray] = @"Array");
  XCTAssertEqualObjects(tolledDict[returnSet], @"Set");

  NSMutableSet *allValues = [[NSMutableSet alloc] init];
  XCTAssertNoThrow(({
    for (NSSet *key in tolledDict) {
      [allValues addObject:tolledDict[key]];
    }
  }));
  XCTAssertEqualObjects(allValues, [NSSet setWithArray:tolledDict.allValues]);
}

// Test enable value type for custom class conforming to NSCoding.
- (void)testEnableCustomClassToBeValueType {
  EDOTestValueType *object = [[EDOTestValueType alloc] init];
  EDOTestDummy *dummyOnBackground = self.rootObjectOnBackground;
  XCTAssertEqualObjects([dummyOnBackground returnClassNameWithObject:object], @"EDOObject");
  [EDOTestValueType edo_enableValueType];
  XCTAssertEqualObjects([dummyOnBackground returnClassNameWithObject:object], @"EDOTestValueType");

  // Enable again to guarantee idempotency
  [EDOTestValueType edo_enableValueType];
  XCTAssertEqualObjects([dummyOnBackground returnClassNameWithObject:object], @"EDOTestValueType");
}

// Test enable value type for custom class not conforming to NSCoding.
- (void)testFailToEnableNonNSCodingTypetoBeValueType {
  EDOTestNonNSCodingType *object = [[EDOTestNonNSCodingType alloc] init];
  EDOTestDummy *dummyOnBackground = self.rootObjectOnBackground;
  XCTAssertThrows([EDOTestNonNSCodingType edo_enableValueType]);
  XCTAssertEqualObjects([dummyOnBackground returnClassNameWithObject:object], @"EDOObject");
}

- (void)testEDOReturnsAsValueType {
  EDOTestDummy *dummyOnBackground = self.rootObjectOnBackground;
  NSArray *returnArray = [[dummyOnBackground returnByValue] returnArray];
  NSArray *localArray = @[ @1, @2, @3, @4 ];
  XCTAssertEqual([returnArray class], [localArray class]);
  XCTAssertTrue([returnArray isEqualToArray:localArray]);
}

- (void)testEDOReturnsByValueError {
  NSArray *localArray = @[ @1, @2, @3 ];
  XCTAssertThrowsSpecificNamed([[localArray returnByValue] count], NSException,
                               NSObjectNotAvailableException);
}

- (void)testEDOPassByValue {
  EDOTestDummy *dummyOnBackground = self.rootObjectOnBackground;
  NSArray *array = @[ @1, @2, @3, @4 ];
  XCTAssertEqual([dummyOnBackground returnSumWithArrayAndProxyCheck:[array passByValue]], 10);
}

- (void)testEDOPassByValueWithRemoteObject {
  EDOTestDummy *dummyOnBackground = self.rootObjectOnBackground;
  NSArray *array = [dummyOnBackground returnArray];
  XCTAssertEqual([dummyOnBackground returnCountWithArray:[array passByValue]], 4);
}

- (void)testEDOPassByValueNestedWithReturnByValue {
  EDOTestDummy *dummyOnBackground = self.rootObjectOnBackground;
  NSArray *array = [dummyOnBackground returnArray];
  XCTAssertEqual([dummyOnBackground returnCountWithArray:[[array returnByValue] passByValue]], 4);
}

- (void)testEDOPassByValueNestedWithPassByValue {
  EDOTestDummy *dummyOnBackground = self.rootObjectOnBackground;
  NSArray *array = [dummyOnBackground returnArray];
  XCTAssertEqual([dummyOnBackground returnCountWithArray:[[array passByValue] passByValue]], 4);
}

- (void)testEDOReturnByValueNestedWithPassByValue {
  EDOTestDummy *dummyOnBackground = self.rootObjectOnBackground;
  NSArray *array = [dummyOnBackground returnArray];
  XCTAssertEqual([dummyOnBackground returnCountWithArray:[[array passByValue] returnByValue]], 4);
}

- (void)testEDOHostServiceTrackedByNamingService {
  EDOHostNamingService *namingServiceObject = EDOHostNamingService.sharedService;
  XCTAssertFalse([namingServiceObject portForServiceWithName:kTestServiceName] == 0);
}

- (void)testClientErrorHandlerNotNil {
  EDOSetClientErrorHandler(nil);
  EDOClientErrorHandler oldErrorHandler = EDOSetClientErrorHandler(nil);
  XCTAssertNotNil(oldErrorHandler);
}

- (void)testClientErrorHandlerInvoked {
  XCTestExpectation *expectInvoke = [self expectationWithDescription:@"Error handler is invoked."];
  EDOSetClientErrorHandler(^(NSError *error) {
    [expectInvoke fulfill];
  });
  // The port 0 is reserved and should always fail to connect to it.
  [EDOClientService rootObjectWithPort:0];
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testServicePopulateExecutorHandlingError {
  EDOHostService *hostService = [EDOHostService serviceWithPort:2233 rootObject:self queue:nil];
  EDOHostPort *port = [EDOHostPort hostPortWithLocalPort:2233];
  XCTAssertThrows([EDOClientService
      sendSynchronousRequest:[EDOObjectRequest requestWithHostPort:port]
                      onPort:port]);
  [hostService invalidate];
}

- (void)testServiceRecordProcessTime {
  dispatch_queue_t testQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);
  EDOHostService *hostService = [EDOHostService serviceWithPort:2234
                                                     rootObject:self
                                                          queue:testQueue];
  EDOHostPort *port = [EDOHostPort hostPortWithLocalPort:2234];
  EDOServiceResponse *response =
      [EDOClientService sendSynchronousRequest:[EDOObjectRequest requestWithHostPort:port]
                                        onPort:port];
  [hostService invalidate];
  XCTAssertTrue([response isKindOfClass:[EDOObjectResponse class]]);
  // Assert the duration is within the reasonable range (0ms, 1000ms].
  XCTAssertTrue(response.duration > 0 && response.duration <= 1000);
}

#pragma mark - Helper methods

- (EDOTestDummy *)rootObjectOnBackground {
  return [EDOClientService rootObjectWithPort:self.serviceOnBackground.port.hostPort.port];
}

- (NSArray<NSString *> *)fastEnumerateDictionary:(EDOTestDummy *)dummy {
  NSMutableArray<NSString *> *allKeys = [[NSMutableArray alloc] init];
  for (NSString *key in [dummy returnDictionary]) {
    [allKeys addObject:key];
  }
  return [allKeys copy];
}

- (NSArray<NSNumber *> *)fastEnumerateArray:(EDOTestDummy *)dummy {
  NSMutableArray *allElements = [[NSMutableArray alloc] init];
  for (NSNumber *obj in [dummy returnArray]) {
    [allElements addObject:obj];
  }
  return [allElements copy];
}

- (NSSet<NSNumber *> *)fastEnumerateSet:(EDOTestDummy *)dummy {
  NSMutableSet *allElements = [[NSMutableSet alloc] init];
  for (NSNumber *obj in [dummy returnSet]) {
    [allElements addObject:obj];
  }
  return [allElements copy];
}

- (void)fastEnumerateCustom:(EDOTestDummy *)dummy {
  for (id obj in dummy) {
    NSLog(@"%@", obj);
  }
}

- (void)resetBackgroundService {
  [_serviceBackgroundMock stopMocking];
  [_serviceOnBackground invalidate];
  _serviceOnBackground = [EDOHostService serviceWithPort:0
                                              rootObject:self.rootObject
                                                   queue:self.executionQueue];
  // Disable the isObjectAlive: check so the object from the background queue will not be resolved
  // to the underlying object but a remote object.
  _serviceBackgroundMock = OCMPartialMock(_serviceOnBackground);
  OCMStub([_serviceBackgroundMock isObjectAlive:OCMOCK_ANY]).andReturn(NO);
}

@end
