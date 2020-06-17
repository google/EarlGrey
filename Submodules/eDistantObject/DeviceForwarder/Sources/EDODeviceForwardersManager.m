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

#import "DeviceForwarder/Sources/EDODeviceForwardersManager.h"

#import "Channel/Sources/EDOChannelForwarder.h"
#import "Channel/Sources/EDOHostPort.h"
#import "Channel/Sources/EDOSocket.h"
#import "Channel/Sources/EDOSocketChannel.h"
#import "Device/Sources/EDODeviceConnector.h"

/**
 *  The number of tries the manager attempts to connect to the multiplexer at start.
 *
 *  @note The manager can start trying before the device starts the multiplexer, so we have a fair
 *        number of tries in case.
 */
static const int kEDODeviceConnectMaxRetries = 15;
static const int kEDODeviceRetryIntervalInSeconds = 1;

@implementation EDODeviceForwardersManager {
  /** The set of forwarders that connect to the multiplexer or forward the channel. */
  NSMutableSet<EDOChannelForwarder *> *_forwarders;
}

- (instancetype)initWithDeviceUUID:(NSString *)deviceUUID
                              port:(UInt16)port
                   numOfForwarders:(NSUInteger)numOfForwarders {
  NSParameterAssert(deviceUUID.length > 0);
  NSParameterAssert(port > 0);
  NSParameterAssert(numOfForwarders > 0);
  self = [super init];
  if (self) {
    _deviceUUID = deviceUUID;
    _port = port;
    _numOfForwarders = numOfForwarders;
    _forwarders = [[NSMutableSet alloc] init];
  }
  return self;
}

- (void)startWithCompletionBlock:(void (^)(EDODeviceForwardersManager *))block {
  @synchronized(_forwarders) {
    [_forwarders removeAllObjects];
  }
  _deviceIdentifier = nil;

  dispatch_queue_t queue = dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0);
  __weak EDODeviceForwardersManager *weakSelf = self;

  __block int retryCount = kEDODeviceConnectMaxRetries;
  __block __weak void (^weakRetryBlock)(void);
  void (^retryBlock)(void) = ^{
    EDODeviceForwardersManager *strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    NSString *deviceIdentifier = [strongSelf startForwarding];
    if (deviceIdentifier) {
      [strongSelf willChangeValueForKey:@"deviceIdentifier"];
      strongSelf->_deviceIdentifier = deviceIdentifier;
      [strongSelf didChangeValueForKey:@"deviceIdentifier"];

      // Start one additional forwarder to handle concurrent requests.
      [strongSelf startForwarding];
      block(strongSelf);
    } else {
      retryCount--;
      if (retryCount > 0) {
        dispatch_time_t when =
            dispatch_time(DISPATCH_TIME_NOW, kEDODeviceRetryIntervalInSeconds * NSEC_PER_SEC);
        dispatch_after(when, queue, weakRetryBlock);
      } else {
        NSLog(@"Fail to connect to the multiplexer after %d retries.", kEDODeviceConnectMaxRetries);
        block(strongSelf);
      }
    }
  };
  retryBlock = [retryBlock copy];
  weakRetryBlock = retryBlock;
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0), queue, retryBlock);
}

/**
 *  Starts a new forwarder to connect to the multiplexer and ready for forwarding.
 *
 *  @note It only starts a new forwarder if it doesn't exceed the limit.
 *  @return The device identifier from the device's multiplexer.
 */
- (NSString *)startForwarding {
  EDOChannelForwarder *forwarder;
  @synchronized(_forwarders) {
    if (_numOfForwarders <= _forwarders.count) {
      return nil;
    }
    forwarder = [[EDOChannelForwarder alloc] initWithConnectBlock:self.multiplexerConnectBlock
                                                 hostConnectBlock:self.hostConnectBlock];
    [_forwarders addObject:forwarder];
  }

  __weak EDODeviceForwardersManager *weakSelf = self;
  EDOForwarderErrorHandler errorHandler = ^(EDOForwarderError errorCode) {
    EDODeviceForwardersManager *strongSelf = weakSelf;
    if (strongSelf) {
      @synchronized(strongSelf->_forwarders) {
        [strongSelf->_forwarders removeObject:forwarder];
      }
    }
    // We re-establish the forwarder if the port fails to connect so the multiplexer can set up a
    // new connection.
    if (errorCode == EDOForwarderErrorPortConnection) {
      [strongSelf startForwarding];
    } else {
      // For any other errors, we don't retry and just kill it.
    }
  };

  NSData *deviceData = [forwarder startWithErrorHandler:errorHandler];
  if (!deviceData) {
    @synchronized(_forwarders) {
      [_forwarders removeObject:forwarder];
    }
    return nil;
  } else {
    return [[NSString alloc] initWithData:deviceData encoding:NSUTF8StringEncoding];
  }
}

/** Gets a block that sets up the connection to the multiplexer. */
- (EDOMultiplexerConnectBlock)multiplexerConnectBlock {
  NSString *deviceUUID = _deviceUUID;
  UInt16 port = _port;
  EDOMultiplexerConnectBlock block = ^{
    NSError *error;
    id<EDOChannel> channel;
    dispatch_io_t deviceChannel = [EDODeviceConnector.sharedConnector connectToDevice:deviceUUID
                                                                               onPort:port
                                                                                error:&error];
    if (deviceChannel && !error) {
      channel = [[EDOSocketChannel alloc] initWithDispatchIO:deviceChannel];
    }
    return channel;
  };
  return block;
}

/** Gets a block that handles the incoming EDOHostPort to forward. */
- (EDOHostChannelConnectBlock)hostConnectBlock {
  __weak EDODeviceForwardersManager *weakSelf = self;
  return ^(EDOHostPort *port) {
    id<EDOChannel> channel;
    NSError *connectionError;
    if (port.connectsDevice) {
      dispatch_io_t deviceChannel =
          [EDODeviceConnector.sharedConnector connectToDevice:port.deviceSerialNumber
                                                       onPort:port.port
                                                        error:&connectionError];
      if (!connectionError) {
        channel = [[EDOSocketChannel alloc] initWithDispatchIO:deviceChannel];
      }
    } else {
      EDOSocket *socket = [EDOSocket socketWithTCPPort:port.port queue:nil error:&connectionError];
      if (socket) {
        channel = [EDOSocketChannel channelWithSocket:socket];
      }
    }
    if (connectionError) {
      // TODO(haowoo): we only log the error for now as we don't return the error back to the
      //               multiplexer just yet.
      NSLog(@"Error when connecting to %@, %@", port, connectionError);
    } else {
      // This forwarder is being used now, we need to create a new one for the new request.
      [weakSelf startForwarding];
    }
    return channel;
  };
}

@end
