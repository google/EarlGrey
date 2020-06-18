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

#import "Service/Sources/EDOHostNamingService.h"

#import "Channel/Sources/EDOChannelPool.h"
#import "Channel/Sources/EDOHostPort.h"
#import "Service/Sources/EDOHostNamingService+Private.h"
#import "Service/Sources/EDOHostService.h"
#import "Service/Sources/EDOServicePort.h"

@implementation EDOHostNamingService {
  // The mapping from service name to host service port.
  NSMutableDictionary<NSString *, EDOServicePort *> *_servicePortsInfo;
  // The dispatch queue to execute atomic operations of starting/stopping service and
  // tracking/untracking service port info.
  dispatch_queue_t _namingServicePortQueue;
  // The dispatch queue to execute service start/stop events and request handler of the naming
  // service.
  dispatch_queue_t _namingServiceEventQueue;
  // The host service serving the naming service object.
  EDOHostService *_service;
}

+ (UInt16)namingServerPort {
  return 11237;
}

+ (instancetype)sharedService {
  static EDOHostNamingService *instance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[EDOHostNamingService alloc] initInternal];
  });
  return instance;
}

- (instancetype)initInternal {
  self = [super init];
  if (self) {
    _servicePortsInfo = [[NSMutableDictionary alloc] init];
    _service = nil;
    _namingServicePortQueue =
        dispatch_queue_create("com.google.edo.namingService.port", DISPATCH_QUEUE_SERIAL);
    _namingServiceEventQueue =
        dispatch_queue_create("com.google.edo.namingService.event", DISPATCH_QUEUE_SERIAL);
  }
  return self;
}

- (void)dealloc {
  [_service invalidate];
}

- (UInt16)serviceConnectionPort {
  return EDOChannelPool.sharedChannelPool.serviceConnectionPort;
}

- (UInt16)portForServiceWithName:(NSString *)name {
  __block EDOServicePort *portInfo;
  dispatch_sync(_namingServicePortQueue, ^{
    portInfo = self->_servicePortsInfo[name];
  });
  return portInfo ? portInfo.hostPort.port : 0;
}

- (BOOL)start {
  // Use a local variable to guarantee thread-safety.
  __block BOOL result;
  dispatch_sync(_namingServiceEventQueue, ^{
    if (self->_service) {
      return;
    }
    self->_service = [EDOHostService serviceWithPort:EDOHostNamingService.namingServerPort
                                          rootObject:self
                                               queue:self->_namingServiceEventQueue];
    result = self->_service.port.hostPort.port != 0;
  });
  return result;
}

- (void)stop {
  dispatch_sync(_namingServiceEventQueue, ^{
    [self->_service invalidate];
    self->_service = nil;
  });
}

#pragma mark - Private category

- (BOOL)addServicePort:(EDOServicePort *)servicePort {
  if (!servicePort.hostPort.name) {
    return NO;
  }
  __block BOOL result;
  dispatch_sync(_namingServicePortQueue, ^{
    if ([self->_servicePortsInfo objectForKey:servicePort.hostPort.name]) {
      result = NO;
    } else {
      [self->_servicePortsInfo setObject:servicePort forKey:servicePort.hostPort.name];
      result = YES;
    }
  });
  return result;
}

- (BOOL)removeServicePort:(EDOServicePort *)servicePort {
  if (!servicePort.hostPort.name) {
    return NO;
  }
  dispatch_sync(_namingServicePortQueue, ^{
    [self->_servicePortsInfo removeObjectForKey:servicePort.hostPort.name];
  });
  return YES;
}

@end
