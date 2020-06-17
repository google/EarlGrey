//
// Copyright 2018 Google LLC.
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

#import "Device/Sources/EDODeviceChannel.h"

#include <sys/socket.h>
#include <sys/un.h>

#import "Device/Sources/EDOUSBMuxUtil.h"

@implementation EDODeviceChannel {
  dispatch_io_t _dispatchChannel;
  dispatch_queue_t _queue;
}

+ (instancetype)channelWithError:(NSError **)error {
  EDODeviceChannel *channel = [[EDODeviceChannel alloc] initInternal];
  if ([channel openWithError:error]) {
    return channel;
  }
  return nil;
}

- (instancetype)initInternal {
  self = [super init];
  if (self) {
    _queue = dispatch_queue_create("com.google.edo.deviceChannel", DISPATCH_QUEUE_CONCURRENT);
  }
  return self;
}

- (dispatch_io_t)releaseAsDispatchIO {
  @synchronized(self) {
    dispatch_io_t channel = _dispatchChannel;
    _dispatchChannel = nil;
    return channel;
  }
}

- (void)receivePacketWithHandler:(EDODevicePacketReceivedHandler)handler {
  // Read the first `size` bytes off the channel_
  dispatch_io_read(
      _dispatchChannel, 0, [EDOUSBMuxUtil sizeOfPayloadSize], _queue,
      ^(bool done, dispatch_data_t sizeData, int error) {
        if (!done) {
          return;
        }

        if (error) {
          handler(nil, [[NSError alloc] initWithDomain:NSPOSIXErrorDomain code:error userInfo:nil]);
          return;
        }

        // Read size of incoming usbmux_packet_t
        uint32_t packetLength = 0;
        char *buffer = NULL;
        size_t bufferSize = 0;
        NS_VALID_UNTIL_END_OF_SCOPE dispatch_data_t mapData =
            dispatch_data_create_map(sizeData, (const void **)&buffer, &bufferSize);
        // NS_VALID_UNTIL_END_OF_SCOPE guarantees 'mapData' isn't released before
        // memcpy has a chance to do its thing
        if (bufferSize == 0) {
          // The packet could be dropped by usbmuxd when there are more than ~50 packets in transit.
          NSError *error = [NSError
              errorWithDomain:NSPOSIXErrorDomain
                         code:ECONNREFUSED
                     userInfo:@{NSLocalizedDescriptionKey : @"The packet was dropped by usbmuxd."}];
          handler(nil, error);
          return;
        }
        NSAssert(bufferSize == [EDOUSBMuxUtil sizeOfPayloadSize],
                 @"Buffer size is different from the size field.");
        NSAssert(sizeof(packetLength) == [EDOUSBMuxUtil sizeOfPayloadSize],
                 @"PacketLength has different size from the size field.");
        memcpy((void *)&(packetLength), (const void *)buffer, bufferSize);

        // Read rest of the incoming usbmux packet
        size_t offset = [EDOUSBMuxUtil sizeOfPayloadSize];
        dispatch_io_read(
            self->_dispatchChannel, 0, packetLength - offset, self->_queue,
            ^(bool done, dispatch_data_t data, int error) {
              if (!done) {
                return;
              }

              if (error) {
                handler(nil, [[NSError alloc] initWithDomain:NSPOSIXErrorDomain
                                                        code:error
                                                    userInfo:nil]);
                return;
              }

              if (packetLength > kEDOPacketMaxPayloadSize) {
                handler(nil, [[NSError alloc] initWithDomain:EDODeviceErrorDomain
                                                        code:1
                                                    userInfo:@{
                                                      NSLocalizedDescriptionKey :
                                                          @"Received a packet that is too large"
                                                    }]);
                return;
              }

              dispatch_data_t totalData = dispatch_data_create_concat(sizeData, data);
              NSError *packetError;
              NSDictionary *payloadDict =
                  [EDOUSBMuxUtil payloadDictionaryFromPacketData:totalData error:&packetError];

              // Invoke completion handler
              handler(payloadDict, packetError);
            });
      });
}

- (void)sendPacket:(NSDictionary *)packet completion:(EDODevicePacketSentHandler)completion {
  NSError *error = nil;
  dispatch_data_t data = [EDOUSBMuxUtil createPacketDataWithPayload:packet error:&error];

  if (!data) {
    if (completion) {
      completion(error);
    }
  } else {
    dispatch_io_write(
        _dispatchChannel, 0, data, _queue, ^(bool done, dispatch_data_t data, int _errno) {
          if (!done) {
            return;
          }
          if (completion) {
            NSError *err = nil;
            if (_errno) {
              err = [[NSError alloc] initWithDomain:NSPOSIXErrorDomain code:_errno userInfo:nil];
            }
            completion(err);
          }
        });
  }
}

#pragma mark - Private

- (BOOL)openWithError:(NSError **)error {
  if (_dispatchChannel) {
    return YES;
  }

  // Create socket
  dispatch_fd_t fd = socket(AF_UNIX, SOCK_STREAM, 0);
  if (fd == -1) {
    if (error) {
      *error = [[NSError alloc] initWithDomain:NSPOSIXErrorDomain code:errno userInfo:nil];
    }
    return NO;
  }

  // prevent SIGPIPE
  int on = 1;
  setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &on, sizeof(on));

  // Connect socket
  struct sockaddr_un addr;
  addr.sun_family = AF_UNIX;
  strcpy(addr.sun_path, "/var/run/usbmuxd");
  socklen_t socklen = sizeof(addr);
  if (connect(fd, (struct sockaddr *)&addr, socklen) == -1) {
    if (error) {
      *error = [[NSError alloc] initWithDomain:NSPOSIXErrorDomain code:errno userInfo:nil];
    }
    return NO;
  }

  _dispatchChannel = dispatch_io_create(DISPATCH_IO_STREAM, fd, _queue, ^(int error) {
    if (error == 0) {
      close(fd);
    }
  });
  return _dispatchChannel != NULL;
}

@end
