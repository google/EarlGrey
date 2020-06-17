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

#import "Channel/Sources/EDOChannel.h"

NS_ASSUME_NONNULL_BEGIN

@class EDOSocket;

/**
 *  The channel implemented using dispatch I/O.
 *
 *  It uses dispatch I/O API to process the non-blocking I/O operations. The channel manages a
 *  header frame to ensure the integrity of each data block received. If two consecutive receiving
 *  blocks are scheduled at once, it may interrupt how the channel interpret the header frame. The
 *  caller shall schedule another receiving callback only after the previous one is completed.
 *
 *  TODO(haowoo): Rename this to EDODispatchChannel as it is a wrapper around dispatch_io_t.
 */
@interface EDOSocketChannel : NSObject <EDOChannel>

/** Convenience creation method. See -initWithSocket:. */
+ (nullable instancetype)channelWithSocket:(EDOSocket *)socket;

/**
 *  Initializes a channel with the established socket.
 *
 *  @param socket The established socket from the @c EDOSocketConnectedBlock callback.
 *  @return An instance of @c EDOSocketChannel on success; @c nil if the @c socket is invalid.
 */
- (nullable instancetype)initWithSocket:(EDOSocket *)socket;

/**
 *  Initializes a channel with the given dispatch I/O channel.
 *
 *  @param channel The established channel.
 *  @return An instance of @c EDOSocketChannel.
 */
- (instancetype)initWithDispatchIO:(dispatch_io_t)channel;

@end

NS_ASSUME_NONNULL_END
