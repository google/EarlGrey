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

@class EDOHostPort;

/**
 *  The port information of a @c EDOHostService.
 */
@interface EDOServicePort : NSObject <NSSecureCoding>

/** The port that the service listens on. This API will be deprecated. */
// TODO(ynzhang): remove this property and update external codes that uses it.
@property(nonatomic, readonly) UInt16 port;

/** The port information to recognize the service. */
@property(nonatomic, readonly) EDOHostPort *hostPort;

/** Creates a service port with the information from given service port and host port. */
+ (EDOServicePort *)servicePortWithPort:(EDOServicePort *)port hostPort:(EDOHostPort *)hostPort;

/** Checks if the two @c EDOServicePort have the same identity. */
- (BOOL)match:(EDOServicePort *)otherPort;

/**
 *  Creates an instance with the given port number and service name.
 */
+ (instancetype)servicePortWithPort:(UInt16)port serviceName:(NSString *_Nullable)serviceName;

@end

NS_ASSUME_NONNULL_END
