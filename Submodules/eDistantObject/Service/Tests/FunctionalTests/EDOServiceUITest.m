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

#import "Service/Tests/FunctionalTests/EDOServiceUIBaseTest.h"

#include <objc/runtime.h>

#import "Channel/Sources/EDOHostPort.h"
#import "Channel/Sources/EDOSocket.h"
#import "Channel/Sources/EDOSocketChannel.h"
#import "Service/Sources/EDOClientService.h"
#import "Service/Sources/EDOHostNamingService.h"
#import "Service/Sources/EDOHostService.h"
#import "Service/Sources/EDORemoteException.h"
#import "Service/Sources/EDOServiceError.h"
#import "Service/Sources/NSObject+EDOBlacklistedType.h"
#import "Service/Sources/NSObject+EDOValueObject.h"
#import "Service/Tests/FunctionalTests/EDOTestDummyInTest.h"
#import "Service/Tests/TestsBundle/EDOTestClassDummy.h"
#import "Service/Tests/TestsBundle/EDOTestDummy.h"
#import "Service/Tests/TestsBundle/EDOTestProtocol.h"
#import "Service/Tests/TestsBundle/EDOTestProtocolInApp.h"
#import "Service/Tests/TestsBundle/EDOTestProtocolInTest.h"

static NSString *const kTestServiceName = @"com.google.edo.testService";

@interface EDOUITestAppUITests : EDOServiceUIBaseTest
@end

@implementation EDOUITestAppUITests

- (void)tearDown {
  EDOSetClientErrorHandler(nil);
  [super tearDown];
}

- (void)testServiceNonExist {
  [self launchApplicationWithPort:EDOTEST_APP_SERVICE_PORT initValue:5];
  EDOTestDummy *remoteDummy = [EDOClientService rootObjectWithPort:EDOTEST_APP_SERVICE_PORT];

  // The temporary service is created and self is wrapped as a remote object being sent
  // to the application process without the service created locally here.
  XCTAssertEqualObjects([remoteDummy returnClassNameWithObject:self], @"EDOObject");
}

- (void)testValueAndIdOutParameter {
  [self launchApplicationWithPort:EDOTEST_APP_SERVICE_PORT initValue:7];
  EDOHostService *service =
      [EDOHostService serviceWithPort:2234
                           rootObject:[[EDOTestDummyInTest alloc] initWithValue:9]
                                queue:dispatch_get_main_queue()];

  EDOTestDummy *remoteDummy = [EDOClientService rootObjectWithPort:EDOTEST_APP_SERVICE_PORT];
  XCTAssertEqualObjects([remoteDummy class], NSClassFromString(@"EDOObject"));

  NSError *errorOut;
  XCTAssertFalse([remoteDummy returnBoolWithError:nil]);
  XCTAssertTrue([remoteDummy returnBoolWithError:&errorOut]);
  XCTAssertEqual(errorOut.code, 7);

  EDOTestDummy *dummyOut;
  XCTAssertThrows([remoteDummy voidWithOutObject:nil]);

  [remoteDummy voidWithOutObject:&dummyOut];
  XCTAssertEqualObjects([dummyOut class], NSClassFromString(@"EDOObject"));
  XCTAssertEqual(dummyOut.value, 12);

  EDOTestDummyInTest *dummyInTestOut;
  // 11 + 7 + 12
  XCTAssertEqual(
      [dummyOut selWithOutEDO:&dummyInTestOut dummy:[[EDOTestDummyInTest alloc] initWithValue:11]],
      30);
  // dummyInTestOut is created in this process and need to be unwrapped to the local address
  // as an out parameter.
  XCTAssertEqualObjects([dummyInTestOut class], [EDOTestDummyInTest class]);
  XCTAssertEqual(dummyInTestOut.value.intValue, 30);

  EDOTestDummyInTest *dummyInTestOutRet = [dummyOut selWithInOutEDO:&dummyInTestOut];
  XCTAssertEqual(dummyInTestOut.value.intValue, 30);
  XCTAssertEqual(dummyInTestOutRet.value.intValue, 49);  // 12 + 7 + 30

  EDOTestDummyInTest *dummyInNil;
  XCTAssertNil([dummyOut selWithInOutEDO:&dummyInNil]);
  XCTAssertThrows([dummyOut selWithInOutEDO:nil]);

  [service invalidate];
}

- (void)testProtocolParameter {
  [self launchApplicationWithPort:EDOTEST_APP_SERVICE_PORT initValue:10];

  EDOTestDummy *remoteDummy = [EDOClientService rootObjectWithPort:EDOTEST_APP_SERVICE_PORT];

  // The protocol is loaded in the both sides so it shouldn't throw an exception.
  XCTAssertNoThrow([remoteDummy voidWithProtocol:@protocol(EDOTestProtocol)]);
  // This protocol isn't loaded on the app-side.
  XCTAssertThrowsSpecificNamed([remoteDummy voidWithProtocol:@protocol(EDOTestProtocolInTest)],
                               NSException, NSInternalInconsistencyException);
  // Calling a method from the protocol
  XCTAssertTrue([[remoteDummy protocolName] isEqualToString:@"EDOTestProtocolInApp"]);
  // Getting a protocol that wasn't loaded on the test side
  XCTAssertThrowsSpecificNamed([remoteDummy returnWithProtocolInApp], NSException,
                               NSInternalInconsistencyException);
}

- (void)testBlacklistedParameter {
  [self launchApplicationWithPort:EDOTEST_APP_SERVICE_PORT initValue:0];
  EDOBlacklistedTestDummyInTest *testDummy =
      [[EDOBlacklistedTestDummyInTest alloc] initWithValue:0];
  EDOHostService *service = [EDOHostService serviceWithPort:2234
                                                 rootObject:testDummy
                                                      queue:dispatch_get_main_queue()];
  EDOTestDummy *remoteDummy = [EDOClientService rootObjectWithPort:EDOTEST_APP_SERVICE_PORT];

  XCTAssertNoThrow([remoteDummy callBackToTest:testDummy withValue:0]);
  XCTAssertNoThrow([remoteDummy createEDOWithPort:2234]);
  XCTAssertNoThrow([remoteDummy selWithInOutEDO:&testDummy]);
  [EDOBlacklistedTestDummyInTest edo_disallowRemoteInvocation];
  XCTAssertThrows([remoteDummy callBackToTest:testDummy withValue:0]);
  XCTAssertThrows([remoteDummy createEDOWithPort:2234]);
  XCTAssertThrows([remoteDummy selWithInOutEDO:&testDummy]);
  EDOTestDummyInTest *plainTestDummy = [[EDOTestDummyInTest alloc] initWithValue:0];
  XCTAssertNoThrow([remoteDummy callBackToTest:plainTestDummy withValue:0]);

  [service invalidate];
}

- (void)testTwoWayAndMultiplexInvocation {
  [self launchApplicationWithPort:EDOTEST_APP_SERVICE_PORT initValue:5];
  EDOHostService *service =
      [EDOHostService serviceWithPort:2234
                           rootObject:[[EDOTestDummyInTest alloc] initWithValue:9]
                                queue:dispatch_get_main_queue()];

  EDOTestDummy *remoteDummy = [EDOClientService rootObjectWithPort:EDOTEST_APP_SERVICE_PORT];
  XCTAssertEqualObjects([remoteDummy class], NSClassFromString(@"EDOObject"));

  EDOTestDummyInTest *dummy = [[EDOTestDummyInTest alloc] initWithValue:8];

  // Test: [A callBackToTest:B withValue:7]
  //   App:    A-> [B callTestDummy:A]
  //     Test:      B-> [A selWithIdReturn:10]
  //        App:         -> A.value = A.value(5) + value(10) * 2 = 25
  //        App:         -> new A(A.value(5) + 10).value
  //        App:         = 15
  //     Test:      B-> (15) + B.value(8) + 3
  //     Test:           = 26
  //   App:    (26) + value(7) + A.value(25)
  // Test:  = 58
  XCTAssertEqual([remoteDummy callBackToTest:dummy withValue:7], 58);

  [service invalidate];
}

- (void)testMultiplexInvocationStressfully {
  [self launchApplicationWithPort:EDOTEST_APP_SERVICE_PORT initValue:5];

  EDOTestDummy *remoteDummy = [EDOClientService rootObjectWithPort:EDOTEST_APP_SERVICE_PORT];
  XCTAssertEqualObjects([remoteDummy class], NSClassFromString(@"EDOObject"));

  const int kStressTestAttempts = 5;
  const int kConcurrentNumber = 15;
  EDOTestDummyInTest *dummy = [[EDOTestDummyInTest alloc] initWithValue:8];

  for (int i = 0; i < kStressTestAttempts; ++i) {
    XCTestExpectation *nestedCallExpectation =
        [self expectationWithDescription:@"nested invocation completed."];
    // The inner dispatch_apply performs actual stressful execution, and the test considers deadlock
    // will happen if dispatch_apply cannot complete within the timeout.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      dispatch_apply(kConcurrentNumber, DISPATCH_APPLY_AUTO, ^(size_t iteration) {
        [remoteDummy callBackToTest:dummy withValue:7];
      });
      [nestedCallExpectation fulfill];
    });
    [self waitForExpectations:@[ nestedCallExpectation ] timeout:5.f];
  }
}

- (void)testDispatchAsyncEarlyReturn {
  [self launchApplicationWithPort:EDOTEST_APP_SERVICE_PORT initValue:5];
  EDOHostService *service =
      [EDOHostService serviceWithPort:2234
                           rootObject:[[EDOTestDummyInTest alloc] initWithValue:9]
                                queue:dispatch_get_main_queue()];

  EDOTestDummy *remoteDummy = [EDOClientService rootObjectWithPort:EDOTEST_APP_SERVICE_PORT];
  EDOTestDummyInTest *dummy = [[EDOTestDummyInTest alloc] initWithValue:7];

  dispatch_semaphore_t waitLock = dispatch_semaphore_create(0L);
  XCTestExpectation *expectsInvoke = [self expectationWithDescription:@"Invoked the block."];
  dummy.block = ^{
    dispatch_semaphore_wait(waitLock, DISPATCH_TIME_FOREVER);
    [expectsInvoke fulfill];
  };

  // Test: [A returnPlus10AndAsyncExecuteBlock:B]
  //   App:   dispatch_async: [B invokeBlock]
  //                   Test:     acquire waitLock
  //          -> 5 + 10
  // Test: = 15
  //       release waitLock
  //   App:   dispatch_async: finish
  XCTAssertEqual([remoteDummy returnPlus10AndAsyncExecuteBlock:dummy], 5 + 10);

  dispatch_semaphore_signal(waitLock);
  [self waitForExpectationsWithTimeout:1 handler:nil];

  [service invalidate];
}

- (void)testDispatchAsyncManyTimes {
  [self launchApplicationWithPort:EDOTEST_APP_SERVICE_PORT initValue:8];
  NS_VALID_UNTIL_END_OF_SCOPE dispatch_queue_t backgroundQueue =
      dispatch_queue_create("com.google.edo.uitest", DISPATCH_QUEUE_SERIAL);
  EDOTestDummyInTest *rootDummy = [[EDOTestDummyInTest alloc] initWithValue:9];
  EDOHostService *service = [EDOHostService serviceWithPort:2234
                                                 rootObject:rootDummy
                                                      queue:backgroundQueue];

  const int totalOfInvokes = 10;
  XCTestExpectation *expectsTen = [self expectationWithDescription:@"Invoked many times."];
  expectsTen.expectedFulfillmentCount = totalOfInvokes;
  rootDummy.block = ^{
    // This block is dispatched to a background queue.
    XCTAssertFalse([NSThread isMainThread]);
    [expectsTen fulfill];
  };

  EDOTestDummy *remoteDummy = [EDOClientService rootObjectWithPort:EDOTEST_APP_SERVICE_PORT];

  // Dispatch to the background queue because we need to wrap dummy into the remote object, the
  // current main queue doesn't have a host service to wrap it.
  dispatch_async(backgroundQueue, ^{
    for (int i = 0; i < totalOfInvokes; ++i) {
      XCTAssertEqual([remoteDummy returnPlus10AndAsyncExecuteBlock:rootDummy], 8 + 10);
    }
  });

  [self waitForExpectationsWithTimeout:5 handler:nil];
  [service invalidate];
}

- (void)testServiceInvalidErrorHandling {
  // Terminate the app if other tests launched it.
  [[[XCUIApplication alloc] init] terminate];

  NSString *exceptionName = @"UITest Exception";
  __block NSError *currentError;
  EDOSetClientErrorHandler(^(NSError *error) {
    currentError = error;
    [NSException raise:exceptionName format:@"%ld", (long)error.code];  // NOLINT
  });

  XCTAssertThrowsSpecificNamed([EDOClientService rootObjectWithPort:EDOTEST_APP_SERVICE_PORT],
                               NSException, exceptionName);
  XCTAssertEqualObjects(currentError.domain, EDOServiceErrorDomain);
  XCTAssertEqual(currentError.code, EDOServiceErrorCannotConnect);
}

- (void)testRemoteObjectShouldFailAfterServiceTerminated {
  NSString *exceptionName = @"UITest Exception";
  __block NSError *currentError;
  EDOSetClientErrorHandler(^(NSError *error) {
    currentError = error;
    [NSException raise:exceptionName format:@"%ld", (long)error.code];  // NOLINT
  });

  [self launchApplicationWithPort:EDOTEST_APP_SERVICE_PORT initValue:8];
  EDOTestDummy *remoteDummy = [EDOClientService rootObjectWithPort:EDOTEST_APP_SERVICE_PORT];
  XCTAssertEqual(remoteDummy.value, 8);
  [remoteDummy invalidateService];
  // The remote object should fail after the remote service is down.
  XCTAssertThrowsSpecificNamed([remoteDummy voidWithValuePlusOne], NSException, exceptionName);
  XCTAssertEqualObjects(currentError.domain, EDOServiceErrorDomain);
  XCTAssertEqual(currentError.code, EDOServiceErrorCannotConnect);
  currentError = nil;

  // The new service is created on the same port and the cached remote object from the previous
  // service should fail.
  // TODO(haowoo): Refactor this after moving to the new exception/error handler logic.
  [self launchApplicationWithPort:EDOTEST_APP_SERVICE_PORT initValue:8];
  XCTAssertThrowsSpecificNamed([remoteDummy voidWithValuePlusOne], NSException,
                               NSDestinationInvalidException);
}

- (void)testAllocAndClassMethod {
  [self launchApplicationWithPort:EDOTEST_APP_SERVICE_PORT initValue:5];

  // Create a local service so it can wrap and deref the any returned EDOObjects.
  EDOHostService *service = [EDOHostService serviceWithPort:2234
                                                 rootObject:[[EDOTestDummyInTest alloc] init]
                                                      queue:dispatch_get_main_queue()];

  // @see EDOTestClassDummyStub.m
  XCTAssertEqual([EDOTestClassDummy classMethodWithInt:7], 16);
  XCTAssertEqual([EDOTestClassDummy classMethodWithIdReturn:8].value, 8);

  EDOTestClassDummy *dummy = [EDOTestClassDummy classMethodWithIdReturn:8];
  XCTAssertEqualObjects([dummy class], NSClassFromString(@"EDOObject"));
  [service invalidate];

  // Validate the class methods don't exist locally.
  unsigned int methodCount = 0;
  Class dummyMeta = object_getClass([EDOTestClassDummy class]);
  Method *methods = class_copyMethodList(dummyMeta, &methodCount);
  for (unsigned int i = 0; i < methodCount; i++) {
    Method method = methods[i];
    char const *selectorName = sel_getName(method_getName(method));

    // Make sure those class methods are not defined locally.
    XCTAssertTrue(strcmp(selectorName, sel_getName(@selector(classMethodWithInt:))) != 0);
    XCTAssertTrue(strcmp(selectorName, sel_getName(@selector(classMethodWithIdReturn:))) != 0);
  }

  free(methods);
}

/**
 *  Verifies `isKindOfClass:` returns true only if the class object belongs to the callee process.
 */
- (void)testIsKindOfClassOnlyResolvesInSameProcess {
  [self launchApplicationWithPort:EDOTEST_APP_SERVICE_PORT initValue:5];
  // Create a local service so it can wrap and deref the any returned EDOObjects.
  EDOHostService *service = [EDOHostService serviceWithPort:2234
                                                 rootObject:[[EDOTestDummyInTest alloc] init]
                                                      queue:dispatch_get_main_queue()];
  EDOTestDummy *remoteDummy = [EDOClientService rootObjectWithPort:EDOTEST_APP_SERVICE_PORT];
  NSArray<NSNumber *> *remoteArray = [remoteDummy returnArray];

  EDOHostPort *hostPort = [EDOHostPort hostPortWithLocalPort:EDOTEST_APP_SERVICE_PORT];
  Class remoteArrayClass = [EDOClientService classObjectWithName:@"NSArray" hostPort:hostPort];
  XCTAssertTrue([remoteArray isKindOfClass:remoteArrayClass]);
  XCTAssertFalse([remoteArray isKindOfClass:[NSArray class]]);

  [service invalidate];
}

- (void)testRemoteObjectCopy {
  [self launchApplicationWithPort:EDOTEST_APP_SERVICE_PORT initValue:5];
  EDOTestDummy *dummy = [EDOClientService rootObjectWithPort:EDOTEST_APP_SERVICE_PORT];
  NSArray *remoteArray = [dummy returnArray];
  NSArray *remoteArrayCopy;
  XCTAssertNoThrow(remoteArrayCopy = [remoteArray copy]);
  XCTAssertEqual(remoteArray, remoteArrayCopy);
}

- (void)testRemoteObjectMutableCopy {
  [self launchApplicationWithPort:EDOTEST_APP_SERVICE_PORT initValue:5];
  EDOTestDummy *dummy = [EDOClientService rootObjectWithPort:EDOTEST_APP_SERVICE_PORT];
  NSArray *remoteArray = [dummy returnArray];
  NSMutableArray *remoteArrayCopy = [remoteArray mutableCopy];
  XCTAssertNotEqual(remoteArray, remoteArrayCopy);
  XCTAssertEqualObjects(remoteArray, remoteArrayCopy);
  [remoteArrayCopy addObject:@"test"];
  XCTAssertEqualObjects([remoteArrayCopy lastObject], @"test");
}

- (void)testInsertRemoteObjectToDictionary {
  [self launchApplicationWithPort:EDOTEST_APP_SERVICE_PORT initValue:5];
  EDOTestDummy *dummy = [EDOClientService rootObjectWithPort:EDOTEST_APP_SERVICE_PORT];
  NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
  XCTAssertNoThrow([dict setObject:dummy forKey:@"key"]);
}

- (void)testBrokenChannelAfterServiceClosed {
  XCUIApplication *app = [self launchApplicationWithPort:EDOTEST_APP_SERVICE_PORT initValue:5];
  EDOTestDummy *remoteDummy = [EDOClientService rootObjectWithPort:EDOTEST_APP_SERVICE_PORT];
  XCTAssertEqualObjects([remoteDummy class], NSClassFromString(@"EDOObject"));
  [app terminate];
  app = [self launchApplicationWithPort:EDOTEST_APP_SERVICE_PORT initValue:5];

  EDOTestDummy *newRemoteDummy = [EDOClientService rootObjectWithPort:EDOTEST_APP_SERVICE_PORT];
  XCTAssertNotEqualObjects(remoteDummy, newRemoteDummy);
  __block Class clazz;
  XCTestExpectation *expectsReturn = [self expectationWithDescription:@"Returned in time."];
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
    clazz = [newRemoteDummy class];
    [expectsReturn fulfill];
  });
  [self waitForExpectationsWithTimeout:15 handler:nil];
  XCTAssertEqualObjects(clazz, NSClassFromString(@"EDOObject"));
  XCTAssertThrowsSpecificNamed([remoteDummy returnInt], NSException, NSDestinationInvalidException);
}

/**
 *  Tests requesting service ports info of the application process, and verifies the port info with
 *  service name.
 */
- (void)testFetchServicePortsInfo {
  [self launchApplicationWithServiceName:kTestServiceName initValue:5];
  EDOHostNamingService *service;
  XCTAssertNoThrow(service =
                       [EDOClientService rootObjectWithPort:EDOHostNamingService.namingServerPort]);
  XCTAssertFalse([service portForServiceWithName:kTestServiceName] == 0);
}

/** Tests running multiple naming services in the same host, and verifies that exception happens. */
- (void)testStartMultipleNamingServiceObject {
  [self launchApplicationWithServiceName:kTestServiceName initValue:5];
  EDOHostNamingService *localService = EDOHostNamingService.sharedService;
  XCTAssertFalse([localService start]);
}

/** Tests passing local object to remote dummy using pass by value. */
- (void)testPassByValueWithLocalObject {
  [self launchApplicationWithPort:EDOTEST_APP_SERVICE_PORT initValue:5];
  EDOTestDummy *dummy = [EDOClientService rootObjectWithPort:EDOTEST_APP_SERVICE_PORT];
  NSArray<NSString *> *localArray = @[ @"foo" ];
  dummy.valueObject = [localArray passByValue];
  NSArray<NSString *> *remoteArray = (NSArray *)dummy.valueObject;
  XCTAssertEqualObjects(localArray[0], remoteArray[0]);

  NSString *remoteClassName = [dummy returnClassNameWithObject:remoteArray];
  // Ensure that in the remote side, the object is passed by value instead of EDOObject.
  XCTAssertNotEqualObjects(remoteClassName, @"EDOObject");

  NSString *localClassName = NSStringFromClass(object_getClass(remoteArray));
  // Ensure that in the local side, the object is fetched by reference as normal.
  XCTAssertEqualObjects(localClassName, @"EDOObject");
}

/** Tests local object is released on the execution queue if it is released by EDOHostService. */
- (void)testLocalObjectReleaseOnHostExecutionQueue {
  [self launchApplicationWithPort:EDOTEST_APP_SERVICE_PORT initValue:5];
  EDOHostService *service =
      [EDOHostService serviceWithPort:2234
                           rootObject:[[EDOTestDummyInTest alloc] initWithValue:9]
                                queue:dispatch_get_main_queue()];
  __block EDOTestDummyInTest *dummy = [[EDOTestDummyInTest alloc] init];
  __weak EDOTestDummyInTest *weakDummy = dummy;
  EDOTestDummy *remoteDummy = [EDOClientService rootObjectWithPort:EDOTEST_APP_SERVICE_PORT];

  XCTestExpectation *expectation = [self expectationWithDescription:@"dummy is released on main."];
  dummy.deallocHandlerBlock = ^{
    XCTAssertTrue([NSThread isMainThread]);
    [expectation fulfill];
  };
  dummy.block = ^{
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      dummy = nil;
    });
  };

  [remoteDummy returnPlus10AndAsyncExecuteBlock:dummy];
  [self waitForExpectations:@[ expectation ] timeout:2.0f];
  XCTAssertNil(weakDummy);

  [service invalidate];
}

- (void)testRemoteExceptionRevealsInformation {
  [self launchApplicationWithPort:EDOTEST_APP_SERVICE_PORT initValue:5];
  EDOHostService *service =
      [EDOHostService serviceWithPort:2234
                           rootObject:[[EDOTestDummyInTest alloc] initWithValue:9]
                                queue:dispatch_get_main_queue()];
  EDOTestDummy *dummy = [EDOClientService rootObjectWithPort:EDOTEST_APP_SERVICE_PORT];

  EDORemoteException *remoteException;
  @try {
    [dummy selWithThrow];
  } @catch (EDORemoteException *exception) {
    remoteException = exception;
  }
  XCTAssertNotNil(remoteException);
  XCTAssertEqualObjects(remoteException.name, @"Dummy Just Throw 5");
  XCTAssertEqualObjects(remoteException.reason, @"Just Throw");
  NSString *callStackSymbols = [remoteException.callStackSymbols componentsJoinedByString:@"|"];
  XCTAssertTrue([callStackSymbols containsString:@"testRemoteExceptionRevealsInformation"]);
  XCTAssertTrue([callStackSymbols containsString:@"[EDOTestDummy selWithThrow]"]);
  XCTAssertTrue([callStackSymbols containsString:@"TestsHost"]);

  [service invalidate];
}

@end
