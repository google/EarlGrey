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

#import "EarlGrey.h"

#import "GREYSyntheticEvents.h"
#import "GREYKeyboard.h"
#import "GREYAssertionDefinesPrivate.h"
#import "GREYFatalAsserts.h"
#import "GREYHostBackgroundDistantObject.h"
#import "GREYTestApplicationDistantObject.h"
#import "GREYError.h"
#import "GREYErrorConstants.h"
#import "GREYAppleInternals.h"
#import "GREYLogger.h"

#import "GREYXCTestAppleInternals.h"
#import "EarlGreyImpl+XCUIApplication.h"
#import "GREYElementInteractionErrorHandler.h"
#import "GREYElementInteractionProxy.h"
#import "GREYRemoteExecutor.h"
#import "GREYDefaultFailureHandler.h"
#import "EDOClientService.h"

/**
 *  Sets EarlGrey provided default failure handler if there's no failure handler set for the current
 *  thread.
 */
static inline void SetDefaultFailureHandler() {
  NSMutableDictionary *TLSDict = [[NSThread currentThread] threadDictionary];
  [TLSDict setValue:[[GREYDefaultFailureHandler alloc] init] forKey:GREYFailureHandlerKey];
}

/** Returns the current failure handler. If it's @c nil, sets the default one and returns it. */
static inline id<GREYFailureHandler> GREYGetCurrentFailureHandler() {
  NSMutableDictionary *TLSDict = [[NSThread currentThread] threadDictionary];
  id<GREYFailureHandler> handler = [TLSDict valueForKey:GREYFailureHandlerKey];
  if (!handler) {
    SetDefaultFailureHandler();
    handler = [TLSDict valueForKey:GREYFailureHandlerKey];
  }
  return handler;
}

@implementation EarlGreyImpl

/**
 *  Executes the specified @block in a remote executor background queue.
 *
 *  @param block The block to run in aremote executor background queue.
 */
static BOOL ExecuteSyncBlockInBackgroundQueue(BOOL (^block)(void)) {
  __block BOOL success;
  GREYExecuteSyncBlockInBackgroundQueue(^{
    success = block();
  });
  return success;
};

+ (void)load {
  // This needs to be done in load as there may be calls to GREYAssert APIs that access the failure
  // handler directy. If it's not set, they won't be able to raise an error.
  GREYGetCurrentFailureHandler();
}

+ (instancetype)invokedFromFile:(NSString *)fileName lineNumber:(NSUInteger)lineNumber {
  static EarlGreyImpl *instance = nil;
  static dispatch_once_t token = 0;
  dispatch_once(&token, ^{
    instance = [[EarlGreyImpl alloc] initOnce];
  });

  id<GREYFailureHandler> failureHandler = GREYGetCurrentFailureHandler();
  SEL invocationFileAndLineSEL = @selector(setInvocationFile:andInvocationLine:);
  if ([failureHandler respondsToSelector:invocationFileAndLineSEL]) {
    [failureHandler setInvocationFile:fileName andInvocationLine:lineNumber];
  }
  
  return instance;
}

- (instancetype)initOnce {
  self = [super init];
  return self;
}

- (id<GREYInteraction>)selectElementWithMatcher:(id<GREYMatcher>)elementMatcher {
  return [[GREYElementInteractionProxy alloc] initWithElementMatcher:elementMatcher];
}

- (BOOL)rotateDeviceToOrientation:(UIDeviceOrientation)deviceOrientation error:(NSError **)error {
  __block GREYError *rotationError = nil;
  BOOL success = ExecuteSyncBlockInBackgroundQueue(^{
    return [GREYSyntheticEvents rotateDeviceToOrientation:deviceOrientation error:&rotationError];
  });
  if (!success) {
    if (error) {
      *error = rotationError;
    } else {
      [GREYElementInteractionErrorHandler handleInteractionError:rotationError outError:nil];
    }
  }
  return success;
}

- (BOOL)dismissKeyboardWithError:(NSError **)error {
  __block GREYError *dismissalError = nil;
  BOOL success = ExecuteSyncBlockInBackgroundQueue(^{
    return [GREYKeyboard dismissKeyboardWithoutReturnKeyWithError:&dismissalError];
  });
  if (!success) {
    NSString *errorDescription =
        [NSString stringWithFormat:@"Failed to dismiss keyboard since it was not showing. "
                                   @"Internal Error: %@",
                                   dismissalError.description];
    dismissalError = GREYErrorMake(kGREYKeyboardDismissalErrorDomain,
                                   GREYKeyboardDismissalFailedErrorCode, errorDescription);
    if (error) {
      *error = dismissalError;
    } else {
      [GREYElementInteractionErrorHandler handleInteractionError:dismissalError outError:nil];
    }
  }
  return success;
}

- (BOOL)openDeeplinkURL:(NSString *)URL
          inApplication:(XCUIApplication *)application
                  error:(NSError **)error {
#if defined(__IPHONE_11_0)
  XCUIApplication *safariApp =
      [[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.mobilesafari"];
  [safariApp activate];
  BOOL success = [safariApp waitForState:XCUIApplicationStateRunningForeground timeout:30];
  I_GREYAssertTrue(success, @"Safari did not launch successfully.");

  // As Safari loads up for the first time, the URL is not clickable and we have to wait for the
  // app to be hittable for it.
  if (safariApp.hittable) {
    [safariApp.buttons[@"URL"] tap];
    [safariApp typeText:URL];
    [safariApp.buttons[@"Go"] tap];
  } else if (error) {
    *error = GREYErrorMake(kGREYDeeplinkErrorDomain, kGREYInteractionActionFailedErrorCode,
                           @"Deeplink open action failed since URL field not present.");
  }

  XCUIElement *openBtn = safariApp.buttons[@"Open"];
  if ([openBtn waitForExistenceWithTimeout:10]) {
    [safariApp.buttons[@"Open"] tap];
    return YES;
  } else if (error) {
    *error = GREYErrorMake(kGREYDeeplinkErrorDomain, kGREYInteractionActionFailedErrorCode,
                           @"Deeplink open action failed since Open Button on the app "
                           @"dialog for the deeplink not present.");
  }
  // this is needed otherwise failed tests will hang until failure.
  [application activate];
  return NO;
#else
  NSString *errorDescription =
      @"Cannot open the deeplink because it is not supported with the current system version.";
  GREYError *notSupportedError =
      GREYErrorMake(kGREYDeeplinkErrorDomain, GREYDeeplinkNotSupported, errorDescription);
  if (error) {
    *error = notSupportedError;
  } else {
    [GREYElementInteractionErrorHandler handleInteractionError:notSupportedError outError:nil];
  }
  return NO;
#endif
}

- (BOOL)shakeDeviceWithError:(NSError **)error {
  __block GREYError *shakeDeviceError = nil;
  BOOL success = ExecuteSyncBlockInBackgroundQueue(^{
    return [GREYSyntheticEvents shakeDeviceWithError:&shakeDeviceError];
  });
  if (!success && error) {
    *error = shakeDeviceError;
  }
  return success;
}

- (void)handleException:(GREYFrameworkException *)exception details:(NSString *)details {
  id<GREYFailureHandler> failureHandler = GREYGetCurrentFailureHandler();
  [failureHandler handleException:exception details:details];
}

- (BOOL)isKeyboardShownWithError:(NSError **)error {
  __block GREYError *keyboardShownError = nil;
  BOOL keyboardShown = ExecuteSyncBlockInBackgroundQueue(^{
    return [GREYKeyboard keyboardShownWithError:&keyboardShownError];
  });
  // Handle keyboardShownError if any, if the app failed to idle.
  if (keyboardShownError) {
    if (error) {
      *error = keyboardShownError;
    } else {
      [GREYElementInteractionErrorHandler handleInteractionError:keyboardShownError outError:nil];
    }
  }
  return keyboardShown;
}

- (Class)remoteClassInApp:(Class)theClass {
  uint16_t port = GREYTestApplicationDistantObject.sharedInstance.hostPort;
  id remoteObject = [EDOClientService classObjectWithName:NSStringFromClass(theClass) port:port];
  I_GREYAssertNotNil(remoteObject, @"Class %@ does not exist in app", theClass);
  return remoteObject;
}

@end
