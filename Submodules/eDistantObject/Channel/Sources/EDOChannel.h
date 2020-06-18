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

NS_ASSUME_NONNULL_BEGIN

/**
 *  @protocol EDOChannel
 *  The protocol that channels must conform to.
 *
 *  The channel is an asynchronous bi-directional data channel where it reads and writes. Each
 *  channel assigns one remote endpoint to read from or write to.
 */
@protocol EDOChannel <NSObject>

/**
 *  @typedef EDOChannelReceiveHandler
 *  The type handlers handling how the data is received.
 *
 *  When the channel is closed, the handler is dispatched with both the @c data and @c error being
 *  nil. In the case of errors, the @c data is nil and the @c error parameter holding the reason for
 *  failure.
 *  TODO(haowoo): define proper error domains and codes.
 *
 *  @param channel The channel where the data is received.
 *  @param data    The data being received. The channel is closed when it's nil.
 *  @param error   The error when it fails to receive data.
 */
typedef void (^EDOChannelReceiveHandler)(id<EDOChannel> channel, NSData *_Nullable data,
                                         NSError *_Nullable error);

/**
 *  @typedef EDOChannelSentHandler
 *  The type handlers handling after the data is sent.
 *
 *  TODO(haowoo): define proper error domains and codes.
 *
 *  @param channel The channel where the data is sent to.
 *  @param error   The error object if the data is failed to send.
 */
typedef void (^EDOChannelSentHandler)(id<EDOChannel> channel, NSError *_Nullable error);

/**
 *  Check if the channel is valid and available to send and receive data.
 *
 *  It is possible even if @c valid returns true, you will still get the error when sending the
 *  data, because the other end of channel can be closed abruptly and the transfer over network can
 *  error out for various other reasons.
 */
@property(readonly, nonatomic, getter=isValid) BOOL valid;

/**
 *  Asynchronously send the data to this channel.
 *
 *  It will dispatch the completion block asynchronously after it is done or errors. The @c handler
 *  is dispatched in the same order of each invocation of this method. If multiple threads invoke
 *  this method on the same object, it will be guaranteed that the completion block is executed in
 *  the same order as originally sendData is invoked.
 *
 *  @param data    The data being sent.
 *  @param handler The completion block.
 *  @remark Once it starts to send the data, it will retain itself until it completes or errors.
 */
- (void)sendData:(NSData *)data withCompletionHandler:(EDOChannelSentHandler _Nullable)handler;

/**
 *  Schedule the block for the next received data to process.
 *
 *  When the new data is received, the handler will be dispatched. (The dispatch queue will be up to
 *  the implementation). If the data is received without scheduling any block, it is up to the
 *  implementation to ignore or buffer it locally, i.e. TCP socket may allow some system buffer to
 *  temporarily cache the data. For the request/response style communication, it is better to call
 *  this in the sentCompletion block to avoid race condition as the scheduled receive block may not
 *  be in the same order of the @c sendData:withCompletionHandler.
 *
 *  @param handler The handler to be dispatched when the data is received.
 *  @remark Once it schedules the block to receive data, it will retain itself until the data is
 *          received or it becomes invalid by calling @c invalidate or it detects the other end
 *          closes the channel.
 */
- (void)receiveDataWithHandler:(EDOChannelReceiveHandler _Nullable)handler;

/**
 *  Invalidate this channel.
 *
 *  After invalidation, no data will be sent or received. The channel is safely closed and it
 *  should not be used any longer. It is possible to invalidate the channel when there is data being
 *  transferred. It is the user's responsibilities to make sure the transfer is complete before the
 *  channel is closed.
 */
- (void)invalidate;

@end

NS_ASSUME_NONNULL_END
