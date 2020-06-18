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

#import "Channel/Sources/EDOSocketPort.h"

#include <arpa/inet.h>
#include <sys/un.h>

#import <XCTest/XCTest.h>

@interface EDOSocketPortTest : XCTestCase
@property(nonatomic) dispatch_fd_t listenSocket;
@property(nonatomic) UInt16 listenPort;
@end

@implementation EDOSocketPortTest

- (void)setUp {
  [super setUp];
  self.listenSocket = [self createListenSocket:[self.name containsString:@"IPV4"]];
  self.listenPort = [self socketPortOfSocket:self.listenSocket];
}

- (void)tearDown {
  close(self.listenSocket);
  [super tearDown];
}

- (void)testListenSocketIPV4 {
  EDOSocketPort *socketPort = [[EDOSocketPort alloc] initWithSocket:self.listenSocket];
  XCTAssertEqual(socketPort.port, self.listenPort);
  XCTAssertEqual(socketPort.peerPort, 0);
  XCTAssertEqualObjects(socketPort.IPAddress, @"127.0.0.1");
  XCTAssertNil(socketPort.localPath);
  XCTAssertNil(socketPort.peerIPAddress);
}

- (void)testListenSocketIPV6 {
  EDOSocketPort *socketPort = [[EDOSocketPort alloc] initWithSocket:self.listenSocket];
  XCTAssertEqual(socketPort.port, self.listenPort);
  XCTAssertEqual(socketPort.peerPort, 0);
  XCTAssertEqualObjects(socketPort.IPAddress, @"::1");
  XCTAssertNil(socketPort.localPath);
  XCTAssertNil(socketPort.peerIPAddress);
}

- (void)testSocketConnectIPV4 {
  dispatch_fd_t fd = socket(AF_INET, SOCK_STREAM, 0);

  struct sockaddr_in addr;
  memset(&addr, 0, sizeof(addr));
  addr.sin_family = AF_INET;
  addr.sin_port = htons(self.listenPort);
  addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
  connect(fd, (struct sockaddr const *)&addr, sizeof(addr));
  UInt16 port = [self socketPortOfSocket:fd];

  EDOSocketPort *socketPort = [[EDOSocketPort alloc] initWithSocket:fd];
  XCTAssertEqual(socketPort.port, port);
  XCTAssertEqual(socketPort.peerPort, self.listenPort);
  XCTAssertEqualObjects(socketPort.IPAddress, @"127.0.0.1");
  XCTAssertEqualObjects(socketPort.peerIPAddress, @"127.0.0.1");
  XCTAssertNil(socketPort.localPath);
}

- (void)testSocketConnectIPV6 {
  dispatch_fd_t fd = socket(AF_INET6, SOCK_STREAM, 0);

  struct sockaddr_in6 addr;
  memset(&addr, 0, sizeof(addr));
  addr.sin6_family = AF_INET6;
  addr.sin6_port = htons(self.listenPort);
  addr.sin6_addr = in6addr_loopback;
  connect(fd, (struct sockaddr const *)&addr, sizeof(addr));
  UInt16 port = [self socketPortOfSocket:fd];

  EDOSocketPort *socketPort = [[EDOSocketPort alloc] initWithSocket:fd];
  XCTAssertEqual(socketPort.port, port);
  XCTAssertEqual(socketPort.peerPort, self.listenPort);
  XCTAssertEqualObjects(socketPort.IPAddress, @"::1");
  XCTAssertEqualObjects(socketPort.peerIPAddress, @"::1");
  XCTAssertNil(socketPort.localPath);
}

- (void)testSocketConnectUNIXSocket {
  NSString *domainPath = [self createUnixDomainSocket];

  dispatch_fd_t connectSocket = socket(AF_UNIX, SOCK_STREAM, 0);

  struct sockaddr_un addr;
  addr.sun_family = AF_UNIX;
  strncpy(addr.sun_path, domainPath.UTF8String, sizeof(addr.sun_path) - 1);
  connect(connectSocket, (struct sockaddr *)&addr, sizeof(addr));

  EDOSocketPort *socketPort = [[EDOSocketPort alloc] initWithSocket:connectSocket];
  XCTAssertEqual(socketPort.port, 0);
  XCTAssertEqual(socketPort.peerPort, 0);
  XCTAssertNil(socketPort.IPAddress);
  XCTAssertNil(socketPort.peerIPAddress);
  XCTAssertEqualObjects(socketPort.localPath, domainPath);
}

- (void)testInvalidSocket {
  // Close the socket so it becomes invalid.
  dispatch_fd_t listenSocket = self.listenSocket;
  close(listenSocket);

  EDOSocketPort *socketPort = [[EDOSocketPort alloc] initWithSocket:listenSocket];
  XCTAssertEqual(socketPort.port, 0);
  XCTAssertEqual(socketPort.peerPort, 0);
  XCTAssertNil(socketPort.IPAddress);
  XCTAssertNil(socketPort.peerIPAddress);
  XCTAssertNil(socketPort.localPath);
}

#pragma mark - Helper methods

/**
 *  Creates a socket that listens on any available port.
 *
 *  @param isIPV4 YES if an IPV4 socket is created, otherwise IPV6.
 *
 *  @return The listening socket descriptor.
 */
- (dispatch_fd_t)createListenSocket:(BOOL)isIPV4 {
  dispatch_fd_t fd = socket(isIPV4 ? AF_INET : AF_INET6, SOCK_STREAM, 0);

  if (isIPV4) {
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_len = sizeof(addr);
    addr.sin_port = htons(0);
    addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    bind(fd, (struct sockaddr *)&addr, sizeof(addr));
  } else {
    struct sockaddr_in6 addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin6_family = AF_INET6;
    addr.sin6_addr = in6addr_loopback;
    addr.sin6_port = htons(0);
    bind(fd, (struct sockaddr *)&addr, sizeof(addr));
  }

  listen(fd, SOMAXCONN);

  int socketError = 0;
  socklen_t errorLen = sizeof(socketError);

  // If there is an error, the connection fails.
  if (getsockopt(fd, SOL_SOCKET, SO_ERROR, &socketError, &errorLen) != 0 || socketError != 0) {
    XCTFail(@"Fail to create a listen socket.");
  }
  return fd;
}

/** Gets the port number that the given socket is bound to. */
- (UInt16)socketPortOfSocket:(dispatch_fd_t)socketFD {
  struct sockaddr_storage socketAddress;
  socklen_t addrLen = sizeof(socketAddress);
  if (getsockname(socketFD, (struct sockaddr *)&socketAddress, &addrLen) == -1) {
    XCTFail(@"Fail to retrieve socket address.");
  }
  if (socketAddress.ss_family == AF_INET) {
    return ntohs(((const struct sockaddr_in *)&socketAddress)->sin_port);
  } else if (socketAddress.ss_family == AF_INET6) {
    return ntohs(((const struct sockaddr_in6 *)&socketAddress)->sin6_port);
  } else {
    XCTFail(@"Not a valid socket.");
  }
  return 0;
}

/**
 *  Creates a Unix domain socket under the temporary folder.
 *
 *  @return The path that the socket is listening to.
 */
- (NSString *)createUnixDomainSocket {
  NSString *UUID = [NSUUID UUID].UUIDString;
#if TARGET_IPHONE_SIMULATOR
  NSURL *tempFile = [NSURL fileURLWithPath:[NSString stringWithFormat:@"/tmp/edo.%@.sock", UUID]];
#else
  NSFileManager *fileManager = NSFileManager.defaultManager;
  NSURL *tempFile = [fileManager.temporaryDirectory URLByAppendingPathComponent:UUID];
#endif
  dispatch_fd_t unixSocket = socket(AF_UNIX, SOCK_STREAM, 0);
  struct sockaddr_un addr;
  addr.sun_family = AF_UNIX;
  strncpy(addr.sun_path, tempFile.fileSystemRepresentation, sizeof(addr.sun_path) - 1);
  bind(unixSocket, (struct sockaddr *)&addr, sizeof(addr));
  listen(unixSocket, SOMAXCONN);

  // Replace with the domain socket so it can be closed at tearDown.
  close(self.listenSocket);
  self.listenSocket = unixSocket;
  return [NSString stringWithUTF8String:tempFile.fileSystemRepresentation];
}
@end
