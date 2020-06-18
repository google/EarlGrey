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

#import "Channel/Sources/EDOChannelMultiplexer.h"

#import "Channel/Sources/EDOBlockingQueue.h"
#import "Channel/Sources/EDOHostPort.h"
#import "Channel/Sources/EDOSocket.h"
#import "Channel/Sources/EDOSocketChannel.h"
#import "Channel/Sources/EDOSocketPort.h"

static const int64_t kEDOConnectTimeout = 3 * NSEC_PER_SEC;
static const int64_t kEDOGetChannelTimeout = 5 * NSEC_PER_SEC;

@implementation EDOChannelMultiplexer {
  /** The listen socket for the multiplexer to handle incoming forwarders. */
  EDOSocket *_listenSocket;
  /** The connected channels that are ready to forward. */
  EDOBlockingQueue<id<EDOChannel>> *_connectedChannels;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _connectedChannels = [[EDOBlockingQueue alloc] init];
  }
  return self;
}

- (NSUInteger)numberOfChannels {
  return _connectedChannels.count;
}

- (BOOL)start:(EDOHostPort *)port error:(NSError **)error {
  __weak EDOChannelMultiplexer *weakSelf = self;
  NSData *deviceIdentifier = [EDOHostPort.deviceIdentifier dataUsingEncoding:NSUTF8StringEncoding];
  _listenSocket = [EDOSocket
      listenWithTCPPort:port.port
                  queue:nil
         connectedBlock:^(EDOSocket *socket, NSError *serviceError) {
           EDOSocketChannel *channel = [EDOSocketChannel channelWithSocket:socket];

           // Sends the deviceIdentifier to ACK the connection.
           [channel sendData:deviceIdentifier withCompletionHandler:nil];

           dispatch_semaphore_t connectWait = dispatch_semaphore_create(0);
           dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, kEDOConnectTimeout);
           [channel receiveDataWithHandler:^(id<EDOChannel> _, NSData *data, NSError *error) {
             EDOChannelMultiplexer *strongSelf = weakSelf;
             // An device ACK message from the forwarder to finish the handshaking, from now on,
             // the channel can be used for forwarding.
             if (strongSelf && data) {
               // TODO(haowoo): The data should contain the forwarder info, but we ignore for now.
               [strongSelf->_connectedChannels appendObject:channel];
             } else {
               [channel invalidate];
             }
             dispatch_semaphore_signal(connectWait);
           }];
           if (dispatch_semaphore_wait(connectWait, timeout) != 0) {
             [channel invalidate];
           }
         }];
  UInt16 listenPort = _listenSocket.socketPort.port;
  _port = [[EDOHostPort alloc] initWithPort:listenPort name:nil deviceSerialNumber:nil];
  return _listenSocket != nil;
}

- (void)stop {
  [_listenSocket invalidate];
  _connectedChannels = [[EDOBlockingQueue alloc] init];
  _port = nil;
}

- (id<EDOChannel>)channelWithPort:(EDOHostPort *)hostPort
                          timeout:(NSTimeInterval)timeout
                            error:(NSError **)error {
  dispatch_time_t channelTimeout = dispatch_time(DISPATCH_TIME_NOW, kEDOGetChannelTimeout);
  EDOSocketChannel *channel = [_connectedChannels lastObjectWithTimeout:channelTimeout];
  if (!channel) {
    return nil;
  }

  __block BOOL connected = NO;
  dispatch_semaphore_t connectWait = dispatch_semaphore_create(0);
  NSData *deviceIdentifier = [EDOHostPort.deviceIdentifier dataUsingEncoding:NSUTF8StringEncoding];
  // Sends the host post and waits for the confirmation
  [channel sendData:hostPort.data withCompletionHandler:nil];
  [channel receiveDataWithHandler:^(id<EDOChannel> _, NSData *data, NSError *error) {
    // The forwarder should respond with the deviceIdentifier that is sent when setting up the
    // connection.
    if ([deviceIdentifier isEqualToData:data]) {
      connected = YES;
    }
    dispatch_semaphore_signal(connectWait);
  }];
  dispatch_time_t connectTimeout = dispatch_time(DISPATCH_TIME_NOW, timeout * NSEC_PER_SEC);
  dispatch_semaphore_wait(connectWait, connectTimeout);
  if (!connected) {
    [channel invalidate];
    return nil;
  } else {
    return channel.valid ? channel : nil;
  }
}

@end
