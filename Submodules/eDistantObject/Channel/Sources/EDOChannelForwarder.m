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

#import "Channel/Sources/EDOChannelForwarder.h"

#import "Channel/Sources/EDOChannelPool.h"
#import "Channel/Sources/EDOHostPort.h"
#import "Channel/Sources/EDOSocketChannel.h"

/**
 *  Creates a receiveHandler for the multiplexer to receive the data and forwards to the forwarded
 *  channel.
 */
static EDOChannelReceiveHandler GetMultiplexerReceiveHandler(
    id<EDOChannel> forwardedChannel, EDOForwarderErrorHandler errorHandler) {
  // The handler to receive the data from the multiplexer and sends it to the forwarded channel.
  __block __weak EDOChannelReceiveHandler weakHandler;
  EDOChannelReceiveHandler handler = ^(id<EDOChannel> channel, NSData *data, NSError *error) {
    // The multiplexer closes or errors.
    if (error || !data) {
      [forwardedChannel invalidate];
      errorHandler(EDOForwarderErrorMultiplerxerClosed);
      return;
    }
    [forwardedChannel sendData:data withCompletionHandler:nil];
    [channel receiveDataWithHandler:weakHandler];
  };
  handler = [handler copy];
  weakHandler = handler;
  return handler;
}

/**
 *  Creates a receiveHandler for the forwarded channel to receive the data and forwards to the
 *  multiplexer.
 */
static EDOChannelReceiveHandler GetForwarderReceiveHandler(id<EDOChannel> multiplexerChannel,
                                                           EDOForwarderErrorHandler errorHandler) {
  // The handler to receive the data from the forwarded channel and sends it to the multiplexer.
  __block __weak EDOChannelReceiveHandler weakHandler;
  EDOChannelReceiveHandler handler = ^(id<EDOChannel> channel, NSData *data, NSError *error) {
    // The forwarded host closes or errors.
    if (error || !data) {
      [multiplexerChannel invalidate];
      errorHandler(EDOForwarderErrorForwardedChannelClosed);
      return;
    }

    [multiplexerChannel sendData:data withCompletionHandler:nil];
    [channel receiveDataWithHandler:weakHandler];
  };
  handler = [handler copy];
  weakHandler = handler;
  return handler;
}

@implementation EDOChannelForwarder {
  /** The block to set up the connection with the multiplexer. */
  EDOMultiplexerConnectBlock _connectBlock;
  /** The block to set up the connection with the host from the port. */
  EDOHostChannelConnectBlock _hostConnectBlock;
  /** The channel connecting to the multiplexer. */
  id<EDOChannel> _multiplexerChannel;
}

- (instancetype)initWithConnectBlock:(EDOMultiplexerConnectBlock)connectBlock
                    hostConnectBlock:(EDOHostChannelConnectBlock)hostConnectBlock {
  self = [super init];
  if (self) {
    _connectBlock = connectBlock;
    _hostConnectBlock = hostConnectBlock;
  }
  return self;
}

- (NSData *)startWithErrorHandler:(EDOForwarderErrorHandler)errorHandler {
  // Close any existing channel.
  [_multiplexerChannel invalidate];

  id<EDOChannel> channel = _connectBlock();
  if (!channel) {
    return nil;
  }

  __block NSData *deviceIdentifier;
  dispatch_semaphore_t waitHandshake = dispatch_semaphore_create(0);
  [channel receiveDataWithHandler:^(id<EDOChannel> _, NSData *data, NSError *error) {
    if (!data || error) {
      [channel invalidate];
      errorHandler(EDOForwarderErrorHandshake);
      dispatch_semaphore_signal(waitHandshake);
      return;
    }

    deviceIdentifier = data;

    // Right now we simply bounce back the deviceIdentifier to ACK.
    [channel sendData:data withCompletionHandler:nil];
    EDOChannelReceiveHandler portHandler = [self portHandlerWithDeviceIdentifier:deviceIdentifier
                                                                    errorHandler:errorHandler];
    [channel receiveDataWithHandler:portHandler];
    dispatch_semaphore_signal(waitHandshake);
  }];
  dispatch_time_t handshakeTimeout = dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC);
  if (dispatch_semaphore_wait(waitHandshake, handshakeTimeout) != 0) {
    [channel invalidate];
  }
  _multiplexerChannel = channel;
  return deviceIdentifier;
}

- (void)stop {
  [_multiplexerChannel invalidate];
  _multiplexerChannel = nil;
}

/**
 *  Creates a receiveHandler to handle the initial port data and set up the connection.
 *
 *  @param deviceIdentifier The data received in the handshake to ackknowledge the connection.
 */
- (EDOChannelReceiveHandler)portHandlerWithDeviceIdentifier:(NSData *)deviceIdentifier
                                               errorHandler:(EDOForwarderErrorHandler)errorHandler {
  EDOHostChannelConnectBlock hostConnectBlock = _hostConnectBlock;
  // The handler to receive the hostPort to set up the initial connection to forward channel.
  EDOChannelReceiveHandler portHandler = ^(id<EDOChannel> channel, NSData *data, NSError *error) {
    if (error || !data) {
      errorHandler(EDOForwarderErrorPortSerialization);
      return;
    }
    EDOHostPort *hostPort = data ? [[EDOHostPort alloc] initWithData:data] : nil;
    if (!hostPort) {
      // Close the channel for invalid port data.
      [channel invalidate];
      errorHandler(EDOForwarderErrorPortSerialization);
      return;
    }

    id<EDOChannel> forwardChannel = hostConnectBlock(hostPort);
    if (!forwardChannel) {
      // Failed to connect, sending empty message will close the channel.
      [channel sendData:NSData.data withCompletionHandler:nil];
      [channel invalidate];
      errorHandler(EDOForwarderErrorPortConnection);
    } else {
      // Sends the deviceIdentifier to acknowledge the connection.
      [channel sendData:deviceIdentifier withCompletionHandler:nil];

      // Starts to receive data from both ends.
      [channel receiveDataWithHandler:GetMultiplexerReceiveHandler(forwardChannel, errorHandler)];
      [forwardChannel receiveDataWithHandler:GetForwarderReceiveHandler(channel, errorHandler)];
    }
  };
  return portHandler;
}

@end
