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

#import "Channel/Sources/EDOHostPort.h"
#import "Channel/Sources/EDOSocket.h"
#import "Channel/Sources/EDOSocketChannel.h"
#import "Channel/Sources/EDOSocketPort.h"

@interface EDOSocketChannelTest : XCTestCase
@property(readonly) NSData *replyData;
@end

@implementation EDOSocketChannelTest
@dynamic replyData;

- (void)testCreateHostWithoutAssignedPort {
  XCTestExpectation *expectConnected = [self expectationWithDescription:@"Connected to host"];

  // Set up a listen socket w/ port = zero will auto-assign any available port.
  EDOSocket *host = [EDOSocket listenWithTCPPort:0 queue:nil connectedBlock:nil];
  XCTAssertNotEqual(host.socketPort.port, 0);
  XCTAssertEqualObjects(host.socketPort.IPAddress, @"127.0.0.1");

  // Test if the connection completes.
  [EDOSocket connectWithTCPPort:host.socketPort.port
                          queue:nil
                 connectedBlock:^(EDOSocket *socket, NSError *error) {
                   XCTAssertEqualObjects(socket.socketPort.IPAddress, @"127.0.0.1");
                   XCTAssertNil(error);
                   [expectConnected fulfill];
                 }];

  [self waitForExpectationsWithTimeout:1 handler:nil];

  [host invalidate];
  XCTAssertFalse(host.valid, @"The socket should become invalid right after invalidating.");
}

- (void)testConnectHostError {
  // Create a listen socket and invalidate it so no one can connect to it.
  EDOSocket *host = [EDOSocket listenWithTCPPort:0
                                           queue:nil
                                  connectedBlock:^(EDOSocket *socket, NSError *error){
                                  }];
  XCTAssertNotEqual(host.socketPort.port, 0);
  XCTAssertEqualObjects(host.socketPort.IPAddress, @"127.0.0.1");
  [host invalidate];

  // Wait the host to be invalid.
  [self expectationForPredicate:[NSPredicate predicateWithFormat:@"valid == false"]
            evaluatedWithObject:host
                        handler:nil];
  [self waitForExpectationsWithTimeout:2 handler:nil];

  XCTestExpectation *expectError =
      [self expectationWithDescription:@"Failed to connect to the host"];
  [EDOSocket connectWithTCPPort:host.socketPort.port
                          queue:nil
                 connectedBlock:^(EDOSocket *socket, NSError *error) {
                   XCTAssertNil(socket);
                   XCTAssertEqualObjects(error.domain, NSPOSIXErrorDomain);
                   XCTAssertEqual(error.code, ECONNREFUSED);
                   [expectError fulfill];
                 }];

  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testCanConnectHost {
  XCTestExpectation *expectConnected = [self expectationWithDescription:@"Connected to host"];

  // The empty handler only accepts the connection and drops it.
  EDOSocket *host = [EDOSocket listenWithTCPPort:1234 queue:nil connectedBlock:nil];
  XCTAssertEqual(host.socketPort.port, 1234);
  XCTAssertEqualObjects(host.socketPort.IPAddress, @"127.0.0.1");

  // Test if the connection completes.
  [EDOSocket connectWithTCPPort:1234
                          queue:nil
                 connectedBlock:^(EDOSocket *socket, NSError *error) {
                   XCTAssertEqualObjects(socket.socketPort.IPAddress, @"127.0.0.1");
                   XCTAssertNil(error);
                   [expectConnected fulfill];
                 }];
  [self waitForExpectationsWithTimeout:1 handler:nil];

  XCTAssertTrue(host.valid, @"the host should be valid");
  [host invalidate];

  // The host should become invalid after the invalidation.
  [self expectationForPredicate:[NSPredicate predicateWithFormat:@"valid == false"]
            evaluatedWithObject:host
                        handler:nil];
  [self waitForExpectationsWithTimeout:2 handler:nil];

  XCTestExpectation *expectError = [self expectationWithDescription:@"Connection is rejected"];
  [EDOSocket connectWithTCPPort:1234
                          queue:nil
                 connectedBlock:^(EDOSocket *socket, NSError *error) {
                   XCTAssertNotNil(error);
                   [expectError fulfill];
                 }];
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testRetainAndReleaseClient {
  __block id<EDOChannel> remoteClient = nil;
  XCTestExpectation *expectConnected = [self expectationWithDescription:@"Conntected to host"];
  NS_VALID_UNTIL_END_OF_SCOPE EDOSocket *host = [EDOSocket
      listenWithTCPPort:0
                  queue:nil
         connectedBlock:^(EDOSocket *socket, NSError *err) {
           remoteClient = [EDOSocketChannel channelWithSocket:socket];
           [expectConnected fulfill];

           // The client can close right away, causing the half-open socket, this is to only
           // signal the system so it can detect the closed socket and generate the event.
           // It is not a bug per se, it is up to the user to handle the half-open connection, i.e.
           // it may use extensive system resources to allocate for the open sockets.
           [remoteClient sendData:self.replyData
               withCompletionHandler:^(id<EDOChannel> channel, NSError *error) {
                 // The receiveHandler to receive close signals from the other end of the channel.
                 [channel receiveDataWithHandler:nil];
               }];
         }];
  XCTAssertNotEqual(host.socketPort.port, 0);

  // Not-retaining the client will get released and then disconnected.
  [EDOSocket connectWithTCPPort:host.socketPort.port queue:nil connectedBlock:nil];

  // Wait until it connects so we get the reference of remoteClient.
  [self waitForExpectationsWithTimeout:10 handler:nil];

  XCTAssertNotNil(remoteClient, @"The client is not connected.");

  // The remoteClient should become invalid after the client is released and disconnected.
  [self expectationForPredicate:[NSPredicate predicateWithFormat:@"valid == false"]
            evaluatedWithObject:remoteClient
                        handler:nil];

  [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testClientCanRecieveData {
  XCTestExpectation *expectConnected = [self expectationWithDescription:@"Connected to host"];
  XCTestExpectation *expectIncoming = [self expectationWithDescription:@"Incoming req is received"];
  XCTestExpectation *expectReply = [self expectationWithDescription:@"Received from host"];
  NSData *replyHugeData = [self replyHugeData:20871416];  // ~20mb
  NS_VALID_UNTIL_END_OF_SCOPE EDOSocket *host =
      [EDOSocket listenWithTCPPort:0
                             queue:nil
                    connectedBlock:^(EDOSocket *socket, NSError *error) {
                      [expectIncoming fulfill];
                      EDOSocketChannel *client = [EDOSocketChannel channelWithSocket:socket];
                      [client sendData:replyHugeData withCompletionHandler:nil];
                      [client sendData:self.replyData withCompletionHandler:nil];
                    }];
  XCTAssertNotEqual(host.socketPort.port, 0);

  NSMutableArray<NSData *> *receivedData = [[NSMutableArray alloc] init];
  [EDOSocket connectWithTCPPort:host.socketPort.port
                          queue:nil
                 connectedBlock:^(EDOSocket *socket, NSError *error) {
                   [expectConnected fulfill];
                   XCTAssertNil(error);
                   // Holds it until received the data.
                   __block id<EDOChannel> remoteConn = nil;
                   remoteConn = [EDOSocketChannel channelWithSocket:socket];
                   [remoteConn receiveDataWithHandler:^(id<EDOChannel> channel, NSData *data,
                                                        NSError *error) {
                     [receivedData addObject:data];
                     [remoteConn receiveDataWithHandler:^(id<EDOChannel> channel, NSData *data,
                                                          NSError *error) {
                       [receivedData addObject:data];
                       [expectReply fulfill];
                       remoteConn = nil;
                     }];
                   }];
                 }];

  [self waitForExpectationsWithTimeout:5 handler:nil];
  XCTAssertTrue(memcmp(self.replyData.bytes, receivedData[1].bytes, self.replyData.length) == 0);
  XCTAssertTrue(memcmp(replyHugeData.bytes, receivedData[0].bytes, replyHugeData.length) == 0);
  XCTAssertEqual(replyHugeData.length, receivedData[0].length);
  XCTAssertEqual(self.replyData.length, receivedData[1].length);
}

- (void)testHostCanRecieveData {
  XCTestExpectation *expectConnected = [self expectationWithDescription:@"Connected to host"];
  XCTestExpectation *expectIncoming = [self expectationWithDescription:@"Incoming req is received"];
  XCTestExpectation *expectReply = [self expectationWithDescription:@"Received from host"];
  NSData *replyHugeData = [self replyHugeData:20871416];  // ~20mb

  NSMutableArray<NSData *> *receivedData = [[NSMutableArray alloc] init];
  NS_VALID_UNTIL_END_OF_SCOPE EDOSocket *host = [EDOSocket
      listenWithTCPPort:0
                  queue:nil
         connectedBlock:^(EDOSocket *socket, NSError *error) {
           [expectIncoming fulfill];
           EDOSocketChannel *client = [EDOSocketChannel channelWithSocket:socket];
           [client receiveDataWithHandler:^(id<EDOChannel> channel, NSData *data, NSError *error) {
             [receivedData addObject:data];
             [client
                 receiveDataWithHandler:^(id<EDOChannel> channel, NSData *data, NSError *error) {
                   [receivedData addObject:data];
                   [expectReply fulfill];
                 }];
           }];
         }];
  XCTAssertNotEqual(host.socketPort.port, 0);

  // Connect to the host and send the data
  [EDOSocket connectWithTCPPort:host.socketPort.port
                          queue:nil
                 connectedBlock:^(EDOSocket *socket, NSError *error) {
                   [expectConnected fulfill];
                   XCTAssertNil(error);

                   EDOSocketChannel *client = [EDOSocketChannel channelWithSocket:socket];
                   [client sendData:self.replyData withCompletionHandler:nil];
                   [client sendData:replyHugeData withCompletionHandler:nil];
                 }];

  [self waitForExpectationsWithTimeout:5 handler:nil];
  XCTAssertTrue(memcmp(self.replyData.bytes, receivedData[0].bytes, receivedData[0].length) == 0);
  XCTAssertTrue(memcmp(replyHugeData.bytes, receivedData[1].bytes, receivedData[1].length) == 0);
}

- (void)testEmptyAcceptBlock {
  XCTestExpectation *expectConnected = [self expectationWithDescription:@"Conntected to host"];
  XCTestExpectation *expectDisconnected =
      [self expectationWithDescription:@"Disconnected from host"];

  __block id<EDOChannel> remoteConn = nil;

  // The empty handler only accepts the connection and drops it.
  NS_VALID_UNTIL_END_OF_SCOPE EDOSocket *host = [EDOSocket listenWithTCPPort:0
                                                                       queue:nil
                                                              connectedBlock:nil];
  XCTAssertNotEqual(host.socketPort.port, 0);

  // Test if the connection completes.
  [EDOSocket connectWithTCPPort:host.socketPort.port
                          queue:nil
                 connectedBlock:^(EDOSocket *socket, NSError *error) {
                   [expectConnected fulfill];
                   remoteConn = [EDOSocketChannel channelWithSocket:socket];
                   [remoteConn receiveDataWithHandler:^(id<EDOChannel> channel, NSData *data,
                                                        NSError *error) {
                     // The channel should be immediately dropped.
                     XCTAssertNil(error);
                     XCTAssertNil(data, "shouldn't receive any data");
                     XCTAssertEqual(remoteConn, channel, "should be the same channel");
                     [expectDisconnected fulfill];
                   }];
                 }];

  [self waitForExpectationsWithTimeout:1 handler:nil];
}

#pragma mark - Test Utils

- (NSData *)replyData {
  return [@"reply" dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSData *)replyHugeData:(NSUInteger)dataSize {
  // int twentyMb           = 20971520;
  NSMutableData *data = [NSMutableData dataWithCapacity:dataSize];
  for (NSUInteger i = 0; i < dataSize / 4; ++i) {
    uint32_t randomBits = arc4random();
    [data appendBytes:(void *)&randomBits length:4];
  }
  return data;
}

@end
