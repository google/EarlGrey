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

@protocol EDOChannel;
@class EDOHostPort;

/**
 *  The multiplexer forwards the socket.
 *
 *  The multiplexer is started to listen on a given port, and the forwarder connects to it
 *  proactively to establish a channel. The forwarder, sitting on a different process or machine,
 *  receives the @c EDOHostPort to connect to the destination, then the forwarded channel is
 *  established.
 *
 *  This is used when the client is not able to connect to another machine but needs others to
 *  connect back. For example, the application on the iOS devices won't be able to connect a port
 *  on the host machine via USB, and it requires the host machine to connect back using usbmuxd.
 */
@interface EDOChannelMultiplexer : NSObject

/** The port that the multiplexer is listening on. */
@property(readonly, nonatomic) EDOHostPort *port;

/** The number of channels that are set up with the forwarder and ready to connect. */
@property(readonly) NSUInteger numberOfChannels;

/**
 *  Starts the multiplexer on the given @c port.
 *
 *  The multiplexer starts to listen on the given port, waiting for the forwarder to connect. Once
 *  a forwarder successfully connects, they do a simple handshake and exchange the deviceIdentifier
 *  for the future identification. The connected forwarder will be queued for the client to use.
 *
 *  @param port   The port to listen on. Currently it only supports the local port number. If @c
 *                nil, it will pick an available number.
 *  @param error  The error if failing to start. Currently no error is reported and will always be
 *                @c nil.
 *  @return @c YES if started successfully. It doesn't generate the error yet when failing to start.
 */
- (BOOL)start:(nullable EDOHostPort *)port error:(NSError *_Nullable *_Nullable)error;

/** Stops the multiplexer. */
- (void)stop;

/**
 *  Fetches a channel from the multiplexer.
 *
 *  The multiplexer picks a channel connected with the forwarder, and sends @c hostPort to ask the
 *  forwarder to connect the given port, once connected, The forwarder ACK's with the
 *  deviceIdentification handshaked earlier. If the frowarder can't connect to the port, it will
 *  fail. Currently there is no error that will be sent from the forwarder. The channel shall close
 *  immediately. On success, the channel will start to forward data, and can be used as a
 *  regular channel connecting to the @c hostPort.
 *
 *  @param hostPort The destination the channel connects to.
 *  @param timeout  The timeout before an available channel is returned.
 *  @param error    The error if the channel fails. Currently no error is reported.
 *  @return The connected channel that's ready to send and receive data.
 */
- (id<EDOChannel>)channelWithPort:(EDOHostPort *)hostPort
                          timeout:(NSTimeInterval)timeout
                            error:(NSError *_Nullable *_Nullable)error;

@end

NS_ASSUME_NONNULL_END
