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

#include <dlfcn.h>

#import "GREYFatalAsserts.h"
#import "GREYConfiguration.h"
#import "GREYTestApplicationDistantObject+Private.h"
#import "GREYTestApplicationDistantObject.h"
#import "GREYSwizzler.h"
#import "GREYTestConfiguration.h"
#import "XCUIApplication+GREYEnvironment.h"

#if !(TARGET_IPHONE_SIMULATOR)
/**
 * Text Input preferences controller to modify the keyboard preferences on device for iOS 8+.
 */
@interface TIPreferencesController : NSObject

/** Whether the autocorrection is enabled. */
@property BOOL autocorrectionEnabled;

/** Whether the predication is enabled. */
@property BOOL predictionEnabled;

/** The shared singleton instance. */
+ (instancetype)sharedPreferencesController;

/** Synchronize the change to save it on disk. */
- (void)synchronizePreferences;

/** Modify the preference @c value by @c key. */
- (void)setValue:(NSValue *)value forPreferenceKey:(NSString *)key;
@end
#endif

@implementation XCUIApplication (GREYTest)

+ (void)load {
  GREYSwizzler *swizzler = [[GREYSwizzler alloc] init];
  BOOL swizzleSuccess = [swizzler swizzleClass:[self class]
                         replaceInstanceMethod:@selector(launch)
                                    withMethod:@selector(grey_launch)];
  GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle XCUIApplication launch");
  swizzleSuccess = [swizzler swizzleClass:[self class]
                    replaceInstanceMethod:@selector(terminate)
                               withMethod:@selector(grey_terminate)];
  GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle XCUIApplication terminate");
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
  self.launchArguments = launchArgs;

  // Reset the port number for the app under test before every -[XCUIApplication launch] call.
  [testDistantObject resetHostArguments];
  INVOKE_ORIGINAL_IMP(void, @selector(grey_launch));
  NSLog(@"Application Launch Completed. UI Test with EarlGrey Starting");
}

- (void)grey_terminate {
  GREYTestConfiguration *testConfiguration =
      (GREYTestConfiguration *)GREYConfiguration.sharedConfiguration;
  testConfiguration.remoteConfiguration = nil;
  INVOKE_ORIGINAL_IMP(void, @selector(grey_terminate));
}

/**
 * Modifies the autocorrect and predictive typing settings to turn them off through the keyboard.
 */
- (void)modifyKeyboardSettings {
  static dispatch_once_t onceToken;
#if TARGET_IPHONE_SIMULATOR
  dispatch_once(&onceToken, ^{
    // Set the preferences values directly on simulator for the keyboard modifiers. For persisting
    // these values, CFPreferencesSynchronize must be called after.
    CFStringRef app = CFSTR("com.apple.Preferences");
    CFPreferencesSetValue(CFSTR("KeyboardAutocorrection"), kCFBooleanFalse, app,
                          kCFPreferencesAnyUser, kCFPreferencesAnyHost);
    CFPreferencesSetValue(CFSTR("KeyboardPrediction"), kCFBooleanFalse, app, kCFPreferencesAnyUser,
                          kCFPreferencesAnyHost);
    CFPreferencesSetValue(CFSTR("DidShowContinuousPathIntroduction"), kCFBooleanTrue, app,
                          kCFPreferencesAnyUser, kCFPreferencesAnyHost);
    CFPreferencesSetValue(CFSTR("KeyboardDidShowProductivityTutorial"), kCFBooleanTrue, app,
                          kCFPreferencesAnyUser, kCFPreferencesAnyHost);
    CFPreferencesSetValue(CFSTR("DidShowGestureKeyboardIntroduction"), kCFBooleanTrue, app,
                          kCFPreferencesAnyUser, kCFPreferencesAnyHost);
    CFPreferencesSetValue(CFSTR("UIKeyboardDidShowInternationalInfoIntroduction"), kCFBooleanTrue,
                          app, kCFPreferencesAnyUser, kCFPreferencesAnyHost);

    CFPreferencesSynchronize(kCFPreferencesAnyApplication, kCFPreferencesAnyUser,
                             kCFPreferencesAnyHost);
  });
#else
  dispatch_once(&onceToken, ^{
    // Setting the global keyboard preferences does not work on devices as this needs to be done
    // on the preferences application, which is sandboxed. We have to use the TextInput
    // framework to turn off the keyboard settings on device.
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

    if (iOS13_OR_ABOVE() &&
        UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
      [controller setValue:@YES forPreferenceKey:@"DidShowContinuousPathIntroduction"];
    } else if (iOS11_OR_ABOVE()) {
      [controller setValue:@YES forPreferenceKey:@"DidShowGestureKeyboardIntroduction"];
    }

    [controller synchronizePreferences];

    dlclose(handle);
  });
#endif
}

@end
