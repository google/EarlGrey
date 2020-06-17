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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  A category provides methods for eDO to manage information of running @c EDOHostService
 *  instances.
 *
 *  @note eDO clients should only make any remote invocation of methods in this category.
 */
@interface EDOHostNamingService (Private)

/**
 *  Adds a service port to track associated @c EDOHostService instance. Returns @c NO if a service
 *  port with the same name already exists.
 */
- (BOOL)addServicePort:(EDOServicePort *)servicePort;

/** Removes a service port to untrack associated @c EDOHostService instance. */
- (BOOL)removeServicePort:(EDOServicePort *)servicePort;

@end

NS_ASSUME_NONNULL_END
