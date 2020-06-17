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

#import "Device/Sources/EDODeviceConnector.h"

#import "Device/Sources/EDODeviceChannel.h"
#import "Device/Sources/EDODeviceDetector.h"
#import "Device/Sources/EDOUSBMuxUtil.h"

NSString *const EDODeviceDidAttachNotification = @"EDODeviceDidAttachNotification";
NSString *const EDODeviceDidDetachNotification = @"EDODeviceDidDetachNotification";

NSString *const EDODeviceSerialKey = @"EDODeviceSerialKey";
NSString *const EDODeviceIDKey = @"EDODeviceIDKey";

/** Timeout for connecting to device. */
static const int64_t kDeviceConnectTimeout = 5 * NSEC_PER_SEC;
/** Seconds to detect connected devices when connector starts. */
static const int64_t kDeviceDetectTime = 2;

@interface EDODeviceConnector ()
/** The detector to detect iOS device attachment/detachment events. */
@property(nonatomic) EDODeviceDetector *detector;
/** The connected device info of mappings from device serial strings to auto-assigned device IDs. */
@property(nonatomic) NSMutableDictionary *deviceInfo;
@end

@implementation EDODeviceConnector {
  // The dispatch queue to guarantee thread-safety of the connector. @c deviceInfo should be guarded
  // by this queue.
  dispatch_queue_t _syncQueue;
}

- (instancetype)initInternal {
  self = [super init];
  if (self) {
    _deviceInfo = [[NSMutableDictionary alloc] init];
    _syncQueue = dispatch_queue_create("com.google.edo.connectorSync", DISPATCH_QUEUE_SERIAL);
    _detector = [[EDODeviceDetector alloc] init];
  }
  return self;
}

+ (EDODeviceConnector *)sharedConnector {
  static EDODeviceConnector *sharedConnector;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedConnector = [[EDODeviceConnector alloc] initInternal];
  });
  return sharedConnector;
}

- (NSArray<NSString *> *)connectedDevices {
  BOOL started = [self startListening];
  if (started) {
    // Wait for a short time to detect all connected devices when listening just starts.
    sleep(kDeviceDetectTime);
  }
  __block NSArray *result;
  dispatch_sync(_syncQueue, ^{
    result = [self.deviceInfo.allKeys copy];
  });
  return result;
}

- (dispatch_io_t)connectToDevice:(NSString *)deviceSerial
                          onPort:(UInt16)port
                           error:(NSError **)error {
  if (![self.connectedDevices containsObject:deviceSerial]) {
    if (error) {
      // TODO(ynzhang): add proper error code for better error handling.
      *error = [NSError errorWithDomain:EDODeviceErrorDomain code:0 userInfo:nil];
    }
    NSLog(@"Device %@ is not detected.", deviceSerial);
    return NULL;
  }
  NSNumber *deviceID = _deviceInfo[deviceSerial];

  NSDictionary *packet = [EDOUSBMuxUtil connectPacketWithDeviceID:deviceID port:port];
  __block NSError *connectError;
  EDODeviceChannel *channel = [EDODeviceChannel channelWithError:&connectError];
  if (channel) {
    dispatch_semaphore_t lock = dispatch_semaphore_create(0);
    [channel
        sendPacket:packet
        completion:^(NSError *packetError) {
          if (packetError) {
            connectError = packetError;
            dispatch_semaphore_signal(lock);
          } else {
            EDODevicePacketReceivedHandler handler = ^(
                NSDictionary<NSString *, id> *_Nullable packet, NSError *_Nullable packetError) {
              if (packetError) {
                connectError = packetError;
              } else {
                NSAssert([packet[kEDOMessageTypeKey] isEqualToString:kEDOPlistPacketTypeResult],
                         @"Unexpected response packet type.");
                connectError = [EDOUSBMuxUtil errorFromPlistResponsePacket:packet];
              }
              dispatch_semaphore_signal(lock);
            };
            [channel receivePacketWithHandler:handler];
          }
        }];
    dispatch_semaphore_wait(lock, dispatch_time(DISPATCH_TIME_NOW, kDeviceConnectTimeout));
  }

  if (error) {
    *error = connectError;
  }
  return connectError ? NULL : [channel releaseAsDispatchIO];
}

#pragma mark - Private

- (BOOL)startListening {
  return [self.detector
      listenToBroadcastWithError:nil
                  receiveHandler:^(NSDictionary *packet, NSError *error) {
                    if (error) {
                      [self.detector cancel];
                      NSLog(@"Stopped listening to broadcast from usbmuxd: %@", error);
                    }
                    [self handleBroadcastPacket:packet];
                  }];
}

- (void)handleBroadcastPacket:(NSDictionary *)packet {
  NSString *messageType = [packet objectForKey:kEDOMessageTypeKey];

  if ([messageType isEqualToString:kEDOMessageTypeAttachedKey]) {
    NSNumber *deviceID = packet[kEDOMessageDeviceIDKey];
    NSString *serialNumber = packet[kEDOMessagePropertiesKey][kEDOMessageSerialNumberKey];
    dispatch_sync(_syncQueue, ^{
      [self.deviceInfo setObject:deviceID forKey:serialNumber];
    });
    NSDictionary *userInfo = @{EDODeviceIDKey : deviceID, EDODeviceSerialKey : serialNumber};
    [[NSNotificationCenter defaultCenter] postNotificationName:EDODeviceDidAttachNotification
                                                        object:self
                                                      userInfo:userInfo];
  } else if ([messageType isEqualToString:kEDOMessageTypeDetachedKey]) {
    NSNumber *deviceID = packet[kEDOMessageDeviceIDKey];
    NSMutableArray *keysToRemove = [[NSMutableArray alloc] init];
    dispatch_sync(_syncQueue, ^{
      for (NSString *serialNumberString in self.deviceInfo) {
        if ([self.deviceInfo[serialNumberString] isEqualToNumber:deviceID]) {
          [keysToRemove addObject:serialNumberString];
        }
      }
      [self.deviceInfo removeObjectsForKeys:keysToRemove];
    });
    NSDictionary *userInfo = @{EDODeviceIDKey : deviceID};
    [[NSNotificationCenter defaultCenter] postNotificationName:EDODeviceDidDetachNotification
                                                        object:self
                                                      userInfo:userInfo];
  } else {
    NSLog(@"Warning: Unhandled broadcast message: %@", packet);
  }
}

@end
