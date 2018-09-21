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
#import "CommonLib/Assertion/GREYAssertionDefines.h"
#import "CommonLib/Assertion/GREYFatalAsserts.h"
#import "CommonLib/DistantObject/GREYHostBackgroundDistantObject.h"
#import "CommonLib/Error/GREYError.h"
#import "CommonLib/Error/GREYErrorConstants.h"
#import "CommonLib/GREYAppleInternals.h"
#import "CommonLib/GREYLogger.h"
#import "TestLib/Analytics/GREYAnalytics.h"
#import "TestLib/EarlGreyImpl/EarlGreyImpl+XCUIApplication.h"
#import "TestLib/EarlGreyImpl/GREYElementInteractionProxy.h"
#import "TestLib/Exception/GREYDefaultFailureHandler.h"
#import "TestLib/GREYXCTestAppleInternals.h"

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

- (BOOL)rotateDeviceToOrientation:(UIDeviceOrientation)deviceOrientation
                            error:(NSError **)errorOrNil {
  NSError *error = nil;
  BOOL success = [GREYSyntheticEvents rotateDeviceToOrientation:deviceOrientation error:&error];
  if (!success) {
    if (errorOrNil) {
      *errorOrNil = error;
    } else {
      I_GREYFail(@"Failed to change device orientation. Error: %@",
                 [GREYError grey_nestedDescriptionForError:error]);
    }
  }
  return success;
}

- (BOOL)dismissKeyboardInApplication:(XCUIApplication *)application error:(NSError **)errorOrNil {
  NSError *error = nil;
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"return")] performAction:grey_tap()
                                                                                  error:&error];
  if (error) {
    NSString *errorDescription =
        [NSString stringWithFormat:
                      @"Failed to dismiss keyboard since it was not showing. "
                      @"Internal Error: %@",
                      error.description];
    GREYError *executionError = GREYErrorMake(
        kGREYKeyboardDismissalErrorDomain, GREYKeyboardDismissalFailedErrorCode, errorDescription);
    if (errorOrNil) {
      *errorOrNil = executionError;
    } else {
      I_GREYFail(@"%@\nError: %@", @"Dismissing keyboard errored out.",
                 [GREYError grey_nestedDescriptionForError:executionError]);
    }
    return NO;
  }
  return YES;
}

- (BOOL)openDeeplinkURL:(NSString *)URL
          inApplication:(XCUIApplication *)application
                  error:(NSError **)errorOrNil {
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
  } else if (errorOrNil) {
    *errorOrNil = GREYErrorMake(kGREYDeeplinkErrorDomain, kGREYInteractionActionFailedErrorCode,
                                @"Deeplink open action failed since URL field not present.");
  }

  XCUIElement *openBtn = safariApp.buttons[@"Open"];
  if ([openBtn waitForExistenceWithTimeout:10]) {
    [safariApp.buttons[@"Open"] tap];
    return YES;
  } else if (errorOrNil) {
    *errorOrNil = GREYErrorMake(kGREYDeeplinkErrorDomain, kGREYInteractionActionFailedErrorCode,
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
  if (errorOrNil) {
    *errorOrNil = notSupportedError;
  } else {
    I_GREYFail(@"%@\nError: %@", @"Unsupported os version for deeplinking.",
               [GREYError grey_nestedDescriptionForError:notSupportedError]);
  }
  return NO;
#endif
}

- (BOOL)shakeDeviceWithError:(NSError **)errorOrNil {
  NSError *error = nil;
  BOOL success = [GREYSyntheticEvents shakeDeviceWithError:&error];
  if (!success) {
    if (errorOrNil) {
      *errorOrNil = error;
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

@end
