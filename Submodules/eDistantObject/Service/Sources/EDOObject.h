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
 *  EDOObject proxies for objects in other processes (or threads).
 *
 *  When a distant object receives a message, it forwards the message through its service object to
 *  the real object in another process, supplying the return value and out parameters if any, and
 *  propagating any exception back to the invoker of the method that raised it. The EDOObject is a
 *  transparent proxy to its user and should only be retrieved from the @c EDOHostService or
 *  @c EDOClientService.
 */
@interface EDOObject : NSProxy <NSSecureCoding>

/** The flag that tells us whether the object is a local temporary object or not. */
@property(nonatomic, assign, getter=isLocal) BOOL local;

- (instancetype)init NS_UNAVAILABLE;

/** Method to be called on invocation target to get a value object from remote invocation. */
- (id)returnByValue;

/** Method to wrap an NSObject into a EDOWeakObject. Throws an
 *  EDOWeakObjectRemoteWeakMisuseException when invoked on EDOObject. */
- (id)remoteWeak;
@end

NS_ASSUME_NONNULL_END
