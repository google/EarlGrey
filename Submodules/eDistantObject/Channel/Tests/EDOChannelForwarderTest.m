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

#import "Channel/Sources/EDOChannelForwarder.h"
#import "Channel/Sources/EDOChannelMultiplexer.h"
#import "Channel/Sources/EDOHostPort.h"
#import "Channel/Sources/EDOSocket.h"
#import "Channel/Sources/EDOSocketChannel.h"
#import "Channel/Sources/EDOSocketPort.h"

@interface EDOChannelForwarderTest : XCTestCase
@end

@implementation EDOChannelForwarderTest {
  EDOChannelMultiplexer *_multiplexer;
}

- (void)setUp {
  [super setUp];

  _multiplexer = [[EDOChannelMultiplexer alloc] init];
  XCTAssertTrue([_multiplexer start:nil error:nil]);
}

- (void)tearDown {
  [_multiplexer stop];
  [super tearDown];
}

- (void)testForwarderFailConnectMultiplexer {
  EDOMultiplexerConnectBlock connectBlock = ^id<EDOChannel> { return nil; };
  NS_VALID_UNTIL_END_OF_SCOPE EDOChannelForwarder *forwarder =
      [[EDOChannelForwarder alloc] initWithConnectBlock:connectBlock
                                       hostConnectBlock:[self hostConnectBlockWithDelay:0]];

  XCTestExpectation *expectNotInvoke = [self expectationWithDescription:@"Handler not invoked."];
  expectNotInvoke.inverted = YES;
  expectNotInvoke.assertForOverFulfill = NO;
  XCTAssertNil([forwarder startWithErrorHandler:^(EDOForwarderError errorCode) {
    [expectNotInvoke fulfill];
  }]);
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testForwarderCanConnectMultiplexer {
  NS_VALID_UNTIL_END_OF_SCOPE EDOChannelForwarder *forwarder =
      [[EDOChannelForwarder alloc] initWithConnectBlock:self.multiplexerConnectBlock
                                       hostConnectBlock:[self hostConnectBlockWithDelay:0]];

  XCTestExpectation *expectNotInvoke = [self expectationWithDescription:@"Handler not invoked."];
  expectNotInvoke.inverted = YES;
  expectNotInvoke.assertForOverFulfill = NO;
  XCTAssertNotNil([forwarder startWithErrorHandler:^(EDOForwarderError errorCode) {
    [expectNotInvoke fulfill];
  }]);
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testForwarderCannotConnectHostPort {
  EDOHostPort *fakePort = [[EDOHostPort alloc] initWithPort:100 name:nil deviceSerialNumber:nil];
  XCTestExpectation *expectConnectHost = [self expectationWithDescription:@"Connecting host."];
  NS_VALID_UNTIL_END_OF_SCOPE EDOChannelForwarder *forwarder =
      [[EDOChannelForwarder alloc] initWithConnectBlock:self.multiplexerConnectBlock
                                       hostConnectBlock:^id<EDOChannel>(EDOHostPort *port) {
                                         XCTAssertEqualObjects(fakePort, port);
                                         [expectConnectHost fulfill];
                                         return nil;
                                       }];

  XCTestExpectation *expectHostPortFail = [self expectationWithDescription:@"Host port failed."];
  XCTAssertNotNil([forwarder startWithErrorHandler:^(EDOForwarderError errorCode) {
    if (errorCode == EDOForwarderErrorPortConnection) {
      [expectHostPortFail fulfill];
    }
  }]);

  [self expectNumberChannels:1];
  XCTAssertNil([_multiplexer channelWithPort:fakePort timeout:1 error:nil]);
  XCTAssertEqual(_multiplexer.numberOfChannels, 0);
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testForwarderConnectHostSuperSlow {
  EDOChannelForwarder *forwarder =
      [[EDOChannelForwarder alloc] initWithConnectBlock:self.multiplexerConnectBlock
                                       hostConnectBlock:[self hostConnectBlockWithDelay:1]];

  XCTestExpectation *expectNotInvoke = [self expectationWithDescription:@"Handler not invoked."];
  expectNotInvoke.inverted = YES;
  expectNotInvoke.assertForOverFulfill = NO;
  XCTAssertNotEqualObjects([forwarder startWithErrorHandler:^(EDOForwarderError errorCode) {
                             [expectNotInvoke fulfill];
                           }],
                           EDOHostPort.deviceIdentifier);
  [self expectNumberChannels:1];

  NS_VALID_UNTIL_END_OF_SCOPE EDOSocket *bouncing = [self boucingTwiceListenSocket];
  EDOHostPort *serverPort = [[EDOHostPort alloc] initWithPort:bouncing.socketPort.port
                                                         name:nil
                                           deviceSerialNumber:nil];
  id<EDOChannel> channel = [_multiplexer channelWithPort:serverPort timeout:1.5 error:nil];
  XCTAssertNotNil(channel);
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testForwarderCanForwardData {
  EDOChannelForwarder *forwarder =
      [[EDOChannelForwarder alloc] initWithConnectBlock:self.multiplexerConnectBlock
                                       hostConnectBlock:[self hostConnectBlockWithDelay:0]];
  XCTAssertNotNil([forwarder startWithErrorHandler:^(EDOForwarderError errorCode){
  }]);
  [self expectNumberChannels:1];

  NS_VALID_UNTIL_END_OF_SCOPE EDOSocket *bouncing = [self boucingTwiceListenSocket];
  EDOHostPort *serverPort = [[EDOHostPort alloc] initWithPort:bouncing.socketPort.port
                                                         name:nil
                                           deviceSerialNumber:nil];
  id<EDOChannel> channel = [_multiplexer channelWithPort:serverPort timeout:5 error:nil];
  XCTAssertNotNil(channel);

  XCTestExpectation *expectBounce = [self expectationWithDescription:@"Data bounced."];
  NSData *data = [@"bouncing" dataUsingEncoding:NSUTF8StringEncoding];
  [channel sendData:data withCompletionHandler:nil];
  [channel receiveDataWithHandler:^(id<EDOChannel> channel, NSData *receivedData, NSError *error) {
    if ([receivedData isEqualToData:data]) {
      [expectBounce fulfill];
    }
  }];
  [self waitForExpectationsWithTimeout:3 handler:nil];

  XCTestExpectation *expectBounceTwice = [self expectationWithDescription:@"Data bounced twice."];
  [channel sendData:data withCompletionHandler:nil];
  [channel receiveDataWithHandler:^(id<EDOChannel> channel, NSData *receivedData, NSError *error) {
    if ([receivedData isEqualToData:data]) {
      [expectBounceTwice fulfill];
    }
  }];
  [self waitForExpectationsWithTimeout:3 handler:nil];
}

- (void)testNoChannelAfterForwarderStop {
  EDOChannelForwarder *forwarder =
      [[EDOChannelForwarder alloc] initWithConnectBlock:self.multiplexerConnectBlock
                                       hostConnectBlock:[self hostConnectBlockWithDelay:0]];

  XCTAssertNotNil([forwarder startWithErrorHandler:^(EDOForwarderError errorCode){
  }]);
  [self expectNumberChannels:1];
  [forwarder stop];

  NS_VALID_UNTIL_END_OF_SCOPE EDOSocket *bouncing = [self boucingTwiceListenSocket];
  EDOHostPort *serverPort = [[EDOHostPort alloc] initWithPort:bouncing.socketPort.port
                                                         name:nil
                                           deviceSerialNumber:nil];
  XCTAssertNil([_multiplexer channelWithPort:serverPort timeout:0.1 error:nil]);
}

- (void)testMultipleForwarderCanConnectMultiplexerAndForward {
  int numOfForwarders = 20;
  NS_VALID_UNTIL_END_OF_SCOPE NSMutableArray<id> *savedForwarders = [[NSMutableArray alloc] init];
  // Add the placeholders first.
  for (int i = 0; i < numOfForwarders; ++i) {
    [savedForwarders addObject:NSNull.null];
  }

  dispatch_queue_t feedQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_CONCURRENT);
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
    dispatch_apply(numOfForwarders, feedQueue, ^(size_t idx) {
      EDOChannelForwarder *forwarder =
          [[EDOChannelForwarder alloc] initWithConnectBlock:self.multiplexerConnectBlock
                                           hostConnectBlock:[self hostConnectBlockWithDelay:0]];

      XCTAssertNotNil([forwarder startWithErrorHandler:^(EDOForwarderError errorCode){
      }]);
      savedForwarders[idx] = forwarder;
    });
  });

  NS_VALID_UNTIL_END_OF_SCOPE EDOSocket *bouncing = [self boucingTwiceListenSocket];
  EDOHostPort *serverPort = [[EDOHostPort alloc] initWithPort:bouncing.socketPort.port
                                                         name:nil
                                           deviceSerialNumber:nil];
  XCTestExpectation *expectBounce = [self expectationWithDescription:@"Data bounced."];
  expectBounce.expectedFulfillmentCount = numOfForwarders;
  NSData *data = [@"bouncing" dataUsingEncoding:NSUTF8StringEncoding];

  dispatch_queue_t fetchQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_CONCURRENT);
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
    dispatch_apply(numOfForwarders, fetchQueue, ^(size_t idx) {
      id<EDOChannel> channel = [self->_multiplexer channelWithPort:serverPort timeout:1 error:nil];
      XCTAssertNotNil(channel);

      [channel sendData:data withCompletionHandler:nil];
      [channel receiveDataWithHandler:^(id<EDOChannel> _, NSData *receivedData, NSError *error) {
        if ([receivedData isEqualToData:data]) {
          [expectBounce fulfill];
        }
      }];
    });
  });
  [self waitForExpectationsWithTimeout:20 handler:nil];
  [self expectNumberChannels:0];
}

- (void)testForwarderCanRestart {
  EDOChannelForwarder *forwarder =
      [[EDOChannelForwarder alloc] initWithConnectBlock:self.multiplexerConnectBlock
                                       hostConnectBlock:[self hostConnectBlockWithDelay:1]];

  XCTAssertNotNil([forwarder startWithErrorHandler:^(EDOForwarderError errorCode){
  }]);
  [self expectNumberChannels:1];

  NS_VALID_UNTIL_END_OF_SCOPE EDOSocket *bouncing = [self boucingTwiceListenSocket];
  EDOHostPort *serverPort = [[EDOHostPort alloc] initWithPort:bouncing.socketPort.port
                                                         name:nil
                                           deviceSerialNumber:nil];
  XCTAssertNil([_multiplexer channelWithPort:serverPort timeout:0.8 error:nil]);

  XCTAssertEqual(_multiplexer.numberOfChannels, 0);
  XCTAssertNotNil([forwarder startWithErrorHandler:^(EDOForwarderError errorCode){
  }]);
  [self expectNumberChannels:1];
  XCTAssertNotNil([_multiplexer channelWithPort:serverPort timeout:1.5 error:nil]);
}

#pragma mark - Helper methods

/** Gets a simple listener that will bounce back the data at most twice. */
- (EDOSocket *)boucingTwiceListenSocket {
  return [EDOSocket
      listenWithTCPPort:0
                  queue:nil
         connectedBlock:^(EDOSocket *socket, NSError *error) {
           EDOSocketChannel *channel = [EDOSocketChannel channelWithSocket:socket];
           [channel receiveDataWithHandler:^(id<EDOChannel> _, NSData *data, NSError *error) {
             [channel sendData:data withCompletionHandler:nil];
             [channel receiveDataWithHandler:^(id<EDOChannel> _, NSData *data, NSError *error) {
               [channel sendData:data withCompletionHandler:nil];
             }];
           }];
         }];
}

/** Gets the connect block that connects to the given port after @c delayInSeconds. */
- (EDOHostChannelConnectBlock)hostConnectBlockWithDelay:(uint64_t)delayInSeconds {
  return ^id<EDOChannel>(EDOHostPort *port) {
    __block id<EDOChannel> channel;
    dispatch_semaphore_t waitConnect = dispatch_semaphore_create(0);
    [EDOSocket connectWithTCPPort:port.port
                            queue:nil
                   connectedBlock:^(EDOSocket *socket, NSError *error) {
                     if (!socket.valid) {
                       return;
                     }
                     channel = [EDOSocketChannel channelWithSocket:socket];
                     dispatch_time_t when =
                         dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                     dispatch_after(when, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
                       dispatch_semaphore_signal(waitConnect);
                     });
                   }];
    dispatch_semaphore_wait(waitConnect, DISPATCH_TIME_FOREVER);
    return channel;
  };
}

/** Gets the connect block that connects to the default test's multiplexer. */
- (EDOMultiplexerConnectBlock)multiplexerConnectBlock {
  UInt16 port = _multiplexer.port.port;
  return ^id<EDOChannel> {
    EDOSocket *socket = [EDOSocket socketWithTCPPort:port queue:nil error:nil];
    return [EDOSocketChannel channelWithSocket:socket];
  };
}

/** Expects the given number of channels are available in the multiplexer. */
- (void)expectNumberChannels:(NSUInteger)numOfChannels {
  NSPredicate *predicate =
      [NSPredicate predicateWithFormat:@"numberOfChannels = %d", numOfChannels];
  XCTestExpectation *expectNumberChannels =
      [[XCTNSPredicateExpectation alloc] initWithPredicate:predicate object:_multiplexer];
  XCTAssertEqual([XCTWaiter waitForExpectations:@[ expectNumberChannels ] timeout:5],
                 XCTWaiterResultCompleted);
}

@end
