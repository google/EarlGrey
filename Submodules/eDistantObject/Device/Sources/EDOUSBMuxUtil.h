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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#ifndef EDOUSBMuxUtil_h
#define EDOUSBMuxUtil_h

// References about usbmuxd packet can be found at https://www.theiphonewiki.com/wiki/Usbmux.

// The error domain of device error.
extern NSString *const EDODeviceErrorDomain;

// Message type of response from usbmux.
extern NSString *const kEDOPlistPacketTypeResult;

// Keys of the data in the broadcast message.
extern NSString *const kEDOMessageDeviceIDKey;
extern NSString *const kEDOMessagePropertiesKey;
extern NSString *const kEDOMessageSerialNumberKey;
extern NSString *const kEDOMessageTypeAttachedKey;
extern NSString *const kEDOMessageTypeKey;
extern NSString *const kEDOMessageTypeDetachedKey;

// The max value of the packet payload size.
extern const uint32_t kEDOPacketMaxPayloadSize;

#endif /* EDOUSBMuxUtil_h */

/** Util class of usbmux about payload and packet. */
@interface EDOUSBMuxUtil : NSObject

/** Creates a listen packet to send to usbmux. */
+ (NSDictionary *)listenPacket;

/** Creates a connect packet to send to usbmux with device id and port number. */
+ (NSDictionary *)connectPacketWithDeviceID:(NSNumber *)deviceID port:(UInt16)port;

/** Returns the number of bytes of the first 'size' field of the packet struct. */
+ (size_t)sizeOfPayloadSize;

/** Creates a @c dispatch_data_t object with given payload. */
+ (dispatch_data_t)createPacketDataWithPayload:(NSDictionary<NSString *, id> *)payload
                                         error:(NSError **)error;

/** Extracts the payload dictionary from the complete packet data. */
+ (NSDictionary *)payloadDictionaryFromPacketData:(dispatch_data_t)data error:(NSError **)error;

/**
 *  Generates an error from the response packet from usbmuxd. Returns @c nil if no error is present
 *  in the response.
 */
+ (NSError *)errorFromPlistResponsePacket:(NSDictionary<NSString *, id> *)packet;

@end

NS_ASSUME_NONNULL_END
