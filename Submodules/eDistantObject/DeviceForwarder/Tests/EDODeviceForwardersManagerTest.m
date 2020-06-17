//
// Copyright 2019 Google LLC
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

#import "DeviceForwarder/Sources/EDODeviceForwardersManager.h"

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "Channel/Sources/EDOChannel.h"
#import "Channel/Sources/EDOChannelMultiplexer.h"
#import "Channel/Sources/EDOHostPort.h"
#import "Channel/Sources/EDOSocket.h"
#import "Channel/Sources/EDOSocketChannel.h"
#import "Channel/Sources/EDOSocketPort.h"
#import "Device/Sources/EDODeviceConnector.h"

@interface EDODeviceForwardersManagerTest : XCTestCase
@end

@implementation EDODeviceForwardersManagerTest {
  EDOChannelMultiplexer *_multiplexer;
  EDOSocket *_simpleListener;
}

- (void)setUp {
  [super setUp];
  _multiplexer = [[EDOChannelMultiplexer alloc] init];
  [_multiplexer start:nil error:nil];

  // The listen socket that closes itself in 0.3 seconds.
  _simpleListener = [EDOSocket
      listenWithTCPPort:0
                  queue:nil
         connectedBlock:^(EDOSocket *socket, NSError *error) {
           EDOSocketChannel *channel = [EDOSocketChannel channelWithSocket:socket];
           dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC));
           dispatch_after(when, dispatch_get_main_queue(), ^{
             [channel invalidate];
           });
         }];
}

- (void)tearDown {
  [_multiplexer stop];
  [_simpleListener invalidate];
  [super tearDown];
}

- (void)testFailConnectInvalidDevice {
  XCTestExpectation *expectFail = [self expectationWithDescription:@"Failed to connect."];
  EDODeviceForwardersManager *mananger =
      [[EDODeviceForwardersManager alloc] initWithDeviceUUID:@"fakeId" port:100 numOfForwarders:5];
  [mananger startWithCompletionBlock:^(EDODeviceForwardersManager *_) {
    XCTAssertNil(mananger.deviceIdentifier);
    [expectFail fulfill];
  }];
  [self waitForExpectationsWithTimeout:20 handler:nil];
}

- (void)testCanConnectDeviceAfterRetries {
  id mockConnector = OCMPartialMock(EDODeviceConnector.sharedConnector);
  __block int retries = 5;
  OCMStub([mockConnector connectToDevice:@"fakeId"
                                  onPort:100
                                   error:(NSError * __autoreleasing *)[OCMArg anyPointer]])
      .andDo(^(NSInvocation *invocation) {
        void *returnValue = NULL;
        [invocation setReturnValue:&returnValue];
        if (--retries > 0) {
          return;
        }

        EDOSocket *socket = [EDOSocket socketWithTCPPort:self->_multiplexer.port.port
                                                   queue:nil
                                                   error:nil];
        __autoreleasing dispatch_io_t dispatchIO = [socket releaseAsDispatchIO];
        [invocation setReturnValue:&dispatchIO];
      });

  XCTestExpectation *expectConnect = [self expectationWithDescription:@"Connect to multiplexer."];
  EDODeviceForwardersManager *mananger =
      [[EDODeviceForwardersManager alloc] initWithDeviceUUID:@"fakeId" port:100 numOfForwarders:5];
  [mananger startWithCompletionBlock:^(EDODeviceForwardersManager *_) {
    XCTAssertEqualObjects(mananger.deviceIdentifier, EDOHostPort.deviceIdentifier);
    [expectConnect fulfill];
  }];
  [self expectationForPredicate:[NSPredicate predicateWithFormat:@"numberOfChannels = 2"]
            evaluatedWithObject:_multiplexer
                        handler:nil];
  [self waitForExpectationsWithTimeout:9 handler:nil];
  XCTAssertLessThan(retries, 0);
  [mockConnector stopMocking];
}

- (void)testNewForwarderEstablishedAfterForwarding {
  EDOHostPort *port = self.simplePort;
  id connectorMock = self.connectorMock;
  NS_VALID_UNTIL_END_OF_SCOPE EDODeviceForwardersManager *mananger =
      [[EDODeviceForwardersManager alloc] initWithDeviceUUID:@"fakeId" port:100 numOfForwarders:5];
  [mananger startWithCompletionBlock:^(EDODeviceForwardersManager *_){
  }];

  [self expectationForPredicate:[NSPredicate predicateWithFormat:@"numberOfChannels = 2"]
            evaluatedWithObject:_multiplexer
                        handler:nil];
  [self waitForExpectationsWithTimeout:2 handler:nil];

  id<EDOChannel> channel = [_multiplexer channelWithPort:port timeout:5 error:nil];
  XCTAssertNotNil(channel);
  [self expectationForPredicate:[NSPredicate predicateWithFormat:@"numberOfChannels = 2"]
            evaluatedWithObject:_multiplexer
                        handler:nil];
  [self waitForExpectationsWithTimeout:2 handler:nil];
  [connectorMock stopMocking];
}

- (void)testForwarderReestablishedAfterFailConnect {
  id connectorMock = self.connectorMock;
  int maxForwarders = 3;
  NS_VALID_UNTIL_END_OF_SCOPE EDODeviceForwardersManager *mananger =
      [[EDODeviceForwardersManager alloc] initWithDeviceUUID:@"fakeId"
                                                        port:100
                                             numOfForwarders:maxForwarders];
  [mananger startWithCompletionBlock:^(EDODeviceForwardersManager *_){
  }];

  // The bad connection will be dropped and never exceed to the limit as it will continue to
  // re-establish the forwarder.
  EDOHostPort *port = [[EDOHostPort alloc] initWithPort:500 name:nil deviceSerialNumber:nil];
  for (int i = 0; i < maxForwarders * 2; ++i) {
    XCTAssertNil([_multiplexer channelWithPort:port timeout:0.1 error:nil]);
  }
  [self expectationForPredicate:[NSPredicate predicateWithFormat:@"numberOfChannels = 2"]
            evaluatedWithObject:_multiplexer
                        handler:nil];
  [self waitForExpectationsWithTimeout:2 handler:nil];
  [connectorMock stopMocking];
}

- (void)testForwarderNotExceedingLimit {
  EDOHostPort *port = self.simplePort;
  id connectorMock = self.connectorMock;
  int maxForwarders = 3;
  NS_VALID_UNTIL_END_OF_SCOPE EDODeviceForwardersManager *mananger =
      [[EDODeviceForwardersManager alloc] initWithDeviceUUID:@"fakeId"
                                                        port:100
                                             numOfForwarders:maxForwarders];
  [mananger startWithCompletionBlock:^(EDODeviceForwardersManager *_){
  }];

  for (int i = 0; i < maxForwarders; ++i) {
    XCTAssertNotNil([_multiplexer channelWithPort:port timeout:0.1 error:nil]);
  }
  XCTAssertNil([_multiplexer channelWithPort:port timeout:0.5 error:nil]);
  [connectorMock stopMocking];
}

- (id)connectorMock {
  id connectorMock = OCMPartialMock(EDODeviceConnector.sharedConnector);
  OCMStub([connectorMock connectToDevice:@"fakeId"
                                  onPort:100
                                   error:(NSError * __autoreleasing *)[OCMArg anyPointer]])
      .andDo(^(NSInvocation *invocation) {
        [invocation retainArguments];
        EDOSocket *socket = [EDOSocket socketWithTCPPort:self->_multiplexer.port.port
                                                   queue:nil
                                                   error:nil];
        // OCMock doesn't play well with the ARC, force it to retain and autorelease.
        dispatch_io_t dispatchIO = [socket releaseAsDispatchIO];
        [invocation setReturnValue:&dispatchIO];
      });
  return connectorMock;
}

- (EDOHostPort *)simplePort {
  return [[EDOHostPort alloc] initWithPort:_simpleListener.socketPort.port
                                      name:nil
                        deviceSerialNumber:nil];
}
@end
