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
#import "Service/Sources/EDOClientService.h"
#import "Service/Sources/EDOHostService+Private.h"
#import "Service/Sources/EDOServicePort.h"
#import "Service/Sources/NSObject+EDOValueObject.h"
#import "Service/Tests/TestsBundle/EDOTestDummy.h"

/**
 *  Expose the benchmark API.
 *  It executes the given @c block @count times and then returns the average number of nanoseconds
 *  per execution.
 *  @see https://www.unix.com/man-page/All/3/dispatch_benchmark
 *
 *  @param count Number of times to run.
 *  @param block The block to measure.
 *
 *  @return Nanoseconds per execution.
 */
extern uint64_t dispatch_benchmark(size_t count, void (^block)(void));

// Currently a single remote call should be less or equal than 15ms.
static const uint64_t kRemoteInvocationThresholdInNano = 15e6;

// The number of times to execute the measured blocks.
static const size_t kNumOfBenchmarkExecutions = 100;

@interface EDOUITestAppPerfTests : XCTestCase
@property(readonly) EDOTestDummy *remoteDummy;
@property(readonly) Class remoteClass;

@property(readonly) id serviceBackgroundMock;
@property(readonly) id serviceMainMock;
@property(readonly) EDOHostService *serviceOnBackground;
@property(readonly) EDOHostService *serviceOnMain;
@property(readonly) EDOTestDummy *rootObject;
@property(readonly) dispatch_queue_t executionQueue;
@property(readonly) EDOTestDummy *rootObjectOnBackground;
@end

@implementation EDOUITestAppPerfTests

- (void)setUp {
  [super setUp];

  NSString *queueName = [NSString stringWithFormat:@"com.google.edotest.%@", self.name];
  _executionQueue = dispatch_queue_create(queueName.UTF8String, DISPATCH_QUEUE_SERIAL);
  _rootObject = [[EDOTestDummy alloc] init];

  _serviceOnBackground = [EDOHostService serviceWithPort:0
                                              rootObject:self.rootObject
                                                   queue:self.executionQueue];

  _serviceOnMain = [EDOHostService serviceWithPort:0
                                        rootObject:[[EDOTestDummy alloc] init]
                                             queue:dispatch_get_main_queue()];

  _serviceBackgroundMock = OCMPartialMock(_serviceOnBackground);
  _serviceMainMock = OCMPartialMock(_serviceOnMain);
  OCMStub([_serviceBackgroundMock isObjectAlive:OCMOCK_ANY]).andReturn(NO);
  OCMStub([_serviceMainMock isObjectAlive:OCMOCK_ANY]).andReturn(NO);
}

- (void)tearDown {
  [self.serviceMainMock stopMocking];
  [self.serviceBackgroundMock stopMocking];
  _serviceMainMock = nil;
  _serviceBackgroundMock = nil;

  [self.serviceOnMain invalidate];
  [self.serviceOnBackground invalidate];
  _executionQueue = nil;
  _serviceOnMain = nil;
  _serviceOnBackground = nil;
  _rootObject = nil;

  [super tearDown];
}

- (EDOTestDummy *)remoteDummy {
  return [EDOClientService rootObjectWithPort:self.serviceOnBackground.port.hostPort.port];
}

- (Class)remoteClass {
  return EDO_REMOTE_CLASS(EDOTestDummy, self.serviceOnBackground.port.hostPort.port);
}

- (void)testSimpleMethodLotsTimes {
  [self assertPerformBlockWithWeight:1
                               block:^(EDOTestDummy *remoteDummy) {
                                 [remoteDummy voidWithValuePlusOne];
                               }];
}

- (void)testMethodWithVariablesLotsTimes {
  [self assertPerformBlockWithWeight:1
                               block:^(EDOTestDummy *remoteDummy) {
                                 [remoteDummy voidWithStruct:(EDOTestDummyStruct){}];
                               }];
}

- (void)testMethodWithOutVarLotsTimes {
  [self assertPerformBlockWithWeight:1
                               block:^(EDOTestDummy *remoteDummy) {
                                 NSError *error;
                                 [remoteDummy voidWithErrorOut:&error];
                               }];
}

- (void)testMethodWithReturnLotsTimes {
  [self assertPerformBlockWithWeight:1
                               block:^(EDOTestDummy *remoteDummy) {
                                 [remoteDummy returnInt];
                               }];

  [self assertPerformBlockWithWeight:1
                               block:^(EDOTestDummy *remoteDummy) {
                                 [remoteDummy returnData];
                               }];

  [self assertPerformBlockWithWeight:1
                               block:^(EDOTestDummy *remoteDummy) {
                                 [remoteDummy returnSelf];
                               }];
}

- (void)testComplicatedMethodLotsTimes {
  [self assertPerformBlockWithWeight:1
                               block:^(EDOTestDummy *remoteDummy) {
                                 [remoteDummy returnIdWithInt:10];
                               }];

  [self assertPerformBlockWithWeight:1
                               block:^(EDOTestDummy *remoteDummy) {
                                 NSError *error;
                                 [remoteDummy returnBoolWithError:&error];
                               }];

  [self assertPerformBlockWithWeight:1
                               block:^(EDOTestDummy *remoteDummy) {
                                 [remoteDummy structWithStruct:(EDOTestDummyStruct){}];
                               }];

  [self assertPerformBlockWithWeight:2
                               block:^(EDOTestDummy *remoteDummy) {
                                 EDOTestDummy *localDummy = [[EDOTestDummy alloc] init];
                                 [remoteDummy voidWithOutObject:&localDummy];
                               }];  // two remote calls
}

- (void)testClassMethodLotsTimes {
  Class remoteClass = self.remoteClass;
  [self assertPerformBlockWithWeight:1
                               block:^(EDOTestDummy *remoteDummy) {
                                 [remoteClass classMethodWithNumber:@10];
                               }];
}

- (void)testIteratingReturnByValueResultLotsTimes {
  uint64_t byValueResult = [self
      assertPerformBlockWithWeight:1
                        executions:10
                             block:^(EDOTestDummy *remoteDummy) {
                               NSArray *result = [[remoteDummy returnByValue] returnLargeArray];
                               for (NSInteger i = 0; i < 1000; i++) {
                                 XCTAssert(((NSNumber *)result[i]).integerValue == i);
                               }
                             }];
  uint64_t byReferenceResult =
      [self assertPerformBlockWithWeight:1000
                              executions:10
                                   block:^(EDOTestDummy *remoteDummy) {
                                     NSArray *result = [remoteDummy returnLargeArray];
                                     for (NSInteger i = 0; i < 1000; i++) {
                                       XCTAssert(((NSNumber *)result[i]).integerValue == i);
                                     }
                                   }];
  XCTAssertLessThan(byValueResult * 100, byReferenceResult);
}

- (void)testIteratingPassByValueParameterLotsTimes {
  NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:1000];
  for (int i = 0; i < 1000; i++) {
    [array addObject:@(i)];
  }
  uint64_t byValueResult =
      [self assertPerformBlockWithWeight:1
                              executions:10
                                   block:^(EDOTestDummy *remoteDummy) {
                                     [remoteDummy returnSumWithArray:[[array copy] passByValue]];
                                   }];
  uint64_t byReferenceResult = [self
      assertPerformBlockWithWeight:1000
                        executions:10
                             block:^(EDOTestDummy *remoteDummy) {
                               [remoteDummy returnSumWithArray:[NSArray arrayWithArray:array]];
                             }];
  XCTAssertLessThan(byValueResult * 100, byReferenceResult);
}

/**
 *  Assert the block is performed within the @weight multiple of threshold.
 */
- (uint64_t)assertPerformBlockWithWeight:(uint64_t)weight block:(void (^)(EDOTestDummy *))block {
  return [self assertPerformBlockWithWeight:weight
                                 executions:kNumOfBenchmarkExecutions
                                      block:block];
}

/**
 *  Assert the block is performed @excutions times within the @weight multiple of threshold.
 */
- (uint64_t)assertPerformBlockWithWeight:(uint64_t)weight
                              executions:(NSInteger)executions
                                   block:(void (^)(EDOTestDummy *))block {
  EDOTestDummy *remoteDummy = self.remoteDummy;
  uint64_t result = dispatch_benchmark(executions, ^{
    block(remoteDummy);
  });
  XCTAssertLessThanOrEqual(result, kRemoteInvocationThresholdInNano * weight);
  return result;
}

@end
