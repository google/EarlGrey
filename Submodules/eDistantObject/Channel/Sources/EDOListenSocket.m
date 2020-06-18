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

#import "Channel/Sources/EDOListenSocket.h"

#include <arpa/inet.h>
#include <fcntl.h>
#include <netinet/tcp.h>
#include <sys/un.h>

#import "Channel/Sources/EDOSocketPort.h"

static char const *gListenSocketQueueLabel = "com.google.edo.socketListen";

@implementation EDOListenSocket {
  // The dispatch source to listen on for incoming requests.
  dispatch_source_t _source;
}

+ (instancetype)socketWithSocket:(dispatch_fd_t)socket source:(dispatch_source_t)source {
  return [[self alloc] initWithSocket:socket source:source];
}

+ (EDOListenSocket *)listenSocketWithSocket:(dispatch_fd_t)socketFD
                             connectedBlock:(EDOSocketConnectedBlock)block {
  NSAssert(socketFD >= 0, @"Invalid socket descriptor to listen");

  // TODO(haowoo): proper way to report the socket error.
  if (listen(socketFD, SOMAXCONN) != 0) {
    close(socketFD);
    return nil;
  }

  dispatch_queue_t eventQueue =
      dispatch_queue_create(gListenSocketQueueLabel, DISPATCH_QUEUE_SERIAL);

  dispatch_source_t source =
      dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, (uintptr_t)socketFD, 0, eventQueue);

  EDOListenSocket *listenSocket = [EDOListenSocket socketWithSocket:socketFD source:source];
  __weak EDOListenSocket *weakSelf = listenSocket;
  dispatch_source_set_event_handler(source, ^{
    EDOListenSocket *strongSelf = weakSelf;

    unsigned long nconns = dispatch_source_get_data(source);

    while (nconns > 0) {
      EDOSocket *socket = [strongSelf accept:socketFD];
      if (socket) {
        block(socket, nil);
      }
      --nconns;
    }
  });

  dispatch_source_set_cancel_handler(source, ^{
    // Release the socket and reset it to -1.
    EDOSocket *strongSelf = weakSelf;
    [strongSelf releaseSocket];
    close(socketFD);
  });

  dispatch_resume(source);
  return listenSocket;
}

- (instancetype)initWithSocket:(dispatch_fd_t)socket source:(dispatch_source_t)source {
  self = [super initWithSocket:socket];
  if (self) {
    _source = source;
  }
  return self;
}

// Override the [EDOSocket invalidate] so it will not close its associated socket.
- (void)invalidate {
  // Cancelling the source will close the socket, so it releases its owership for the underlying
  // socket descriptor w/o closing it. We don't close socket here because there is a potential race
  // condition between calling close and cancel the source. The source handler can still process the
  // incoming requests while we close the socket. Cancelling the source first can make sure the
  // handler is complete before the socket is closed.
  if (_source) {
    dispatch_source_cancel(_source);
    _source = NULL;
  }
}

- (BOOL)valid {
  return _source != NULL;
}

/**
 *  Accept the incoming socket fd.
 *
 *  The socket fd is wrapped in a @c EDOSocket to be used for creating the socket connection
 *  object.
 *
 *  @param fd The incoming socket descriptor.
 */
- (EDOSocket *)accept:(dispatch_fd_t)fd {
  struct sockaddr_in addr;
  socklen_t addrLen = sizeof(addr);
  dispatch_fd_t clientFD = accept(fd, (struct sockaddr *)&addr, &addrLen);

  // TODO(haowoo): report this error.
  if (clientFD == -1) {
    return nil;
  }

  // Prevent SIGPIPE, suggested by Apple.
  int on = 1;
  setsockopt(clientFD, SOL_SOCKET, SO_NOSIGPIPE, &on, sizeof(on));

  // TODO(haowoo_: report this error.
  if (fcntl(clientFD, F_SETFL, O_NONBLOCK) == -1) {
    close(clientFD);
    return nil;
  }

  return [EDOSocket socketWithSocket:clientFD];
}

@end
