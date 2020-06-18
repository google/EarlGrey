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

#import "Channel/Sources/EDOHostPort.h"

#import <TargetConditionals.h>

/** The device identifer for the host that @c EDOHostPort targets to . */
static NSString *const kEDOHostPortHostIdentifier = @"host";

static NSString *const kEDOHostPortCoderPortKey = @"port";
static NSString *const kEDOHostPortCoderNameKey = @"serviceName";
static NSString *const kEDOHostPortCoderDeviceSerialKey = @"deviceSerialNumber";

/**
 *  The host port data layout
 *  |--- 32 bit ---|-- 16 bit --|--- 16 bit ----|---- 16 bit -----|--- name ----|--- serial ---|
 *  |- data size --|-  port #  -|- name offset -|- serial offset -|--- "name"---|-- "serial" --|
 *
 *  Note the name and serial both have the ending '\0' to tell it's nil or an empty string.
 */
typedef struct EDOHostPortData_s {
  uint32_t size;
  uint16_t port;
  uint16_t nameOffset;
  uint16_t serialOffset;
} __attribute__((__packed__)) EDOHostPortData_t;

@implementation EDOHostPort

+ (BOOL)supportsSecureCoding {
  return YES;
}

+ (NSString *)deviceIdentifier {
  static dispatch_once_t onceToken;
  static NSString *deviceIdentifier;
  dispatch_once(&onceToken, ^{
    deviceIdentifier = NSProcessInfo.processInfo.globallyUniqueString;
  });
  return deviceIdentifier;
}

+ (instancetype)hostPortWithLocalPort:(UInt16)port {
  return [self hostPortWithPort:port name:nil deviceSerialNumber:nil];
}

+ (instancetype)hostPortWithLocalPort:(UInt16)port serviceName:(NSString *)name {
  return [self hostPortWithPort:port name:name deviceSerialNumber:nil];
}

+ (instancetype)hostPortWithName:(NSString *)name {
  return [self hostPortWithPort:0 name:name deviceSerialNumber:nil];
}

+ (instancetype)hostPortWithPort:(UInt16)port
                            name:(NSString *_Nullable)name
              deviceSerialNumber:(NSString *_Nullable)deviceSerialNumber {
  return [[self alloc] initWithPort:port name:name deviceSerialNumber:deviceSerialNumber];
}

- (instancetype)initWithPort:(UInt16)port
                        name:(NSString *)name
          deviceSerialNumber:(NSString *)deviceSerialNumber {
  self = [super init];
  if (self) {
    _port = port;
    _name = name;
    // The deviceSerialNumber identifies whether it is on a real device or a host device:
    // 1) If @c deviceSerialNumber is not given or @c nil, then it targets to the local host;
    // 2) If @c deviceSerialNumber is "host", then it targets to the mac host and requires the
    //    multiplexer to connect if it runs on a real device;
    // 3) If @c deviceSerialNumber is neither @c nil nor "host", then it targets to a real device
    //    UUID.
    // TODO(haowoo): This should be renamed to deviceUUID or deviceIdentifier.
    if (deviceSerialNumber) {
      _deviceSerialNumber = [deviceSerialNumber copy];
    } else {
      if (@available(macOS 10.10, *)) {
        _deviceSerialNumber = kEDOHostPortHostIdentifier;
      } else if (@available(iOS 2.0, *)) {
#if TARGET_OS_SIMULATOR
        // The simulator is running on the mac host and considered to be a host destination.
        _deviceSerialNumber = kEDOHostPortHostIdentifier;
#else
        _deviceSerialNumber = nil;
#endif
      }
    }
  }
  return self;
}

- (instancetype)initWithData:(NSData *)data {
  self = [super init];
  if (self) {
    const char *bytes = data.bytes;
    if (!bytes) {
      return nil;
    }

    const EDOHostPortData_t *header = data.bytes;
    if (header->size != data.length || header->nameOffset != sizeof(EDOHostPortData_t) ||
        header->serialOffset > data.length) {
      return nil;
    }

    _port = header->port;
    if (header->serialOffset > header->nameOffset) {
      _name = [[NSString alloc] initWithBytes:bytes + header->nameOffset
                                       length:header->serialOffset - header->nameOffset - 1
                                     encoding:NSASCIIStringEncoding];
    }
    if (header->size > header->serialOffset) {
      _deviceSerialNumber = [[NSString alloc] initWithBytes:bytes + header->serialOffset
                                                     length:header->size - header->serialOffset - 1
                                                   encoding:NSASCIIStringEncoding];
    }
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  NSData *data = [aDecoder decodeDataObject];
  if (data) {
    return [self initWithData:data];
  }

  self = [super init];
  if (self) {
    _port = (UInt16)[aDecoder decodeIntForKey:kEDOHostPortCoderPortKey];
    _name = [aDecoder decodeObjectOfClass:[NSString class] forKey:kEDOHostPortCoderNameKey];
    _deviceSerialNumber = [aDecoder decodeObjectOfClass:[NSString class]
                                                 forKey:kEDOHostPortCoderDeviceSerialKey];
  }
  return self;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"EDOHostPort (%@) with port (%d) and serial number (%@)",
                                    self.name ?: @"no name", self.port,
                                    self.deviceSerialNumber ?: @"no serial"];
}

- (BOOL)requiresMultiplexer {
#if TARGET_OS_SIMULATOR || TARGET_OS_MAC
  // We never need a multiplexer on the host as we can connect to any device from the host.
  return NO;
#else
  // If we are running on the real device, we can only check if the port is targeting to a host,
  // for others, we will only assume it's from the same device as we don't exchange the device info
  // with other devices and processes, and we currently can't tell if the deviceIdentifier is
  // coming from the same device or other device.
  return [self.deviceSerialNumber isEqualToString:kEDOHostPortHostIdentifier];
#endif
}

- (BOOL)connectsDevice {
#if TARGET_OS_SIMULATOR || TARGET_OS_MAC
  // @c YES if we have a serial number and it targets to a device UUID, not a host.
  return self.deviceSerialNumber &&
         ![self.deviceSerialNumber isEqualToString:kEDOHostPortHostIdentifier];
#else
  // If we are running on the real device, we can't connect to the device directly.
  return NO;
#endif
}

#pragma mark - Object Equality

- (BOOL)isEqual:(id)other {
  if (other == self) {
    return YES;
  } else if ([other isKindOfClass:[self class]]) {
    EDOHostPort *otherPort = (EDOHostPort *)other;
    BOOL isPortEqual = _port == otherPort.port;
    BOOL isSerialEqual = _deviceSerialNumber == otherPort.deviceSerialNumber ||
                         [_deviceSerialNumber isEqualToString:otherPort.deviceSerialNumber];
    BOOL isNameEqual = _name == otherPort.name || [_name isEqualToString:otherPort.name];
    return isPortEqual && isSerialEqual && isNameEqual;
  }
  return NO;
}

- (NSUInteger)hash {
  return [_deviceSerialNumber hash] ^ [_name hash] ^ _port;
}

#pragma mark - NSCopying

- (id)copyWithZone:(nullable NSZone *)zone {
  return [[EDOHostPort alloc] initWithPort:_port
                                      name:[_name copy]
                        deviceSerialNumber:[_deviceSerialNumber copy]];
}

#pragma mark - NSSecureCoding

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeDataObject:self.data];
  // TODO(haowoo): Remove below once all the compatible issues are resolved.
  [aCoder encodeInteger:self.port forKey:kEDOHostPortCoderPortKey];
  [aCoder encodeObject:self.name forKey:kEDOHostPortCoderNameKey];
  [aCoder encodeObject:self.deviceSerialNumber forKey:kEDOHostPortCoderDeviceSerialKey];
}

- (NSData *)data {
  uint32_t size = sizeof(EDOHostPortData_t);
  size += self.name ? (uint32_t)self.name.length + 1 : 0;
  size += self.deviceSerialNumber ? (uint32_t)self.deviceSerialNumber.length + 1 : 0;
  NSMutableData *data = [[NSMutableData alloc] initWithCapacity:size];
  data.length = size;
  EDOHostPortData_t *header = data.mutableBytes;
  header->size = size;
  header->port = self.port;
  header->nameOffset = sizeof(EDOHostPortData_t);
  if (self.name) {
    header->serialOffset = header->nameOffset + self.name.length + 1;
    memcpy(data.mutableBytes + header->nameOffset, self.name.UTF8String, self.name.length + 1);
  } else {
    header->serialOffset = sizeof(EDOHostPortData_t);
  }
  if (self.deviceSerialNumber) {
    memcpy(data.mutableBytes + header->serialOffset, self.deviceSerialNumber.UTF8String,
           self.deviceSerialNumber.length + 1);
  }
  return [data copy];
}

@end
