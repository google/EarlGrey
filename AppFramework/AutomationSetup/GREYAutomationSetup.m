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

#import "GREYAutomationSetup.h"

#include <dlfcn.h>
#include <execinfo.h>
#include <objc/runtime.h>
#include <signal.h>

#import "GREYFatalAsserts.h"
#import "GREYAppleInternals.h"
#import "GREYDefines.h"
#import "GREYTestApplicationDistantObject+GREYLogger.h"

// Exception handler that was previously installed before we replaced it with our own.
static NSUncaughtExceptionHandler *gPreviousUncaughtExceptionHandler;

// Normal signal handler.
typedef void (*SignalHandler)(int signum);

// When SA_SIGINFO is set, it is an extended signal handler.
typedef void (*SignalHandlerEX)(int signum, struct __siginfo *siginfo, void *context);

// All signals that we want to handle.
static const int gSignals[] = {
    SIGQUIT, SIGILL, SIGTRAP, SIGABRT, SIGFPE, SIGBUS, SIGSEGV, SIGSYS,
};

// Total number of signals we handle.
static const int kNumSignals = sizeof(gSignals) / sizeof(gSignals[0]);

// A union of normal and extended signal handler.
typedef union GREYSignalHandlerUnion {
  SignalHandler signalHandler;
  SignalHandlerEX signalHandlerExtended;
} GREYSignalHandlerUnion;

// Saved signal handler with a bit indicating extended or normal handler signature.
typedef struct GREYSignalHandler {
  GREYSignalHandlerUnion handler;
  bool extended;
} GREYSignalHandler;

// All previous signal handlers we replaced with our own.
static GREYSignalHandler gPreviousSignalHandlers[kNumSignals];

#pragma mark - Automation Setup

@implementation GREYAutomationSetup

+ (void)load {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  // TODO: Perform a scan of UIWebView usage and deprecate if possible. // NOLINT
  // It seems that in +[UIWebView initialize], it performs something that needs to be done on the
  // thread; this causes crashes when we try to fetch +[UIWebView class] from a background thread,
  // where our actions are being performed. We proactively load the class and trigger the message
  // +initialize to be sent on UIWebView on the main thread here.
  [UIWebView class];
#pragma clang diagnostic pop

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(setupOnAppLaunch)
                                               name:UIApplicationDidFinishLaunchingNotification
                                             object:nil];
}

/**
 *  Setup any prerequisites for EarlGrey such as changing preference bundles or setting crash
 *  handlers.
 */
+ (void)setupOnAppLaunch {
  [[GREYAutomationSetup sharedInstance] prepare];
}

+ (instancetype)sharedInstance {
  static GREYAutomationSetup *sharedInstance = nil;
  static dispatch_once_t token = 0;
  dispatch_once(&token, ^{
    sharedInstance = [[GREYAutomationSetup alloc] initOnce];
  });
  return sharedInstance;
}

- (instancetype)initOnce {
  self = [super init];
  return self;
}

- (void)prepare {
  [self grey_setupCrashHandlers];
  // Force software keyboard.
  [[UIKeyboardImpl sharedInstance] setAutomaticMinimizationEnabled:NO];
  // Turn off auto correction as it interferes with typing on iOS 8.2+.
  [self grey_modifyKeyboardSettings];
}

#pragma mark - Accessibility
// Modifies the autocorrect and predictive typing settings to turn them off through the
// keyboard settings bundle.
- (void)grey_modifyKeyboardSettings {
  static char const *const controllerPrefBundlePath =
      "/System/Library/PrivateFrameworks/TextInput.framework/TextInput";
  static NSString *const controllerClassName = @"TIPreferencesController";
  void *handle = dlopen(controllerPrefBundlePath, RTLD_LAZY);
  GREYFatalAssertWithMessage(handle, @"dlopen couldn't open settings bundle at path bundle %s",
                             controllerPrefBundlePath);

  Class controllerClass = NSClassFromString(controllerClassName);
  GREYFatalAssertWithMessage(controllerClass, @"Couldn't find %@ class", controllerClassName);

  TIPreferencesController *controller = [controllerClass sharedPreferencesController];
  if ([controller respondsToSelector:@selector(setAutocorrectionEnabled:)]) {
    controller.autocorrectionEnabled = NO;
  } else {
    [controller setValue:@NO forPreferenceKey:@"KeyboardAutocorrection"];
  }

  if ([controller respondsToSelector:@selector(setPredictionEnabled:)]) {
    controller.predictionEnabled = NO;
  } else {
    [controller setValue:@NO forPreferenceKey:@"KeyboardPrediction"];
  }

  if (iOS11_OR_ABOVE()) {
    [controller setValue:@YES forPreferenceKey:@"DidShowGestureKeyboardIntroduction"];
  }
  if (iOS13_OR_ABOVE()) {
    [controller setValue:@YES forPreferenceKey:@"DidShowContinuousPathIntroduction"];
  }

  [controller synchronizePreferences];

  dlclose(handle);
}

#pragma mark - Crash Handlers

// Installs the default handler and raises the specified @c signum.
static void grey_installDefaultHandlerAndRaise(int signum) {
  // Install default and re-raise the signal.
  struct sigaction defaultSignalAction;
  memset(&defaultSignalAction, 0, sizeof(defaultSignalAction));
  int result = sigemptyset(&defaultSignalAction.sa_mask);
  if (result != 0) {
    char *sigEmptyError = "Unable to empty sa_mask";
    write(STDERR_FILENO, sigEmptyError, strlen(sigEmptyError));
    kill(getpid(), SIGKILL);
  }

  defaultSignalAction.sa_handler = SIG_DFL;
  if (sigaction(signum, &defaultSignalAction, NULL) == 0) {
    // re-raise with default in place.
    raise(signum);
  }
}

// Call only asynchronous-safe functions within signal handlers
// Learn more:
// NOLINTNEXTLINE
// https://www.securecoding.cert.org/confluence/display/c/SIG00-C.+Mask+signals+handled+by+noninterruptible+signal+handlers
static void grey_signalHandler(int signum) {
  char *signalCaught = "Signal caught: ";
  char *signalString = strsignal(signum);
  write(STDERR_FILENO, signalCaught, strlen(signalCaught));
  write(STDERR_FILENO, signalString, strlen(signalString));

  write(STDERR_FILENO, "\n", 1);
  static const int kMaxStackSize = 128;
  void *callStack[kMaxStackSize];
  const int numFrames = backtrace(callStack, kMaxStackSize);
  backtrace_symbols_fd(callStack, numFrames, STDERR_FILENO);

  int signalIndex = -1;
  for (size_t i = 0; i < kNumSignals; i++) {
    if (signum == gSignals[i]) {
      signalIndex = (int)i;
    }
  }

  if (signalIndex == -1) {  // Not found.
    char *signalNotFound = "Caught signal not in handled signal array: ";
    write(STDERR_FILENO, signalNotFound, strlen(signalNotFound));
    write(STDERR_FILENO, signalString, strlen(signalString));
    kill(getpid(), SIGKILL);
  }

  GREYSignalHandler previousSignalHandler = gPreviousSignalHandlers[signalIndex];
  if (previousSignalHandler.extended) {
    // We don't handle these yet, simply re-raise with default handler.
    grey_installDefaultHandlerAndRaise(signum);
  } else {
    SignalHandler signalHandler = previousSignalHandler.handler.signalHandler;
    if (signalHandler == SIG_DFL) {
      grey_installDefaultHandlerAndRaise(signum);
    } else if (signalHandler == SIG_IGN) {
      // Ignore.
    } else {
      signalHandler(signum);
    }
  }
}

static void grey_uncaughtExceptionHandler(NSException *exception) {
  NSString *formatString = @"Uncaught exception in Application: %@\n%@";
  NSString *callStackSymbols = [exception.callStackSymbols componentsJoinedByString:@"\n"];
  NSString *exceptionString = [NSString stringWithFormat:formatString, exception, callStackSymbols];
  [[GREYTestApplicationDistantObject sharedInstance] printLogInTest:exceptionString];
  if (gPreviousUncaughtExceptionHandler) {
    gPreviousUncaughtExceptionHandler(exception);
  } else {
    exit(EXIT_FAILURE);
  }
}

- (void)grey_setupCrashHandlers {
  NSLog(@"Crash handler setup started.");

  struct sigaction signalAction;
  memset(&signalAction, 0, sizeof(signalAction));
  int result = sigemptyset(&signalAction.sa_mask);
  if (result != 0) {
    NSLog(@"Unable to empty sa_mask. Return value:%d", result);
    exit(EXIT_FAILURE);
  }
  signalAction.sa_handler = &grey_signalHandler;

  for (size_t i = 0; i < kNumSignals; i++) {
    int signum = gSignals[i];
    struct sigaction previousSigAction;
    memset(&previousSigAction, 0, sizeof(previousSigAction));

    GREYSignalHandler *previousSignalHandler = &gPreviousSignalHandlers[i];
    memset(previousSignalHandler, 0, sizeof(gPreviousSignalHandlers[0]));

    int returnValue = sigaction(signum, &signalAction, &previousSigAction);
    if (returnValue != 0) {
      NSLog(@"Error installing %s handler. errorno:'%s'.", strsignal(signum), strerror(errno));
      previousSignalHandler->extended = false;
      previousSignalHandler->handler.signalHandler = SIG_IGN;
    } else if (previousSigAction.sa_flags & SA_SIGINFO) {
      previousSignalHandler->extended = true;
      previousSignalHandler->handler.signalHandlerExtended =
          previousSigAction.__sigaction_u.__sa_sigaction;
    } else {
      previousSignalHandler->extended = false;
      previousSignalHandler->handler.signalHandler = previousSigAction.__sigaction_u.__sa_handler;
    }
  }
  // Register the handler for uncaught exceptions.
  gPreviousUncaughtExceptionHandler = NSGetUncaughtExceptionHandler();
  NSSetUncaughtExceptionHandler(&grey_uncaughtExceptionHandler);

  NSLog(@"Crash handler setup completed.");
}

@end
