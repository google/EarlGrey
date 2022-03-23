//
// Copyright 2022 Google Inc.
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

#import "GREYSetup.h"

#include <dlfcn.h>

#import "GREYFatalAsserts.h"
#import "GREYAppleInternals.h"
#import "GREYDefines.h"

void GREYSetupKeyboardPreferences(BOOL isTestProcess) {
#if TARGET_IPHONE_SIMULATOR
  CFStringRef app = isTestProcess ? CFSTR("com.apple.Preferences")
                                  : CFSTR("com.apple.keyboard.preferences.plist");
  CFPreferencesSetValue(CFSTR("DidShowContinuousPathIntroduction"), kCFBooleanTrue, app,
                        kCFPreferencesAnyUser, kCFPreferencesAnyHost);
  CFPreferencesSetValue(CFSTR("KeyboardDidShowProductivityTutorial"), kCFBooleanTrue, app,
                        kCFPreferencesAnyUser, kCFPreferencesAnyHost);
  CFPreferencesSetValue(CFSTR("DidShowGestureKeyboardIntroduction"), kCFBooleanTrue, app,
                        kCFPreferencesAnyUser, kCFPreferencesAnyHost);
  CFPreferencesSetValue(CFSTR("UIKeyboardDidShowInternationalInfoIntroduction"), kCFBooleanTrue,
                        app, kCFPreferencesAnyUser, kCFPreferencesAnyHost);

  CFPreferencesSetValue(CFSTR("KeyboardAutocorrection"), kCFBooleanFalse, app,
                        kCFPreferencesAnyUser, kCFPreferencesAnyHost);
  CFPreferencesSetValue(CFSTR("KeyboardPrediction"), kCFBooleanFalse, app, kCFPreferencesAnyUser,
                        kCFPreferencesAnyHost);
  CFPreferencesSetValue(CFSTR("KeyboardShowPredictionBar"), kCFBooleanFalse, app,
                        kCFPreferencesAnyUser, kCFPreferencesAnyHost);
  CFPreferencesSynchronize(kCFPreferencesAnyApplication, kCFPreferencesAnyUser,
                           kCFPreferencesAnyHost);
#else
  // On iOS-15+ the TextInput framework has to be used in the application itself to turn off the
  // keyboard tutorial on iPads.
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

  if (iOS13_OR_ABOVE() && UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
    [controller setValue:@YES forPreferenceKey:@"DidShowContinuousPathIntroduction"];
  } else if (iOS11_OR_ABOVE()) {
    [controller setValue:@YES forPreferenceKey:@"DidShowGestureKeyboardIntroduction"];
  }

  [controller synchronizePreferences];

  dlclose(handle);
#endif
}
