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
 *  The destination host that the channel can connect to.
 *
 *  This interface represents a host port that can be on a local machine or on a real device.
 */
@interface EDOHostPort : NSObject <NSCopying, NSSecureCoding>

/**
 *  The unique device identifier for the current running process.
 *
 *  TODO(haowoo): This will be used to identify whether the host is on a real device or a machine
 *                later, to replace deviceSerialNumber.
 */
@property(readonly, class) NSString *deviceIdentifier;

/** The listen port number of the host. 0 if the host port is identified by name. */
@property(readonly, nonatomic) UInt16 port;

/** The optional name of the host port. @c nil if the host port is identified by port. */
@property(readonly, nonatomic, nullable) NSString *name;

/** The device serial number string. @c nil if the connection is not to a physical iOS device. */
@property(readonly, nonatomic, nullable) NSString *deviceSerialNumber;

/** Whether to require a multiplexer to connect to the destination. */
@property(readonly, nonatomic) BOOL requiresMultiplexer;

/** Whether to require to connect to usbmuxd for the device connections. */
@property(readonly, nonatomic) BOOL connectsDevice;

/** The data representation of the host port. */
@property(readonly, nonatomic) NSData *data;

/**
 *  Creates a host port instance with local port number. This is used for host ports on a local
 *  machine.
 */
+ (instancetype)hostPortWithLocalPort:(UInt16)port;

/**
 *  Creates a host port instance with a unique name which is to identify the host port when
 *  communicate with a service on Mac from an iOS physical device.
 *  In this case the @c port is always 0 and @c deviceSerialNumber is always @c nil.
 */
+ (instancetype)hostPortWithName:(NSString *)name;

/**
 *  Creates a host port instance with local port number and optional service name. This is used for
 *  host ports on a local machine.
 */
+ (instancetype)hostPortWithLocalPort:(UInt16)port serviceName:(NSString *_Nullable)name;

/* Creates a host port instance with port number and optional name and device serial number. */
+ (instancetype)hostPortWithPort:(UInt16)port
                            name:(NSString *_Nullable)name
              deviceSerialNumber:(NSString *_Nullable)deviceSerialNumber;

/** Initializes the host port with the given @c port, @c name and @c deviceSerialNumber. */
- (instancetype)initWithPort:(UInt16)port
                        name:(nullable NSString *)name
          deviceSerialNumber:(nullable NSString *)deviceSerialNumber;

/**
 *  Initializes the host port from the data representation. Returns @c nil if the data is not valid.
 */
- (nullable instancetype)initWithData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
