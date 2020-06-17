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

#import "Channel/Sources/EDOSocketChannel.h"

#include <arpa/inet.h>
#include <fcntl.h>
#include <netinet/tcp.h>
#include <sys/un.h>

#import "Channel/Sources/EDOChannelUtil.h"
#import "Channel/Sources/EDOHostPort.h"
#import "Channel/Sources/EDOSocket.h"
#import "Channel/Sources/EDOSocketPort.h"

#pragma mark - Socket Connection Extension

@interface EDOSocketChannel ()
// The dispatch io channel to send and receive I/O data from the underlying socket.
@property(readonly, nonatomic) dispatch_io_t channel;
// The dispatch queue where the receive handler block will be dispatched to.
@property(readonly, nonatomic) dispatch_queue_t handlerQueue;
@end

#pragma mark - Socket Connection

@implementation EDOSocketChannel
@dynamic valid;

+ (instancetype)channelWithSocket:(EDOSocket *)socket {
  return [[EDOSocketChannel alloc] initWithSocket:socket];
}

- (instancetype)initWithDispatchIO:(dispatch_io_t)channel {
  NSParameterAssert(channel != nil);

  self = [self init];
  if (self) {
    _channel = channel;
  }
  return self;
}

- (instancetype)initWithSocket:(EDOSocket *)socket {
  return [self initWithDispatchIO:[socket releaseAsDispatchIO]];
}

- (instancetype)init {
  self = [super init];
  if (self) {
    // For internal IO and event handlers, it is equivalent to creating it as a serial queue as they
    // are not reentrant and only one block will be scheduled by dispatch io and dispatch source.
    _handlerQueue =
        dispatch_queue_create("com.google.edo.socketChannel.handler", DISPATCH_QUEUE_SERIAL);
  }
  return self;
}

- (void)dealloc {
  [self invalidate];
}

#pragma mark - EDOChannel

- (void)sendData:(NSData *)data withCompletionHandler:(EDOChannelSentHandler)handler {
  dispatch_queue_t handlerQueue = self.handlerQueue;
  if (!self.channel) {
    dispatch_async(handlerQueue, ^{
      if (handler) {
        handler(self, [NSError errorWithDomain:NSPOSIXErrorDomain code:0 userInfo:nil]);
      }
    });
    return;
  }

  dispatch_data_t totalData = EDOBuildFrameFromDataWithQueue(data, handlerQueue);
  dispatch_io_write(
      self.channel, 0, totalData, handlerQueue, ^(bool done, dispatch_data_t _, int errCode) {
        if (!done) {
          return;
        }

        if (handler) {
          dispatch_async(handlerQueue, ^{
            NSError *error;
            if (errCode != 0) {
              error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errCode userInfo:nil];
            }
            handler(self, error);
          });
        }
      });
}

- (void)receiveDataWithHandler:(EDOChannelReceiveHandler)handler {
  dispatch_queue_t handlerQueue = self.handlerQueue;
  dispatch_io_t channel = self.channel;
  if (!channel) {
    dispatch_async(handlerQueue, ^{
      // TODO(haowoo): Add better error code define.
      handler(self, nil,
              [NSError errorWithDomain:NSInternalInconsistencyException code:0 userInfo:nil]);
    });
    return;
  }

  __block dispatch_data_t dataReceived;
  __block size_t remainingDataSize;
  dispatch_io_handler_t dataHandler = ^(bool done, dispatch_data_t data, int error) {
    if (error || !data) {
      if (handler) {
        dispatch_async(handlerQueue, ^{
          handler(self, nil, [NSError errorWithDomain:NSPOSIXErrorDomain code:error userInfo:nil]);
        });
      }
      return;
    }
    remainingDataSize -= dispatch_data_get_size(data);
    dataReceived = dataReceived ? dispatch_data_create_concat(dataReceived, data) : data;

    if (remainingDataSize > 0) {
      return;
    }

    NSMutableData *receivedData =
        [NSMutableData dataWithCapacity:dispatch_data_get_size(dataReceived)];
    dispatch_data_apply(dataReceived, ^bool(dispatch_data_t region, size_t offset,
                                            const void *buffer, size_t size) {
      [receivedData appendBytes:buffer length:size];
      return YES;
    });

    if (handler) {
      dispatch_async(handlerQueue, ^{
        handler(self, receivedData, nil);
      });
    }
  };

  dispatch_io_handler_t frameHandler = ^(bool done, dispatch_data_t data, int error) {
    size_t payloadSize = EDOGetPayloadSizeFromFrameData(data);
    if (payloadSize > 0) {
      remainingDataSize = payloadSize;
      dispatch_io_read(channel, 0, payloadSize, handlerQueue, dataHandler);
    } else {
      // Close the channel on errors and closed sockets.
      if (error != 0 || payloadSize == 0) {
        [self invalidate];
      }

      // Execute the block on closing the channel.
      if (payloadSize == 0 && error == 0 && handler) {
        dispatch_async(handlerQueue, ^{
          handler(self, nil, nil);
        });
      }
    }
  };

  dispatch_io_read(channel, 0, EDOGetPayloadHeaderSize(), handlerQueue, frameHandler);
}

/** @see -[EDOChannel isValid] */
- (BOOL)isValid {
  @synchronized(self) {
    return _channel != NULL;
  }
}

/** @see -[EDOChannel invalidate] */
- (void)invalidate {
  @synchronized(self) {
    if (_channel) {
      dispatch_io_close(_channel, 0);
      _channel = NULL;
    }
  }
}

@end
