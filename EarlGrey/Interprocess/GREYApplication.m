//
// Copyright 2016 Google Inc.
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

#import "GREYApplication.h"

#import <XCTest/XCTest.h>

#import "Additions/XCTestCase+GREYAdditions.h"
#import "Assertion/GREYAssertionDefines.h"
#import "Common/GREYAnalytics.h"
#import "Common/GREYCoder.h"
#import "Common/GREYExposed.h"
#import "Common/GREYPrivate.h"
#import "Event/GREYSyntheticEvents.h"
#import "Core/GREYElementInteraction.h"
#import "Interprocess/GREYMessage.h"

static NSString *const kClientInternalException = @"kClientInternalException";
static NSString *const kServerName = @"com.google.earlgrey";

static const CFTimeInterval kResponseTimeoutSeconds = 10;
static const CFTimeInterval kExecutionTimeoutSeconds = 180;
static const CFTimeInterval kPollIntervalSeconds = 0.01;

typedef NS_ENUM(NSInteger, GREYApplicationState) {
  kGREYApplicationStateLocal = 1,
  kGREYApplicationStateUnknown,
  kGREYApplicationStateLaunched,
  kGREYApplicationStateReady,
  kGREYApplicationStatePendingResponse,
  kGREYApplicationStatePerformingAction,
  kGREYApplicationStateNotResponding,
  kGREYApplicationStateTerminated,
  kGREYApplicationStateCrashed,
};

static NSMutableDictionary *gApps;
GREYApplication *gTargetApp;

@implementation GREYApplication {
  BOOL _connected;
  NSString *_connectionName;
  GREYApplicationState _state;
  /* server */
  NSError *_error;
  /* client */
  BOOL _exceptionSent;
}

static void listenerCallback(CFNotificationCenterRef center,
                             void *observer,
                             CFStringRef name,
                             const void *string,
                             CFDictionaryRef userInfo) {
  @autoreleasepool {
    NSData *data = [[NSData alloc] initWithBase64EncodedString:(__bridge NSString *)string options:0];
    [GREYApplication grey_callbackWithMessage:[NSKeyedUnarchiver unarchiveObjectWithData:data]];
  }
}

+ (void)load {
  // Register listener callback.
  NSString *clientName =
      [NSString stringWithFormat:@"%@.app.%@", kServerName, [[NSBundle mainBundle] bundleIdentifier]];
  CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(),
                                  NULL,
                                  listenerCallback,
                                  (CFStringRef)([GREYCoder isInXCTestProcess] ? kServerName : clientName),
                                  NULL,
                                  CFNotificationSuspensionBehaviorDeliverImmediately);
  gApps = [[NSMutableDictionary alloc] init];
  // If we are in XCTRunner, the target app bundle ID can be found in XCTestConfiguration.
  // If we are in not in XCTRunner but this process is running XCTest, then this must be a unit test
  // target and the target app bundle ID is the current bundle ID.
  NSString *_targetBundleID = [[XCTestConfiguration activeTestConfiguration] targetApplicationBundleID];
  if (!_targetBundleID) {
    _targetBundleID = [[NSBundle mainBundle] bundleIdentifier];
    NSAssert(_targetBundleID, @"mainBundle bundleIdentifier was nil");
  }
  gTargetApp = [[GREYApplication alloc] initWithBundleID:_targetBundleID];
  gApps[_targetBundleID] = gTargetApp;
  // Register as an observer for test case teardown.
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(grey_performCleanUpOnTearDown)
                                               name:kGREYXCTestCaseInstanceDidTearDown
                                             object:nil];
}

+ (GREYApplication *)targetApplication {
  return gTargetApp;
}

+ (GREYApplication *)systemApplication {
  I_CHECK_XCTEST_PROCESS();

  GREYApplication *app = gApps[@"com.apple.springboard"];
  NSAssert(app, @"system application not available");
  return app;
}

- (BOOL)isReady {
  I_CHECK_XCTEST_PROCESS();
  NSAssert(_state != kGREYApplicationStatePendingResponse &&
           _state != kGREYApplicationStatePerformingAction, @"app should not be in these states");
  
  if (_state == kGREYApplicationStateLocal) {
    return YES;
  }
  if (_state == kGREYApplicationStateLaunched) {
    [self grey_waitForStateChangeFromState:kGREYApplicationStateLaunched
                               withTimeout:kResponseTimeoutSeconds];
  }
  if (!_connected ||
      _state == kGREYApplicationStateCrashed ||
      _state == kGREYApplicationStateTerminated ||
      _state == kGREYApplicationStateNotResponding) {
    return NO;
  }
  _state = kGREYApplicationStatePendingResponse;
  [self grey_sendMessage:[GREYMessage messageForType:kGREYMessageCheckConnection]];
  // Wait for response.
  return [self grey_waitForStateChangeFromState:kGREYApplicationStatePendingResponse
                                    withTimeout:kResponseTimeoutSeconds];
}

- (void)launch {
  I_CHECK_XCTEST_PROCESS();
  NSAssert(_state != kGREYApplicationStateLocal && self == gTargetApp, @"only supported for remote target application");
  
  XCUIApplication *app = [[XCUIApplication alloc] init];
  NSMutableDictionary *d = [app.launchEnvironment mutableCopy];
  d[@"DYLD_INSERT_LIBRARIES"] = [GREYCoder relativeEarlGreyPath];
  app.launchEnvironment = d;
  _state = kGREYApplicationStateLaunched;
  [app launch];
  // Wait for app to connect.
  BOOL timedOut = ![self grey_waitForStateChangeFromState:kGREYApplicationStateLaunched
                                              withTimeout:kExecutionTimeoutSeconds];
  if (timedOut) {
    GREYFail(@"launch timed out waiting for app to connect");
  }
}

- (void)terminate {
  I_CHECK_XCTEST_PROCESS();
  NSAssert(_state != kGREYApplicationStateLocal && self == gTargetApp, @"only supported for remote target application");
  
  XCUIApplication *app = [[XCUIApplication alloc] init];
  _state = kGREYApplicationStateTerminated;
  [app terminate];
}

- (void)executeBlock:(GREYExecBlock)block {
  GREY_REMOTE1(self, return, Object, id, block);
  
  block();
}

- (void)execute:(GREYExecFunction)function {
  GREY_REMOTE1(self, return, Function, GREYExecFunction, function);
  
  function();
}

- (BOOL)rotateDeviceToOrientation:(UIDeviceOrientation)deviceOrientation errorOrNil:(__strong NSError **)errorOrNil {
  GREY_REMOTE2(self, return (!errorOrNil || *errorOrNil == nil),
               NSInteger, NSInteger, deviceOrientation,
               Out, NSError *__strong *, errorOrNil);
  
  return [GREYSyntheticEvents rotateDeviceToOrientation:deviceOrientation errorOrNil:errorOrNil];
}

- (GREYElementInteraction *)selectElementWithMatcher:(id<GREYMatcher>)elementMatcher {
  return [[GREYElementInteraction alloc] initWithApplication:self elementMatcher:elementMatcher];
}

- (void)makeRPCWithMessage:(GREYMessage *)message error:(__strong NSError **)errorOrNil {
  I_CHECK_XCTEST_PROCESS();
  NSAssert(_state == kGREYApplicationStateReady, @"application should be ready");
  NSAssert(!_error, @"error should be nil");
  NSAssert(message.type == kGREYMessageRPC, @"must be RPC message");
  
  [[GREYAnalytics sharedInstance] didInvokeEarlGrey];
  _state = kGREYApplicationStatePendingResponse;
  [self grey_sendMessage:message];
  if (![self grey_waitForStateChangeFromState:kGREYApplicationStatePendingResponse
                                  withTimeout:kResponseTimeoutSeconds]) {
    GREYFail(@"application timed out waiting for RPC to begin");
  }
  if (![self grey_waitForStateChangeFromState:kGREYApplicationStatePerformingAction
                                  withTimeout:kExecutionTimeoutSeconds]) {
    GREYFail(@"application timed out waiting for RPC to finish");
  }
  if (_error) {
    *errorOrNil = _error;
    _error = nil;
  }
}

#pragma mark - Private

+ (void)grey_performCleanUpOnTearDown {
  for (GREYApplication *app in [gApps allValues]) {
    if ([app isReady]) {
      [app grey_performCleanUpOnTearDown];
    }
  }
}

+ (void)grey_callbackWithMessage:(GREYMessage *)message {
  NSParameterAssert(message);

  if ([GREYCoder isInXCTestProcess]) {
    if (!gApps[message.origin]) {
      NSAssert(message.type == kGREYMessageConnect, @"new app must send connect first");

      gApps[message.origin] = [[GREYApplication alloc] initWithBundleID:message.origin];
    }
    [gApps[message.origin] grey_callbackWithMessage:message];
  } else {
    [gTargetApp grey_callbackWithMessage:message];
  }
}

- (instancetype)initWithBundleID:(NSString *)bundleID {
  NSParameterAssert(bundleID);

  self = [super init];
  if (self) {
    _bundleID = bundleID;
    NSString *clientName = [NSString stringWithFormat:@"%@.app.%@", kServerName, _bundleID];
    _connectionName = [GREYCoder isInXCTestProcess] ? clientName : kServerName;
    _connected = NO;
    if ([_bundleID isEqualToString:[[NSBundle mainBundle] bundleIdentifier]]) {
      _state = kGREYApplicationStateLocal;
    } else {
      _state = kGREYApplicationStateUnknown;
    }
    if (![GREYCoder isInXCTestProcess]) {
      [self grey_connectToServer];
    }
  }
  return self;
}

- (void)grey_sendMessage:(GREYMessage *)message {
  NSParameterAssert(message);
  NSAssert(_connected || message.type == kGREYMessageConnect, @"must be connected or connect message");

  NSString *string = [[NSKeyedArchiver archivedDataWithRootObject:message] base64EncodedStringWithOptions:0];
  CFNotificationCenterPostNotification(
      CFNotificationCenterGetDistributedCenter(), (CFStringRef)_connectionName, (CFStringRef)string, NULL, TRUE);
}

- (void)grey_callbackWithMessage:(GREYMessage *)message {
  NSParameterAssert(message);
  
  switch (message.type) {
    case kGREYMessageConnect:
      I_CHECK_XCTEST_PROCESS();
      NSAssert(_state != kGREYApplicationStateLocal, @"should not be called on a local application");
      NSAssert(!_connected, @"should not be connected");

      NSLog(@"GREYApplication %@ connected", message.origin);
      _connected = YES;
      _state = kGREYApplicationStateReady;
      [self grey_sendMessage:[GREYMessage messageForType:kGREYMessageAcceptConnection]];
      return;
    case kGREYMessageConnectionOK:
      I_CHECK_XCTEST_PROCESS();
      NSAssert(_state != kGREYApplicationStateLocal, @"should not be called on a local application");

      _state = kGREYApplicationStateReady;
      return;
    case kGREYMessageActionWillBegin:
      I_CHECK_XCTEST_PROCESS();
      NSAssert(_state != kGREYApplicationStateLocal, @"should not be called on a local application");

      _state = kGREYApplicationStatePerformingAction;
      return;
    case kGREYMessageActionDidFinish:
      I_CHECK_XCTEST_PROCESS();
      NSAssert(_state != kGREYApplicationStateLocal, @"should not be called on a local application");

      _state = kGREYApplicationStateReady;
      return;
    case kGREYMessageNSError:
      I_CHECK_XCTEST_PROCESS();
      NSAssert(_state != kGREYApplicationStateLocal, @"should not be called on a local application");
      NSAssert(!_error, @"error should be nil");

      _error = [message nsError];
      return;
    case kGREYMessageInvocationFileLine:
      I_CHECK_XCTEST_PROCESS();
      NSAssert(_state != kGREYApplicationStateLocal, @"should not be called on a local application");

      [greyFailureHandler setInvocationFile:[message filename] andInvocationLine:[message lineNumber]];
      return;
    case kGREYMessageException:
      I_CHECK_XCTEST_PROCESS();
      NSAssert(_state != kGREYApplicationStateLocal, @"should not be called on a local application");

      _state = [message details] ? kGREYApplicationStateReady : kGREYApplicationStateCrashed;
      [greyFailureHandler handleRemoteException:[message exception] exceptionLog:[message details]];
      return;
    case kGREYMessageAcceptConnection:
      I_CHECK_REMOTE_APPLICATION_PROCESS();
      
      _connected = YES;
      NSLog(@"EarlGrey client established a connection to the server");
      return;
    case kGREYMessageCheckConnection:
      I_CHECK_REMOTE_APPLICATION_PROCESS();
      
      [self grey_sendMessage:[GREYMessage messageForType:kGREYMessageConnectionOK]];
      return;
    case kGREYMessageRPC:
      I_CHECK_REMOTE_APPLICATION_PROCESS();
      
      if ([greyFailureHandler respondsToSelector:@selector(setScreenshotName:)]) {
        [greyFailureHandler setScreenshotName:[message screenshotName]];
      }
      CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^{
        @try {
          NSAssert(!_exceptionSent, @"no exception should have been sent");
          
          [self grey_sendMessage:[GREYMessage messageForType:kGREYMessageActionWillBegin]];
          NSError *error = nil;
          GREYSerializable *serializable = [message serializable];
          [serializable block](serializable, [message errorIsSet] ? &error : nil);
          if (error) {
            [self grey_sendMessage:[GREYMessage messageForNSError:error]];
          }
          [self grey_sendMessage:[GREYMessage messageForType:kGREYMessageActionDidFinish]];
          NSAssert(!_exceptionSent, @"no exception should have been sent");
        } @catch (NSException *exception) {
          if (![exception.name isEqualToString:kClientInternalException]) {
            [self grey_reportException:exception withLog:nil halt:NO];
            @throw;
          } else {
            NSAssert(_exceptionSent, @"exception should have been sent");
          }
        } @finally {
          _exceptionSent = NO;
          if ([greyFailureHandler respondsToSelector:@selector(setScreenshotName:)]) {
            [greyFailureHandler setScreenshotName:nil];
          }
        }
      });
      return;
  }
}

- (BOOL)grey_waitForStateChangeFromState:(GREYApplicationState)oldState
                             withTimeout:(CFTimeInterval)timeoutSeconds {
  I_CHECK_XCTEST_PROCESS();

  CFTimeInterval timeoutTime = CACurrentMediaTime() + timeoutSeconds;
  while (_state == oldState) {
    if (CACurrentMediaTime() > timeoutTime) {
      _state = kGREYApplicationStateNotResponding;
      return NO;
    }
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, kPollIntervalSeconds, false);
  }
  return YES;
}

- (void)grey_reportException:(NSException *)exception withLog:(NSString *)log halt:(BOOL)halt {
  I_CHECK_REMOTE_APPLICATION_PROCESS();
  
  [self grey_sendMessage:[GREYMessage messageForException:exception details:log]];
  _exceptionSent = YES;
  if (halt) {
    [[GREYFrameworkException exceptionWithName:kClientInternalException
                                        reason:@"Immediately halt execution in client"] raise];
  }
}

- (void)grey_connectToServer {
  I_CHECK_REMOTE_APPLICATION_PROCESS();

  if (!_connected) {
    [self grey_sendMessage:[GREYMessage messageForType:kGREYMessageConnect]];
    NSLog(@"EarlGrey client application sent connection request to the server");
    // Try again in 1 second if connection isn't established by then.
    [self performSelector:@selector(grey_connectToServer) withObject:nil afterDelay:1];
  }
}

- (void)grey_performCleanUpOnTearDown {
  GREY_REMOTE(self, return);

  [[GREYUIThreadExecutor sharedInstance] grey_forcedStateTrackerCleanUp];
}

// TODO: Improve.
- (id)initWithCoder:(NSCoder *)coder {
  I_CHECK_REMOTE_APPLICATION_PROCESS();

  self = [super init];
  return self;
}

// TODO: Improve.
- (void)encodeWithCoder:(NSCoder *)coder {
}

// TODO: Improve.
- (id)awakeAfterUsingCoder:(NSCoder *)coder {
  I_CHECK_REMOTE_APPLICATION_PROCESS();

  // Substitute target application.
  return [GREYApplication targetApplication];
}

@end
