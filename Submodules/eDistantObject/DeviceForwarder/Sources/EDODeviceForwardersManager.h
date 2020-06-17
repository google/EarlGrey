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

/**
 *  The helper class to manage a set of forwarders connecting to the device's multiplexer.
 *
 *  The manager attempts to connect to the device's multiplexer and manages the established
 *  forwarders. The manager will set up two forwarder in the beginning so it can handle two
 *  concurrent connections. Once the forwarder starts to forwarding, the manager will attempt
 *  to establish another one, it not exceeding the limit, so the multiplexer can make concurrent
 *  requests. If the multiplexer closes, the manager will invalidate all the forwarders
 *  automatically.
 */
@interface EDODeviceForwardersManager : NSObject

/** The device UUID whose multiplexer the forwarder connects to. */
@property(nonatomic, readonly) NSString *deviceUUID;

/** The port for the multiplexer that the forwarder connects to. */
@property(nonatomic, readonly) UInt16 port;

/** The max concurrent forwarders that connect to the mutiplexer. */
@property(nonatomic, readonly) NSUInteger numOfForwarders;

/** The identifier of the mutiplexer's device that the forwarder connects to. */
@property(nonatomic, readonly) NSString *deviceIdentifier;

- (instancetype)init NS_UNAVAILABLE;

/** Initializes the instance. */
- (instancetype)initWithDeviceUUID:(NSString *)deviceUUID
                              port:(UInt16)port
                   numOfForwarders:(NSUInteger)numOfForwarders NS_DESIGNATED_INITIALIZER;

/**
 *  Starts to connect to the device asynchronously.
 *
 *  @note Calling this again before the @c block is invoked will corrupt the manager. You should
 *        only start again after the completion @c block is invoked.
 *
 *  @param block The completion block that is invoked when it finishes attempts to connect.
 *               If it successfully connects to the device's multiplexer, the @c deviceIdentifier
 *               will be set, otherwise it is set to @c nil.
 */
- (void)startWithCompletionBlock:(void (^)(EDODeviceForwardersManager *))block;

@end

NS_ASSUME_NONNULL_END
