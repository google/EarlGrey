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
 *  The helper class for the connected socket to retrieve its peer socket info.
 *
 *  @note This class supports both IPv4 and IPv6 addresses, but currently only IPv4 is used.
 */
@interface EDOSocketPort : NSObject

/** The port number that the socket itself is bound to. */
@property(readonly, nonatomic) UInt16 port;
/** The IP address that the socket is bound to. */
@property(readonly, nullable, nonatomic) NSString *IPAddress;

/** The port number for the peer. */
@property(readonly, nonatomic) UInt16 peerPort;
/** The IP address for the peer. */
@property(readonly, nullable, nonatomic) NSString *peerIPAddress;

/** The local path for the UNIX socket it connects to. */
@property(readonly, nullable, nonatomic) NSString *localPath;

- (instancetype)init NS_UNAVAILABLE;

/** Init with an established socket file descriptor. */
- (instancetype)initWithSocket:(dispatch_fd_t)socketFD NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
