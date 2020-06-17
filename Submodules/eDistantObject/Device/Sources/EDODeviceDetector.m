//
// Copyright 2018 Google Inc.
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

#import "Device/Sources/EDODeviceDetector.h"

#import "Device/Sources/EDODeviceChannel.h"
#import "Device/Sources/EDOUSBMuxUtil.h"

@interface EDODeviceDetector ()
/**
 *  The channel to communicate with usbmuxd. It is lazily loaded when listenWithBroadcastHandler:
 *  is called.
 */
@property(nonatomic) EDODeviceChannel *channel;
/** @c YES if the detector has already started to listen to broadcast. */
@property(readonly) BOOL started;

@end

@implementation EDODeviceDetector

- (BOOL)listenToBroadcastWithError:(NSError **)error
                    receiveHandler:(EDOBroadcastHandler)receiveHandler {
  __block NSError *resultError;
  EDODeviceChannel *deviceChannel;
  @synchronized(self) {
    if (!self.started) {
      deviceChannel = [EDODeviceChannel channelWithError:&resultError];
      self.channel = deviceChannel;
    } else {
      // Return @c NO if the detector is already listening to broadcast.
      return NO;
    }
  }

  __block BOOL success = NO;
  if (deviceChannel) {
    NSDictionary<NSString *, id> *packet = [EDOUSBMuxUtil listenPacket];
    // Synchronously send the listen packet and read response.
    dispatch_semaphore_t lock = dispatch_semaphore_create(0);
    [deviceChannel
        sendPacket:packet
        completion:^(NSError *packetSendError) {
          if (packetSendError) {
            resultError = packetSendError;
            dispatch_semaphore_signal(lock);
          } else {
            [deviceChannel
                receivePacketWithHandler:^(NSDictionary<NSString *, id> *packet, NSError *error) {
                  NSError *rootError = error ?: [EDOUSBMuxUtil errorFromPlistResponsePacket:packet];
                  if (rootError) {
                    resultError = rootError;
                  } else {
                    NSAssert([packet[kEDOMessageTypeKey] isEqualToString:kEDOPlistPacketTypeResult],
                             @"Invalid result packet type.");
                    success = YES;
                  }
                  dispatch_semaphore_signal(lock);
                }];
          }
        }];
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    if (success) {
      // Schedule read recursively to constantly listen to broadcast event.
      [self edo_scheduleReadBroadcastPacketWithHandler:receiveHandler];
    }
  }
  if (resultError) {
    NSLog(@"Failed to listen to broadcast: %@", resultError);
    if (error) {
      *error = resultError;
    }
  }
  return success;
}

- (void)cancel {
  @synchronized(self) {
    self.channel = nil;
  }
}

- (BOOL)started {
  return self.channel != nil;
}

#pragma mark - Private

- (void)edo_scheduleReadBroadcastPacketWithHandler:(EDOBroadcastHandler)handler {
  __weak EDODeviceDetector *weakSelf = self;
  [_channel receivePacketWithHandler:^(NSDictionary<NSString *, id> *packet, NSError *error) {
    // Interpret the broadcast packet we just received
    if (handler) {
      handler(packet, error);
    }

    // Re-schedule reading another incoming broadcast packet
    if (!error) {
      [weakSelf edo_scheduleReadBroadcastPacketWithHandler:handler];
    }
  }];
}

@end
