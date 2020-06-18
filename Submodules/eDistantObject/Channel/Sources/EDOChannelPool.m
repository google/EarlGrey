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

#import "Channel/Sources/EDOChannelPool.h"

#import "Channel/Sources/EDOBlockingQueue.h"
#import "Channel/Sources/EDOChannelErrors.h"
#import "Channel/Sources/EDOHostPort.h"
#import "Channel/Sources/EDOSocket.h"
#import "Channel/Sources/EDOSocketChannel.h"
#import "Channel/Sources/EDOSocketPort.h"
#import "Device/Sources/EDODeviceConnector.h"

/** Timeout for channel fetch. */
static const int64_t kChannelPoolTimeout = 10 * NSEC_PER_SEC;

@implementation EDOChannelPool {
  // The isolation queue to access the channelMap.
  dispatch_queue_t _channelPoolQueue;
  // The reusable channels, mapping from the host port to the channels.
  NSMutableDictionary<EDOHostPort *, EDOBlockingQueue<id<EDOChannel>> *> *_channelMap;
  // The socket of service registration.
  EDOSocket *_serviceRegistrationSocket;
  // The dispatch queue to accept service connection by name.
  dispatch_queue_t _serviceConnectionQueue;
}

+ (instancetype)sharedChannelPool {
  static EDOChannelPool *instance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[EDOChannelPool alloc] init];
  });
  return instance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _channelPoolQueue = dispatch_queue_create("com.google.edo.ChannelPool", DISPATCH_QUEUE_SERIAL);
    _channelMap = [[NSMutableDictionary alloc] init];
    _serviceConnectionQueue =
        dispatch_queue_create("com.google.edo.serviceConnection", DISPATCH_QUEUE_SERIAL);
  }
  return self;
}

- (id<EDOChannel>)channelWithPort:(EDOHostPort *)port error:(NSError **)error {
  dispatch_time_t now = dispatch_time(DISPATCH_TIME_NOW, 0);
  id<EDOChannel> channel = [[self channelsForPort:port] lastObjectWithTimeout:now];
  NSError *resultError;

  if (channel) {
    return channel;
  } else if (port.port == 0) {
    // TODO(ynzhang): Should request connection channel from the service side and add it to channel
    // pool. Currently we rely on the other side registering the service to create channel.

    // The channel from the device to the host will be registered asynchronously. We give a short
    // period time to wait here until the channel is being added from the host.
    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, kChannelPoolTimeout);
    channel = [[self channelsForPort:port] lastObjectWithTimeout:timeout];
    if (!channel) {
      NSDictionary<NSErrorUserInfoKey, id> *userInfo = @{EDOChannelPortKey : port};
      resultError = [NSError errorWithDomain:EDOChannelErrorDomain
                                        code:EDOChannelErrorFetchFailed
                                    userInfo:userInfo];
    }
  } else {
    channel = [self edo_createChannelWithPort:port error:&resultError];
  }
  if (error) {
    *error = resultError;
  } else {
    NSLog(@"Error fetching channel: %@", resultError);
  }
  return channel;
}

- (EDOBlockingQueue<id<EDOChannel>> *)channelsForPort:(EDOHostPort *)port {
  __block EDOBlockingQueue *channels;
  dispatch_sync(_channelPoolQueue, ^{
    channels = self->_channelMap[port];
    if (!channels) {
      channels = [[EDOBlockingQueue alloc] init];
      [self->_channelMap setObject:channels forKey:port];
    }
  });
  return channels;
}

- (void)addChannel:(id<EDOChannel>)channel forPort:(EDOHostPort *)port {
  // reuse the channel only when it is valid
  if (channel.isValid) {
    [[self channelsForPort:port] appendObject:channel];
  }
}

- (void)removeChannelsWithPort:(EDOHostPort *)port {
  dispatch_sync(_channelPoolQueue, ^{
    [self->_channelMap removeObjectForKey:port];
  });
}

- (NSUInteger)countChannelsWithPort:(EDOHostPort *)port {
  return [self channelsForPort:port].count;
}

- (UInt16)serviceConnectionPort {
  @synchronized(self) {
    [self edo_startHostRegistrationPortIfNeeded];
  }
  return _serviceRegistrationSocket.socketPort.port;
}

#pragma mark - Private

- (id<EDOChannel>)edo_createChannelWithPort:(EDOHostPort *)port error:(NSError **)error {
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
  if (error) {
    *error = connectionError;
  }
  return channel;
}

- (void)edo_startHostRegistrationPortIfNeeded {
  if (_serviceRegistrationSocket) {
    return;
  }
  __weak EDOChannelPool *weakSelf = self;
  _serviceRegistrationSocket = [EDOSocket
      listenWithTCPPort:0
                  queue:_serviceConnectionQueue
         connectedBlock:^(EDOSocket *socket, NSError *serviceError) {
           if (serviceError) {
             // Only log the error for now, it is fine to ignore any error for the incoming
             // connection as the eDO will continue to function without this setup.
             NSLog(@"Fail to accept a new connection. %@", serviceError);
           }
           EDOSocketChannel *socketChannel = [EDOSocketChannel channelWithSocket:socket];
           [socketChannel receiveDataWithHandler:^(id<EDOChannel> channel, NSData *data,
                                                   NSError *error) {
             if (error) {
               // Log the error instead of exception in order not to terminate the process,
               // since eDO may still work without getting the host port name.
               NSLog(@"Unable to receive host port name: %@", error);
               return;
             }
             NSString *name = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
             if (name.length) {
               EDOHostPort *hostPort = [EDOHostPort hostPortWithName:name];
               [weakSelf addChannel:channel forPort:hostPort];
             } else {
               NSLog(@"The port name is empty, the channel is discarded.");
             }
           }];
         }];
}

@end
