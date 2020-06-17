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

#import "Channel/Sources/EDOChannelErrors.h"

NS_ASSUME_NONNULL_BEGIN

@class EDOHostPort;
@protocol EDOChannel;

/**
 *  @typedef EDOForwarderErrorHandler
 *  The handler block to invoke when the forwarder encounters an error.
 *
 *  @param errorCode The error code defined in @c EDOForwarderError.
 */
typedef void (^EDOForwarderErrorHandler)(EDOForwarderError errorCode);

/**
 *  @typedef EDOMultiplexerConnectBlock
 *  The block to connect to the multiplexer.
 *
 *  @return The channel connecting to the multiplexer.
 */
typedef _Nullable id<EDOChannel> (^EDOMultiplexerConnectBlock)(void);

/**
 *  @typedef EDOHostChannelConnectBlock
 *  The block to connect to the host by the given port.
 *
 *  @param port The port to connect to.
 *  @return The channel connecting to the host by the @c port.
 */
typedef _Nullable id<EDOChannel> (^EDOHostChannelConnectBlock)(EDOHostPort *port);

/**
 *  The forwarder that connects to the multiplexer and forwards the connection.
 *
 *  The forwarder connects to the multiplexer and waits on it. Once received the host port, it
 *  connects to the host given by the port, and starts to forward data between the multiplexer
 *  and the connected host.
 */
@interface EDOChannelForwarder : NSObject

- (instancetype)init NS_UNAVAILABLE;

/**
 *  Initializes the forwarder.
 *
 *  @param connectBlock     The block that the forwarder uses to connect to the multiplexer.
 *  @param hostConnectBlock The block that the forwarder uses to connect to the host.
 */
- (instancetype)initWithConnectBlock:(EDOMultiplexerConnectBlock)connectBlock
                    hostConnectBlock:(EDOHostChannelConnectBlock)hostConnectBlock
    NS_DESIGNATED_INITIALIZER;

/**
 *  Starts to connect the multiplexer and ready to forward.
 *
 *  @note  This will first attempt to close any existing connection it maintains first.
 *
 *  @param errorHandler The handler to invoke on errors. It will not be invoked when connecting to
 *                      the multiplexer.
 *  @return The identifier data for the connected multiplexer on success; @c nil if failed to
 * connect or handshake.
 */
- (nullable NSData *)startWithErrorHandler:(EDOForwarderErrorHandler)errorHandler;

/** Stops forwarding by closing the channels. */
- (void)stop;

@end

NS_ASSUME_NONNULL_END
