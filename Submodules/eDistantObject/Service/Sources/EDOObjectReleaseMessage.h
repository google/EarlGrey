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

#import "Service/Sources/EDOObject+Private.h"
#import "Service/Sources/EDOServiceRequest.h"

NS_ASSUME_NONNULL_BEGIN

/** The request to release an object in the host. */
@interface EDOObjectReleaseRequest : EDOServiceRequest

- (instancetype)init NS_UNAVAILABLE;

/**
 *  Creates an EDOObjectReleaseRequest for EDOObjects.
 *
 *  @param remoteAddress The remote address for the EDOObject that is going to be released.
 *
 *  @return An instance of EDOObjectReleaseRequest that removes the EDOObject from dictionary.
 */
+ (instancetype)requestWithRemoteAddress:(EDOPointerType)remoteAddress;

/**
 *  Creates an EDOObjectReleaseRequest for weak EDOObjects.
 *
 *  @param remoteAddress The remote address for the weak EDOObject that is going to be released.
 *
 *  @return An instance of EDOObjectReleaseRequest that removes the weak EDOObject from dictionary.
 */
+ (instancetype)requestWithWeakRemoteAddress:(EDOPointerType)remoteAddress;

@end

NS_ASSUME_NONNULL_END
