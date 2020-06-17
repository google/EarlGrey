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

#import <XCTest/XCTest.h>

#import "Channel/Sources/EDOChannelPool.h"
#import "Channel/Sources/EDOHostPort.h"
#import "Service/Sources/EDOClientService+Private.h"
#import "Service/Sources/EDOHostNamingService+Private.h"
#import "Service/Sources/EDOHostService.h"
#import "Service/Sources/EDOServicePort.h"

static NSString *const kDummyServiceName = @"com.google.testService";
static const UInt16 kDummyServicePort = 1234;

@interface EDOHostNamingServiceTest : XCTestCase
@end

@implementation EDOHostNamingServiceTest {
  EDOServicePort *_dummyServicePort;
}

- (void)setUp {
  [super setUp];
  EDOHostNamingService *namingService = EDOHostNamingService.sharedService;
  _dummyServicePort = [EDOServicePort servicePortWithPort:kDummyServicePort
                                              serviceName:kDummyServiceName];
  [namingService addServicePort:_dummyServicePort];
}

- (void)tearDown {
  EDOHostNamingService *serviceObject = EDOHostNamingService.sharedService;
  [serviceObject removeServicePort:_dummyServicePort];
  [super tearDown];
}

/** Tests getting correct service name by sending ports message to @c EDOHostNamingService. */
- (void)testStartEDONamingServiceObject {
  [EDOHostNamingService.sharedService start];
  EDOHostNamingService *namingService =
      [EDOClientService rootObjectWithPort:EDOHostNamingService.namingServerPort];
  XCTAssertEqual([namingService portForServiceWithName:kDummyServiceName], kDummyServicePort);
}

/**
 *  Tests sending object request to the naming service after stopping it, and verifies that
 *  exception happens.
 */
- (void)testStopEDONamingServiceObject {
  EDOHostNamingService *namingService = EDOHostNamingService.sharedService;
  [namingService start];
  [namingService stop];
  // Clean up connected channels.
  [EDOChannelPool.sharedChannelPool
      removeChannelsWithPort:[EDOHostPort
                                 hostPortWithLocalPort:EDOHostNamingService.namingServerPort]];
  XCTAssertThrows([EDOClientService rootObjectWithPort:EDOHostNamingService.namingServerPort]);
}

/** Tests starting/stoping the naming service multiple times to verify idempotency. */
- (void)testStartAndStopMultipleTimes {
  EDOHostNamingService *namingService = EDOHostNamingService.sharedService;
  [namingService start];
  [namingService start];
  XCTAssertNoThrow([EDOClientService rootObjectWithPort:EDOHostNamingService.namingServerPort]);
  [namingService stop];
  [namingService stop];
  // Clean up connected channels.
  [EDOChannelPool.sharedChannelPool
      removeChannelsWithPort:[EDOHostPort
                                 hostPortWithLocalPort:EDOHostNamingService.namingServerPort]];
  XCTAssertThrows([EDOClientService rootObjectWithPort:EDOHostNamingService.namingServerPort]);
}

/** Verifies no side effect when adding the same service multiple times. */
- (void)testAddingServiceMultipleTimes {
  EDOHostNamingService *namingService = EDOHostNamingService.sharedService;
  NSString *serviceName = @"com.google.testService.adding";
  EDOServicePort *dummyPort = [EDOServicePort servicePortWithPort:12345 serviceName:serviceName];
  [namingService addServicePort:dummyPort];
  XCTAssertFalse([namingService addServicePort:dummyPort]);
  // Clean up.
  [namingService removeServicePort:dummyPort];
}

/** Verifies no side effect when removing the same service multiple times. */
- (void)testRemoveServiceMultipleTimes {
  EDOHostNamingService *namingService = EDOHostNamingService.sharedService;
  NSString *serviceName = @"com.google.testService.removing";
  EDOServicePort *dummyPort = [EDOServicePort servicePortWithPort:12346 serviceName:serviceName];
  [namingService addServicePort:dummyPort];

  [namingService removeServicePort:dummyPort];
  [namingService removeServicePort:dummyPort];

  XCTAssertTrue([namingService portForServiceWithName:serviceName] == 0);
}

/** Verifies service are added even when naming service has stopped serving. */
- (void)testAddingServiceAfterStop {
  EDOHostNamingService *namingService = EDOHostNamingService.sharedService;
  [namingService stop];
  NSString *serviceName = @"com.google.testService.stop";
  UInt16 port = 12347;
  EDOServicePort *dummyPort = [EDOServicePort servicePortWithPort:port serviceName:serviceName];
  [namingService addServicePort:dummyPort];
  XCTAssertEqual([namingService portForServiceWithName:serviceName], port);
  // Clean up.
  [namingService removeServicePort:dummyPort];
}

/**
 *  Tests thread safety of adding/removing services.
 *  This test adds two service ports concurrently to the naming service, and then removes them
 *  concurrently. And it verifies the state of the naming service after each step.
 */
- (void)testUpdateServicesConcurrently {
  EDOHostNamingService *namingService = EDOHostNamingService.sharedService;
  NSString *serviceName1 = @"com.google.testService.concurrent1";
  UInt16 port1 = 12348;
  NSString *serviceName2 = @"com.google.testService.concurrent2";
  UInt16 port2 = 12349;
  EDOServicePort *dummyPort1 = [EDOServicePort servicePortWithPort:port1 serviceName:serviceName1];
  EDOServicePort *dummyPort2 = [EDOServicePort servicePortWithPort:port2 serviceName:serviceName2];
  dispatch_queue_t concurrentQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_CONCURRENT);
  dispatch_async(concurrentQueue, ^{
    [namingService addServicePort:dummyPort1];
  });
  dispatch_async(concurrentQueue, ^{
    [namingService addServicePort:dummyPort2];
  });
  dispatch_barrier_sync(concurrentQueue, ^{
    XCTAssertEqual([namingService portForServiceWithName:serviceName1], port1);
    XCTAssertEqual([namingService portForServiceWithName:serviceName2], port2);
  });
  dispatch_async(concurrentQueue, ^{
    [namingService removeServicePort:dummyPort1];
  });
  dispatch_async(concurrentQueue, ^{
    [namingService removeServicePort:dummyPort2];
  });
  dispatch_barrier_sync(concurrentQueue, ^{
    XCTAssertTrue([namingService portForServiceWithName:serviceName1] == 0);
    XCTAssertTrue([namingService portForServiceWithName:serviceName2] == 0);
  });
}

/**
 *  Tests accessing service connection port and verifies the listen socket is created and returns a
 *  non-zero port.
 */
- (void)testAccessServiceConnectionPort {
  EDOHostNamingService *namingService = EDOHostNamingService.sharedService;
  XCTAssertFalse(namingService.serviceConnectionPort == 0);
}

@end
