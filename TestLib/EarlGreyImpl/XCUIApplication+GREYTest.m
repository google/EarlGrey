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

#import "XCUIApplication+GREYTest.h"

#include <objc/runtime.h>

#import "GREYFatalAsserts.h"
#import "GREYConfigKey.h"
#import "GREYConfiguration.h"
#import "GREYTestApplicationDistantObject+Private.h"
#import "GREYTestApplicationDistantObject.h"
#import "GREYFrameworkException.h"
#import "GREYLogger.h"
#import "GREYSetup.h"
#import "GREYSwizzler.h"
#import "GREYTestConfiguration.h"
#import "XCUIApplication+GREYEnvironment.h"

@implementation XCUIApplication (GREYTest)

+ (void)load {
  GREYSwizzler *swizzler = [[GREYSwizzler alloc] init];
  BOOL swizzleSuccess = [swizzler swizzleClass:[self class]
                         replaceInstanceMethod:@selector(launch)
                                    withMethod:@selector(grey_launch)];
  GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle XCUIApplication launch");
  swizzleSuccess = [swizzler swizzleClass:[self class]
                    replaceInstanceMethod:@selector(terminate)         // NOLINT
                               withMethod:@selector(grey_terminate)];  // NOLINT
  GREYFatalAssertWithMessage(swizzleSuccess,
                             @"Cannot swizzle XCUIApplication terminate");  // NOLINT
}

+ (NSString *)greyTestRigName {
  return objc_getAssociatedObject(self, @selector(greyTestRigName));
}

- (void)grey_launch {
  [self modifyKeyboardSettings];

  // Setup the Launch Environments.
  [self grey_configureApplicationForLaunch];
  // Setup the Launch Arguments for eDO.
  NSMutableArray<NSString *> *launchArgs = [self.launchArguments mutableCopy];
  if (!launchArgs) {
    launchArgs = [[NSMutableArray alloc] init];
  }
  GREYTestApplicationDistantObject *testDistantObject =
      GREYTestApplicationDistantObject.sharedInstance;
  [launchArgs addObjectsFromArray:@[
    @"-edoTestPort",
    @(testDistantObject.servicePort).stringValue,
    @"-IsRunningEarlGreyTest",
    @"YES",
  ]];

  NSString *loggingValue = [NSProcessInfo processInfo].environment[kGREYAllowVerboseLogging];
  if (loggingValue) {
    AddVerboseLoggingIfNeeded(launchArgs, loggingValue);
  }
  self.launchArguments = launchArgs;

  // Reset the port number for the app under test before every -[XCUIApplication launch] call.
  [testDistantObject resetHostArguments];

  NSTimer *validTimer = AddTimerForLaunchTimeout();
  INVOKE_ORIGINAL_IMP(void, @selector(grey_launch));
  [validTimer invalidate];
  // When the identifier is @c nil or empty, it is the TestRig application being launched.
  if (self.identifier.length == 0) {
    objc_setAssociatedObject([XCUIApplication class], @selector(greyTestRigName), self.label,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }
  GREYLog(@"Application Launch Completed. UI Test with EarlGrey Starting");
}

- (void)grey_terminate {  // NOLINT
  GREYTestConfiguration *testConfiguration =
      (GREYTestConfiguration *)GREYConfiguration.sharedConfiguration;
  testConfiguration.remoteConfiguration = nil;
  INVOKE_ORIGINAL_IMP(void, @selector(grey_terminate));  // NOLINT
}

#pragma mark - Private

/**
 * @return An NSTimer which will raise an exception once fired and fail the test.
 */
static NSTimer *AddTimerForLaunchTimeout(void) {
  // The max amount of time needed to launch the application.
  NSTimeInterval launchActionTimeout = GREY_CONFIG_DOUBLE(kGREYConfigKeyAppLaunchTimeout);
  NSString *launchTimeoutReason = [NSString
      stringWithFormat:
          @"The Host Application (TestRig) took longer than EarlGrey's timeout: %f seconds to "
          @"launch. Please check any system logs, crashes or run the test locally to pinpoint the "
          @"delay.",
          launchActionTimeout];
  NSTimer *validTimer =
      [NSTimer scheduledTimerWithTimeInterval:launchActionTimeout
                                      repeats:NO
                                        block:^(NSTimer *_Nonnull timer) {
                                          [[GREYFrameworkException
                                              exceptionWithName:kGREYGenericFailureException
                                                         reason:launchTimeoutReason] raise];
                                        }];
  [[NSRunLoop currentRunLoop] addTimer:validTimer forMode:NSDefaultRunLoopMode];
  return validTimer;
}

/**
 * If verbose logging related key-values are present, then add them to the launchEnvironment.
 *
 * @param launchArgs   The XCUIApplication launch arguments to be modified.
 * @param loggingValue The verbose logging related value present.
 */
static void AddVerboseLoggingIfNeeded(NSMutableArray<NSString *> *launchArgs,
                                      NSString *loggingValue) {
  GREYVerboseLogType verboseLoggingType = GREYVerboseLogTypeFromString(loggingValue);
  if (verboseLoggingType) {
    [launchArgs addObject:[NSString stringWithFormat:@"-%@", kGREYAllowVerboseLogging]];
    [launchArgs addObject:[NSString stringWithFormat:@"%zd", verboseLoggingType]];
  }
}

/**
 * Modifies the autocorrect and predictive typing settings to turn them off through the keyboard.
 */
- (void)modifyKeyboardSettings {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    GREYSetupKeyboardPreferences(YES);
  });
}

@end
