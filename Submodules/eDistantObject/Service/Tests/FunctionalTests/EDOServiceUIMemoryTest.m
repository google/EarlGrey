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

#import "Service/Tests/FunctionalTests/EDOServiceUIBaseTest.h"

#import "Service/Sources/EDOClientService.h"
#import "Service/Sources/EDOHostService.h"
#import "Service/Sources/EDORemoteException.h"
#import "Service/Sources/EDOServiceException.h"
#import "Service/Sources/NSObject+EDOValueObject.h"
#import "Service/Sources/NSObject+EDOWeakObject.h"
#import "Service/Tests/FunctionalTests/EDOTestDummyInTest.h"
#import "Service/Tests/TestsBundle/EDOTestClassDummy.h"
#import "Service/Tests/TestsBundle/EDOTestDummy.h"

// Memory tests to assure the local and remote objects don't leak.
@interface EDOUIMemoryTest : EDOServiceUIBaseTest
// The launched application for the running test.
@property(nonatomic) XCUIApplication *application;
@end

@implementation EDOUIMemoryTest

- (void)setUp {
  [super setUp];

  self.application = [self launchApplicationWithPort:EDOTEST_APP_SERVICE_PORT initValue:6];
}

- (void)testStubClassAllocReturnsEDOObject {
  // Stub class forwarding alloc will alloc an instance of EDOObject.
  XCTAssertEqualObjects([[EDOTestClassDummy alloc] class], NSClassFromString(@"EDOObject"));
  XCTAssertEqualObjects([[EDOTestClassDummy allocWithZone:nil] class],
                        NSClassFromString(@"EDOObject"));
}

- (void)testStubClassAllocEqualsInit {
  EDOTestClassDummy *testDummy;
  @autoreleasepool {
    // The autoreleasepool to assure the inserted releases within the scope and all the temporary
    // objects if any will be reclaimed.
    // +alloc should return the same instance as from -init.
    testDummy = [EDOTestClassDummy alloc];
    XCTAssertEqual(testDummy, [testDummy initWithValue:10]);
  }
  // Ensure the appropriate value is retrieved from the object.
  XCTAssertEqual(testDummy.value, 10);
}

- (void)testAllocFamilyRetainsReturn {
  EDOTestClassDummy *testDummy1, *testDummy2, *testDummy3;
  @autoreleasepool {
    // allocDummy will trigger ARC to insert an extra release.
    // The autoreleasepool to assure the inserted releases within the scope and all the temporary
    // objects if any will be reclaimed.
    testDummy1 = [[EDOTestClassDummy allocDummy] initWithValue:10];
    testDummy2 = [[EDOTestClassDummy _allocDummy] initWithValue:20];
    testDummy3 = [[EDOTestClassDummy allocateDummy] initWithValue:30];
  }
  // Ensure the appropriate value is retrieved from the object.
  XCTAssertEqual(testDummy1.value, 10);
  XCTAssertEqual(testDummy2.value, 20);
  XCTAssertEqual(testDummy3.value, 30);
}

- (void)testAllocRemoteValueType {
  XCTAssertThrowsSpecificNamed([[EDO_REMOTE_CLASS(NSData, EDOTEST_APP_SERVICE_PORT) alloc] init],
                               EDORemoteException, EDOServiceAllocValueTypeException);
  XCTAssertThrowsSpecificNamed(
      [[EDO_REMOTE_CLASS(EDOTestDummy, EDOTEST_APP_SERVICE_PORT) returnByValue] alloc],
      EDORemoteException, EDOServiceAllocValueTypeException);
  XCTAssertNoThrow([EDO_REMOTE_CLASS(NSData, EDOTEST_APP_SERVICE_PORT) data]);
}

// Test that the remote objects are resolved to be local objects if they are coming back to their
// origin.
- (void)testEDOResolveToLocalAddress {
  // Use NSClassFromString to fetch EDOObject to make it private here.
  Class edoClass = NSClassFromString(@"EDOObject");

  XCTAssertNil(NSClassFromString(@"EDOTestDummy"));
  EDOTestDummyInTest *rootObject = [[EDOTestDummyInTest alloc] initWithValue:5];
  EDOHostService *service = [EDOHostService serviceWithPort:2234
                                                 rootObject:rootObject
                                                      queue:dispatch_get_main_queue()];

  EDOTestDummyInTest *dummyInTest = [[EDOTestDummyInTest alloc] initWithValue:5];
  EDOTestDummyInTest *dummyAssigned = [[EDOTestDummyInTest alloc] initWithValue:6];

  EDOTestDummy *remoteDummy = [EDOClientService rootObjectWithPort:EDOTEST_APP_SERVICE_PORT];
  XCTAssertEqualObjects([remoteDummy class], edoClass);

  EDOTestDummy *returnDummy = [remoteDummy returnIdWithInt:5];
  XCTAssertEqualObjects([returnDummy class], edoClass);
  // returnDummy.value = 5 + initValue(6);
  XCTAssertEqual(returnDummy.value, 11);

  Class testDummyClass = EDO_REMOTE_CLASS(EDOTestDummy, EDOTEST_APP_SERVICE_PORT);
  XCTAssertEqualObjects([testDummyClass class], edoClass);
  XCTAssertEqualObjects([remoteDummy class], edoClass);

  [remoteDummy setDummInTest:dummyInTest withDummy:dummyAssigned];

  XCTAssertEqual(dummyInTest.dummyInTest, dummyAssigned);
  XCTAssertEqual([remoteDummy getRootObject:2234], rootObject);

  EDOTestDummyInTest *returnedDummy = [remoteDummy createEDOWithPort:2234];
  XCTAssertEqualObjects([returnedDummy class], [EDOTestDummyInTest class]);
  // returnedDummy.value = -> createEDOWithPort:
  //     makeAnotherDummy:
  //        -> 7 + rooObject.value(5)
  //     -> 12 + 5
  XCTAssertEqual(returnedDummy.value.intValue, 17);

  [service invalidate];
}

// Test that the underlying object gets released if there is no remote reference.
- (void)testUnderlyingObjectReleasedIfNotHeldRemotely {
  [self launchApplicationWithPort:EDOTEST_APP_SERVICE_PORT initValue:6];
  EDOTestDummy *remoteDummy = self.remoteRootObject;
  @autoreleasepool {
    // Allocate a weak variable inside the autoreleasepool.
    EDOTestDummy *dummyInTest = [remoteDummy weaklyHeldDummyForMemoryTest];
    // Assert that the remoteDummy holds a reference to the weak variable.
    XCTAssertNotNil(remoteDummy.weakDummyInTest);
    XCTAssertNotNil(dummyInTest);
  }
  // The strong variable that held a strong reference is gone. Since the remoteDummy holds a weak
  // reference to itself, then it should be nil.
  XCTAssertNil(remoteDummy.weakDummyInTest);
}

// Test that the same underlying objects should live if there is at least one remote reference.
- (void)testUnderlyingObjectStayAliveIfHeldRemotely {
  EDOTestDummy *remoteDummy = self.remoteRootObject;
  NS_VALID_UNTIL_END_OF_SCOPE EDOTestDummy *strongReference;
  @autoreleasepool {
    // Hold the remote object strongly.
    strongReference = [remoteDummy weaklyHeldDummyForMemoryTest];
    XCTAssertNotNil(strongReference);
  }
  // Remote strong reference should keep the underlying object still alive.
  XCTAssertNotNil(remoteDummy.weakDummyInTest);
}

// Test that the multiple holdings of the same underlying objects can get released remotely.
- (void)testUnderlyingObjectReleasedIfHeldWeakly {
  EDOTestDummy *remoteDummy = self.remoteRootObject;
  __weak EDOTestDummy *weakReference;
  @autoreleasepool {
    // Get a weak variable.
    NS_VALID_UNTIL_END_OF_SCOPE EDOTestDummy *dummy = [remoteDummy weaklyHeldDummyForMemoryTest];
    weakReference = dummy;
    XCTAssertNotNil(weakReference);
  }
  // Both variables are weak. When one of them is released both of them get released.
  XCTAssertNil(weakReference);
  XCTAssertNil(remoteDummy.weakDummyInTest);
}

// Test that the root object is strongly held even if the remote references are gone.
- (void)testUnderlyingObjectStayAliveRegardlessOfRemoteReference {
  __weak EDOTestDummy *remoteWeakDummy;
  @autoreleasepool {
    // Initialize a weak reference to the rootObject.
    NS_VALID_UNTIL_END_OF_SCOPE EDOTestDummy *dummy = self.remoteRootObject;
    remoteWeakDummy = dummy;
    XCTAssertNotNil(remoteWeakDummy);
  }
  // The remote weak reference is gone but the underlying object should stay alive.
  XCTAssertNil(remoteWeakDummy);
  XCTAssertNotNil([EDOClientService rootObjectWithPort:EDOTEST_APP_SERVICE_PORT]);
}

// Test that the app wouldn't crash if the remote session is terminated.
- (void)testSafeRecoverIfServiceTerminated {
  EDOTestDummy *remoteDummy = self.remoteRootObject;
  __weak EDOTestDummy *weakReference;
  @autoreleasepool {
    NS_VALID_UNTIL_END_OF_SCOPE EDOTestDummy *dummy = [remoteDummy weaklyHeldDummyForMemoryTest];
    weakReference = dummy;
    [self.application terminate];
  }
  // The test shouldn't crash if the app is gone.
  XCTAssertNil(weakReference);
}

/** Tests the remoteWeak function retains the weakly referenced object during its use. */
- (void)testWeakObjectReferenceRetain {
  [self launchApplicationWithPort:EDOTEST_APP_SERVICE_PORT initValue:13];
  EDOHostService *service =
      [EDOHostService serviceWithPort:2234
                           rootObject:[[EDOTestDummyInTest alloc] initWithValue:9]
                                queue:dispatch_get_main_queue()];
  EDOTestDummy *remoteDummy = [EDOClientService rootObjectWithPort:EDOTEST_APP_SERVICE_PORT];
  id local = [[NSObject alloc] init];

  // Originally, without remoteWeak, weakDelegate would return nil.
  remoteDummy.weakDelegate = local;
  XCTAssertNil(remoteDummy.weakDelegate);

  // RemoteWeak will retain the local.
  remoteDummy.weakDelegate = [local remoteWeak];
  XCTAssertNotNil(remoteDummy.weakDelegate);
  [service invalidate];
}

/** Tests the remoteWeak function retains the weakly referenced object during its use and releases
 * once the underlying object is released. */
- (void)testWeakObjectReferenceRetainAndRelease {
  [self launchApplicationWithPort:EDOTEST_APP_SERVICE_PORT initValue:13];
  EDOHostService *service =
      [EDOHostService serviceWithPort:2234
                           rootObject:[[EDOTestDummyInTest alloc] initWithValue:9]
                                queue:dispatch_get_main_queue()];
  EDOTestDummy *remoteDummy;
  @autoreleasepool {
    id local = [[NSObject alloc] init];
    remoteDummy = [EDOClientService rootObjectWithPort:EDOTEST_APP_SERVICE_PORT];
    // Original usage:
    // remoteDummy.weakDelegate = local;
    remoteDummy.weakDelegate = [local remoteWeak];
    XCTAssertNotNil(remoteDummy.weakDelegate);
  }
  XCTAssertNil(remoteDummy.weakDelegate);
  [service invalidate];
}

/** Tests the remoteWeak returns the same value when using on a local object.  */
- (void)testRemoteWeakToLocalObject {
  EDOTestDummyInTest *dummy = [[EDOTestDummyInTest alloc] init];
  XCTAssertEqual([[dummy remoteWeak] value], [dummy value]);
}

/** Tests assigning remoteWeak to EDOObject throws the right exception. */
- (void)testRemoteWeakToEDOObjectWithLocalReference {
  [self launchApplicationWithPort:EDOTEST_APP_SERVICE_PORT initValue:13];
  EDOHostService *service =
      [EDOHostService serviceWithPort:2234
                           rootObject:[[EDOTestDummyInTest alloc] initWithValue:9]
                                queue:dispatch_get_main_queue()];
  EDOTestDummy *remoteDummy = [EDOClientService rootObjectWithPort:EDOTEST_APP_SERVICE_PORT];
  XCTAssertThrowsSpecificNamed([remoteDummy remoteWeak], NSException,
                               EDOWeakObjectRemoteWeakMisuseException);
  [service invalidate];
}

/** Tests assigning the same underlying object to multiple localReferences doesn't crash the
 * process. */
- (void)testRemoteWeakToMultipleEDOObjectWithLocalReferences {
  [self launchApplicationWithPort:EDOTEST_APP_SERVICE_PORT initValue:13];
  EDOHostService *service =
      [EDOHostService serviceWithPort:2234
                           rootObject:[[EDOTestDummyInTest alloc] initWithValue:9]
                                queue:dispatch_get_main_queue()];
  EDOTestDummy *remoteDummy;
  EDOTestDummy *remoteDummy2;
  @autoreleasepool {
    id local = [[NSObject alloc] init];
    remoteDummy = [EDOClientService rootObjectWithPort:EDOTEST_APP_SERVICE_PORT];
    remoteDummy2 = [remoteDummy returnDeepCopy];
    remoteDummy.weakDelegate = [local remoteWeak];
    XCTAssertNotNil(remoteDummy.weakDelegate);
    remoteDummy2.weakDelegate = [local remoteWeak];
    XCTAssertNotNil(remoteDummy2.weakDelegate);
  }
  XCTAssertNil(remoteDummy.weakDelegate);
  XCTAssertNil(remoteDummy2.weakDelegate);
  [service invalidate];
}

/** Tests assigning the same underlying object to multiple localReferences doesn't crash the
 * process. */
- (void)testRemoteWeakToEDOObjectWithMultipleLocalReferences {
  [self launchApplicationWithPort:EDOTEST_APP_SERVICE_PORT initValue:13];
  EDOHostService *service =
      [EDOHostService serviceWithPort:2234
                           rootObject:[[EDOTestDummyInTest alloc] initWithValue:9]
                                queue:dispatch_get_main_queue()];
  EDOTestDummy *remoteDummy;
  @autoreleasepool {
    id local1 = [[NSObject alloc] init];
    id local2 = [[NSObject alloc] init];
    remoteDummy = [EDOClientService rootObjectWithPort:EDOTEST_APP_SERVICE_PORT];
    remoteDummy.weakDelegate = [local1 remoteWeak];
    remoteDummy.weakDelegate = [local2 remoteWeak];
    XCTAssertNotNil(remoteDummy.weakDelegate);
  }
  XCTAssertNil(remoteDummy.weakDelegate);
  [service invalidate];
}

@end
