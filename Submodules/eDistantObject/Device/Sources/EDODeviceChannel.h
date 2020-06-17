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

/**
 *  @typedef EDODevicePacketReceivedHandler
 *  The type handlers handling how the device packet is received.
 *
 *  When the channel is closed, the handler is dispatched with both the @c data and @c error being
 *  nil. In the case of errors, the @c packet is nil and the @c error parameter holding the reason
 *  for failure.
 *
 *  @param packet The packet being received. The channel is closed when it's nil.
 *  @param error  The error when it fails to receive data.
 */
typedef void (^EDODevicePacketReceivedHandler)(NSDictionary<NSString *, id> *_Nullable packet,
                                               NSError *_Nullable error);

/**
 *  @typedef EDODevicePacketSentHandler
 *  The type handlers handling after the packet is sent.
 *
 *  @param error The error object if the packet is failed to send.
 */
typedef void (^EDODevicePacketSentHandler)(NSError *_Nullable error);

/**
 *  Represents a channel of communication between a Mac process and usbmuxd.
 **/
@interface EDODeviceChannel : NSObject

/**
 *  Creates a channel connected to usbmuxd. If any problem happens, @c nil will be returned and
 *  error details will be saved in @c error if not @c nil.
 **/
+ (instancetype)channelWithError:(NSError *_Nullable *_Nullable)error;

- (instancetype)init NS_UNAVAILABLE;

/**
 *  Releases the ownership of the socket descriptor and returns it as a dispatch I/O.
 *
 *  After calling this, the underlying channel will be released and the device channel will not be
 *  available anymore. Usually it will be used after successfully sending a connect message to a
 *  port on an iOS device.
 *
 *  @return An instance of @c dispatch_io_t that's bound to underlying device socket.
 */
- (dispatch_io_t)releaseAsDispatchIO;

/** Receives packet from usbmuxd asynchronously. */
- (void)receivePacketWithHandler:(EDODevicePacketReceivedHandler _Nullable)handler;

/** Sends packet to usbmuxd asynchronously. */
- (void)sendPacket:(NSDictionary *)packet
        completion:(EDODevicePacketSentHandler _Nullable)completion;

@end

NS_ASSUME_NONNULL_END
