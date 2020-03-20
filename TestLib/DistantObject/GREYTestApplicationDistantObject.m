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

#import <XCTest/XCTest.h>

#import "GREYFatalAsserts.h"
#import "GREYHostBackgroundDistantObject.h"
#import "GREYTestApplicationDistantObject+Private.h"
#import "GREYFrameworkException.h"
#import "GREYRemoteExecutor.h"
#import "EDOHostPort.h"
#import "EDOClientService.h"
#import "EDOHostService.h"
#import "EDOServiceError.h"
#import "EDOServiceException.h"
#import "EDOServicePort.h"
#import "NSObject+EDOBlacklistedType.h"

/** The maximum time to wait for the eDO host ports of app-under-test. */
static const int64_t kPortAllocationWaitTime = 30 * NSEC_PER_SEC;

@interface GREYTestApplicationDistantObject ()
/** @see GREYTestApplicationDistantObject.service, make this readwrite. */
@property EDOHostService *service;
/** @see GREYTestApplicationDistantObject.hostApplicationDead in private header. */
@property(getter=isHostApplicationTerminated) BOOL hostApplicationTerminated;

/**
 *  Checks if @c port is a permanent eDO host port that is listening by the test host. A permanent
 *  eDO host runs throughout the app's life cycle. This declaration is required by the constructor
 *  C function.
 *
 *  @param port The port number to check.
 *
 *  @return @c YES if @c port is the port number that is listened by any eDO host running in the
 *          test host; @c NO otherwise.
 */
- (BOOL)isPermanentAppHostPort:(uint16_t)port;
@end

/** Intializes test-side distant object and failure handler. */;
__attribute__((constructor)) static void SetupTestDistantObject() {
  GREYTestApplicationDistantObject *testDistantObject =
      GREYTestApplicationDistantObject.sharedInstance;
  testDistantObject.service = [EDOHostService serviceWithPort:0
                                                   rootObject:testDistantObject
                                                        queue:dispatch_get_main_queue()];

  // Registers custom handler of EDO connection failure and translates the error message to UI
  // testing scenarios to users. The custom handler will fall back to use EDO's default error
  // handler if the state of the test doesn't conform to any pattern of the UI testing failure.
  void (^defaultHandler)(NSError *) = EDOClientService.errorHandler;
  EDOClientService.errorHandler = ^(NSError *error) {
    if (error.code == EDOServiceErrorCannotConnect) {
      EDOHostPort *hostPort = error.userInfo[EDOErrorPortKey];
      if ([testDistantObject isPermanentAppHostPort:hostPort.port]) {
        testDistantObject.hostApplicationTerminated = YES;
        NSString *errorInfo;
        errorInfo =
            @"App-under-test crashed and disconnected. Unless your tests explicitly relaunch the "
            @"app, the app won't be restarted and thus any requests from test to app side will "
            @"fail. You can register "
            @"GREYTestApplicationDistantObject.hostApplicationRelaunchHandler to relaunch your app "
            @"and clean up your test-side remote objects. To troubleshoot the app's crash, check "
            @"if any crash log was generated in the application's process.";
        [[GREYFrameworkException exceptionWithName:kGREYGenericFailureException
                                            reason:errorInfo] raise];
      }
    }
    defaultHandler(error);
  };
}

@implementation GREYTestApplicationDistantObject {
  /** @see GREYTestApplicationDistantObject::hostPort. This is the underlying ivar. */
  uint16_t _hostPort;
  /**
   *  The dispatch group for the task of fetching main-queue eDO port of app-under-test. The valid
   *  port number of @c _hostPort is always assigned within the group.
   */
  dispatch_group_t _hostPortAllocationGroup;
  /** @see GREYTestApplicationDistantObject::hostBackgroundPort. This is the underlying ivar. */
  uint16_t _hostBackgroundPort;
  /**
   *  The dispatch_group for the task of fetching background-queue eDO port of app-under-test. The
   *  valid port number of @c _hostBackgroundPort is always assigned within the group.
   */
  dispatch_group_t _hostBackgroundPortAllocationGroup;
}

+ (instancetype)sharedInstance {
  static dispatch_once_t onceToken;
  static GREYTestApplicationDistantObject *application;
  dispatch_once(&onceToken, ^{
    application = [[self alloc] init];
    [UIView edo_disallowRemoteInvocation];
    [UIViewController edo_disallowRemoteInvocation];
    [UIWindow edo_disallowRemoteInvocation];
  });
  return application;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _hostPortAllocationGroup = dispatch_group_create();
    dispatch_group_enter(_hostPortAllocationGroup);
    _hostBackgroundPortAllocationGroup = dispatch_group_create();
    dispatch_group_enter(_hostBackgroundPortAllocationGroup);
  }
  return self;
}

- (uint16_t)servicePort {
  return self.service.port.port;
}

- (uint16_t)hostPort {
  if (_hostPort == 0) {
    // Waits up to 30 seconds until @c _hostPort has been changed to a nonzero value.
    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, kPortAllocationWaitTime);
    if ([NSThread isMainThread]) {
      GREYExecuteSyncBlockInBackgroundQueue(^{
        dispatch_group_wait(_hostPortAllocationGroup, timeout);
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
  GREYFatalAssertMainThread();
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
    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, kPortAllocationWaitTime);
    if ([NSThread isMainThread]) {
      GREYExecuteSyncBlockInBackgroundQueue(^{
        dispatch_group_wait(_hostBackgroundPortAllocationGroup, timeout);
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
  GREYFatalAssertMainThread();
  uint16_t currentPort = _hostBackgroundPort;
  _hostBackgroundPort = hostBackgroundPort;
  if (currentPort != 0 && hostBackgroundPort == 0) {
    dispatch_group_enter(_hostBackgroundPortAllocationGroup);
  } else if (currentPort == 0 && hostBackgroundPort != 0) {
    dispatch_group_leave(_hostBackgroundPortAllocationGroup);
  }
}

- (void)resetHostArguments {
  self.hostPort = 0;
  self.hostBackgroundPort = 0;
  self.hostApplicationTerminated = NO;
}

#pragma mark - Private

- (BOOL)isPermanentAppHostPort:(uint16_t)port {
  return port != 0 && (port == _hostPort || port == _hostBackgroundPort);
}

@end
