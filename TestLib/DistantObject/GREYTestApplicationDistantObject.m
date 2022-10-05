//
// Copyright 2017 Google Inc.
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

#import "GREYTestApplicationDistantObject.h"
#import <UIKit/UIKit.h>

#include <stdatomic.h>
#include <stddef.h>

#import "GREYAssertionBlock.h"
#import "GREYFatalAsserts.h"
#import "GREYTestApplicationDistantObject+Private.h"
#import "GREYError.h"
#import "GREYErrorConstants.h"
#import "GREYFrameworkException.h"
#import "GREYConstants.h"
#import "GREYElementMatcherBlock.h"
#import "GREYTestConfiguration.h"
#import "GREYRemoteExecutor.h"
#import "EDOChannel.h"
#import "EDOChannelPool.h"
#import "EDOHostPort.h"
#import "EDOHostService.h"
#import "EDORemoteVariable.h"
#import "EDOServiceError.h"
#import "EDOServicePort.h"
#import "NSObject+EDOBlockedType.h"


/** Checks if main queue has eDO host service. */
static BOOL IsEDOServiceHostedOnMainQueue(void) {
  return [EDOHostService serviceForOriginatingQueue:dispatch_get_main_queue()] != nil;
}

/** The maximum time to wait for the eDO host ports of app-under-test for CI or OSS runs. */
static const int64_t kPortAllocationWaitTime = 30 * NSEC_PER_SEC;

/** The context key to verify test host's executing queue. */
static const void *gGREYTestExecutingQueueKey = &gGREYTestExecutingQueueKey;


@interface GREYTestApplicationDistantObject ()

/** @see GREYTestApplicationDistantObject.hostApplicationDead in private header. */
@property(nonatomic, getter=isHostApplicationStopped) BOOL hostApplicationStopped;

/** @see GREYTestApplicationDistantObject::dispatchPolicy. Make this readwrite. */
@property(nonatomic) GREYRemoteExecutionDispatchPolicy dispatchPolicy;

/**
 * Checks if @c port is a permanent eDO host port that is listening by the test host. A permanent
 * eDO host runs throughout the app's life cycle. This declaration is required by the constructor
 * C function.
 *
 * @param port The port number to check.
 *
 * @return @c YES if @c port is the port number that is listened by any eDO host running in the
 *         test host; @c NO otherwise.
 */
- (BOOL)isPermanentAppHostPort:(uint16_t)port;
@end

/** Constructs error recovery suggestion message. */
static NSString *GetErrorRecoverySuggestion(void) {
  NSString *recoverySuggestion =
      @"Unless your tests explicitly relaunch the app, it won't be restarted. Any requests from "
      @"the test to the app side will fail. Use "
      @"GREYTestApplicationDistantObject.hostApplicationRelaunchHandler to register a callback "
      @"that will be invoked when your app crashes. In this callback you can clean up your "
      @"test-side remote objects and relaunch your app.";
  NSString *troubleShootInfo =
      @" To troubleshoot more, take a look at crash files in ~/Library/Logs/DiagnosticReports";
  return [NSString stringWithFormat:@"%@%@", recoverySuggestion, troubleShootInfo];
}

/** Intializes test-side distant object and failure handler. */;
__attribute__((constructor)) static void SetupTestDistantObject(void) {
  // Registers custom handler of EDO connection failure and translates the error message to UI
  // testing scenarios to users. The custom handler will fall back to use EDO's default error
  // handler if the state of the test doesn't conform to any pattern of the UI testing failure.
  EDOSetClientErrorHandler(^(NSError *error) {
    GREYTestApplicationDistantObject *testDistantObject =
        GREYTestApplicationDistantObject.sharedInstance;
    if (error.code == EDOServiceErrorCannotConnect) {
      EDOHostPort *hostPort = error.userInfo[EDOErrorPortKey];
      if ([testDistantObject isPermanentAppHostPort:hostPort.port]) {
        testDistantObject.hostApplicationStopped = YES;
        NSString *exceptionReason = @"App crashed and disconnected.";
        NSString *recoverySuggestion = GetErrorRecoverySuggestion();
        NSString *errorInfo =
            [NSString stringWithFormat:@"\n\nException Reason:\n%@\n\nRecovery Suggestion:\n%@",
                                       exceptionReason, recoverySuggestion];
        [[GREYFrameworkException exceptionWithName:kGREYGenericFailureException
                                            reason:errorInfo] raise];
      }
    } else if (error.code == EDOServiceErrorConnectTimeout) {
      NSString *exceptionReason = @"App process is hanging.";
      NSString *recoverySuggestion =
          @"App is still running but isn't accepting any network requests. It's likely that "
          @"the app-process has encountered critical issues (e.g. crash) but fails to "
          @"release itself. Please check the application logs to debug further.";
      NSString *errorInfo =
          [NSString stringWithFormat:@"\n\nException Reason:\n%@\n\nRecovery Suggestion:\n%@",
                                     exceptionReason, recoverySuggestion];
      [[GREYFrameworkException exceptionWithName:kGREYGenericFailureException
                                          reason:errorInfo] raise];
    } else {
      NSString *exceptionReason =
          [NSString stringWithFormat:@"eDO invocation in the EarlGrey test-process failed with an "
                                     @"uncommon error code: %ld.",
                                     error.code];
      NSString *recoverySuggestion = [NSString
          stringWithFormat:
              @"Please file a bug for this rare case at %@ with the stack-trace below:\n\n%@",
              GREYBugDestination(), NSThread.callStackSymbols.description];
      NSString *errorInfo =
          [NSString stringWithFormat:@"\n\nException Reason:\n%@\n\nRecovery Suggestion:\n%@",
                                     exceptionReason, recoverySuggestion];
      [[GREYFrameworkException exceptionWithName:kGREYGenericFailureException
                                          reason:errorInfo] raise];
    }
  });
}

@implementation GREYTestApplicationDistantObject {
  /**
   * The queue to execute the all the remote calls from app-under-test to the test side. It is
   * either the main queue or a background queue, determined by
   * GREYTestApplicationDistantObject::dispatchPolicy.
   */
  dispatch_queue_t _executingQueue;
  /** @see GREYTestApplicationDistantObject::service. This is the underlying ivar. */
  EDOHostService *_service;
  /** @see GREYTestApplicationDistantObject::hostPort. This is the underlying ivar. */
  uint16_t _hostPort;
  /**
   * The dispatch group for the task of fetching main-queue eDO port of app-under-test. The valid
   * port number of @c _hostPort is always assigned within the group.
   */
  dispatch_group_t _hostPortAllocationGroup;
  /** @see GREYTestApplicationDistantObject::hostBackgroundPort. This is the underlying ivar. */
  uint16_t _hostBackgroundPort;
  /**
   * The dispatch group for the task of fetching background-queue eDO port of app-under-test. The
   * valid port number of @c _hostBackgroundPort is always assigned within the group.
   */
  dispatch_group_t _hostBackgroundPortAllocationGroup;
  /**
   * The atomic flag for executing the initialization of GREYTestApplicationDistantObject::Service
   * once.
   */
  atomic_flag _serviceOneTimeInitializationFlag;
  /**
   * The dispatch group for the task of initializing GREYTestApplicationDistantObject::Service.
   * The service is always instantiated within the group.
   */
  dispatch_group_t _serviceInitializationGroup;
}

+ (instancetype)sharedInstance {
  static dispatch_once_t onceToken;
  static GREYTestApplicationDistantObject *application;
  dispatch_once(&onceToken, ^{
    application = [[self alloc] initOnce];
    [UIView edo_disallowRemoteInvocation];
    [UIViewController edo_disallowRemoteInvocation];
    [UIWindow edo_disallowRemoteInvocation];
    [GREYTestApplicationDistantObject edo_alwaysAllowRemoteInvocation];
    [GREYTestConfiguration edo_alwaysAllowRemoteInvocation];
    [GREYElementMatcherBlock edo_alwaysAllowRemoteInvocation];
    [GREYAssertionBlock edo_alwaysAllowRemoteInvocation];
    [EDORemoteVariable edo_alwaysAllowRemoteInvocation];
    // TODO(b/235243280): Use class type instead.
    [NSClassFromString(@"EarlGreyImpl") edo_alwaysAllowRemoteInvocation];
  });
  return application;
}

- (instancetype)initOnce {
  self = [super init];
  if (self) {
    _dispatchPolicy = GREYRemoteExecutionDispatchPolicyMain;
    _hostPortAllocationGroup = dispatch_group_create();
    dispatch_group_enter(_hostPortAllocationGroup);
    _hostBackgroundPortAllocationGroup = dispatch_group_create();
    dispatch_group_enter(_hostBackgroundPortAllocationGroup);
    _serviceInitializationGroup = dispatch_group_create();
    dispatch_group_enter(_serviceInitializationGroup);
  }
  return self;
}

- (EDOHostService *)service {
  if (!atomic_flag_test_and_set(&_serviceOneTimeInitializationFlag)) {
    GREYFatalAssertWithMessage(!IsEDOServiceHostedOnMainQueue(),
                               @"Unable to register EarlGrey's eDO service on the main thread as "
                               @"there's one already running.");
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    GREYRemoteExecutionDispatchPolicy dispatchPolicy = self.dispatchPolicy;
    if (dispatchPolicy == GREYRemoteExecutionDispatchPolicyMain) {
      _executingQueue = mainQueue;
      _service = [EDOHostService serviceWithPort:0 rootObject:self queue:_executingQueue];
    } else {
      _executingQueue = dispatch_queue_create("com.google.earlgrey.TestDO", DISPATCH_QUEUE_SERIAL);
      _service = [EDOHostService serviceWithPort:0 rootObject:self queue:_executingQueue];
      _service.originatingQueues = @[ mainQueue ];
    }
    dispatch_queue_set_specific(_executingQueue, &gGREYTestExecutingQueueKey,
                                (void *)gGREYTestExecutingQueueKey, NULL);
    dispatch_group_leave(_serviceInitializationGroup);
  }
  dispatch_group_wait(_serviceInitializationGroup, DISPATCH_TIME_FOREVER);
  return _service;
}

- (uint16_t)servicePort {
  return self.service.port.port;
}

- (uint16_t)hostPort {
  if (_hostPort == 0) {
    // Waits up to 30 seconds until @c _hostPort has been changed to a nonzero value.
    dispatch_time_t timeout = AllocationWaitTime();
    if ([NSThread isMainThread]) {
      GREYExecuteSyncBlockInBackgroundQueue(^{
        dispatch_group_wait(self->_hostPortAllocationGroup, timeout);
      });
    } else {
      dispatch_group_wait(_hostPortAllocationGroup, timeout);
    }
    GREYFatalAssertWithMessage(_hostPort != 0,
                               @"Host port not assigned. Application under test may have failed "
                               @"to launch and/or does not link to EarlGrey's AppFramework.");
  }
  return _hostPort;
}

- (void)setHostPort:(uint16_t)hostPort {
  GREYFatalAssertWithMessage(dispatch_get_specific(&gGREYTestExecutingQueueKey),
                             @"Host port should be set on the queue that handles app-under-test "
                             @"side remote call.");
  uint16_t currentPort = _hostPort;
  _hostPort = hostPort;
  if (currentPort != 0 && hostPort == 0) {
    dispatch_group_enter(_hostPortAllocationGroup);
  } else if (currentPort == 0 && hostPort != 0) {
    dispatch_group_leave(_hostPortAllocationGroup);
  }
}

- (uint16_t)hostBackgroundPort {
  if (_hostBackgroundPort == 0) {
    // Waits up to 30 seconds until @c _hostBackgroundPort has been changed to a nonzero value.
    dispatch_time_t timeout = AllocationWaitTime();
    if ([NSThread isMainThread]) {
      GREYExecuteSyncBlockInBackgroundQueue(^{
        dispatch_group_wait(self->_hostBackgroundPortAllocationGroup, timeout);
      });
    } else {
      dispatch_group_wait(_hostBackgroundPortAllocationGroup, timeout);
    }
    GREYFatalAssertWithMessage(_hostBackgroundPort != 0,
                               @"Host background port not assigned. Application under test may "
                               @"have failed to launch and/or "
                               @"does not link to EarlGrey's AppFramework.");
  }
  return _hostBackgroundPort;
}

- (void)setHostBackgroundPort:(uint16_t)hostBackgroundPort {
  GREYFatalAssertWithMessage(dispatch_get_specific(&gGREYTestExecutingQueueKey),
                             @"Host background port should be set on the queue that handles "
                             @"app-under-test side remote call.");
  uint16_t currentPort = _hostBackgroundPort;
  _hostBackgroundPort = hostBackgroundPort;
  if (currentPort != 0 && hostBackgroundPort == 0) {
    dispatch_group_enter(_hostBackgroundPortAllocationGroup);
  } else if (currentPort == 0 && hostBackgroundPort != 0) {
    dispatch_group_leave(_hostBackgroundPortAllocationGroup);
  }
}

- (BOOL)setDispatchPolicy:(GREYRemoteExecutionDispatchPolicy)dispatchPolicy
                    error:(NSError **)error {
  GREYFatalAssertWithMessage(dispatchPolicy == GREYRemoteExecutionDispatchPolicyMain ||
                                 dispatchPolicy == GREYRemoteExecutionDispatchPolicyBackground,
                             @"Received unexpected policy: %lu", (unsigned long)dispatchPolicy);
  // Checks if there's already an EDOHostService serving test's main queue. If that's the case,
  // this class already created the EDOHostService to serve remote invocations from the app side.
  // We cannot override the existing EDOHostService or reset the executing queue, otherwise
  // app-under-test will crash when it calls the stale EDOObject.
  if (!IsEDOServiceHostedOnMainQueue()) {
    _dispatchPolicy = dispatchPolicy;
  } else {
    if (error) {
      NSString *reason = @"Failed to set dispatch policy of remote execution. You cannot set "
                         @"dispatch policy after XCUIApplication::launch.";
      NSString *recoverySuggestion =
          @"Move it before the launch or inside an attribute constructor before your tests launch "
          @"the app";
      NSDictionary<NSString *, NSString *> *userInfo =
          @{kErrorDetailRecoverySuggestionKey : recoverySuggestion};
      *error =
          GREYErrorMakeWithUserInfo(kGREYIntializationErrorDomain,
                                    GREYIntializationServiceAlreadyExistError, reason, userInfo);
    }
    return NO;
  }
  return YES;
}

- (BOOL)hostActiveWithAppComponent {
  uint16_t portNumber = self.pingMessagePort;
  if (!portNumber) {
    return NO;
  }

  NSError *connectionError;
  EDOHostPort *hostPort = [EDOHostPort hostPortWithLocalPort:portNumber];
  id<EDOChannel> channel = [EDOChannelPool.sharedChannelPool channelWithPort:hostPort
                                                                       error:&connectionError];
  if (connectionError) {
    return NO;
  }

  dispatch_semaphore_t waitLock = dispatch_semaphore_create(0);
  __block BOOL hostAlive = NO;
  NSData *request = [kHostPingRequestMessage dataUsingEncoding:NSUTF8StringEncoding];
  [channel sendData:request withCompletionHandler:nil];
  [channel receiveDataWithHandler:^(id<EDOChannel> _Nonnull targetChannel, NSData *_Nullable data,
                                    NSError *_Nullable error) {
    if (data) {
      NSString *response = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
      hostAlive = [response isEqualToString:kHostPingSuccessMessage];
    }
    dispatch_semaphore_signal(waitLock);
  }];
  if (!dispatch_semaphore_wait(waitLock, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC))) {
    [EDOChannelPool.sharedChannelPool addChannel:channel forPort:hostPort];
  }
  return hostAlive;
}

- (void)resetHostArguments {
  // Checks if the method is called on @c _executingQueue. If it's not, it dispatches the resetting
  // procedure to that queue.
  if (!dispatch_get_specific(&gGREYTestExecutingQueueKey)) {
    dispatch_sync(_executingQueue, ^{
      [self resetHostArguments];
    });
    return;
  }
  self.hostPort = 0;
  self.hostBackgroundPort = 0;
  self.pingMessagePort = 0;
  self.hostApplicationStopped = NO;
  self.hostLaunchedWithAppComponent = NO;
}

#pragma mark - Private

- (BOOL)isPermanentAppHostPort:(uint16_t)port {
  return port != 0 && (port == _hostPort || port == _hostBackgroundPort);
}

/** @return The dispatch_time_t to wait for port allocation. */
static dispatch_time_t AllocationWaitTime(void) {
  return dispatch_time(DISPATCH_TIME_NOW, kPortAllocationWaitTime);
}

@end
