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
#import "GREYTestApplicationDistantObject+Private.h"
#import "GREYTestApplicationDistantObject.h"
#import "GREYError.h"
#import "GREYErrorConstants.h"
#import "GREYObjectFormatter.h"
#import "GREYAppleInternals.h"
#import "GREYLogger.h"

#import "GREYXCTestAppleInternals.h"
#import "EarlGreyImpl+XCUIApplication.h"
#import "GREYElementInteractionErrorHandler.h"
#import "GREYElementInteractionProxy.h"
#import "GREYDefaultFailureHandler.h"
#import "GREYRemoteExecutor.h"
#import "XCTestCase+GREYTest.h"
#import "EDOClientService.h"

/**
 *  Sets EarlGrey provided default failure handler if there's no failure handler set for the current
 *  thread.
 */
static inline void SetDefaultFailureHandler() {
  NSDictionary<NSString *, id> *TLSDict = [[NSThread mainThread] threadDictionary];
  [TLSDict setValue:[[GREYDefaultFailureHandler alloc] init] forKey:GREYFailureHandlerKey];
}

/** Returns the current failure handler. If it's @c nil, sets the default one and returns it. */
static inline id<GREYFailureHandler> GREYGetCurrentFailureHandler() {
  NSDictionary<NSString *, id> *TLSDict = [[NSThread mainThread] threadDictionary];
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
}

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

#if TARGET_OS_IOS
- (BOOL)rotateDeviceToOrientation:(UIDeviceOrientation)deviceOrientation error:(NSError **)error {
  GREYError *syncErrorBeforeRotation;
  GREYError *syncErrorAfterRotation;
  BOOL success = NO;
  XCUIDevice *sharedDevice = [XCUIDevice sharedDevice];
  UIDevice *currentDevice = [GREY_REMOTE_CLASS_IN_APP(UIDevice) currentDevice];
  CFTimeInterval interactionTimeout = GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration);

  BOOL syncSuccessBeforeRotation =
      GREYWaitForAppToIdleWithTimeoutAndError(interactionTimeout, &syncErrorBeforeRotation);
  if (syncSuccessBeforeRotation) {
    [sharedDevice setOrientation:deviceOrientation];
    [currentDevice setOrientation:deviceOrientation animated:NO];
    BOOL syncSuccessAfterRotation =
        GREYWaitForAppToIdleWithTimeoutAndError(interactionTimeout, &syncErrorAfterRotation);
    if (syncSuccessAfterRotation) {
      success = currentDevice.orientation == deviceOrientation;
    }
  }

  if (!success) {
    NSString *errorDescription;
    if (syncErrorBeforeRotation) {
      NSString *errorReason = @"Application did not idle before rotating.\n%@\n%@";
      // TODO(b/147072566): Provide an error API to format description glossary on the test side.
      NSString *descriptionGlossary =
          [GREYObjectFormatter formatDictionary:syncErrorBeforeRotation.descriptionGlossary
                                         indent:kGREYObjectFormatIndent
                                      hideEmpty:YES
                                       keyOrder:nil];
      errorDescription =
          [NSString stringWithFormat:errorReason, syncErrorBeforeRotation.localizedDescription,
                                     descriptionGlossary];
    } else if (syncErrorAfterRotation) {
      NSString *errorReason =
          @"Application did not idle after rotating and before verifying the rotation.\n%@@\n%@";
      NSString *descriptionGlossary =
          [GREYObjectFormatter formatDictionary:syncErrorBeforeRotation.descriptionGlossary
                                         indent:kGREYObjectFormatIndent
                                      hideEmpty:YES
                                       keyOrder:nil];
      errorDescription =
          [NSString stringWithFormat:errorReason, syncErrorAfterRotation.localizedDescription,
                                     descriptionGlossary];
    } else if (!syncErrorBeforeRotation && !syncErrorAfterRotation) {
      NSString *errorReason = @"Could not rotate application to orientation: %tu. XCUIDevice "
                              @"Orientation: %tu UIDevice Orientation: %tu. UIDevice is the "
                              @"orientation being checked here.";
      errorDescription =
          [NSString stringWithFormat:errorReason, deviceOrientation, sharedDevice.orientation,
                                     currentDevice.orientation];
    }

    GREYError *rotationError =
        GREYErrorMake(kGREYSyntheticEventInjectionErrorDomain,
                      kGREYOrientationChangeFailedErrorCode, errorDescription);

    GREYHandleInteractionError(rotationError, error);
  }
  return success;
}
#endif  // TARGET_OS_IOS

- (BOOL)dismissKeyboardWithError:(NSError **)error {
  __block GREYError *dismissalError = nil;
  BOOL success = ExecuteSyncBlockInBackgroundQueue(^{
    return [GREYKeyboard dismissKeyboardWithoutReturnKeyWithError:&dismissalError];
  });
  if (!success) {
    NSString *errorDescription =
        [NSString stringWithFormat:@"Failed to dismiss keyboard since it was not showing. "
                                   @"Internal Error: %@",
                                   dismissalError.localizedDescription];
    dismissalError = GREYErrorMake(kGREYKeyboardDismissalErrorDomain,
                                   GREYKeyboardDismissalFailedErrorCode, errorDescription);
    if (error) {
      *error = dismissalError;
    } else {
      GREYHandleInteractionError(dismissalError, nil);
    }
  }
  return success;
}

#if defined(__IPHONE_11_0)
- (BOOL)openDeeplinkURL:(NSString *)URL
          inApplication:(XCUIApplication *)application
                  error:(NSError **)error {
  XCUIApplication *safariApp =
      [[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.mobilesafari"];
  [safariApp activate];
  BOOL success = [safariApp waitForState:XCUIApplicationStateRunningForeground timeout:30];
  I_GREYAssertTrue(success, @"Safari did not launch successfully.");

  // As Safari loads up for the first time, the URL is not clickable and we have to wait for the
  // app to be hittable for it.
  if (safariApp.hittable) {
#if TARGET_OS_IOS
    if (![safariApp.textFields[@"URL"] exists]) {
      [safariApp.buttons[@"URL"] tap];
    }
    [safariApp typeText:URL];
    [safariApp.buttons[@"Go"] tap];
#endif  // TARGET_OS_IOS
  } else if (error) {
    *error = GREYErrorMake(kGREYDeeplinkErrorDomain, kGREYInteractionActionFailedErrorCode,
                           @"Deeplink open action failed since URL field not present.");
  }

  XCUIElement *openBtn = safariApp.buttons[@"Open"];
  if ([openBtn waitForExistenceWithTimeout:10]) {
#if TARGET_OS_IOS
    [safariApp.buttons[@"Open"] tap];
#endif  // TARGET_OS_IOS
    return YES;
  } else if (error) {
    *error = GREYErrorMake(kGREYDeeplinkErrorDomain, kGREYInteractionActionFailedErrorCode,
                           @"Deeplink open action failed since Open Button on the app "
                           @"dialog for the deeplink not present.");
  }
  // this is needed otherwise failed tests will hang until failure.
  [application activate];
  return NO;
}
#endif  // defined(__IPHONE_11_0)

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
      GREYHandleInteractionError(keyboardShownError, nil);
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

- (void)setHostApplicationCrashHandler:(nullable GREYHostApplicationCrashHandler)handler {
  [XCTestCase grey_setHostApplicationCrashHandler:handler];
}

- (void)setRemoteExecutionsDispatchPolicy:(GREYRemoteExecutionsDispatchPolicy)dispatchPolicy {
  GREYError *setPolicyError;
  GREYTestApplicationDistantObject *distantObject = GREYTestApplicationDistantObject.sharedInstance;
  if (![distantObject setDispatchPolicy:dispatchPolicy error:&setPolicyError]) {
    GREYHandleInteractionError(setPolicyError, nil);
  }
}

@end
