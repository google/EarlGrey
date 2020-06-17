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

#import "Device/Sources/EDOUSBMuxUtil.h"

// The types of usbmux message.
NSString *const kEDOPlistPacketTypeConnect = @"Connect";
NSString *const kEDOPlistPacketTypeListen = @"Listen";
NSString *const kEDOPlistPacketTypeResult = @"Result";

NSString *const kEDOMessageDeviceIDKey = @"DeviceID";
NSString *const kEDOMessagePropertiesKey = @"Properties";
NSString *const kEDOMessageSerialNumberKey = @"SerialNumber";
NSString *const kEDOMessageTypeAttachedKey = @"Attached";
NSString *const kEDOMessageTypeDetachedKey = @"Detached";
NSString *const kEDOMessageTypeKey = @"MessageType";

NSString *const EDODeviceErrorDomain = @"EDODeviceError";

// The code of usbmuxd response.
typedef NS_ENUM(uint32_t, EDOUSBMuxReplyCode) {
  USBMuxReplyCodeOK = 0,
  USBMuxReplyCodeBadCommand = 1,
  USBMuxReplyCodeBadDevice = 2,
  USBMuxReplyCodeConnectionRefused = 3,
  // ? = 4,
  // ? = 5,
  USBMuxReplyCodeBadVersion = 6,
};

// The code of usbmuxd packet type.
typedef NS_ENUM(uint32_t, EDOUSBMuxPacketType) {
  USBMuxPacketTypeResult = 1,
  USBMuxPacketTypeConnect = 2,
  USBMuxPacketTypeListen = 3,
  USBMuxPacketTypeDeviceAdd = 4,
  USBMuxPacketTypeDeviceRemove = 5,
  // ? = 6,
  // ? = 7,
  USBMuxPacketTypePlistPayload = 8,
};

// The code of usbmuxd protocol type. eDO is only using plist.
typedef NS_ENUM(uint32_t, EDOUSBMuxPacketProtocol) {
  USBMuxPacketProtocolBinary = 0,
  USBMuxPacketProtocolPlist = 1,
};

/** The struct of a usbmuxd packet. */
typedef struct EDOUSBMuxPacket {
  uint32_t size;
  EDOUSBMuxPacketProtocol protocol;
  EDOUSBMuxPacketType type;
  uint32_t tag;
  char data[0];
} __attribute__((__packed__)) EDOUSBMuxPacket_t;

const uint32_t kEDOPacketMaxPayloadSize = UINT32_MAX - (uint32_t)sizeof(EDOUSBMuxPacket_t);

@implementation EDOUSBMuxUtil

+ (NSDictionary *)listenPacket {
  return [self packetDictionaryWithMessageType:kEDOPlistPacketTypeListen payload:nil];
}

+ (NSDictionary *)connectPacketWithDeviceID:(NSNumber *)deviceID port:(UInt16)port {
  // Need to transform to big endian for usbmuxd.
  UInt16 bigEndianPort = CFSwapInt16HostToBig(port);

  return [self packetDictionaryWithMessageType:kEDOPlistPacketTypeConnect
                                       payload:@{
                                         @"DeviceID" : deviceID,
                                         @"PortNumber" : [NSNumber numberWithInt:bigEndianPort]
                                       }];
}

+ (size_t)sizeOfPayloadSize {
  static EDOUSBMuxPacket_t refPacket;
  return sizeof(refPacket.size);
}

+ (dispatch_data_t)createPacketDataWithPayload:(NSDictionary<NSString *, id> *)payload
                                         error:(NSError **)error {
  NSData *payloadData =
      [NSPropertyListSerialization dataWithPropertyList:payload
                                                 format:NSPropertyListXMLFormat_v1_0
                                                options:0
                                                  error:error];
  if (!payload) {
    return nil;
  }
  uint32_t payloadSize = (uint32_t)(payloadData ? payloadData.length : 0);
  assert(payloadSize <= kEDOPacketMaxPayloadSize);
  uint32_t packetSize = sizeof(EDOUSBMuxPacket_t) + payloadSize;
  EDOUSBMuxPacket_t *packet = malloc(packetSize);
  memset(packet, 0, sizeof(EDOUSBMuxPacket_t));
  packet->size = packetSize;

  packet->protocol = USBMuxPacketProtocolPlist;
  packet->type = USBMuxPacketTypePlistPayload;

  if (payloadData && payloadSize) {
    const void *payloadBytes = payloadData ? payloadData.bytes : NULL;
    memcpy((void *)packet->data, payloadBytes, (uint32_t)payloadSize);
  }
  dispatch_queue_t backgroundQueue = dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0);
  dispatch_data_t data =
      dispatch_data_create((const void *)packet, packet->size, backgroundQueue, ^{
        // Free packet when data is freed
        free(packet);
      });
  return data;
}

+ (NSDictionary *)payloadDictionaryFromPacketData:(dispatch_data_t)data error:(NSError **)error {
  // Copy read bytes onto our usbmux_packet_t
  EDOUSBMuxPacket_t *packet = NULL;
  size_t buffer_size = 0;
  NS_VALID_UNTIL_END_OF_SCOPE dispatch_data_t map_data =
      dispatch_data_create_map(data, (const void **)&packet, &buffer_size);
  assert(buffer_size == (size_t)(packet->size));

  NSDictionary *dict = nil;
  NSError *packetError;
  if ([self validatePacket:packet error:&packetError]) {
    // Try to decode any payload as plist

    uint32_t payloadSize = [self payloadSizeFromPacket:packet];
    if (payloadSize > 0) {
      dict = [NSPropertyListSerialization
          propertyListWithData:[NSData dataWithBytesNoCopy:(void *)packet->data
                                                    length:payloadSize
                                              freeWhenDone:NO]
                       options:NSPropertyListImmutable
                        format:NULL
                         error:&packetError];
    }
  }
  if (error) {
    *error = packetError;
  }
  return dict;
}

+ (NSError *)errorFromPlistResponsePacket:(NSDictionary<NSString *, id> *)packet {
  NSNumber *number = [packet objectForKey:@"Number"];
  if (number) {
    EDOUSBMuxReplyCode replyCode = (EDOUSBMuxReplyCode)number.integerValue;
    if (replyCode != 0) {
      NSString *errmessage = @"Unspecified error";
      switch (replyCode) {
        case USBMuxReplyCodeBadCommand:
          errmessage = @"illegal command";
          break;
        case USBMuxReplyCodeBadDevice:
          errmessage = @"unknown device";
          break;
        case USBMuxReplyCodeConnectionRefused:
          errmessage = @"connection refused";
          break;
        case USBMuxReplyCodeBadVersion:
          errmessage = @"invalid version";
          break;
        default:
          break;
      }
      return [NSError errorWithDomain:EDODeviceErrorDomain
                                 code:replyCode
                             userInfo:@{NSLocalizedDescriptionKey : errmessage}];
    }
  }
  return nil;
}

#pragma mark - Private

/**
 *  Creates a packet with given @c messageType and @c payload.
 *
 *  @param messageType The type of message usbmuxd accepts. See @c EDOUSBMuxUtil.h for all
 *                     available types.
 *  @param payload     The payload sent to usbmuxd. The content depends on the type of message.
 *
 *  @return The data of the packet to send to usbmuxd.
 */
+ (NSDictionary *)packetDictionaryWithMessageType:(NSString *)messageType
                                          payload:(NSDictionary<NSString *, id> *)payload {
  NSDictionary *packet = nil;

  static NSString *bundleName = nil;
  static NSString *bundleVersion = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSDictionary *infoDict = [NSBundle mainBundle].infoDictionary;
    if (infoDict) {
      bundleName = infoDict[@"CFBundleName"];
      bundleVersion = [infoDict[@"CFBundleVersion"] description];
    }
  });

  if (bundleName) {
    packet = @{
      kEDOMessageTypeKey : messageType,
      @"ProgName" : bundleName,
      @"ClientVersionString" : bundleVersion
    };
  } else {
    packet = @{kEDOMessageTypeKey : messageType};
  }

  if (payload) {
    NSMutableDictionary<NSString *, id> *mpacket =
        [NSMutableDictionary dictionaryWithDictionary:payload];
    [mpacket addEntriesFromDictionary:packet];
    packet = mpacket;
  }

  return packet;
}

+ (BOOL)validatePacket:(EDOUSBMuxPacket_t *)packet error:(NSError **)error {
  // We only support plist protocol
  if (packet->protocol != USBMuxPacketProtocolPlist) {
    *error =
        [NSError errorWithDomain:EDODeviceErrorDomain
                            code:0
                        userInfo:@{NSLocalizedDescriptionKey : @"Unexpected package protocol"}];
    return NO;
  }

  // Only one type of packet in the plist protocol
  if (packet->type != USBMuxPacketTypePlistPayload) {
    *error = [NSError errorWithDomain:EDODeviceErrorDomain
                                 code:0
                             userInfo:@{NSLocalizedDescriptionKey : @"Unexpected package type"}];
    return NO;
  }
  return YES;
}

+ (uint32_t)payloadSizeFromPacket:(EDOUSBMuxPacket_t *)packet {
  return packet->size - sizeof(EDOUSBMuxPacket_t);
}

@end
