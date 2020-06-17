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

#import "Service/Tests/FunctionalTests/EDOServiceUIBaseTest.h"

#import "Service/Sources/EDOClientService.h"
#import "Service/Sources/EDOHostService.h"
#import "Service/Sources/NSObject+EDOValueObject.h"
#import "Service/Tests/TestsBundle/EDOTestDummy.h"

// Block tests to assure the block can be invoked remotely from another process.
@interface EDOUIBlockTest : EDOServiceUIBaseTest
@property(nonatomic) int numRemoteInvokes;
@property(nonatomic) EDOHostService *service;
@end

@implementation EDOUIBlockTest

- (void)setUp {
  [super setUp];
  [self launchApplicationWithPort:EDOTEST_APP_SERVICE_PORT initValue:10];
  self.service = [EDOHostService serviceWithPort:2234
                                      rootObject:self
                                           queue:dispatch_get_main_queue()];
}

- (void)tearDown {
  [self.service invalidate];
  [super tearDown];
}

// Test that the simple block can be invoked remotely from another process.
- (void)testSimpleBlock {
  EDOTestDummy *remoteDummy = [EDOClientService rootObjectWithPort:EDOTEST_APP_SERVICE_PORT];
  __block BOOL blockAssignment = NO;
  [remoteDummy voidWithBlock:^{
    blockAssignment = YES;
  }];
  XCTAssertTrue(blockAssignment);
}

// Test that the simple block can be invoked remotely from another process.
- (void)testSimpleBlockWithReturn {
  EDOTestDummy *remoteDummy = [EDOClientService rootObjectWithPort:EDOTEST_APP_SERVICE_PORT];
  XCTAssertEqual([remoteDummy returnWithBlockDouble:^double {
                   return 100.0;
                 }],
                 100.0);
}

// Test that the different types of block can be invoked locally and remotely.
- (void)testInvokeDifferentTypesOfBlock {
  EDOTestDummy *remoteDummy = [EDOClientService rootObjectWithPort:EDOTEST_APP_SERVICE_PORT];

  self.numRemoteInvokes = 0;
  // Assign a block that will outlive the method scope and can be safely invoked.
  [self assignStackBlockToDummy:remoteDummy];
  // This invocation happens remotely.
  XCTAssertNoThrow([remoteDummy invokeBlock]);
  // This invocation happens locally as a property.
  XCTAssertNoThrow(remoteDummy.block());
  // This invocation happens locally as a return.
  XCTAssertNoThrow([remoteDummy returnBlock]());
  // Assign a block that stays inside the same method scope.
  XCTAssertNoThrow([remoteDummy voidWithBlockAssigned:^{
    ++self.numRemoteInvokes;
  }]);
  // Invoke the remote block remotely.
  XCTAssertNoThrow([remoteDummy invokeBlock]);
  XCTAssertEqual(self.numRemoteInvokes, 3);
}

// Test that the block can have structs as returns.
- (void)testBlockWithStructReturn {
  EDOTestDummy *remoteDummy = [EDOClientService rootObjectWithPort:EDOTEST_APP_SERVICE_PORT];
  EDOTestDummyStruct dummyStruct = [remoteDummy returnStructWithBlockStret:^EDOTestDummyStruct {
    return (EDOTestDummyStruct){.value = 100, .a = 30.0, .x = 50, .z = 200};
  }];
  XCTAssertEqual(dummyStruct.value, 100);
  XCTAssertEqual(dummyStruct.a, 30);
  XCTAssertEqual(dummyStruct.x, 50);
  XCTAssertEqual(dummyStruct.z, 200);
}

// Test that the block can have structs as returns.
- (void)testBlockWithStructArguments {
  EDOTestDummy *remoteDummy = [EDOClientService rootObjectWithPort:EDOTEST_APP_SERVICE_PORT];
  EDOTestDummy *dummyReturn = [remoteDummy
      returnWithInt:5
        dummyStruct:(EDOTestDummyStruct){.value = 150, .a = 30.0, .x = 50, .z = 200}
       blockComplex:^EDOTestDummy *(EDOTestDummyStruct dummy, int i, EDOTestDummy *test) {
         XCTAssertEqual(dummy.a, 30);
         XCTAssertEqual(dummy.x, 50);
         XCTAssertEqual(dummy.z, 200);
         XCTAssertEqual(i, 5);
         XCTAssertEqual(dummy.value, 150);
         // Random calculation inside the block to be validated outside.
         test.value = i + dummy.value + 4;
         return test;
       }];
  XCTAssertEqual(dummyReturn.value, 159);
}

// Test that the blocks that are bounced back and forth between processes should stay the same.
- (void)testBlockIsEqual {
  EDOTestDummy *remoteDummy = [EDOClientService rootObjectWithPort:EDOTEST_APP_SERVICE_PORT];

  void (^localBlock)(void) = ^{
    // This block captures self to ensure that the block is moved to the heap when copied.
    [self class];
  };
  void (^returnedBlock)(void) = [remoteDummy returnWithBlockObject:^id(EDOTestDummy *_) {
    return localBlock;
  }];
  // Make sure those are the actual same block objects that can be invoked.
  XCTAssertEqual(localBlock, returnedBlock);
  XCTAssertEqual([remoteDummy returnBlock], [remoteDummy returnBlock]);

  XCTAssertNoThrow(returnedBlock());
  XCTAssertNoThrow([remoteDummy returnBlock]());
}

/**
 *  Test that makes sure local block is resolved to its address, when it is decoded from the service
 *  which is different from the service it is encoded.
 */
- (void)testBlockResolveToLocalAddress {
  EDOTestDummy *remoteDummy = [EDOClientService rootObjectWithPort:EDOTEST_APP_SERVICE_PORT];
  dispatch_queue_t backgroundQueue =
      dispatch_queue_create("com.google.edo.testbackground", DISPATCH_QUEUE_SERIAL);
  EDOHostService *backgroundService = [EDOHostService serviceWithPort:2235
                                                           rootObject:self
                                                                queue:backgroundQueue];

  void (^localBlock)(void) = ^{
    // This block captures self to ensure that the block is moved to the heap when copied.
    [self class];
  };

  // Sending block to remote process through background eDO host.
  dispatch_sync(backgroundQueue, ^{
    remoteDummy.block = localBlock;
  });

  // Resolve the block from main thread eDO host.
  id returnedBlock = remoteDummy.block;
  XCTAssertEqual((id)localBlock, returnedBlock);

  [backgroundService invalidate];
}

// Test that the block can also have out parameters and passByValue.
- (void)testBlockByValueAndOutArgument {
  EDOTestDummy *remoteDummy = [EDOClientService rootObjectWithPort:EDOTEST_APP_SERVICE_PORT];

  NSArray *arrayReturn = [remoteDummy returnWithBlockObject:^id(EDOTestDummy *dummy) {
    // Use NSClassFromString to fetch EDOObject to make it private here.
    XCTAssertEqual([dummy class], NSClassFromString(@"EDOObject"));
    XCTAssertEqual(dummy.value, 10);
    dummy.value += 10;
    return [@[ @(dummy.value), @20 ] passByValue];
  }];
  // The returned array from the block, if not passByValue, should be resolved to the local array
  // here.
  XCTAssertEqual([arrayReturn class], NSClassFromString(@"EDOObject"));
  XCTAssertEqualObjects(arrayReturn[0], @20);
  XCTAssertEqualObjects(arrayReturn[1], @20);

  EDOTestDummy *outDummy = [remoteDummy returnWithBlockOutObject:^(EDOTestDummy **dummy) {
    *dummy = [EDO_REMOTE_CLASS(EDOTestDummy, EDOTEST_APP_SERVICE_PORT) classMethodWithNumber:@10];
  }];
  XCTAssertEqual(outDummy.value, 10);
}

- (void)assignStackBlockToDummy:(EDOTestDummy *)dummy {
  void (^block)(void) = ^{
    ++self.numRemoteInvokes;
  };
  // Make sure the block will still live outside this function's scope.
  dummy.block = block;
}

@end
