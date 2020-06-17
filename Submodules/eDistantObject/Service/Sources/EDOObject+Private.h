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

#import "Service/Sources/EDOObject.h"

NS_ASSUME_NONNULL_BEGIN

@class EDOServicePort;

typedef int64_t EDOPointerType;

/**
 *  The internal use to create a EDOObject.
 *
 *  The EDOObject is an opaque object that user doesn't need to be aware of its existence. User
 *  will not directly create any EDOObject.
 */
@interface EDOObject (Private)

/** The port to connect to the local socket. */
@property(readonly) EDOServicePort *servicePort;
/** The proxied object's address in the remote. */
@property(readonly, assign) EDOPointerType remoteAddress;
/** The proxied object's class object in the remote. */
@property(readonly, assign) EDOPointerType remoteClass;
/** The proxied object's class name in the remote. */
@property(readonly) NSString *className;
/** Whether the @c EDOObject is from the same process. */
@property(readonly) BOOL isLocalEdo;
/** Whether the @c EDOObject is weakly referenced. */
@property(readonly) BOOL weaklyReferenced;

/** Create an object with the given local target and port the session listens on. */
+ (instancetype)objectWithTarget:(id)target port:(EDOServicePort *)port;

/** Init with the given local target and port the session listens on. */
- (instancetype)initWithTarget:(id)target port:(EDOServicePort *)port;

/** Init as a proxy with the given target and clazz under the @c port **/
- (instancetype)edo_initWithLocalObject:(id)target port:(EDOServicePort *)port;

/** Create an EDOObject distant object based on an underlying object. */
+ (EDOObject *)edo_remoteProxyFromUnderlyingObject:(id)object withPort:(EDOServicePort *)port;

/**
 *  The method to forward invocation.
 *
 *  @note The object invocation has the first two arguments being the object and the selector,
 *        whereas the block invocation only has the first argument being the block, and the rest
 *        of arguments follow. Because we cannot tell if the invocation is from a block or an
 *        object, the selector received from the @c invocation object may or may not be valid
 *        depending on the type of invocation. The @c selector is thus passed explicitly here.
 *  @param  invocation    The invocation to forward.
 *  @param  selector      The selector to be sent. @c nil if it forwards a block invocation.
 *  @param  returnByValue If @c YES, the invocation will return the object by value instead
 *                        of by reference.
 */
- (void)edo_forwardInvocation:(NSInvocation *)invocation
                     selector:(SEL _Nullable)selector
                returnByValue:(BOOL)returnByValue;

@end

NS_ASSUME_NONNULL_END
