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

#import "Channel/Sources/EDOChannelMultiplexer.h"
#import "Channel/Sources/EDOHostPort.h"
#import "Channel/Sources/EDOSocket.h"
#import "Channel/Sources/EDOSocketChannel.h"

@interface EDOChannelMultiplexerTest : XCTestCase
@end

@implementation EDOChannelMultiplexerTest

- (void)testMultiplexerCanStartAndStop {
  EDOChannelMultiplexer *multiplexer = [[EDOChannelMultiplexer alloc] init];
  [multiplexer start:nil error:nil];
  XCTAssertNotEqual(multiplexer.port, nil);

  EDOChannelMultiplexer *multiplexer2 = [[EDOChannelMultiplexer alloc] init];
  [multiplexer2 start:nil error:nil];
  XCTAssertNotEqual(multiplexer2.port, nil);

  [multiplexer stop];
  [multiplexer2 stop];
}

- (void)testMultiplexerAcceptForwardChannels {
  EDOChannelMultiplexer *multiplexer = [[EDOChannelMultiplexer alloc] init];
  [multiplexer start:nil error:nil];
  NS_VALID_UNTIL_END_OF_SCOPE id<EDOChannel> channel = [self channelWithPort:multiplexer.port
                                                                  handShaked:NO];

  NSData *deviceInfo = [@"info" dataUsingEncoding:NSUTF8StringEncoding];
  [channel receiveDataWithHandler:^(id<EDOChannel> _, NSData *data, NSError *error) {
    NSData *ackMsg = [EDOHostPort.deviceIdentifier dataUsingEncoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects(data, ackMsg);
    XCTAssertEqual(multiplexer.numberOfChannels, 0);

    [channel sendData:deviceInfo withCompletionHandler:nil];
  }];

  [self expectMultiplexer:multiplexer withNumberChannels:1];
}

- (void)testMultiplexerAcceptChannelAckTimeout {
  EDOChannelMultiplexer *multiplexer = [[EDOChannelMultiplexer alloc] init];
  [multiplexer start:nil error:nil];
  id<EDOChannel> channel = [self channelWithPort:multiplexer.port handShaked:NO];

  XCTestExpectation *expectHandshake = [self expectationWithDescription:@"Handshaked."];
  NSData *deviceInfo = [@"info" dataUsingEncoding:NSUTF8StringEncoding];
  [channel receiveDataWithHandler:^(id<EDOChannel> _, NSData *data, NSError *error) {
    NSData *ackMsg = [EDOHostPort.deviceIdentifier dataUsingEncoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects(data, ackMsg);
    XCTAssertEqual(multiplexer.numberOfChannels, 0);

    [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:5]];
    [channel sendData:deviceInfo withCompletionHandler:nil];
    // Receiving data will cause the channel invalidation.
    [channel receiveDataWithHandler:nil];
    [expectHandshake fulfill];
  }];

  [self expectationForPredicate:[NSPredicate predicateWithFormat:@"valid == NO"]
            evaluatedWithObject:channel
                        handler:nil];
  [self waitForExpectationsWithTimeout:10 handler:nil];
  [self expectMultiplexer:multiplexer withNumberChannels:0];
}

- (void)testNoChannelWithTimeout {
  EDOHostPort *port = [EDOHostPort hostPortWithLocalPort:100];
  EDOChannelMultiplexer *multiplexer = [[EDOChannelMultiplexer alloc] init];

  ({
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    XCTAssertNil([multiplexer channelWithPort:port timeout:1 error:nil]);
    XCTAssertGreaterThanOrEqual(CFAbsoluteTimeGetCurrent() - startTime, 1);
  });

  ({
    [multiplexer start:nil error:nil];
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    XCTAssertNil([multiplexer channelWithPort:port timeout:1 error:nil]);
    XCTAssertGreaterThanOrEqual(CFAbsoluteTimeGetCurrent() - startTime, 1);
  });
}

- (void)testForwardedChannelWithIncorrectAck {
  EDOChannelMultiplexer *multiplexer = [[EDOChannelMultiplexer alloc] init];
  [multiplexer start:nil error:nil];
  NS_VALID_UNTIL_END_OF_SCOPE id<EDOChannel> channel = [self channelWithPort:multiplexer.port
                                                                  handShaked:YES];
  [self expectMultiplexer:multiplexer withNumberChannels:1];

  EDOHostPort *port = [EDOHostPort hostPortWithLocalPort:100];
  CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
  XCTAssertNil([multiplexer channelWithPort:port timeout:1 error:nil]);
  XCTAssertGreaterThanOrEqual(CFAbsoluteTimeGetCurrent() - startTime, 1);
  [self expectMultiplexer:multiplexer withNumberChannels:0];
}

- (void)testMultiplexerCanFetchForwardedChannelWithHostPort {
  EDOChannelMultiplexer *multiplexer = [[EDOChannelMultiplexer alloc] init];
  [multiplexer start:nil error:nil];
  id<EDOChannel> channel = [self channelWithPort:multiplexer.port handShaked:YES];
  [self expectMultiplexer:multiplexer withNumberChannels:1];

  EDOHostPort *port = [EDOHostPort hostPortWithLocalPort:100];
  NSData *deviceIdentifier = [EDOHostPort.deviceIdentifier dataUsingEncoding:NSUTF8StringEncoding];
  [channel receiveDataWithHandler:^(id<EDOChannel> _, NSData *data, NSError *error) {
    EDOHostPort *receivedPort = [[EDOHostPort alloc] initWithData:data];
    XCTAssertEqualObjects(port, receivedPort);
    [channel sendData:deviceIdentifier withCompletionHandler:nil];
  }];

  XCTAssertNotNil([multiplexer channelWithPort:port timeout:1 error:nil]);
  [self expectMultiplexer:multiplexer withNumberChannels:0];
}

- (void)testCanFetchChannelWithHostPortConcurrently {
  int numOfChannels = 200;
  EDOChannelMultiplexer *multiplexer = [[EDOChannelMultiplexer alloc] init];
  [multiplexer start:nil error:nil];

  NSData *deviceIdentifier = [EDOHostPort.deviceIdentifier dataUsingEncoding:NSUTF8StringEncoding];
  EDOHostPort *port = [EDOHostPort hostPortWithLocalPort:100];
  XCTestExpectation *expectChannels = [self expectationWithDescription:@"Fetched all channels."];

  NS_VALID_UNTIL_END_OF_SCOPE NSMutableArray<id> *savedChannels = [[NSMutableArray alloc] init];
  // Add the placeholders first.
  for (int i = 0; i < numOfChannels; ++i) {
    [savedChannels addObject:NSNull.null];
  }

  dispatch_queue_t feedQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_CONCURRENT);
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
    dispatch_apply(numOfChannels, feedQueue, ^(size_t idx) {
      id<EDOChannel> channel = [self channelWithPort:multiplexer.port handShaked:YES];

      [channel receiveDataWithHandler:^(id<EDOChannel> _, NSData *data, NSError *error) {
        EDOHostPort *receivedPort = [[EDOHostPort alloc] initWithData:data];
        XCTAssertEqualObjects(port, receivedPort);
        [channel sendData:deviceIdentifier withCompletionHandler:nil];
      }];
      savedChannels[idx] = channel;
    });
  });

  dispatch_queue_t fetchQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_CONCURRENT);
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
    dispatch_apply(numOfChannels, fetchQueue, ^(size_t idx) {
      XCTAssertNotNil([multiplexer channelWithPort:port timeout:5 error:nil]);
    });
    [expectChannels fulfill];
  });

  [self waitForExpectationsWithTimeout:5 handler:nil];
  [self expectMultiplexer:multiplexer withNumberChannels:0];
}

- (void)testCanFetchChannelWithBothCorrectAndIncorrectAckConcurrently {
  int numOfChannels = 30;
  EDOChannelMultiplexer *multiplexer = [[EDOChannelMultiplexer alloc] init];
  [multiplexer start:nil error:nil];

  NSData *deviceIdentifier = [EDOHostPort.deviceIdentifier dataUsingEncoding:NSUTF8StringEncoding];
  EDOHostPort *port = [EDOHostPort hostPortWithLocalPort:100];
  NSData *deviceInfo = [@"info" dataUsingEncoding:NSUTF8StringEncoding];
  NSData *incorrectAck = [@"deadbeef" dataUsingEncoding:NSUTF8StringEncoding];
  XCTestExpectation *expectChannelCreated = [self expectationWithDescription:@"Channels created."];

  NS_VALID_UNTIL_END_OF_SCOPE NSMutableArray<id> *savedChannels = [[NSMutableArray alloc] init];
  // Add the placeholders first.
  for (int i = 0; i < numOfChannels; ++i) {
    [savedChannels addObject:NSNull.null];
  }

  dispatch_queue_t queue = dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0);
  dispatch_async(queue, ^{
    dispatch_apply(numOfChannels, queue, ^(size_t idx) {
      id<EDOChannel> channel;
      if (idx % 3 == 1) {
        // The channels that don't respond correctly with hostPort.
        channel = [self channelWithPort:multiplexer.port handShaked:YES];
        [channel receiveDataWithHandler:^(id<EDOChannel> _, NSData *data, NSError *error) {
          if (error || !data) {
            return;
          }
          XCTAssertEqualObjects(port, [[EDOHostPort alloc] initWithData:data]);
          [channel sendData:incorrectAck withCompletionHandler:nil];
        }];
      } else if (idx % 3 == 2) {
        // The channels that don't respond correctly when setting up the forwarder.
        channel = [self channelWithPort:multiplexer.port handShaked:NO];
        [channel receiveDataWithHandler:^(id<EDOChannel> _, NSData *data, NSError *error) {
          dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), queue, ^{
            [channel sendData:deviceInfo withCompletionHandler:nil];
            [channel receiveDataWithHandler:nil];
          });
        }];
      } else {
        channel = [self channelWithPort:multiplexer.port handShaked:YES];
        [channel receiveDataWithHandler:^(id<EDOChannel> _, NSData *data, NSError *error) {
          XCTAssertEqualObjects(port, [[EDOHostPort alloc] initWithData:data]);
          [channel sendData:deviceIdentifier withCompletionHandler:nil];
        }];
      }
      savedChannels[idx] = channel;
    });
    [expectChannelCreated fulfill];
  });

  int numOfBadChannels = (numOfChannels + 1) / 3;
  int numOfConnectedChannels = numOfChannels - numOfBadChannels;
  int numOfGoodChannels = (numOfChannels - 1) / 3 + 1;
  XCTestExpectation *expectChannels = [self expectationWithDescription:@"Fetched channels."];
  XCTestExpectation *expectFailedChannels = [self expectationWithDescription:@"Failed channels."];
  expectChannels.expectedFulfillmentCount = numOfGoodChannels;
  expectFailedChannels.expectedFulfillmentCount = numOfConnectedChannels - numOfGoodChannels;
  dispatch_async(queue, ^{
    dispatch_apply(numOfConnectedChannels, queue, ^(size_t idx) {
      if ([multiplexer channelWithPort:port timeout:2 error:nil]) {
        [expectChannels fulfill];
      } else {
        [expectFailedChannels fulfill];
      }
    });
  });
  [self waitForExpectationsWithTimeout:10 handler:nil];
  [self expectMultiplexer:multiplexer withNumberChannels:0];
}

/**
 *  Gets a channel connecting to the multiplexer at the given port.
 *
 *  @param port       The host port the multiplexer listens on.
 *  @param handShaked Whether to send the initial handshake data so the multiplexer can add it to
 *                    the channels pool.
 */
- (id<EDOChannel>)channelWithPort:(EDOHostPort *)port handShaked:(BOOL)handShaked {
  UInt16 portNumber = port.port;
  __block id<EDOChannel> channel;
  dispatch_semaphore_t waitConnect = dispatch_semaphore_create(0);
  EDOSocketConnectedBlock block = ^(EDOSocket *socket, NSError *error) {
    channel = [EDOSocketChannel channelWithSocket:socket];
    if (handShaked) {
      [channel receiveDataWithHandler:^(id<EDOChannel> _, NSData *data, NSError *error) {
        [channel sendData:[@"info" dataUsingEncoding:NSUTF8StringEncoding]
            withCompletionHandler:nil];
        dispatch_semaphore_signal(waitConnect);
      }];
    } else {
      dispatch_semaphore_signal(waitConnect);
    }
  };
  [EDOSocket connectWithTCPPort:portNumber queue:nil connectedBlock:block];
  dispatch_semaphore_wait(waitConnect, dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC));
  return channel;
}

- (void)expectMultiplexer:(EDOChannelMultiplexer *)multiplexer
       withNumberChannels:(NSUInteger)numOfChannels {
  NSPredicate *predicate =
      [NSPredicate predicateWithFormat:@"numberOfChannels = %d", numOfChannels];
  XCTestExpectation *expectNumberChannels =
      [[XCTNSPredicateExpectation alloc] initWithPredicate:predicate object:multiplexer];
  XCTAssertEqual([XCTWaiter waitForExpectations:@[ expectNumberChannels ] timeout:5],
                 XCTWaiterResultCompleted);
}

@end
