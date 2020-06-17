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

@class EDOObject;

NS_ASSUME_NONNULL_BEGIN

/**
 *  The proxy object for @c EDOObject to implement by-value behavior. A remote invocation using
 *  @c EDOValueObject as param or return value will have pass-by-value/return-by-value behavior.
 */
@interface EDOValueObject : NSProxy

/** The local object wrapped in @c EDOValueObject. nil if a remote object is wrapped. */
@property(nonatomic, readonly, nullable) id<NSCoding> localObject;
/** The remote object wrapped in @c EDOValueObject. @c nil if a local object is wrapped. */
@property(nonatomic, readonly, nullable) EDOObject *remoteObject;

- (instancetype)init NS_UNAVAILABLE;

/** Initialize the @c EDOValueObject as the proxy of given @c remoteObject */
- (instancetype)initWithRemoteObject:(EDOObject *)remoteObject;

/** Initialize the @c EDOValueObject as the proxy of given @c localObject */
- (instancetype)initWithLocalObject:(id<NSCoding>)localObject;

@end

NS_ASSUME_NONNULL_END
