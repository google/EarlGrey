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

#import "EarlGrey.h"

#include <dlfcn.h>
#include <execinfo.h>
#include <pthread.h>
#include <signal.h>

#import "Additions/CALayer+GREYAdditions.h"
#import "Additions/XCTestCase+GREYAdditions.h"
#import "Common/GREYAnalytics.h"
#import "Common/GREYConfiguration.h"
#import "Common/GREYDefines.h"
#import "Common/GREYExposed.h"
#import "Core/GREYKeyboard.h"
#import "Event/GREYSyntheticEvents.h"
#import "Exception/GREYDefaultFailureHandler.h"
#import "Synchronization/GREYUIThreadExecutor.h"

// Handler for all EarlGrey failures.
id<GREYFailureHandler> greyFailureHandler;

// Lock to guard access to @c greyFailureHandler.
static pthread_mutex_t gFailureHandlerLock = PTHREAD_RECURSIVE_MUTEX_INITIALIZER;

@implementation EarlGreyImpl {
  // Invocation should be tracked on next teardown.
  BOOL _makeAnalyticsCallOnTearDown;
}

+ (void)load {
  @autoreleasepool {
    // These need to be set in load since someone might call GREYAssertXXX APIs without calling
    // into EarlGrey.
    greyFailureHandler = [[GREYDefaultFailureHandler alloc] init];

    [self grey_setupCrashHandlers];
    [self grey_configureDeviceAndSimulatorForAutomation];
  }
}

+ (instancetype)invokedFromFile:(NSString *)fileName lineNumber:(NSUInteger)lineNumber {
  static EarlGreyImpl *instance = nil;
  static dispatch_once_t token = 0;
  dispatch_once(&token, ^{
    instance = [[EarlGreyImpl alloc] initOnce];
  });

  if ([greyFailureHandler respondsToSelector:@selector(setInvocationFile:andInvocationLine:)]) {
    [greyFailureHandler setInvocationFile:fileName andInvocationLine:lineNumber];
  }
  [instance grey_didInvokeEarlGrey];
  return instance;
}

- (instancetype)initOnce {
  self = [super init];
  if (self) {
    // Add a global observer for all test teardown events.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(grey_testCaseDidTearDown:)
                                                 name:kGREYXCTestCaseInstanceDidTearDown
                                               object:nil];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:kGREYXCTestCaseInstanceDidTearDown
                                                object:nil];
}

- (GREYElementInteraction *)selectElementWithMatcher:(id<GREYMatcher>)elementMatcher {
  return [[GREYElementInteraction alloc] initWithElementMatcher:elementMatcher];
}

- (void)setFailureHandler:(id<GREYFailureHandler>)handler {
  [self grey_lockFailureHandler];
  greyFailureHandler = (handler == nil) ? [[GREYDefaultFailureHandler alloc] init] : handler;
  [self grey_unlockFailureHandler];
}

- (void)handleException:(GREYFrameworkException *)exception details:(NSString *)details {
  [self grey_lockFailureHandler];
  [greyFailureHandler handleException:exception details:details];
  [self grey_unlockFailureHandler];
}

- (BOOL)rotateDeviceToOrientation:(UIDeviceOrientation)deviceOrientation
                       errorOrNil:(__strong NSError **)errorOrNil {
  return [GREYSyntheticEvents rotateDeviceToOrientation:deviceOrientation errorOrNil:errorOrNil];
}

#pragma mark - Private

// Called when any Earlgrey invocation occurs using any @code [EarlGrey XXX] @endcode statements.
- (void)grey_didInvokeEarlGrey {
  if ([XCTestCase grey_currentTestCase]) {
    // Count a hit only if EarlGrey is called within the context of a test case.
    _makeAnalyticsCallOnTearDown = YES;
  }
}

- (void)grey_testCaseDidTearDown:(NSNotification *)note {
  if (_makeAnalyticsCallOnTearDown) {
    if (GREY_CONFIG_BOOL(kGREYConfigKeyAnalyticsEnabled)) {
      [GREYAnalytics trackTestCaseCompletion];
    }
    _makeAnalyticsCallOnTearDown = NO;
  }
}

- (void)grey_lockFailureHandler {
  int lock = pthread_mutex_lock(&gFailureHandlerLock);
  NSAssert(lock == 0, @"Failed to lock.");
}

- (void)grey_unlockFailureHandler {
  int unlock = pthread_mutex_unlock(&gFailureHandlerLock);
  NSAssert(unlock == 0, @"Failed to unlock.");
}

// Global simulator/device settings that must be configured for EarlGrey to perform correctly.
// These settings must be set before EarlGrey starts interacting with elements on screen.
+ (void)grey_configureDeviceAndSimulatorForAutomation {
  // This method ensures the software keyboard is shown.
  [[UIKeyboardImpl sharedInstance] setAutomaticMinimizationEnabled:NO];

  // Modifies the accessibility settings to ensure that the accessibility inspector
  // is always shown.
  [self grey_modifyAccessibilitySettings];

  // Modifies the keyboard settings to ensure that auto correction is turned off by default
  // for a ui keyboard. We perform this action only in the case of iOS8+.
  if (iOS8_2_OR_ABOVE()) {
    [self grey_modifyKeyboardSettings];
  }
}

// For simulators and devices, this hack enables accessibility which is required for using
// anything related to accessibility.
// Before we can access AX settings preference, bundle needs to be loaded.
+ (void)grey_modifyAccessibilitySettings {
  NSString *accessibilitySettingsPrefBundlePath =
      @"/System/Library/PreferenceBundles/AccessibilitySettings.bundle/AccessibilitySettings";
  NSString *accessibilityControllerClassName = @"AccessibilitySettingsController";
  id accessibilityControllerInstance =
      [self grey_settingsClassInstanceFromBundleAtPath:accessibilitySettingsPrefBundlePath
                                         withClassName:accessibilityControllerClassName];
  [accessibilityControllerInstance setAXInspectorEnabled:@(YES) specifier:nil];
}

// Modifies the autocorrect and predictive typing settings to turn them off through the
// keyboard settings bundle.
+ (void)grey_modifyKeyboardSettings {
  NSString *keyboardSettingsPrefBundlePath =
      @"/System/Library/PreferenceBundles/KeyboardSettings.bundle/KeyboardSettings";
  NSString *keyboardControllerClassName = @"KeyboardController";
  id keyboardControllerInstance =
      [self grey_settingsClassInstanceFromBundleAtPath:keyboardSettingsPrefBundlePath
                                         withClassName:keyboardControllerClassName];
  [keyboardControllerInstance setAutocorrectionPreferenceValue:@(NO) forSpecifier:nil];
  [keyboardControllerInstance setPredictionPreferenceValue:@(NO) forSpecifier:nil];
}

// For the provided settings bundle path, we use the actual name of the controller
// class to extract and return a class instance that can be modified.
+ (id)grey_settingsClassInstanceFromBundleAtPath:(NSString *)path
                                   withClassName:(NSString *)className {
  NSParameterAssert(path);
  NSParameterAssert(className);
  char const *const preferenceBundlePath = [path fileSystemRepresentation];
  void *handle = dlopen(preferenceBundlePath, RTLD_LAZY);
  if (!handle) {
    NSAssert(NO, @"dlopen couldn't open settings bundle at path bundle %@", path);
  }

  Class klass = NSClassFromString(className);
  if (!klass) {
    NSAssert(NO, @"Couldn't find %@ class", klass);
  }

  id klassInstance = [[klass alloc] init];
  if (!klassInstance) {
    NSAssert(NO, @"Couldn't initialize controller for class: %@", klass);
  }

  return klassInstance;
}

#pragma mark - Crash Handlers

// Call only asynchronous-safe functions within signal handlers
// See definition here: https://www.securecoding.cert.org/confluence/display/seccode/BB.+Definitions
static void grey_signalHandler(int signal) {
  char *signalString = strsignal(signal);
  write(STDERR_FILENO, signalString, strlen(signalString));
  write(STDERR_FILENO, "\n", 1);
  static const int kMaxStackSize = 128;
  void *callStack[kMaxStackSize];
  const int numFrames = backtrace(callStack, kMaxStackSize);
  backtrace_symbols_fd(callStack, numFrames, STDERR_FILENO);
  kill(getpid(), SIGKILL);
}

static void grey_uncaughtExceptionHandler(NSException *exception) {
  NSLog(@"Uncaught exception: %@", exception);
  exit(-1);
}

static void grey_installSignalHandler(int signalId, struct sigaction *handler) {
  int returnValue = sigaction(signalId, handler, NULL);
  if (returnValue != 0) {
    NSLog(@"Error installing %s handler: '%s'.", strsignal(signalId), strerror(errno));
  }
}

+ (void) grey_setupCrashHandlers {
  NSLog(@"Crash handler setup started.");

  struct sigaction signalActionHandler;
  memset(&signalActionHandler, 0, sizeof(signalActionHandler));
  int result = sigemptyset(&signalActionHandler.sa_mask);
  if (result != 0) {
    NSLog(@"Unable to empty sa_mask. Return value:%d", result);
    exit(-1);
  }
  signalActionHandler.sa_handler = &grey_signalHandler;

  // Register the signal handlers.
  grey_installSignalHandler(SIGQUIT, &signalActionHandler);
  grey_installSignalHandler(SIGILL, &signalActionHandler);
  grey_installSignalHandler(SIGTRAP, &signalActionHandler);
  grey_installSignalHandler(SIGABRT, &signalActionHandler);
  grey_installSignalHandler(SIGFPE, &signalActionHandler);
  grey_installSignalHandler(SIGBUS, &signalActionHandler);
  grey_installSignalHandler(SIGSEGV, &signalActionHandler);
  grey_installSignalHandler(SIGSYS, &signalActionHandler);

  // Register the handler for uncaught exceptions.
  NSSetUncaughtExceptionHandler(&grey_uncaughtExceptionHandler);

  NSLog(@"Crash handlers setup complete.");
}

@end
