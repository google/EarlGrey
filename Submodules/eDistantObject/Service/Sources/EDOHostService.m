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

#import "Service/Sources/EDOHostService.h"

#include <objc/runtime.h>

#import "Channel/Sources/EDOHostPort.h"
#import "Channel/Sources/EDOSocket.h"
#import "Channel/Sources/EDOSocketChannel.h"
#import "Channel/Sources/EDOSocketPort.h"
#import "Device/Sources/EDODeviceConnector.h"
#import "Service/Sources/EDOBlockObject.h"
#import "Service/Sources/EDOClientService+Private.h"
#import "Service/Sources/EDOClientService.h"
#import "Service/Sources/EDOExecutor.h"
#import "Service/Sources/EDOHostNamingService+Private.h"
#import "Service/Sources/EDOHostService+Handlers.h"
#import "Service/Sources/EDOObject+Private.h"
#import "Service/Sources/EDOObjectReleaseMessage.h"
#import "Service/Sources/EDOServicePort.h"
#import "Service/Sources/EDOTimingFunctions.h"
#import "Service/Sources/NSKeyedArchiver+EDOAdditions.h"
#import "Service/Sources/NSKeyedUnarchiver+EDOAdditions.h"

/**  The context key to save the service to the dispatch queue. This shall be removed later. */
static const char *gServiceKey = "com.google.edo.servicekey";

/** The context key to find the service for the originating queue. */
static const char kEDOOriginatingQueueKey = '\0';

/** The context key to find the service for the executing queue.*/
static const char kEDOExecutingQueueKey = '\0';

#pragma mark - EDODispatchQueueWeakRef

/**
 *  The weak object wrapper to hold a weak reference to be saved in a container like NSArray.
 */
@interface EDOWeakReference : NSObject
/** The weak object it holds. */
@property(nonatomic, weak, readonly) id object;
@end

@implementation EDOWeakReference

- (instancetype)initWithObject:(id)object {
  self = [super init];
  if (self) {
    _object = object;
  }
  return self;
}

@end

#pragma mark - EDOHostService

@interface EDOHostService ()
/** The execution queue for the root object. */
@property(readonly, weak) dispatch_queue_t executionQueue;
/** The executor to handle the request. */
@property(readonly) EDOExecutor *executor;
/** The set to save channel handlers in order to keep channels ready to accept request. */
@property(readonly) NSMutableSet<EDOChannelReceiveHandler> *handlerSet;
/** The queue to update handlerSet atomically. */
@property(readonly) dispatch_queue_t handlerSyncQueue;
/** The listen socket. */
@property(readonly) EDOSocket *listenSocket;
/**
 * The tracked objects in the service. The key is the address of a tracked object and the value is
 * the object.
 */
@property(readonly) NSMutableDictionary<NSNumber *, id> *localObjects;
/** The queue to update local objects atomically. */
@property(readonly) dispatch_queue_t localObjectsSyncQueue;
/**
 * The tracked weak objects in the service. The key is the address of a tracked object and the
 * value is the object.
 */
@property(readonly) NSMutableDictionary<NSNumber *, EDOObject *> *localWeakObjects;
/** The queue to update weak local objects atomically. */
@property(readonly) dispatch_queue_t localWeakObjectsSyncQueue;
/** The underlying root object. */
@property(readonly) id rootLocalObject;
/** Internal property of the read-only flag of device registration. */
@property(readwrite) BOOL registeredToDevice;
@end

@implementation EDOHostService {
  /** The container for the weakly referenced originating queues*/
  NSArray<EDOWeakReference *> *_originatingWeakQueues;
}

@synthesize port = _port;

+ (instancetype)serviceForCurrentOriginatingQueue {
  EDOWeakReference *weakRef =
      (__bridge EDOWeakReference *)dispatch_get_specific(&kEDOOriginatingQueueKey);
  return weakRef.object;
}

+ (instancetype)serviceForCurrentExecutingQueue {
  EDOWeakReference *weakRef =
      (__bridge EDOWeakReference *)dispatch_get_specific(&kEDOExecutingQueueKey);
  return weakRef.object;
}

+ (instancetype)serviceForOriginatingQueue:(dispatch_queue_t)queue {
  EDOWeakReference *weakRef =
      (__bridge EDOWeakReference *)dispatch_queue_get_specific(queue, &kEDOOriginatingQueueKey);
  return weakRef.object;
}

+ (instancetype)serviceWithPort:(UInt16)port rootObject:(id)object queue:(dispatch_queue_t)queue {
  return [[self alloc] initWithPort:port
                         rootObject:object
                        serviceName:nil
                              queue:queue
                         isToDevice:NO];
}

+ (instancetype)serviceWithRegisteredName:(NSString *)name
                               rootObject:(id)object
                                    queue:(dispatch_queue_t)queue {
  return [[self alloc] initWithPort:0 rootObject:object serviceName:name queue:queue isToDevice:NO];
}

+ (instancetype)serviceWithName:(NSString *)name
               registerToDevice:(NSString *)deviceSerial
                     rootObject:(id)object
                          queue:(dispatch_queue_t)queue
                        timeout:(NSTimeInterval)seconds {
  EDOHostService *service = [[self alloc] initWithPort:0
                                            rootObject:object
                                           serviceName:name
                                                 queue:queue
                                            isToDevice:YES];
  [service edo_registerServiceAsyncOnDevice:deviceSerial timeout:seconds];
  return service;
}

- (instancetype)initWithPort:(UInt16)port
                  rootObject:(id)object
                 serviceName:(NSString *)serviceName
                       queue:(dispatch_queue_t)queue
                  isToDevice:(BOOL)isToDevice {
  self = [super init];
  if (self) {
    _registeredToDevice = NO;
    _localObjects = [[NSMutableDictionary alloc] init];
    _localObjectsSyncQueue =
        dispatch_queue_create("com.google.edo.service.localObjects", DISPATCH_QUEUE_SERIAL);

    _localWeakObjects = [[NSMutableDictionary alloc] init];
    _localWeakObjectsSyncQueue =
        dispatch_queue_create("com.google.edo.service.localWeakObjects", DISPATCH_QUEUE_SERIAL);

    _handlerSet = [[NSMutableSet alloc] init];
    _handlerSyncQueue =
        dispatch_queue_create("com.google.edo.service.handlers", DISPATCH_QUEUE_SERIAL);

    _executionQueue = queue;
    _executor = [[EDOExecutor alloc] initWithQueue:queue];

    // Only creates the listen socket when the port is given or the root object is given so we need
    // to serve them at launch.
    if (isToDevice) {
      _port = [EDOServicePort servicePortWithPort:0 serviceName:serviceName];
    } else if (port != 0 || object) {
      _listenSocket = [self edo_createListenSocket:port];
      _port = [EDOServicePort servicePortWithPort:_listenSocket.socketPort.port
                                      serviceName:serviceName];
      [EDOHostNamingService.sharedService addServicePort:_port];
      NSLog(@"The EDOHostService (%p) is created and listening on %d", self, _port.hostPort.port);
    }

    _rootLocalObject = object;

    // TODO(haowoo): The service should hold the executingQueue, but the executionQueue now still
    //               holds the strong reference of the service, and we keep this behaviour for now
    //               as the client is relying on this behavior.
    if (queue) {
      dispatch_queue_set_specific(queue, gServiceKey, (void *)CFBridgingRetain(self),
                                  (dispatch_function_t)CFBridgingRelease);

      EDOWeakReference *selfRef = [[EDOWeakReference alloc] initWithObject:self];
      dispatch_queue_set_specific(queue, &kEDOExecutingQueueKey, (void *)CFBridgingRetain(selfRef),
                                  (dispatch_function_t)CFBridgingRelease);
    }
    self.originatingQueues = nil;
  }
  return self;
}

- (void)dealloc {
  [self invalidate];
}

- (void)invalidate {
  if (!self.listenSocket.valid) {
    return;
  }
  [EDOHostNamingService.sharedService removeServicePort:_port];
  [self.listenSocket invalidate];

  [self edo_removeServiceFromOriginatingQueues];

  // Remove the service from the executing queue.
  if (_executionQueue) {
    dispatch_queue_set_specific(_executionQueue, &kEDOExecutingQueueKey, NULL, NULL);
  }

  NSLog(@"The EDOHostService (%p) is invalidated on port %d", self, _port.hostPort.port);
}

- (EDOServicePort *)port {
  // If the listen socket is not created at launch, we create it only when it's being used for the
  // first time and the auto-assigned zero port is used. This is useful for the temporary services.
  if (!_port) {
    _listenSocket = [self edo_createListenSocket:0];
    _port = [EDOServicePort servicePortWithPort:_listenSocket.socketPort.port serviceName:nil];
    NSLog(@"The EDOHostService (%p) is created lazily and listening on %d", self,
          _port.hostPort.port);
  }
  return _port;
}

- (BOOL)isValid {
  return _listenSocket.valid;
}

- (dispatch_queue_t)executingQueue {
  return _executionQueue;
}

- (void)setOriginatingQueues:(NSArray<dispatch_queue_t> *)originatingQueues {
  [self edo_removeServiceFromOriginatingQueues];

  originatingQueues = originatingQueues ?: [[NSArray alloc] init];

  // TODO(haowoo): Change to executingQueue entirely once we fix the ownership and remove weak.
  dispatch_queue_t executingQueue = _executionQueue;
  if (executingQueue) {
    originatingQueues = [originatingQueues arrayByAddingObject:executingQueue];
  }

  NSMutableArray<EDOWeakReference *> *queues =
      [NSMutableArray arrayWithCapacity:originatingQueues.count];
  EDOWeakReference *selfRef = [[EDOWeakReference alloc] initWithObject:self];
  for (dispatch_queue_t queue in originatingQueues) {
    [queues addObject:[[EDOWeakReference alloc] initWithObject:queue]];
    dispatch_queue_set_specific(queue, &kEDOOriginatingQueueKey, (void *)CFBridgingRetain(selfRef),
                                (dispatch_function_t)CFBridgingRelease);
  }
  _originatingWeakQueues = [queues copy];
}

- (NSArray<dispatch_queue_t> *)originatingQueues {
  NSMutableArray<dispatch_queue_t> *queues = [[NSMutableArray alloc] init];
  for (EDOWeakReference *weakQueue in _originatingWeakQueues) {
    dispatch_queue_t queue = weakQueue.object;
    if (!queue) {
      continue;
    }
    [queues addObject:queue];
  }
  return [queues copy];
}

#pragma mark - Private

- (void)edo_removeServiceFromOriginatingQueues {
  for (EDOWeakReference *weakQueue in _originatingWeakQueues) {
    dispatch_queue_t queue = weakQueue.object;
    if (!queue) {
      continue;
    }
    dispatch_queue_set_specific(queue, &kEDOOriginatingQueueKey, NULL, NULL);
  }
  _originatingWeakQueues = nil;
}

- (EDOObject *)distantObjectForLocalObject:(id)object hostPort:(EDOHostPort *)hostPort {
  // TODO(haowoo): The edoObject shouldn't be shared across different services, currently there is
  //               only one edoObject associated with the underlying object. We need to have a
  //               edoObject for each service per object.

  BOOL isObjectBlock = [EDOBlockObject isBlock:object];
  // We need to make a copy for the block object. This will move the stack block to the heap so
  // we can still access it. For other types of blocks, i.e. global and malloc, it may only increase
  // the retain count.
  // Here we let ARC copy the block properly and we can then safely retain the resulting block.
  if (isObjectBlock) {
    object = [object copy];
  }

  NSNumber *objectKey = [NSNumber numberWithLongLong:(EDOPointerType)object];
  if (object != self.rootLocalObject) {
    dispatch_sync(_localObjectsSyncQueue, ^{
      if (![self.localObjects objectForKey:objectKey]) {
        [self.localObjects setObject:object forKey:objectKey];
      }
    });
  }

  hostPort = hostPort ?: self.port.hostPort;
  EDOServicePort *port = [EDOServicePort servicePortWithPort:self.port hostPort:hostPort];

  if (isObjectBlock) {
    return [EDOBlockObject edo_remoteProxyFromUnderlyingObject:object withPort:port];
  } else {
    return [EDOObject edo_remoteProxyFromUnderlyingObject:object withPort:port];
  }
}

- (BOOL)isObjectAlive:(EDOObject *)object {
  // TODO(haowoo): There can be different strategies to evict the object from the local cache,
  //               we should check if the object is still in the cache (self.localObjects).
  return [self.port match:object.servicePort];
}

- (BOOL)removeObjectWithAddress:(EDOPointerType)remoteAddress {
  NSNumber *edoKey = [NSNumber numberWithLongLong:remoteAddress];
  __block NSObject *object NS_VALID_UNTIL_END_OF_SCOPE;
  dispatch_sync(_localObjectsSyncQueue, ^{
    // Transfer the ownership of local object to the outer queue, where the object should be
    // released.
    object = self.localObjects[edoKey];
    [self.localObjects removeObjectForKey:edoKey];
  });
  return YES;
}

- (BOOL)removeWeakObjectWithAddress:(EDOPointerType)remoteAddress {
  NSNumber *edoKey = [NSNumber numberWithLongLong:remoteAddress];
  dispatch_sync(_localWeakObjectsSyncQueue, ^{
    [self.localWeakObjects removeObjectForKey:edoKey];
  });
  return YES;
}

- (BOOL)addWeakObject:(EDOObject *)object {
  NSNumber *edoKey = [NSNumber numberWithLongLong:object.remoteAddress];
  dispatch_sync(_localWeakObjectsSyncQueue, ^{
    [self.localWeakObjects setObject:object forKey:edoKey];
  });
  return YES;
}

- (void)startReceivingRequestsForChannel:(id<EDOChannel>)channel {
  __block __weak EDOChannelReceiveHandler weakHandlerBlock;
  __weak EDOHostService *weakSelf = self;

  // This handler block will be executed recursively by calling itself at the end of the
  // block in order to accept new request after last one is executed.
  // It is the strong reference of @c weakHandlerBlock above.
  EDOChannelReceiveHandler receiveHandler = ^(id<EDOChannel> targetChannel, NSData *data,
                                              NSError *error) {
    EDOChannelReceiveHandler strongHandlerBlock = weakHandlerBlock;
    EDOHostService *strongSelf = weakSelf;
    NSException *exception;
    // TODO(haowoo): Add the proper error handler.
    NSAssert(error == nil, @"Failed to receive the data (%d) for %@.",
             strongSelf.port.hostPort.port, error);
    if (data == nil) {
      // the client socket is closed.
      NSLog(@"The channel (%p) with port %d is closed", targetChannel,
            strongSelf.port.hostPort.port);
      dispatch_queue_t handlerSyncQueue = strongSelf.handlerSyncQueue;
      if (handlerSyncQueue) {
        dispatch_sync(handlerSyncQueue, ^{
          [strongSelf.handlerSet removeObject:strongHandlerBlock];
        });
      }
      return;
    }
    EDOServiceRequest *request;

    @try {
      request = [NSKeyedUnarchiver edo_unarchiveObjectWithData:data];
    } @catch (NSException *e) {
      // TODO(haowoo): Handle exceptions in a better way.
      exception = e;
    }
    if (![request matchesService:strongSelf.port]) {
      // TODO(ynzhang): With better error handling, we may not throw exception in this
      // case but return an error response.
      NSError *error;

      if (!request) {
        // Error caused by the unarchiving process.
        error = [NSError errorWithDomain:exception.reason code:0 userInfo:nil];
      } else {
        error = [NSError errorWithDomain:NSPOSIXErrorDomain code:0 userInfo:nil];
      }
      EDOServiceResponse *errorResponse = [EDOErrorResponse errorResponse:error forRequest:request];
      NSData *errorData = [NSKeyedArchiver edo_archivedDataWithObject:errorResponse];
      [targetChannel sendData:errorData
          withCompletionHandler:^(id<EDOChannel> _Nonnull _channel, NSError *_Nullable error) {
            dispatch_queue_t handlerSyncQueue = strongSelf.handlerSyncQueue;
            if (handlerSyncQueue) {
              dispatch_sync(handlerSyncQueue, ^{
                [strongSelf.handlerSet removeObject:strongHandlerBlock];
              });
            }
          }];
    } else {
      // For release request, we don't handle it in executor since response is not
      // needed for this request. The request handler will process this request
      // properly in its own queue.
      if ([request class] == [EDOObjectReleaseRequest class]) {
        dispatch_queue_t executionQueue = strongSelf.executionQueue;
        if (executionQueue) {
          dispatch_async(executionQueue, ^{
            [EDOObjectReleaseRequest requestHandler](request, weakSelf);
          });
        } else {
          [EDOObjectReleaseRequest requestHandler](request, strongSelf);
        }
      } else {
        // Health check for the channel.
        [targetChannel sendData:EDOClientService.pingMessageData withCompletionHandler:nil];
        NSString *requestClassName = NSStringFromClass([request class]);
        EDORequestHandler handler = EDOHostService.handlers[requestClassName];
        __block EDOServiceResponse *response = nil;
        NSError *error;
        if (handler) {
          __weak EDOServiceRequest *weakRequest = request;
          void (^requestHandler)(void) = ^{
            uint64_t currentTime = mach_absolute_time();
            response = handler(weakRequest, weakSelf);
            response.duration = EDOGetMillisecondsSinceMachTime(currentTime);
          };
          BOOL isHandled = [strongSelf.executor handleBlock:requestHandler error:&error];
          if (!isHandled) {
            response = [EDOErrorResponse errorResponse:error forRequest:request];
          }
        }

        response = response ?: [EDOErrorResponse unhandledErrorResponseForRequest:request];
        NSData *responseData = [NSKeyedArchiver edo_archivedDataWithObject:response];
        [targetChannel sendData:responseData withCompletionHandler:nil];
      }
      if ([strongSelf edo_shouldReceiveData:channel]) {
        [targetChannel receiveDataWithHandler:strongHandlerBlock];
      }
    }
    // Channel will be released and invalidated if service becomes invalid. So the
    // recursive block will eventually finish after service is invalid.
  };
  // Move the receiveHandler block to the heap by explicitly copying before assigning it to the
  // weak pointer as in the latest clang compiler, it's possible the weak pointer can be invalid if
  // the block hasn't been moved to the heap in time.
  // https://reviews.llvm.org/D58514
  receiveHandler = [receiveHandler copy];
  weakHandlerBlock = receiveHandler;

  // The channel is strongly referenced in receiveHandler until the channel or the host service is
  // invalidated.
  [channel receiveDataWithHandler:receiveHandler];

  dispatch_sync(self.handlerSyncQueue, ^{
    [self.handlerSet addObject:receiveHandler];
  });
}

- (EDOSocket *)edo_createListenSocket:(UInt16)port {
  __weak EDOHostService *weakSelf = self;
  return [EDOSocket listenWithTCPPort:port
                                queue:nil
                       connectedBlock:^(EDOSocket *socket, NSError *error) {
                         EDOHostService *strongSelf = weakSelf;
                         if (!strongSelf) {
                           // TODO(haowoo): Add more info to the response when the service becomes
                           // invalid.
                           [socket invalidate];
                           return;
                         }

                         id<EDOChannel> clientChannel = [EDOSocketChannel channelWithSocket:socket];
                         [strongSelf startReceivingRequestsForChannel:clientChannel];
                       }];
}

- (void)edo_registerServiceAsyncOnDevice:(NSString *)deviceSerial timeout:(NSTimeInterval)seconds {
  __block NSTimeInterval secondsLeft = seconds;
  // The time interval of registration retry interval.
  NSTimeInterval retryInterval = 1;
  dispatch_queue_t backgroundQueue = dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0);

  // Keep trying to register the service before timeout. Using dispatch_after instead of CFRunloop
  // since there is no source/timer by default for runloop of a backgroud thread.
  __block __weak void (^weakServiceRegistrationBlock)(void);
  void (^serviceRegistrationBlock)(void) = serviceRegistrationBlock = ^void(void) {
    NSError *error;
    BOOL success = [self edo_registerServiceOnDevice:deviceSerial error:&error];
    if (!success && secondsLeft > 0) {
      secondsLeft -= retryInterval;
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, retryInterval * NSEC_PER_SEC),
                     backgroundQueue, weakServiceRegistrationBlock);
    } else {
      if (success) {
        NSLog(@"The EDOHostService %@ is registered to device %@", self->_port.hostPort.name,
              deviceSerial);
        self.registeredToDevice = YES;
      } else {
        NSLog(@"Timeout: unable to register service %@ on device %@.", self->_port.hostPort.name,
              deviceSerial);
      }
    }
  };
  // See the comment above about https://reviews.llvm.org/D58514.
  serviceRegistrationBlock = [serviceRegistrationBlock copy];
  weakServiceRegistrationBlock = serviceRegistrationBlock;
  dispatch_async(backgroundQueue, serviceRegistrationBlock);
}

- (BOOL)edo_registerServiceOnDevice:(NSString *)deviceSerial error:(NSError **)error {
  __block NSError *connectionError;
  EDOHostNamingService *namingService =
      [EDOClientService namingServiceWithDeviceSerial:deviceSerial error:&connectionError];
  if (!connectionError) {
    UInt16 port = namingService.serviceConnectionPort;
    // dispatch channel connected to the registration service on device.
    dispatch_io_t deviceChannel =
        [EDODeviceConnector.sharedConnector connectToDevice:deviceSerial
                                                     onPort:port
                                                      error:&connectionError];
    NSString *name = _port.hostPort.name;

    if (!connectionError && deviceChannel) {
      // Channel in the host side to receive requests.
      id<EDOChannel> channel = [[EDOSocketChannel alloc] initWithDispatchIO:deviceChannel];
      NSData *data = [name dataUsingEncoding:NSUTF8StringEncoding];
      dispatch_semaphore_t lock = dispatch_semaphore_create(0);
      [channel sendData:data
          withCompletionHandler:^(id<EDOChannel> channel, NSError *channelError) {
            if (channelError) {
              connectionError = channelError;
            } else {
              [self startReceivingRequestsForChannel:channel];
            }
            dispatch_semaphore_signal(lock);
          }];
      dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    }
  }
  if (error) {
    *error = connectionError;
  }
  return connectionError == nil;
}

- (BOOL)edo_shouldReceiveData:(id<EDOChannel>)channel {
  // If listenSocket is nil and port number is 0, it indicates a service on Mac for iOS device.
  if (!_listenSocket && _port.port == 0) {
    return channel.isValid;
  }
  return channel.isValid && _listenSocket.valid;
}

@end
