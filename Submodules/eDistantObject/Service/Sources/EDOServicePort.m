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

#import "Service/Sources/EDOServicePort.h"

#import "Channel/Sources/EDOHostPort.h"

static NSString *const EDOServicePortCoderPortKey = @"port";
static NSString *const EDOServiceHostPortCoderPortKey = @"hostPort";
static NSString *const EDOServicePortCoderUUIDKey = @"uuid";

@implementation EDOServicePort {
  uuid_t _serviceKey;
}

+ (BOOL)supportsSecureCoding {
  return YES;
}

+ (instancetype)servicePortWithPort:(UInt16)port serviceName:(NSString *)serviceName {
  return [[self alloc] initWithPort:port serviceName:serviceName];
}

+ (instancetype)servicePortWithPort:(EDOServicePort *)port hostPort:(EDOHostPort *)hostPort {
  EDOServicePort *newPort = [[EDOServicePort alloc] initWithHostPort:hostPort
                                                          serviceKey:port->_serviceKey];
  return newPort;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _port = 0;
    uuid_generate(_serviceKey);
  }
  return self;
}

- (instancetype)initWithPort:(UInt16)port serviceName:(NSString *)serviceName {
  self = [self init];
  if (self) {
    _port = port;
    _hostPort = [EDOHostPort hostPortWithLocalPort:port serviceName:serviceName];
  }
  return self;
}

- (instancetype)initWithHostPort:(EDOHostPort *)hostPort serviceKey:(uuid_t)serviceKey {
  self = [super init];
  if (self) {
    _port = hostPort.port;
    _hostPort = hostPort;
    uuid_copy(_serviceKey, serviceKey);
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [super init];
  if (self) {
    _port = (UInt16)[aDecoder decodeIntForKey:EDOServicePortCoderPortKey];
    _hostPort = [aDecoder decodeObjectOfClass:[EDOHostPort class]
                                       forKey:EDOServiceHostPortCoderPortKey];
    uuid_copy(_serviceKey, [aDecoder decodeBytesForKey:EDOServicePortCoderUUIDKey
                                        returnedLength:NULL]);
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeInteger:self.port forKey:EDOServicePortCoderPortKey];
  [aCoder encodeObject:self.hostPort forKey:EDOServiceHostPortCoderPortKey];
  [aCoder encodeBytes:_serviceKey length:sizeof(_serviceKey) forKey:EDOServicePortCoderUUIDKey];
}

- (BOOL)match:(EDOServicePort *)otherPort {
  // Ignore deviceSerial since it is not saved in the host side.
  BOOL isNameEqual = self.hostPort.name == otherPort.hostPort.name ||
                     [self.hostPort.name isEqualToString:otherPort.hostPort.name];
  return self.hostPort.port == otherPort.hostPort.port && isNameEqual &&
         uuid_compare(_serviceKey, otherPort->_serviceKey) == 0;
}

@end
