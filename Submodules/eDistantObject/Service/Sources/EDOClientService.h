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
#import <os/availability.h>

NS_ASSUME_NONNULL_BEGIN

@class EDOHostNamingService;
@class EDOHostPort;

/** The error handler for handling errors generated when sending client requests. */
typedef void (^EDOClientErrorHandler)(NSError *_Nonnull);

/**
 *  Sets the error handler for the client, and returns the error handler that is previously set for
 *  the client. The procedure is thread-safe.
 *
 *  The handler will be invoked if there is an error when sending a request. The default handler
 *  throws an EDOServiceGenericException for any reported error. The exception's user info contains
 *  the entry EDOUnderlyingErrorKey that embeds the @c NSError object.
 *
 *  @param errorHandler The error handler to be used for the client. If it's @c nil, the default
 *                      handler will be used.
 *
 *  @return The old error handler that is set for the client previously, or the default handler
 *          if it get called the first time.
 */
EDOClientErrorHandler EDOSetClientErrorHandler(EDOClientErrorHandler _Nullable errorHandler);

/**
 *  The EDOClientService manages the communication to the remote objects in remote process.
 *
 *  The service manages the distant objects fetched from remote process. It provides API to make
 *  remote invocation to a @c EDOHostService running in the remote process.
 */
@interface EDOClientService<ObjectType> : NSObject

/**
 *  Gets the root object on the host port.
 *
 *  @param hostPort The host port the service is running on.
 *  @return The remote root object.
 */
+ (ObjectType)rootObjectWithHostPort:(EDOHostPort *)hostPort;

/**
 *  Gets the remote class object on the host port.
 *
 *  @param className The class name.
 *  @param hostPort   The host port the service is running on.
 *  @return The remote @c Class object.
 */
+ (Class)classObjectWithName:(NSString *)className hostPort:(EDOHostPort *)hostPort;

- (instancetype)init NS_UNAVAILABLE;

#pragma mark - Deprecated APIs

/** Retrieve the root object from the given host port of a service. */
+ (ObjectType)rootObjectWithPort:(UInt16)port;

/** Retrieve the root object from the given name of a service. */
+ (ObjectType)rootObjectWithServiceName:(NSString *)serviceName;

/** Retrieve the class object from the given host port of a service. */
+ (Class)classObjectWithName:(NSString *)className port:(UInt16)port;

/** Retrieve the class object from the given host port of and name of a service. */
+ (Class)classObjectWithName:(NSString *)className
                 serviceName:(NSString *)serviceName;

@end

/** The device support methods for @c EDOClientService. */
@interface EDOClientService (Device)

/**
 *  Fetches the naming service remote instance running on the physical device with given device
 *  @c serial synchronously.
 *
 *  @note This is used to get the service's listen port on the host side by service name.
 */
+ (EDOHostNamingService *)namingServiceWithDeviceSerial:(NSString *)serial
                                                  error:(NSError *_Nullable *_Nullable)error;

@end

NS_ASSUME_NONNULL_END

/**
 *  Stub the class implementation so it can resolve symbol lookup errors for the class methods.
 *
 *  The linker can't resolve class symbols when it compiles the class method statically. This macro
 *  helps to generate the stub implementation where it forwards the class method to the remote
 *  class object.
 *
 *  @note   This is generally not encouraged because this could cause retain/release imbalance
 *          if not used properly. For example, custom ns_returns_retained will not be
 *          captured at runtime and may lead to a memory crash. This is useful if only the class
 *          methods are used and any method from the +alloc, +new, +copy, and mutableCopy methods
 *          families are not used.
 *
 *  @note   +allocWithZone: is forwarded. +alloc is not forwarded as it calls into the forwarded
 *          method +allocWithZone: for historical reasons.
 *          https://developer.apple.com/documentation/objectivec/nsobject/1571958-alloc?language=objc
 *
 *  @param  __class  The class literal.
 *  @param  __port   The port that the service listens on.
 */
// TODO(haowoo): Cache the class object when we can know when the service is invalid.
// Refer to https://clang.llvm.org/docs/DiagnosticsReference.html for information about the
// ignored flags.
// TODO(ynzhang): Remove clang-format switch when b/78026272 is resolved.
// clang-format off
#define EDO_STUB_CLASS(__class, __port)                                                        \
_Pragma("clang diagnostic push")                                                             \
_Pragma("clang diagnostic ignored \"-Wincomplete-implementation\"")                          \
_Pragma("clang diagnostic ignored \"-Wprotocol\"")                                           \
_Pragma("clang diagnostic ignored \"-Wobjc-property-implementation\"")                       \
_Pragma("clang diagnostic ignored \"-Wobjc-protocol-property-synthesis\"")                   \
\
@implementation __class                                                                      \
\
+ (id)forwardingTargetForSelector:(SEL)sel {                                              \
  return [EDOClientService classObjectWithName:@""#__class port:(__port)];                   \
}                                                                                            \
\
+ (instancetype)allocWithZone:(NSZone *)zone {                                             \
  id instance = [self forwardingTargetForSelector:@selector(alloc)];                         \
  return [instance alloc];                                                                   \
}                                                                                            \
\
@end                                                                                         \
_Pragma("clang diagnostic pop")
// clang-format on

/**
 *  Fetch the remote class type.
 *
 *  When the stub is not used and the reference to the remote class is needed, this method can do
 *  the type checking and bypass the symbol lookup.
 *
 *  @note   The explicit conversion is used to have the compiler check the spelling because it
 *          converts the class literal into a NSString.
 *
 *  @param  __class The class literal
 *  @param  __port  The port that the service listens on.
 */
#define EDO_REMOTE_CLASS(__class, __port) \
  ((Class)(__class *)[EDOClientService classObjectWithName:@"" #__class port:(__port)])
