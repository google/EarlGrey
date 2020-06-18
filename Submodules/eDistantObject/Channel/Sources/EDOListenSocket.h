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

#import "Channel/Sources/EDOSocket.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  The socket that listens on the given port.
 *
 *  It keeps track of the associated socket descriptor like @c EDOSocket, but it doesn't hold its
 *  lifecycle as it will create a dispatch source to manage it. The block will be dispatched when
 *  there is an incoming connection.
 */
@interface EDOListenSocket : EDOSocket

- (instancetype)initWithSocket:(dispatch_fd_t)socket NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)endpointWithSocket:(dispatch_fd_t)socket NS_UNAVAILABLE;

// The user won't be able to release the socket as the socket is managed by the dispatch source.
- (void)releaseSocket NS_UNAVAILABLE;

/**
 *  Create a listen socket.
 *
 *  @param socketFD The already created and bound socket file descriptor.
 *  @param block    The block to be dispatched when there is an incoming connection.
 *
 *  @return An instance of @c EDOListenSocket.
 *  @remark The block will be dispatched to its internal serial queue. Blocking it will suspend the
 *          following requests to be proccessed.
 */
+ (EDOListenSocket *_Nullable)listenSocketWithSocket:(dispatch_fd_t)socketFD
                                      connectedBlock:(EDOSocketConnectedBlock)block;

@end

NS_ASSUME_NONNULL_END
