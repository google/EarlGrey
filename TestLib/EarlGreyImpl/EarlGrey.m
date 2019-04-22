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

#import "TestLib/EarlGreyImpl/EarlGrey.h"

#import "AppFramework/Event/GREYSyntheticEvents.h"
#import "AppFramework/Keyboard/GREYKeyboard.h"
#import "CommonLib/Assertion/GREYAssertionDefines.h"
#import "CommonLib/Assertion/GREYFatalAsserts.h"
#import "CommonLib/DistantObject/GREYHostBackgroundDistantObject.h"
#import "CommonLib/DistantObject/GREYTestApplicationDistantObject.h"
#import "CommonLib/Error/GREYError.h"
#import "CommonLib/Error/GREYErrorConstants.h"
#import "CommonLib/GREYAppleInternals.h"
#import "CommonLib/GREYLogger.h"
#import "TestLib/Analytics/GREYAnalytics.h"
#import "TestLib/AppleInternals/GREYXCTestAppleInternals.h"
#import "TestLib/EarlGreyImpl/EarlGreyImpl+XCUIApplication.h"
#import "TestLib/EarlGreyImpl/GREYElementInteractionErrorHandler.h"
#import "TestLib/EarlGreyImpl/GREYElementInteractionProxy.h"
#import "TestLib/Exception/GREYDefaultFailureHandler.h"

NSString *const kGREYFailureHandlerKey = @"GREYFailureHandlerKey";

/** Resets the failure handler. Must be called from main thread otherwise behavior is undefined. */
static inline void ResetFailureHandler() {
  assert([NSThread isMainThread]);
  NSMutableDictionary *TLSDict = [[NSThread mainThread] threadDictionary];
  [TLSDict setValue:[[GREYDefaultFailureHandler alloc] init] forKey:kGREYFailureHandlerKey];
}

id<GREYFailureHandler> GREYGetFailureHandler(void);

/** Gets the failure handler. Must be called from main thread otherwise behavior is undefined. */
id<GREYFailureHandler> GREYGetFailureHandler() {
  assert([NSThread isMainThread]);
  NSMutableDictionary *TLSDict = [[NSThread mainThread] threadDictionary];
  return [TLSDict valueForKey:kGREYFailureHandlerKey];
}

@implementation EarlGreyImpl

+ (void)load {
  // These need to be set in load since someone might call GREYAssertXXX APIs without calling
  // into EarlGrey.
  ResetFailureHandler();
}

+ (instancetype)invokedFromFile:(NSString *)fileName lineNumber:(NSUInteger)lineNumber {
  static EarlGreyImpl *instance = nil;
  static dispatch_once_t token = 0;
  dispatch_once(&token, ^{
    instance = [[EarlGreyImpl alloc] initOnce];
  });

  id<GREYFailureHandler> failureHandler;
  @synchronized(self) {
    failureHandler = GREYGetFailureHandler();
  }
  SEL invocationFileAndLineSEL = @selector(setInvocationFile:andInvocationLine:);
  if ([failureHandler respondsToSelector:invocationFileAndLineSEL]) {
    [failureHandler setInvocationFile:fileName andInvocationLine:lineNumber];
  }
  [[GREYAnalytics sharedAnalytics] didInvokeEarlGrey];
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
  GREYError *rotationError = nil;
  BOOL success = [GREYSyntheticEvents rotateDeviceToOrientation:deviceOrientation
                                                          error:&rotationError];
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
  GREYError *dismissalError = nil;
  BOOL success = NO;
  id<GREYMatcher> keyboardKeyMatcher =
      grey_allOf(grey_accessibilityLabel(@"return"),
                 grey_kindOfClassName(@"UIAccessibilityElementKBKey"), nil);
  [[self selectElementWithMatcher:keyboardKeyMatcher] performAction:grey_tap()
                                                              error:&dismissalError];
  if ([dismissalError.domain isEqualToString:kGREYInteractionErrorDomain] &&
      dismissalError.code == kGREYInteractionElementNotFoundErrorCode) {
    // Try to dismiss the keyboard programmatically.
    success = [GREYKeyboard dismissKeyboardWithoutReturnKeyWithError:&dismissalError];
  } else {
    success = !dismissalError;
  }
  if (!success) {
    dismissalError = [self grey_errorForKeyboardNotPresentWithInternalError:dismissalError];
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
  GREYError *shakeDeviceError = nil;
  BOOL success = [GREYSyntheticEvents shakeDeviceWithError:&shakeDeviceError];
  if (!success) {
    if (error) {
      *error = shakeDeviceError;
    }
  }
  return success;
}

- (void)setFailureHandler:(id<GREYFailureHandler>)handler {
  @synchronized([self class]) {
    if (handler) {
      NSMutableDictionary *TLSDict = [[NSThread mainThread] threadDictionary];
      [TLSDict setValue:handler forKey:kGREYFailureHandlerKey];
    } else {
      ResetFailureHandler();
    }
  }
}

- (void)handleException:(GREYFrameworkException *)exception details:(NSString *)details {
  @synchronized([self class]) {
    id<GREYFailureHandler> failureHandler = GREYGetFailureHandler();
    [failureHandler handleException:exception details:details];
  }
}

- (BOOL)isKeyboardShownWithError:(NSError **)error {
  GREYError *keyboardShownError = nil;
  BOOL keyboardShown = [GREYKeyboard keyboardShownWithError:&keyboardShownError];
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

/**
 *  @return A GREYError containing details for why the keyboard was not dismissed, containing the
 *          description of the underlying error.
 *
 *  @param underlyingError The error which caused the failure in dismissing the keyboard.
 */
- (GREYError *)grey_errorForKeyboardNotPresentWithInternalError:(GREYError *)underlyingError {
  NSString *errorDescription =
      [NSString stringWithFormat:@"Failed to dismiss keyboard since it was not showing. "
                                 @"Internal Error: %@",
                                 underlyingError.description];
  return GREYErrorMake(kGREYKeyboardDismissalErrorDomain, GREYKeyboardDismissalFailedErrorCode,
                       errorDescription);
}

@end
