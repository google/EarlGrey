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

#import <dlfcn.h>
#import <execinfo.h>
#import <pthread.h>
#import <signal.h>

#import "Additions/CALayer+GREYAdditions.h"
#import "Additions/XCTestCase+GREYAdditions.h"
#import "Common/GREYAnalytics.h"
#import "Common/GREYConfiguration.h"
#import "Common/GREYDefines.h"
#import "Common/GREYExposed.h"
#import "Core/GREYKeyboard.h"
#import "Event/GREYSyntheticEvents.h"
#import "Exception/GREYDefaultFailureHandler.h"
#import "Synchronization/GREYBeaconImageProtocol.h"
#import "Synchronization/GREYUIThreadExecutor.h"

// Handler for all EarlGrey failures.
id<GREYFailureHandler> greyFailureHandler;

static pthread_mutex_t gFailureHandlerLock = PTHREAD_RECURSIVE_MUTEX_INITIALIZER;

@implementation EarlGreyImpl

+ (void)load {
  @autoreleasepool {
    // These need to be set in load since someone might call EarlGrey assertion APIs directly
    //  without calling into EarlGrey.
    greyFailureHandler = [[GREYDefaultFailureHandler alloc] init];

    grey_setupCrashHandlers();
    grey_configureDeviceAndSimulatorForAutomation();
  }
}

+ (void)initialize {
  @autoreleasepool {
    if ([self class] == [EarlGreyImpl class]) {
      // Registering |GREYBeaconImageProtocol| protocol class ensures that requests for EarlGrey
      // beacon images can be served by that class (without hitting external network).
      [NSURLProtocol registerClass:[GREYBeaconImageProtocol class]];
    }
  }
}

// Global simulator/device settings that must be configured for EarlGrey to perform correctly.
// These settings must be set before EarlGrey starts interacting with elements on screen.
static void grey_configureDeviceAndSimulatorForAutomation() {
  // This method ensures the software keyboard is shown.
  [[UIKeyboardImpl sharedInstance] setAutomaticMinimizationEnabled:NO];

  // For simulators and devices, this hack enables accessibility which is required for using
  // anything related to accessibility.
  // Before we can access AX settings preference, bundle needs to be loaded.
  NSString *const accessibilitySettingsPrefBundle =
      @"/System/Library/PreferenceBundles/AccessibilitySettings.bundle/AccessibilitySettings";
  char const *const accessibilitySettingsPrefBundlePath =
      [accessibilitySettingsPrefBundle fileSystemRepresentation];
  void *handle = dlopen(accessibilitySettingsPrefBundlePath, RTLD_LAZY);
  if (!handle) {
    NSLog(@"dlopen couldn't open accessibility settings bundle");
    abort();
  }

  Class axSettingsPrefControllerClass = NSClassFromString(@"AccessibilitySettingsController");
  if (!axSettingsPrefControllerClass) {
    NSLog(@"Couldn't find AccessibilitySettingsController class");
    abort();
  }

  id axSettingPrefController = [[axSettingsPrefControllerClass alloc] init];
  if (!axSettingPrefController) {
    NSLog(@"Couldn't initialize axSettingPrefController");
    abort();
  }

  [axSettingPrefController setAXInspectorEnabled:@(YES) specifier:nil];
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
  return instance;
}

- (instancetype)initOnce {
  self = [super init];
  if (self) {
    // Add observer for test case tearDown event for usage tracking.
    [[NSNotificationCenter defaultCenter] addObserverForName:kGREYXCTestCaseInstanceDidTearDown
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
      if (GREY_CONFIG_BOOL(kGREYConfigKeyAnalyticsEnabled)) {
        [GREYAnalytics trackTestCaseCompletion];
      }
    }];
  }
  return self;
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

- (void)grey_lockFailureHandler {
  int lock = pthread_mutex_lock(&gFailureHandlerLock);
  NSAssert(lock == 0, @"Failed to lock.");
}

- (void)grey_unlockFailureHandler {
  int unlock = pthread_mutex_unlock(&gFailureHandlerLock);
  NSAssert(unlock == 0, @"Failed to unlock.");
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

static void grey_installSignalHander(int signalId, struct sigaction *hander) {
  int returnValue = sigaction(signalId, hander, NULL);
  if (returnValue != 0) {
    NSLog(@"Error installing %s handler: '%s'.", strsignal(signalId), strerror(errno));
  }
}

static void grey_setupCrashHandlers() {
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
  grey_installSignalHander(SIGQUIT, &signalActionHandler);
  grey_installSignalHander(SIGILL, &signalActionHandler);
  grey_installSignalHander(SIGTRAP, &signalActionHandler);
  grey_installSignalHander(SIGABRT, &signalActionHandler);
  grey_installSignalHander(SIGFPE, &signalActionHandler);
  grey_installSignalHander(SIGBUS, &signalActionHandler);
  grey_installSignalHander(SIGSEGV, &signalActionHandler);
  grey_installSignalHander(SIGSYS, &signalActionHandler);

  // Register the handler for uncaught exceptions.
  NSSetUncaughtExceptionHandler(&grey_uncaughtExceptionHandler);

  NSLog(@"Crash handlers setup complete.");
}

@end
