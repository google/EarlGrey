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

@class EDOServicePort;

/**
 *  A naming service which holds information about each @c EDOHostService and the port on which
 *  it's being served.
 *
 *  All services that originate from this process are tracked by this class. Users can query for the
 *  port on which the service is hosted by calling @c -portForServiceWithName: and providing the
 *  unique name associated with the service.
 *  The service is not serving by default when initialized.
 */
@interface EDOHostNamingService : NSObject

/** The default port number 11237 which the naming service will be listening on. */
@property(class, readonly) UInt16 namingServerPort;

/** Shared singleton instance. */
@property(class, readonly) EDOHostNamingService *sharedService;

/**
 *  The port for service registration. Clients can connect to this port to register their
 *  services by name.
 */
@property(readonly) UInt16 serviceConnectionPort;

- (instancetype)init NS_UNAVAILABLE;

/**
 *  Returns the service port info with given service name.
 */
- (UInt16)portForServiceWithName:(NSString *)name;

/**
 *  Starts serving host port information by creating an @c EDOHostService on @c namingServerPort.
 *  Once started, any client can connect to the naming server on @c namingServerPort and query for
 *  hosted objects by name.
 *
 *  @return @c NO if fails to start serving on the default port.
 *
 *  @note Only one @c EDOHostNamingService instance can start serving on a single machine.
 */
- (BOOL)start;

/**
 *  Stops serving host port information for remote clients.
 */
- (void)stop;

@end

NS_ASSUME_NONNULL_END
