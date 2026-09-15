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

#import "EarlGreyImpl.h"

#import "GREYSyntheticEvents.h"
#import "GREYKeyboard.h"
#import "GREYMatchers.h"
#import "GREYConfigKey.h"
#import "GREYTestApplicationDistantObject+Private.h"
#import "GREYError.h"
#import "GREYAppleInternals.h"


#import "GREYElementInteractionErrorHandler.h"
#import "GREYElementInteractionProxy.h"
#import "GREYRemoteExecutor.h"
#import "GREYDefaultFailureHandler.h"
#import "XCTestCase+GREYTest.h"
#import "GREYUIWindowProvider.h"

#if TARGET_OS_IOS

/** Bounded timeouts for Safari automation stages to prevent cumulative stalls before fallback. */
static const CFTimeInterval kSafariLaunchTimeout = 3.0;
static const CFTimeInterval kSafariAddressBarTimeout = 2.0;
static const CFTimeInterval kSafariFocusTimeout = 1.5;
static const CFTimeInterval kSafariOpenDialogTimeout = 4.0;

/** Returns the activity sheet element. */
static XCUIElement *GetActivitySheetElement(XCUIApplication *application) {
  // Before iOS 26, the secondary activity sheet for customizing sharing options is under the same
  // "ActivityListView", which only contains the primary activity sheet on iOS 26. Instead, the
  // container view, which covers both sheets, should be used.
  return iOS26_OR_ABOVE() ? application.otherElements[@"ShareSheet.RemoteContainerView"]
                          : application.otherElements[@"ActivityListView"];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"
#pragma clang diagnostic ignored "-Wunavailable-declarations"
API_AVAILABLE(ios(13.0))
@interface GREYOpenURLContext : UIOpenURLContext

@property(nonatomic, copy) NSURL *URL;

- (instancetype)initWithURL:(NSURL *)URL;

@end

@implementation GREYOpenURLContext

@synthesize URL = _URL;

- (instancetype)initWithURL:(NSURL *)URL {
  SEL initSEL = @selector(init);
  IMP initIMP = [NSObject instanceMethodForSelector:initSEL];
  self = ((id (*)(id, SEL))initIMP)(self, initSEL);
  if (self) {
    _URL = [URL copy];
  }
  return self;
}

- (UISceneOpenURLOptions *)options {
  return nil;
}

- (BOOL)isEqual:(id)object {
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:[UIOpenURLContext class]]) {
    return NO;
  }
  UIOpenURLContext *other = (UIOpenURLContext *)object;
  return [self.URL isEqual:other.URL];
}

- (NSUInteger)hash {
  return self.URL.hash;
}

@end
#pragma clang diagnostic pop

#endif  // TARGET_OS_IOS

/**
 * Sets EarlGrey provided default failure handler if there's no failure handler set for the current
 * thread.
 */
static inline void SetDefaultFailureHandler(void) {
  NSDictionary<NSString *, id> *TLSDict = [[NSThread mainThread] threadDictionary];
  [TLSDict setValue:[[GREYDefaultFailureHandler alloc] init] forKey:GREYFailureHandlerKey];
}

/** Returns the current failure handler. If it's @c nil, sets the default one and returns it. */
static inline id<GREYFailureHandler> GREYGetCurrentFailureHandler(void) {
  NSDictionary<NSString *, id> *TLSDict = [[NSThread mainThread] threadDictionary];
  id<GREYFailureHandler> handler = [TLSDict valueForKey:GREYFailureHandlerKey];
  if (!handler) {
    SetDefaultFailureHandler();
    handler = [TLSDict valueForKey:GREYFailureHandlerKey];
  }
  return handler;
}

@interface GREYMatchers (GREYTest)
+ (id<GREYMatcher>)activitySheetPresentMatcher;
@end

/**
 * The root window matcher that can be set when writing tests on a multi-scene application.
 */
static id<GREYMatcher> gRootWindowMatcher;

@implementation EarlGreyImpl

/**
 * Executes the specified @block in a remote executor background queue.
 *
 * @param block The block to run in aremote executor background queue.
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
  if (!gRootWindowMatcher) {
    return [[GREYElementInteractionProxy alloc] initWithElementMatcher:elementMatcher];
  } else {
    return [[[GREYElementInteractionProxy alloc] initWithElementMatcher:elementMatcher]
        inRoot:gRootWindowMatcher];
  }
}

- (BOOL)dismissKeyboardWithError:(NSError **)error {
  __block GREYError *dismissalError = nil;
  BOOL success = ExecuteSyncBlockInBackgroundQueue(^{
    return [GREYKeyboard dismissKeyboardWithoutReturnKeyWithError:&dismissalError];
  });
  if (!success) {
    NSString *errorDescription =
        [NSString stringWithFormat:@"Failed to dismiss keyboard: %@",
                                   dismissalError.userInfo[kErrorFailureReasonKey]];
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

#if TARGET_OS_IOS

/**
 * Routes the target URL in-app via UISceneDelegate, UIApplicationDelegate, or system openURL.
 *
 * Direct delegate invocation is preferred over system openURL because on iOS 17+, certain
 * registered schemes (e.g. otpauth-migration) are natively intercepted by system sheets
 * (such as Apple Passwords) when routed via SpringBoard, preventing the target application
 * from receiving the payload.
 *
 * @param targetURL The URL to open in the application.
 * @param timeoutInSeconds Maximum time to wait if falling back to asynchronous system openURL.
 * @return YES if the URL was handled by the application, NO otherwise.
 */
static BOOL RouteURLInApp(NSURL *targetURL, double timeoutInSeconds) {
  UIApplication *app = [GREY_REMOTE_CLASS_IN_APP(UIApplication) sharedApplication];
  id<UIApplicationDelegate> delegate = app.delegate;

  NSString *scheme = [targetURL.scheme lowercaseString];
  BOOL isWebURL = [scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"];

  // Step A: Active UISceneDelegate routing (iOS 13+).
  // Apps adopting UIScene lifecycle route URLs through UISceneDelegate instead of
  // UIApplicationDelegate. UIKit suppresses application:openURL:options: when scene delegates
  // are active.
  if (@available(iOS 13.0, *)) {
    if ([app respondsToSelector:@selector(connectedScenes)]) {
      for (UIScene *scene in app.connectedScenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive ||
            scene.activationState == UISceneActivationStateForegroundInactive) {
          id<UISceneDelegate> sceneDelegate = (id<UISceneDelegate>)scene.delegate;
          if (isWebURL) {
            if ([sceneDelegate respondsToSelector:@selector(scene:continueUserActivity:)]) {
              NSUserActivity *activity = [[GREY_REMOTE_CLASS_IN_APP(NSUserActivity) alloc]
                  initWithActivityType:NSUserActivityTypeBrowsingWeb];
              activity.webpageURL = targetURL;
              [sceneDelegate scene:scene continueUserActivity:activity];
              return YES;
            }
          } else {
            if ([sceneDelegate respondsToSelector:@selector(scene:openURLContexts:)]) {
              GREYOpenURLContext *context = [[GREYOpenURLContext alloc] initWithURL:targetURL];
              [sceneDelegate scene:scene openURLContexts:[NSSet setWithObject:context]];
              return YES;
            }
          }
        }
      }
    }
  }

  // Step B: Universal links (http/https) route via NSUserActivityTypeBrowsingWeb on app delegate.
  if (isWebURL) {
    NSUserActivity *activity = [[GREY_REMOTE_CLASS_IN_APP(NSUserActivity) alloc]
        initWithActivityType:NSUserActivityTypeBrowsingWeb];
    activity.webpageURL = targetURL;
    if ([delegate
            respondsToSelector:@selector(application:continueUserActivity:restorationHandler:)]) {
      return [delegate application:app
              continueUserActivity:activity
                restorationHandler:^(NSArray<id<UIUserActivityRestoring>> *restorableObjects){
                }];
    }
  }

  // Step C: Custom schemes route directly to UIApplicationDelegate methods.
  // Direct delegate calls bypass iOS 17+ system interception (e.g. Apple Passwords intercepting
  // otpauth-migration URLs) which would otherwise steal foreground from the app under test.
  if ([delegate respondsToSelector:@selector(application:openURL:options:)]) {
    return [delegate application:app openURL:targetURL options:@{}];
  }
  if ([delegate respondsToSelector:@selector(application:openURL:sourceApplication:annotation:)]) {
    return [delegate application:app openURL:targetURL sourceApplication:nil annotation:@{}];
  }

  // Step D: Fallback to system openURL if neither scene nor app delegates handle custom URLs.
  // Synchronized using GREYCondition on the caller thread to prevent blocking eDO's appProxyQueue.
  NSObject *lock = [[NSObject alloc] init];
  __block BOOL handled = NO;
  __block BOOL completed = NO;
  [app openURL:targetURL
      options:@{}
      completionHandler:^(BOOL success) {
        @synchronized(lock) {
          handled = success;
          completed = YES;
        }
      }];

  GREYCondition *openURLCondition = [GREYCondition conditionWithName:@"Wait for openURL completion"
                                                               block:^BOOL {
                                                                 @synchronized(lock) {
                                                                   return completed;
                                                                 }
                                                               }];
  BOOL conditionSuccess = [openURLCondition waitWithTimeout:timeoutInSeconds pollInterval:0.1];
  return conditionSuccess && handled;
}

static BOOL DispatchInApp(NSString *URL, XCUIApplication *application, NSError **error) {
  // 1. Validate the deep link URL.
  NSURL *targetURL = [NSURL URLWithString:URL];
  if (!targetURL) {
    if (error) {
      *error = GREYErrorMake(kGREYDeeplinkErrorDomain, GREYDeeplinkActionFailedError,
                             @"Deeplink open action failed since URL is invalid.");
    }
    return NO;
  }

  double timeoutInSeconds = GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration);

  // 2. Ensure target application is in foreground before dispatching URL payload.
  [application activate];
  BOOL running = [application waitForState:XCUIApplicationStateRunningForeground
                                   timeout:timeoutInSeconds];
  if (!running) {
    if (error) {
      *error = GREYErrorMake(kGREYDeeplinkErrorDomain, GREYDeeplinkActionFailedError,
                             @"Deeplink open action failed because target application failed to "
                             @"enter foreground.");
    }
    return NO;
  }

  // 3. Deliver URL payload in-app on a remote executor background queue to prevent eDO deadlocks.
  __block BOOL handled = NO;
  GREYExecuteSyncBlockInBackgroundQueue(^{
    handled = RouteURLInApp(targetURL, timeoutInSeconds);
  });

  if (!handled) {
    if (error) {
      *error = GREYErrorMake(kGREYDeeplinkErrorDomain, GREYDeeplinkActionFailedError,
                             @"Deeplink open action failed in application URL routing.");
    }
    return NO;
  }

  // 4. Synchronize with the app's main run loop to ensure any view transitions or modals settle.
  GREYWaitForAppToIdle(@"Wait for application to idle after in-app deep link dispatch.");
  return YES;
}
#endif  // TARGET_OS_IOS

#if defined(__IPHONE_11_0)
- (BOOL)openDeepLinkURL:(NSString *)URL
        withApplication:(XCUIApplication *)application
                  error:(NSError **)error {
#if TARGET_OS_IOS
  // Attempt Safari UI automation first with bounded stage timeouts; fall back to in-app eDO
  // dispatch if Safari fails to launch, address bar cannot be focused, or system dialog is delayed.
  XCUIApplication *safariApp =
      [[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.mobilesafari"];
  [safariApp activate];
  BOOL safariRunning = [safariApp waitForState:XCUIApplicationStateRunningForeground
                                       timeout:kSafariLaunchTimeout];
  if (!safariRunning) {
    [safariApp terminate];
    return DispatchInApp(URL, application, error);
  }

  // Safari's address bar representation in the accessibility hierarchy varies across iOS
  // versions, tab bar layout modes, and interaction states:
  // - iOS 16+: With the redesigned unified tab bar (SFTabBar), the collapsed address bar renders
  //   as "TabBarItemTitle" (either as a Button or an unfocused TextField).
  // - iOS 15 / 15.2: The address bar exposes the placeholder label "Search or enter website name"
  //   as a Button when unfocused, transitioning to a TextField upon focus.
  // - iOS 14 and earlier: The address bar accessibility identifier is "URL" (a Button when not
  //   editing, or a TextField when first responder).
  // Depending on whether a start page is active, whether tabs are shown, or whether single-tab
  // mode is enabled, Safari may expose either a Button or TextField for these identifiers.
  // We poll all candidate identifiers and element types in parallel to avoid cumulative timeouts.
  XCUIElement *addressElement = nil;
  CFAbsoluteTime deadline = CFAbsoluteTimeGetCurrent() + kSafariAddressBarTimeout;
  while (CFAbsoluteTimeGetCurrent() < deadline) {
    if (safariApp.textFields[@"Search or enter website name"].exists) {
      addressElement = safariApp.textFields[@"Search or enter website name"];
      break;
    }
    if (safariApp.buttons[@"Search or enter website name"].exists) {
      addressElement = safariApp.buttons[@"Search or enter website name"];
      break;
    }
    if (safariApp.textFields[@"TabBarItemTitle"].exists) {
      addressElement = safariApp.textFields[@"TabBarItemTitle"];
      break;
    }
    if (safariApp.buttons[@"TabBarItemTitle"].exists) {
      addressElement = safariApp.buttons[@"TabBarItemTitle"];
      break;
    }
    if (safariApp.buttons[@"URL"].exists && safariApp.hittable) {
      addressElement = safariApp.buttons[@"URL"];
      break;
    }
    if (safariApp.textFields[@"URL"].exists) {
      addressElement = safariApp.textFields[@"URL"];
      break;
    }
    [NSThread sleepForTimeInterval:0.1];
  }

  if (!addressElement) {
    [safariApp terminate];
    return DispatchInApp(URL, application, error);
  }

  [addressElement tap];

  // Ensure the input field appears and gains keyboard focus before typing to prevent
  // unhandled event synthesis failure in XCTest. Dismiss any swipe tutorial popup if present.
  XCUIElement *inputField = nil;
  BOOL hasFocus = NO;
  CFAbsoluteTime focusDeadline = CFAbsoluteTimeGetCurrent() + kSafariFocusTimeout;
  while (CFAbsoluteTimeGetCurrent() < focusDeadline) {
    if (@available(iOS 15.0, *)) {
      XCUIElement *swipeTutorialButton =
          safariApp.otherElements[@"UIContinuousPathIntroductionView"].buttons[@"Continue"];
      if (swipeTutorialButton.exists) {
        [swipeTutorialButton tap];
      }
    }

    // Once tapped, Safari transitions the address bar into an active text field. The resulting
    // first-responder element depends on the iOS version and layout mode:
    // - Most iOS versions (including iOS 16/17): The active editing field becomes
    // textFields[@"URL"].
    // - iOS 15 / single-tab layouts: The field may retain textFields[@"Search or enter website
    // name"].
    // - Modern tab bar layouts before transition completes: The field may remain
    //   textFields[@"TabBarItemTitle"].
    // We check all candidate text field identifiers to locate the active editing element.
    inputField = nil;
    if (safariApp.textFields[@"URL"].exists) {
      inputField = safariApp.textFields[@"URL"];
    } else if (safariApp.textFields[@"Search or enter website name"].exists) {
      inputField = safariApp.textFields[@"Search or enter website name"];
    } else if (safariApp.textFields[@"TabBarItemTitle"].exists) {
      inputField = safariApp.textFields[@"TabBarItemTitle"];
    }

    BOOL focused = NO;
    @try {
      focused = [[inputField valueForKey:@"hasKeyboardFocus"] boolValue];
    } @catch (NSException *exception) {
      // Ignore if private property is not accessible.
    }

    if (inputField && focused) {
      hasFocus = YES;
      break;
    }
    [NSThread sleepForTimeInterval:0.1];
  }

  if (!hasFocus) {
    [safariApp terminate];
    return DispatchInApp(URL, application, error);
  }

  [inputField typeText:URL];
  [safariApp.buttons[@"Go"] tap];

  XCUIElement *openButton = safariApp.buttons[@"Open"];
  if ([openButton waitForExistenceWithTimeout:kSafariOpenDialogTimeout]) {
    [openButton tap];
    if ([application waitForState:XCUIApplicationStateRunningForeground
                          timeout:kSafariOpenDialogTimeout]) {
      GREYWaitForAppToIdle(@"Wait for application to idle after Safari deep link transition.");
      return YES;
    }
  }

  // If Safari Open prompt didn't appear within timeout or target application failed to enter
  // foreground, fallback to in-app dispatch.
  [safariApp terminate];
  return DispatchInApp(URL, application, error);
#endif  // TARGET_OS_IOS
  return NO;
}
#endif  // defined(__IPHONE_11_0)

- (BOOL)shakeDeviceWithError:(NSError **)error {
  __block GREYError *shakeDeviceError = nil;
  BOOL success = ExecuteSyncBlockInBackgroundQueue(^{
    double timeoutInSeconds = GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration);
    void (^shakeBlock)(void) = ^{
      [GREY_REMOTE_CLASS_IN_APP(GREYSyntheticEvents) shakeDevice];
    };
    return [[GREYUIThreadExecutor sharedInstance] executeSyncWithTimeout:timeoutInSeconds
                                                                   block:shakeBlock
                                                                   error:&shakeDeviceError];
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

- (void)setHostApplicationCrashHandler:(nullable GREYHostApplicationCrashHandler)handler {
  [XCTestCase grey_setHostApplicationCrashHandler:handler];
}

- (void)setRemoteExecutionDispatchPolicy:(GREYRemoteExecutionDispatchPolicy)dispatchPolicy {
  GREYError *setPolicyError;
  GREYTestApplicationDistantObject *distantObject = GREYTestApplicationDistantObject.sharedInstance;
  if (![distantObject setDispatchPolicy:dispatchPolicy error:&setPolicyError]) {
    GREYHandleInteractionError(setPolicyError, nil);
  }
}

- (void)setRootMatcherForSubsequentInteractions:(nullable id<GREYMatcher>)rootWindowMatcher {
  gRootWindowMatcher = rootWindowMatcher;
}

#pragma mark - Rotation

#if TARGET_OS_IOS

- (BOOL)rotateInterfaceToOrientation:(UIInterfaceOrientation)interfaceOrientation
                               error:(NSError **)error {
  GREYError *syncErrorBeforeRotation;
  __block GREYError *syncErrorAfterRotation;
  BOOL success = NO;
  __block BOOL sendOrientationChangeNotification = NO;
  XCUIDevice *sharedDevice = [XCUIDevice sharedDevice];
  UIDevice *currentDevice = [GREY_REMOTE_CLASS_IN_APP(UIDevice) currentDevice];
  UIDeviceOrientation deviceOrientation =
      [GREYConstants deviceOrientationForInterfaceOrientation:interfaceOrientation];
  if (interfaceOrientation != UIInterfaceOrientationUnknown) {
    NSNotificationCenter *notificationCenter =
        [GREY_REMOTE_CLASS_IN_APP(NSNotificationCenter) defaultCenter];

    // Add an orientation change notification observer.
    [notificationCenter addObserverForName:UIDeviceOrientationDidChangeNotification
                                    object:nil
                                     queue:nil
                                usingBlock:^(NSNotification *_Nonnull note) {
                                  sendOrientationChangeNotification = YES;
                                }];
    CFTimeInterval interactionTimeout =
        GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration);
    BOOL syncSuccessBeforeRotation =
        GREYWaitForAppToIdleWithTimeoutAndError(interactionTimeout, &syncErrorBeforeRotation);
    if (syncSuccessBeforeRotation) {
      [sharedDevice setOrientation:deviceOrientation];
#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 160000)
      if (@available(iOS 16.0, *)) {
        // no-op. There's no need to perform extra process when checking app orientation with
        // UIScene.
      } else {
        [currentDevice setOrientation:deviceOrientation animated:NO];
      }
#else
      [currentDevice setOrientation:deviceOrientation animated:NO];
#endif  // (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 160000)

      BOOL syncSuccessAfterRotation =
          !syncErrorAfterRotation &&
          GREYWaitForAppToIdleWithTimeoutAndError(interactionTimeout, &syncErrorAfterRotation);
      if (syncSuccessAfterRotation) {
#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 160000)
        if (@available(iOS 16.0, *)) {
          UIWindowScene *scene = [[GREY_REMOTE_CLASS_IN_APP(GREYUIWindowProvider)
              keyWindowForSharedApplication] windowScene];
          GREYCondition *rotationWait =
              [GREYCondition conditionWithName:@"App Rotation Condition"
                                         block:^BOOL {
                                           return scene.effectiveGeometry.interfaceOrientation ==
                                                  interfaceOrientation;
                                         }];
          success = [rotationWait
              waitWithTimeout:GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration)];
        } else {
          success = currentDevice.orientation == deviceOrientation;
        }
#else
        success = currentDevice.orientation == deviceOrientation;
#endif  // (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 160000)
      }
    }

    // Remove the orientation change notification observer.
    [notificationCenter removeObserver:self
                                  name:UIDeviceOrientationDidChangeNotification
                                object:nil];
  }

  if (!success) {
    NSString *errorDescription;
    NSMutableDictionary<NSString *, id> *errorDetails = [[NSMutableDictionary alloc] init];

    if (syncErrorBeforeRotation) {
      errorDetails[kErrorDetailRecoverySuggestionKey] =
          syncErrorBeforeRotation.userInfo[kErrorFailureReasonKey];
      errorDescription = @"Application did not idle before rotating.";
    } else if (syncErrorAfterRotation) {
      errorDetails[kErrorDetailRecoverySuggestionKey] =
          syncErrorAfterRotation.userInfo[kErrorFailureReasonKey];
      errorDescription =
          @"Application did not idle after rotating and before verifying the rotation.";
    } else if (!syncErrorBeforeRotation && !syncErrorAfterRotation) {
      if (interfaceOrientation == UIInterfaceOrientationUnknown) {
        errorDescription = [NSString
            stringWithFormat:
                @"Could not rotate application to orientation: %tu because the orientation is not "
                @"supported by the rotation API. The supported orientations are "
                @"UIDeviceOrientationPortrait (%tu), UIDeviceOrientationPortraitUpsideDown (%tu), "
                @"UIDeviceOrientationLandscapeLeft (%tu), UIDeviceOrientationLandscapeRight (%tu).",
                deviceOrientation, UIDeviceOrientationPortrait,
                UIDeviceOrientationPortraitUpsideDown, UIDeviceOrientationLandscapeLeft,
                UIDeviceOrientationLandscapeRight];
      } else if (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        errorDescription = @"Could not rotate the device to portraitUpsideDown because the hosting "
                           @"device doesn't support this orientation.";
      } else {
        UIDeviceOrientation appDeviceOrientation = currentDevice.orientation;
#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 160000)
        if (@available(iOS 16.0, *)) {
          UIWindowScene *scene = [[GREY_REMOTE_CLASS_IN_APP(GREYUIWindowProvider)
              keyWindowForSharedApplication] windowScene];
          appDeviceOrientation =
              [GREYConstants deviceOrientationForInterfaceOrientation:scene.effectiveGeometry
                                                                          .interfaceOrientation];
        }
#endif  // (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 160000)
        errorDescription = [NSString
            stringWithFormat:@"Could not rotate application to orientation: %tu. After applying "
                             @"the orientation, either XCUIDevice orientation (%tu) or application "
                             @"orientation (%tu) doesn't match the requested orientation.",
                             deviceOrientation, sharedDevice.orientation, appDeviceOrientation];
        errorDetails[kErrorDetailRecoverySuggestionKey] =
            @"Verify if orientation is locked (e.g. shouldAutorotate returns NO, or "
            @"supportedInterfaceOrientations does not match the target orientation).";
      }
    }

    GREYError *rotationError = GREYErrorMakeWithUserInfo(kGREYSyntheticEventInjectionErrorDomain,
                                                         kGREYOrientationChangeFailedErrorCode,
                                                         errorDescription, errorDetails);
    GREYHandleInteractionError(rotationError, error);
  } else {
    // Send a notification for the orientation change to the test side since we have confirmed the
    // app has changed its orientation.
    if (sendOrientationChangeNotification) {
      [[NSNotificationCenter defaultCenter]
          postNotificationName:UIDeviceOrientationDidChangeNotification
                        object:nil];
    }
  }

  return success;
}

- (BOOL)rotateDeviceToOrientation:(UIDeviceOrientation)deviceOrientation error:(NSError **)error {
  UIInterfaceOrientation interfaceOrientation =
      [GREYConstants interfaceOrientationForDeviceOrientation:deviceOrientation];
  return [self rotateInterfaceToOrientation:interfaceOrientation error:error];
}

- (NSString *)SystemAlertTextWithError:(NSError **)error {
  return [[XCTestCase grey_currentTestCase] grey_systemAlertTextWithError:error];
}

/** Standalone API for XCTestCase::grey_systemAlertType:. */
- (GREYSystemAlertType)SystemAlertType {
  return [[XCTestCase grey_currentTestCase] grey_systemAlertType];
}

/** Standalone API for XCTestCase::grey_acceptSystemDialogWithError:. */
- (BOOL)AcceptSystemDialogWithError:(NSError **)error {
  return [[XCTestCase grey_currentTestCase] grey_acceptSystemDialogWithError:error];
}

/** Standalone API for XCTestCase::grey_denySystemDialogWithError:. */
- (BOOL)DenySystemDialogWithError:(NSError **)error {
  return [[XCTestCase grey_currentTestCase] grey_denySystemDialogWithError:error];
}

/** Standalone API for XCTestCase::grey_tapSystemDialogButtonWithText:error:. */
- (BOOL)TapSystemDialogButtonWithText:(NSString *)text error:(NSError **)error {
  return [[XCTestCase grey_currentTestCase] grey_tapSystemDialogButtonWithText:text error:error];
}

/** Standalone API for XCTestCase::grey_typeSystemAlertText:forPlaceholderText:error:. */
- (BOOL)TypeSystemAlertText:(NSString *)textToType
         forPlaceholderText:(NSString *)placeholderText
                      error:(NSError **)error {
  return [[XCTestCase grey_currentTestCase] grey_typeSystemAlertText:textToType
                                                  forPlaceholderText:placeholderText
                                                               error:error];
}

/** Standalone API for XCTestCase::grey_waitForAlertVisibility:withTimeout:. */
- (BOOL)WaitForAlertVisibility:(BOOL)visible withTimeout:(CFTimeInterval)seconds {
  return [[XCTestCase grey_currentTestCase] grey_waitForAlertVisibility:visible
                                                            withTimeout:seconds];
}

- (BOOL)activitySheetPresentWithError:(NSError **)error {
  return [self activitySheetWithError:error] != nil;
}

- (XCUIElement *)activitySheetWithError:(NSError **)error {
  GREYError *localError;
  XCUIApplication *currentApplication = [[XCUIApplication alloc] init];
  double timeoutInSeconds = GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration);
  XCUIElement *activitySheet = GetActivitySheetElement(currentApplication);
  BOOL result = [activitySheet waitForExistenceWithTimeout:timeoutInSeconds];
  // Acts as a defensive check for EarlGrey synchronization. For iOS 16, the matcher would just be
  // grey_kindOfClassName(@"_UIActivityContentCollectionView").
  [[EarlGrey selectElementWithMatcher:[GREYMatchers activitySheetPresentMatcher]]
      assertWithMatcher:[GREYMatchers matcherForNotNil]
                  error:&localError];
  if (!result) {
    localError =
        GREYErrorMake(kGREYActivitySheetHandlingErrorDomain,
                      GREYActivitySheetHandlingSheetNotPresent, @"Activity Sheet not present");
    GREYHandleInteractionError(localError, error);
    return nil;
  }
  return activitySheet;
}

- (BOOL)activitySheetAbsentWithError:(NSError **)error {
  GREYError *localError;
  [[EarlGrey selectElementWithMatcher:[GREYMatchers activitySheetPresentMatcher]]
      assertWithMatcher:[GREYMatchers matcherForNil]
                  error:&localError];
  // If there is no error, then the sheet is absent, so we don't need to check again.
  if (!localError) {
    return YES;
  }

  XCUIApplication *application = [[XCUIApplication alloc] init];
  double timeoutInSeconds = GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration);
  if ([GetActivitySheetElement(application) waitForNonExistenceWithTimeout:timeoutInSeconds]) {
    return YES;
  }

  localError = GREYErrorMake(kGREYActivitySheetHandlingErrorDomain,
                             GREYActivitySheetHandlingSheetNotAbsent, @"Activity Sheet present.");
  GREYHandleInteractionError(localError, error);
  return NO;
}

- (BOOL)activitySheetPresentWithURL:(NSString *)URL error:(NSError **)error NS_SWIFT_NOTHROW {
  GREYError *localError;
  BOOL sheetPresent = [self activitySheetPresentWithError:&localError];
  if (sheetPresent) {
    XCUIApplication *application = [[XCUIApplication alloc] init];
    double timeoutInSeconds = GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration);
    sheetPresent = [application.otherElements[URL] waitForExistenceWithTimeout:timeoutInSeconds];
  }
  if (!sheetPresent) {
    NSString *description =
        [NSString stringWithFormat:@"Activity Sheet with URL couldn't be found: %@", URL];
    localError = GREYErrorMake(kGREYActivitySheetHandlingErrorDomain,
                               GREYActivitySheetHandlingSheetWithURLNotPresent, description);
    GREYHandleInteractionError(localError, error);
    return NO;
  }
  return sheetPresent;
}

- (void)tapElementInActivitySheetWithID:(NSString *)identifier error:(NSError **)error {
  [[self elementInActivitySheetWithID:identifier type:XCUIElementTypeAny error:error] tap];
}

- (BOOL)tapButtonInActivitySheetWithId:(NSString *)identifier error:(NSError **)error {
  XCUIElement *button = [self buttonInActivitySheetWithID:identifier error:error];
  [button tap];
  return button != nil;
}

- (BOOL)buttonPresentInActivitySheetWithId:(NSString *)identifier error:(NSError **)error {
  return [self buttonInActivitySheetWithID:identifier error:error] != nil;
}

- (XCUIElement *)buttonInActivitySheetWithID:(NSString *)identifier error:(NSError **)error {
  if ([identifier isEqualToString:@"Close"]) {
    return [self elementInActivitySheetWithID:identifier type:XCUIElementTypeButton error:error];
  }
  return [self elementInActivitySheetWithID:identifier type:XCUIElementTypeStaticText error:error];
}

- (XCUIElement *)elementInActivitySheetWithID:(NSString *)identifier
                                         type:(XCUIElementType)type
                                        error:(NSError **)error {
  XCUIElement *activitySheet = [self activitySheetWithError:error];
  if (!activitySheet) {
    return nil;
  }

  XCUIElementQuery *activityTexts = [activitySheet descendantsMatchingType:type];
  XCUIElement *element = [activityTexts elementMatchingType:type identifier:identifier];

  double timeoutInSeconds = GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration);
  if ([element waitForExistenceWithTimeout:timeoutInSeconds]) {
    return element;
  }

  NSString *description = [NSString
      stringWithFormat:@"Activity Sheet element not present with identifier: %@", identifier];
  GREYError *localError =
      GREYErrorMake(kGREYActivitySheetHandlingErrorDomain,
                    GREYActivitySheetHandlingSheetElementNotPresent, description);
  GREYHandleInteractionError(localError, error);
  return nil;
}

- (BOOL)closeActivitySheetWithError:(NSError **)error {
  if (![self activitySheetPresentWithError:error]) {
    return NO;
  }

  // Popover dismiss region is present on iPads and sheets with small detents on iOS 26.
  XCUIApplication *currentApplication = [[XCUIApplication alloc] init];
  XCUIElement *dismissRegion = currentApplication.otherElements[@"PopoverDismissRegion"];
  if (dismissRegion.exists && dismissRegion.hittable) {
    [dismissRegion tap];
    return YES;
  }
  return [self tapButtonInActivitySheetWithId:@"Close" error:error];
}

#endif  // TARGET_OS_IOS

@end
