//
// Copyright 2019 Google LLC.
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

#import "Service/Sources/EDOClientService.h"
#import "Service/Sources/EDOObject+Private.h"

NS_ASSUME_NONNULL_BEGIN

@class EDOObject;
@class EDOExecutor;
@class EDOHostPort;
@class EDOServiceRequest;
@class EDOServiceResponse;

/** The internal use for sending and receiving EDOObject. */
@interface EDOClientService (Private)

/** The EDOObjects created by all services that are mapped by the remote address. */
@property(class, readonly) NSMapTable<NSNumber *, EDOObject *> *localDistantObjects;
/** The synchronization queue for accessing remote object references. */
@property(class, readonly) dispatch_queue_t edoSyncQueue;
/** The data of ping message for channel health check. */
@property(class, readonly, nonatomic) NSData *pingMessageData;

/** Get the reference of a distant object of the given @c remoteAddress. */
+ (EDOObject *)distantObjectReferenceForRemoteAddress:(EDOPointerType)remoteAddress;

/** Add reference of given distant object. It could be an EDOObject or dummy block object. */
+ (void)addDistantObjectReference:(id)object;

/** Remove the reference of a distant object of the given @c remoteAddress. */
+ (void)removeDistantObjectReference:(EDOPointerType)remoteAddress;

/** Try to get the object from local cache. Update the cache if @c object is not in it. */
+ (id)cachedEDOFromObjectUpdateIfNeeded:(id)object;

/**
 *  Synchronously sends the request and waits for the response with the executor to process
 *  any incoming requests.
 *
 *  @note When sending a request, the executor will starts to process any incoming requests, this
 *        makes it possible to process intercepted requests, for example, the nested remote
 *        invocations.
 *
 *  @param request  The request to be sent.
 *  @param port     The service host port.
 *  @param executor The executor to run and process the incoming requests.
 *  @throw NSInternalInconsistencyException if it fails to communicate with the service.
 *
 *  @return The response from the service.
 */
+ (EDOServiceResponse *)sendSynchronousRequest:(EDOServiceRequest *)request
                                        onPort:(EDOHostPort *)port
                                  withExecutor:(EDOExecutor *)executor;

/**
 *  Synchronously sends the request and waits for the response.
 *
 *  @param request The request to be sent.
 *  @param port    The service host port.
 *  @throw NSInternalInconsistencyException if it fails to communicate with the service.
 *
 *  @return The response from the service.
 */
+ (EDOServiceResponse *)sendSynchronousRequest:(EDOServiceRequest *)request
                                        onPort:(EDOHostPort *)port;

/**
 *  Unwraps an @c object to a local object if it comes from the local process.
 *
 *  @note When nil is given, this is a no-op. This can happen when it is used to unwrap
 *        parameters of a method which may accept nil as an input argument.
 *
 *  @param  object The object to be unwrapped.
 *  @return The unwrapped local object if the given object is an EDOObject and it comes from the
 *          current process; otherwise, the original object is returned.
 */
+ (nullable id)unwrappedObjectFromObject:(nullable id)object;

@end

NS_ASSUME_NONNULL_END
