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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class EDOSocket;
@class EDOSocketPort;

/**
 *  @typedef EDOSocketConnectedBlock
 *  The completion block for when the connection is established.
 *
 *  @param socket     The established socket, it is nil if any error occurs.
 *  @param error      The error why the socket fails to create if there is any.
 */
typedef void (^EDOSocketConnectedBlock)(EDOSocket *_Nullable socket, NSError *_Nullable error);

/**
 *  The opaque socket wrapper used to create a socket channel.
 *
 *  User should not inspect this in any manner, only use it to create a @c EDOSocketChannel. User
 *  may only create one channel from one socket, and the channel will take over the ownership of the
 *  underlying socket and user won't be able to use it to create any other channels. The @c
 *  EDOSocket becomes invalid after.
 */
@interface EDOSocket : NSObject

/** The underlying socket file descriptor. */
@property(nonatomic, readonly) dispatch_fd_t socket;

/** Whether the socket is valid. */
@property(nonatomic, readonly) BOOL valid;

/** The socket port and address this socket is bound to. */
@property(nonatomic, readonly) EDOSocketPort *socketPort;

/**
 *  Connects to localhost on the given port asynchronously.
 *
 *  @param port  The port number.
 *  @param queue The queue where the completion block will be dispatched to. If @c nil, it creates a
 *               serial queue.
 *  @param block The block to be invoked after the connection is established.
 */
+ (void)connectWithTCPPort:(UInt16)port
                     queue:(dispatch_queue_t _Nullable)queue
            connectedBlock:(EDOSocketConnectedBlock _Nullable)block;

/**
 *  Creates a socket that connects to the given port synchronously.
 *
 *  @param port  The port number.
 *  @param queue The queue where the completion block will be dispatched to. If @c nil, it creates a
 *               serial queue.
 *  @param error The error if it fails to connect.
 *  @return An instance of @c EDOSocket that connects to the given port, @c nil if failed.
 */
+ (nullable instancetype)socketWithTCPPort:(UInt16)port
                                     queue:(dispatch_queue_t _Nullable)queue
                                     error:(NSError *_Nullable *_Nullable)error;

/**
 *  Init with a socket descriptor.
 *
 *  It will taking over the ownership of socket, double release or close the socket will result in a
 *  potential crash.
 *
 *  @param socket The socket file descriptor.
 */
- (instancetype)initWithSocket:(dispatch_fd_t)socket NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/** @see [EDOSocket initWithSocket:] */
+ (instancetype)socketWithSocket:(dispatch_fd_t)socket;

/**
 *  Release the ownership of the underlying socket and return it.
 *
 *  It is not guaranteed to return a valid socket; it returns what the underlying socket is and
 *  reset it to -1, the invalid socket descriptor.
 */
- (dispatch_fd_t)releaseSocket;

/**
 *  Release the ownership of the underlying socket and return as a @c dispatch_io_t.
 *
 *  @return An instance of @c dispatch_ic_t if the underlying socket is valid, @c nil otherwise.
 */
- (nullable dispatch_io_t)releaseAsDispatchIO;

/** Invalidate by closing its associated socket file descriptor. */
- (void)invalidate;

/**
 *  Create a @c EDOSocket listening on the given port.
 *
 *  When a new incoming connection is accepted, the block with the new socket will be dispatched
 *  to the queue. The connection may drop if the user ignores and doesn't keep the socket or
 *  create the EDOSocketChannel. It is user's responsibility to track all the incoming connections.
 *
 *  @param port  The port number. If 0, an available port will be assigned.
 *  @param queue The dispatch queue that the block will be dispatched to. If @c nil, it creates a
 *               new concurrent queue.
 *  @param block The block will be dispatched when there is a new connection that is about to be
 *               established.
 *
 *  @return The socket connection that listens on the port, invalidating or releasing it will
 *          effectively reject any new requests, but the already established connections will stay
 *          intact as they are maintained in a different endpoint and @c EDOSocketChannel.
 */
+ (EDOSocket *_Nullable)listenWithTCPPort:(UInt16)port
                                    queue:(dispatch_queue_t _Nullable)queue
                           connectedBlock:(EDOSocketConnectedBlock _Nullable)block;

@end

NS_ASSUME_NONNULL_END
