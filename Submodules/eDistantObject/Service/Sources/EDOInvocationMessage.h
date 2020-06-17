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

#import "Service/Sources/EDOServiceRequest.h"

#import "Service/Sources/EDOObject+Private.h"
#import "Service/Sources/EDORemoteException.h"

NS_ASSUME_NONNULL_BEGIN

@class EDOHostPort;
@class EDOHostService;
@class EDOParameter;
typedef EDOParameter EDOBoxedValueType;

/** The invocation request to make a remote invocation. */
@interface EDOInvocationRequest : EDOServiceRequest

- (instancetype)init NS_UNAVAILABLE;

/**
 *  Creates an invocation request.
 *
 *  @param target        The remote target's plain address. The caller needs to make sure the
 *                       address is valid.
 *  @param selector      The selector that is sent to the @c target. @c nil if the target is a
 *                       block.
 *  @param arguments     The array of arguments to send.
 *  @param hostPort      The host port the request is sent to.
 *  @param returnByValue @c YES if the invocation should return the object by value instead of by
 *                       reference (for value-types that are already return-by-value by default,
 *                       this will be a no-op).
 */
+ (instancetype)requestWithTarget:(EDOPointerType)target
                         selector:(SEL _Nullable)selector
                        arguments:(NSArray *)arguments
                         hostPort:(EDOHostPort *)hostPort
                    returnByValue:(BOOL)returnByValue;

/**
 *  Creates an invocation request from an @c invocation on an EDOObject.
 *
 *  @param invocation    The invocation.
 *  @param target        The EDOObject.
 *  @param selector      The selector to be sent. When this is nil, the case for a block invocation,
 *                       the index of the actual arguments starts at 1; otherwise the case for an
 *                       object invocation, it starts at 2.
 *  @param returnByValue @c YES if the invocation should return the object by value instead of by
 *                       reference.
 *  @param service       The host service used to wrap the arguments in the @c invocation if any.
 *
 *  @return An instance of EDOInvocationRequest.
 */
+ (instancetype)requestWithInvocation:(NSInvocation *)invocation
                               target:(EDOObject *)target
                             selector:(SEL _Nullable)selector
                        returnByValue:(BOOL)returnByValue
                              service:(EDOHostService *)service;

@end

/** The invocation response for the remote invocation. */
@interface EDOInvocationResponse : EDOServiceResponse

/** The exception if thrown remotely. */
@property(readonly, nullable) EDORemoteException *exception;
/** The boxed return value. */
@property(readonly, nullable) EDOBoxedValueType *returnValue;
/** The boxed values for out parameter. */
@property(readonly, nullable) NSArray<EDOBoxedValueType *> *outValues;
/**
 *  Whether the returned object is retained.
 *
 *  With ARC, -retain, -release, and -autorelease, or equivalent methods will be inserted at
 *  compile time to ensure the correct ownership, according to Objective-C memory conventions,
 *  however it doesn't guarantee that the retain count will always balance, for example,
 *  NS_RETURNS_RETAINED will instruct ARC to explicitly transfer the ownership without adding
 *  an extra -retain. ARC reserves the right to remove any -retain/-release if safe in the context
 *  of a source file. As eDO builds the remote invocation using @c NSInvocation, this context will
 *  be lost and ARC treats the memory as what @c NSInvocation states, that is, the annotation gets
 *  lost and all the returns are already balanced. However the returned object will still be
 *  retained if the method family is one of +alloc, +new, -mutableCopy, or -copy. ARC will balance
 *  this by inserting an extra release on the caller, and the object returned will have an extra
 *  retain count, thus we need to:
 *   1) insert an extra retain on the caller;
 *   2) insert an extra release on the receiver,
 *  to ensure that the retain count is balanced.
 *
 *  For more details see
 * [ARC
 * documentation](https://developer.apple.com/library/archive/releasenotes/ObjectiveC/RN-TransitioningToARC/Introduction/Introduction.html),
 * [the method
 * families](http://clang.llvm.org/docs/AutomaticReferenceCounting.html#method-families), and
 * [retained return
 * values](https://clang.llvm.org/docs/AutomaticReferenceCounting.html#retained-return-values).
 */
@property(readonly) BOOL returnRetained;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
