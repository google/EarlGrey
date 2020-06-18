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

#import "Channel/Sources/EDOSocketPort.h"

#include <arpa/inet.h>
#include <sys/un.h>

/** Gets the socket port from the given socket address struct. */
static UInt16 GetSocketPort(const struct sockaddr_storage *socketAddress) {
  if (socketAddress->ss_family == AF_INET) {
    return ntohs(((const struct sockaddr_in *)socketAddress)->sin_port);
  } else if (socketAddress->ss_family == AF_INET6) {
    return ntohs(((const struct sockaddr_in6 *)socketAddress)->sin6_port);
  } else {
    return 0;
  }
}

/** Gets the IP address from the given socket address struct. */
static NSString *GetSocketIPAddress(const struct sockaddr_storage *socketAddress) {
  if (socketAddress->ss_family == AF_INET) {
    char addressBuf[INET_ADDRSTRLEN];
    const struct sockaddr_in *addrIPv4 = (const struct sockaddr_in *)socketAddress;
    inet_ntop(AF_INET, &addrIPv4->sin_addr, addressBuf, sizeof(addressBuf));
    return [NSString stringWithUTF8String:addressBuf];
  } else if (socketAddress->ss_family == AF_INET6) {
    char addressBuf[INET6_ADDRSTRLEN];
    const struct sockaddr_in6 *addrIPv6 = (const struct sockaddr_in6 *)socketAddress;
    inet_ntop(AF_INET6, &addrIPv6->sin6_addr, addressBuf, sizeof(addressBuf));
    return [NSString stringWithUTF8String:addressBuf];
  } else {
    return nil;
  }
}

@implementation EDOSocketPort {
  /** The raw socket address storage. */
  struct sockaddr_storage _socketAddress;
  /** The raw socket address storage for the connected peer. */
  struct sockaddr_storage _peerSocketAddress;
}

- (instancetype)initWithSocket:(dispatch_fd_t)socketFD {
  self = [super init];
  if (self) {
    socklen_t addrLen = sizeof(_socketAddress);
    if (getsockname(socketFD, (struct sockaddr *)&_socketAddress, &addrLen) == -1) {
      // We ignore the failure and reset to zero, for example, the invalid socket.
      memset(&_socketAddress, 0, addrLen);
    }
    socklen_t peerAddrLen = sizeof(_peerSocketAddress);
    if (getpeername(socketFD, (struct sockaddr *)&_peerSocketAddress, &peerAddrLen) == -1) {
      // Ignore the failure and reset to zero for invalid sockets.
      memset(&_peerSocketAddress, 0, peerAddrLen);
    }
  }
  return self;
}

- (UInt16)port {
  return GetSocketPort(&_socketAddress);
}

- (NSString *)IPAddress {
  return GetSocketIPAddress(&_socketAddress);
}

- (UInt16)peerPort {
  return GetSocketPort(&_peerSocketAddress);
}

- (NSString *)peerIPAddress {
  return GetSocketIPAddress(&_peerSocketAddress);
}

- (NSString *)localPath {
  if (_peerSocketAddress.ss_family == AF_UNIX) {
    struct sockaddr_un *unixSock = (struct sockaddr_un *)&_peerSocketAddress;
    return [NSString stringWithUTF8String:unixSock->sun_path];
  } else {
    return nil;
  }
}

- (NSString *)description {
  if (self.localPath) {
    return [NSString stringWithFormat:@"The socket connects to %@", self.localPath];
  } else {
    return [NSString stringWithFormat:@"The socket bound on %d at %@, peer on %d at %@", self.port,
                                      self.IPAddress, self.peerPort, self.peerIPAddress];
  }
}

@end
