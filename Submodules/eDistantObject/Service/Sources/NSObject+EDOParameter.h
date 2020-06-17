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

@class EDOObject;
@class EDOHostPort;
@class EDOHostService;
@class EDOParameter;

/** NSObject extension to help box itself. */
@interface NSObject (EDOParameter)

/**
 *  Boxes an object into a EDOParameter that converts the object into an remote object if needed.
 *
 *  @param service  The host service that the remote object will belong to.
 *  @param target   The remote target that the boxed parameter will send to. This is used when
 *                  the boxed parameter needs to access the destination service, for example, the
 *                  weak remote object.
 *  @param hostPort The port that the remote object will connect back to. If @c nil is given, the
 *                  hostPort will be generated from the given @c service. This will be used if the
 *                  @c hostPort is not the same as the service.hostPort, for example, when the
 *                  service is connecting via usbmuxd.
 */
- (EDOParameter *)edo_parameterForTarget:(nullable EDOObject *)target
                                 service:(EDOHostService *)service
                                hostPort:(nullable EDOHostPort *)hostPort;

@end

NS_ASSUME_NONNULL_END
