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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class EDOHostPort;
@protocol EDOChannel;

/**
 *  The @c EDOChannelPool manages reusable channels that are already connected and ready to send and
 *  receive data.
 *
 *  @c EDOSocketChannel objects that are available can be stored here for future reuse. Reuse will
 *  help reduce the amount to time spent rebuilding and reestablishing a connection. Channels are
 *  clustered with the port they are connected to.
 */
@interface EDOChannelPool : NSObject

/** The singleton of @c EDOChannelPool. */
@property(class, readonly) EDOChannelPool *sharedChannelPool;

/**
 *  A port for clients to accept connection, and receive host name to register as service. This port
 *  will lazily create a listen socket when accessed.
 */
@property(readonly) UInt16 serviceConnectionPort;

/**
 *  Fetches an already-connected channel from the pool, keyed by the host @c port.
 *
 *  @note If there is no channel for the host port, it will attempt to create one by connecting
 *        to the host. In case of real devices, it waits for the remote to be connected because the
 *        device cannot initiate the connection to the Mac host via usbmuxd. It will time out if
 *        there is no connection set up and return @c nil.
 *
 *  @return The channel that's ready to send and receive data, or @c nil if there is an error.
 */
- (nullable id<EDOChannel>)channelWithPort:(EDOHostPort *)port
                                     error:(NSError *_Nullable *_Nullable)error;

/**
 *  Adds the @c channel to the pool.
 *
 *  @param channel The channel being added to be reused.
 *  @param port    The port the channel connects to as the key.
 */
- (void)addChannel:(id<EDOChannel>)channel forPort:(EDOHostPort *)port;

/**
 *  Removes all the channels by the given host port.
 *
 *  @note This should be called when the service the host port belongs to is closed.
 */
- (void)removeChannelsWithPort:(EDOHostPort *)port;

/** Gets the number of available channels in the pool for the given host port. */
- (NSUInteger)countChannelsWithPort:(EDOHostPort *)port;

@end

NS_ASSUME_NONNULL_END
