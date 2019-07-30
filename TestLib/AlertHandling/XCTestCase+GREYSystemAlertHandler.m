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

#import "XCTestCase+GREYSystemAlertHandler.h"

#import <objc/runtime.h>

#import "GREYThrowDefines.h"
#import "GREYAppleInternals.h"
#import "GREYDefines.h"
#import "GREYXCTestAppleInternals.h"
#import "GREYAssertionDefines.h"
#import "GREYCondition.h"

/**
 *  Text denoting part of the Location System Alert Label in iOS 10.
 */
static NSString *const kSystemAlertLabelLocationIOS10 = @"location while you use the app";
/**
 *  Text denoting part of the Location System Alert Label in iOS 11.
 */
static NSString *const kSystemAlertLabelLocationIOS11 = @"location while you are using the app";
/**
 *  Text denoting part of the Background Location System Alert Label when the location alert has
 *  not been accepted.
 */
static NSString *const kSystemAlertLabelBGLocationAlways = @"access your location?";
/**
 *  Text denoting part of the Background Location System Alert Label when the location alert has
 *  been accepted.
 */
static NSString *const kSystemAlertLabelBGLocationNotUsingTheApp =
    @"location even when you are not using the app?";
/**
 *  Text denoting part of the Camera System Alert.
 */
static NSString *const kSystemAlertLabelCamera = @"Camera";
/**
 *  Text denoting part of the Photos System Alert.
 */
static NSString *const kSystemAlertLabelPhotos = @"Photos";
/**
 *  Text denoting part of the Microphone System Alert.
 *  TODO: Add functional tests for this. // NOLINT
 */
static NSString *const kSystemAlertLabelMicrophone = @"Microphone";
/**
 *  Text denoting part of the Reminders System Alert.
 */
static NSString *const kSystemAlertLabelReminders = @"Reminders";
/**
 *  Text denoting part of the Calendar System Alert.
 */
static NSString *const kSystemAlertLabelCalendar = @"Calendar";
/**
 *  Text denoting part of the Notifications (APNS) System Alert.
 */
static NSString *const kSystemAlertLabelNotifications = @"Notifications";
/**
 *  Text denoting part of the Motion Activity System Alert.
 */
static NSString *const kSystemAlertLabelMotionActivity = @"Motion & Fitness Activity";
/**
 *  Text denoting part of the Contacts System Alert.
 */
static NSString *const kSystemAlertLabelContacts = @"Contacts";

CFTimeInterval const kSystemAlertVisibilityTimeout = 10;
NSString *const kGREYSystemAlertDismissalErrorDomain = @"com.google.earlgrey.SystemAlertDismissal";

@implementation XCTestCase (GREYSystemAlertHandler)

- (NSString *)grey_systemAlertTextWithError:(NSError **)error {
  XCUIApplication *springboardApp = [self grey_springboardApplication];
  if (![self grey_ensureAlertIsVisibleInSpringboardApp:springboardApp error:error]) {
    return nil;
  } else {
    XCUIElement *alertInHierarchy =
        [[springboardApp descendantsMatchingType:XCUIElementTypeAlert] firstMatch];
    if (![alertInHierarchy exists]) {
      if (error) {
        *error = [NSError errorWithDomain:kGREYSystemAlertDismissalErrorDomain
                                     code:GREYSystemAlertNotPresent
                                 userInfo:nil];
      }
      return nil;
    }
    return [alertInHierarchy label];
  }
}

- (GREYSystemAlertType)grey_systemAlertType {
  XCUIApplication *springboardApp = [self grey_springboardApplication];
  GREYAssertTrue([self grey_waitForAlertExistenceWithTimeout:kSystemAlertVisibilityTimeout],
                 @"Time out waiting for alert existing in UI hierarchy");

  // Make sure the alert is up before checking for an alert.
  XCUIElement *alert = [[springboardApp descendantsMatchingType:XCUIElementTypeAlert] firstMatch];
  GREYAssertNotNil(alert, @"Alert does not exist");
  NSString *alertValue = [alert label];
  // The Alert Label for the Location Alert is different for iOS 11 and iOS 10.
  NSString *locationAlertLabelString =
      iOS11_OR_ABOVE() ? kSystemAlertLabelLocationIOS11 : kSystemAlertLabelLocationIOS10;
  // There are two descriptions for the background alert, because it has two versions. It can be
  // the case that the location alert is not accepted, which means that a third value with a
  // "Use Once" option will be shown. If the location alert has already been shown, then the
  // denial alert button is not shown.
  if ([alertValue rangeOfString:kSystemAlertLabelBGLocationAlways].location != NSNotFound ||
      [alertValue rangeOfString:kSystemAlertLabelBGLocationNotUsingTheApp].location != NSNotFound) {
    return GREYSystemAlertTypeBackgroundLocation;
  } else if ([alertValue rangeOfString:locationAlertLabelString].location != NSNotFound) {
    return GREYSystemAlertTypeLocation;
  } else if ([alertValue rangeOfString:kSystemAlertLabelCamera].location != NSNotFound) {
    return GREYSystemAlertTypeCamera;
  } else if ([alertValue rangeOfString:kSystemAlertLabelPhotos].location != NSNotFound) {
    return GREYSystemAlertTypePhotos;
  } else if ([alertValue rangeOfString:kSystemAlertLabelMicrophone].location != NSNotFound) {
    return GREYSystemAlertTypeMicrophone;
  } else if ([alertValue rangeOfString:kSystemAlertLabelCalendar].location != NSNotFound) {
    return GREYSystemAlertTypeCalendar;
  } else if ([alertValue rangeOfString:kSystemAlertLabelReminders].location != NSNotFound) {
    return GREYSystemAlertTypeReminder;
  } else if ([alertValue rangeOfString:kSystemAlertLabelNotifications].location != NSNotFound) {
    return GREYSystemAlertTypeNotifications;
  } else if ([alertValue rangeOfString:kSystemAlertLabelMotionActivity].location != NSNotFound) {
    return GREYSystemAlertTypeMotionActivity;
  } else if ([alertValue rangeOfString:kSystemAlertLabelContacts].location != NSNotFound) {
    return GREYSystemAlertTypeContacts;
  }
  GREYThrow(@"Invalid System Alert. Please add support for this value. Label is: %@", alertValue);
  return GREYSystemAlertTypeUnknown;
}

- (BOOL)grey_acceptSystemDialogWithError:(NSError **)error {
  XCUIApplication *springboardApp = [self grey_springboardApplication];
  if (![self grey_ensureAlertIsVisibleInSpringboardApp:springboardApp error:error]) {
    return NO;
  }

  XCUIElement *alertInHierarchy =
      [[springboardApp descendantsMatchingType:XCUIElementTypeAlert] firstMatch];
  if (![alertInHierarchy exists]) {
    if (error) {
      *error = [NSError errorWithDomain:kGREYSystemAlertDismissalErrorDomain
                                   code:GREYSystemAlertAcceptButtonNotFound
                               userInfo:nil];
    }
    return NO;
  }
  NSString *alertText = [alertInHierarchy valueForKey:@"label"];

  XCUIElement *acceptButton = [[alertInHierarchy buttons] elementBoundByIndex:1];
  NSAssert([acceptButton isHittable], @"accept button is not hittable\n%@",
           [springboardApp debugDescription]);

  BOOL dismissed = NO;
  // Retry logic can solve the failure in slow animations mode.
  [acceptButton tap];
  dismissed = [self grey_ensureAlertDismissalInSpringboardApp:springboardApp
                                       withDismissedAlertText:alertText
                                                        error:error];

  return dismissed;
}

- (BOOL)grey_denySystemDialogWithError:(NSError **)error {
  XCUIApplication *springboardApp = [self grey_springboardApplication];
  if (![self grey_ensureAlertIsVisibleInSpringboardApp:springboardApp error:error]) {
    return NO;
  }

  XCUIElement *alertInHierarchy =
      [[springboardApp descendantsMatchingType:XCUIElementTypeAlert] firstMatch];
  if (![alertInHierarchy exists]) {
    if (error) {
      *error = [NSError errorWithDomain:kGREYSystemAlertDismissalErrorDomain
                                   code:GREYSystemAlertDenialButtonNotFound
                               userInfo:nil];
    }
    return NO;
  }

  NSString *alertText = [alertInHierarchy valueForKey:@"label"];
  XCUIElement *denyButton;
  // In case of alerts such a Background Alert where a third "Always While Using This App" option
  // exists, hit the second button for denial.
  if ([[[alertInHierarchy buttons] elementBoundByIndex:2] exists]) {
    denyButton = [[alertInHierarchy buttons] elementBoundByIndex:2];
  } else if ([self grey_systemAlertType] == GREYSystemAlertTypeBackgroundLocation) {
    GREYThrow(@"Dismissing a Background Location System Alert once Location Alert is accepted.");
  } else {
    denyButton = [[alertInHierarchy buttons] firstMatch];
  }
  NSAssert([denyButton isHittable], @"deny button is not hittable\n%@",
           [springboardApp debugDescription]);

  BOOL dismissed = NO;
  // Retry logic can solve the failure in slow animations mode.
  [denyButton tap];
  dismissed = [self grey_ensureAlertDismissalInSpringboardApp:springboardApp
                                       withDismissedAlertText:alertText
                                                        error:error];

  return dismissed;
}

- (BOOL)grey_tapSystemDialogButtonWithText:(NSString *)text error:(NSError **)error {
  XCUIApplication *springboardApp = [self grey_springboardApplication];
  if (![self grey_ensureAlertIsVisibleInSpringboardApp:springboardApp error:error]) {
    return NO;
  }

  XCUIElement *firstAlertPresent =
      [[springboardApp descendantsMatchingType:XCUIElementTypeAlert] firstMatch];
  if (![firstAlertPresent.buttons[text] exists]) {
    if (error) {
      *error = [NSError errorWithDomain:kGREYSystemAlertDismissalErrorDomain
                                   code:GREYSystemAlertCustomButtonNotFound
                               userInfo:nil];
    }
    return NO;
  }
  NSString *alertText = [firstAlertPresent valueForKey:@"label"];
  XCUIElement *button = firstAlertPresent.buttons[text];
  NSAssert([button isHittable], @"button is not hittable\n%@", [springboardApp debugDescription]);

  BOOL dismissed = NO;
  // Retry logic can solve the failure in slow animations mode.
  [button tap];
  dismissed = [self grey_ensureAlertDismissalInSpringboardApp:springboardApp
                                       withDismissedAlertText:alertText
                                                        error:error];

  return dismissed;
}

- (BOOL)grey_typeSystemAlertText:(NSString *)textToType
              forPlaceholderText:(NSString *)placeholderText
                           error:(NSError **)error {
  GREYThrowOnNilParameterWithMessage(textToType, @"textToType cannot be nil.");
  GREYThrowOnNilParameterWithMessage(placeholderText, @"placeholderText cannot be nil.");
  GREYThrowOnNilParameterWithMessage(placeholderText.length, @"placeholderText cannot be empty.");
  XCUIApplication *springboardApp = [self grey_springboardApplication];
  if (![self grey_ensureAlertIsVisibleInSpringboardApp:springboardApp error:error]) {
    return NO;
  }

  XCUIElement *firstAlertPresent =
      [[springboardApp descendantsMatchingType:XCUIElementTypeAlert] firstMatch];
  XCUIElement *elementToType = nil;
  if ([firstAlertPresent.textFields[placeholderText] exists]) {
    elementToType = firstAlertPresent.textFields[placeholderText];
    [firstAlertPresent.textFields[placeholderText] tap];
    [firstAlertPresent.textFields[placeholderText] typeText:textToType];
  } else if ([firstAlertPresent.secureTextFields[placeholderText] exists]) {
    elementToType = firstAlertPresent.secureTextFields[placeholderText];
    [firstAlertPresent.secureTextFields[placeholderText] tap];
    [firstAlertPresent.secureTextFields[placeholderText] typeText:textToType];
  } else if ([firstAlertPresent.searchFields[placeholderText] exists]) {
    elementToType = firstAlertPresent.searchFields[placeholderText];
    [firstAlertPresent.secureTextFields[placeholderText] tap];
    [firstAlertPresent.secureTextFields[placeholderText] typeText:textToType];
  }

  if (![elementToType exists]) {
    if (error) {
      *error = [NSError errorWithDomain:kGREYSystemAlertDismissalErrorDomain
                                   code:GREYSystemAlertTextNotTypedCorrectly
                               userInfo:nil];
    }
    return NO;
  }
  return YES;
}

#pragma mark - Wait for alert

- (BOOL)grey_waitForAlertVisibility:(BOOL)visible withTimeout:(CFTimeInterval)seconds {
  GREYThrowOnFailedConditionWithMessage(seconds >= 0, @"timeout must be >= 0.");
  BOOL (^alertShown)(void) = ^BOOL(void) {
    return [[UIApplication sharedApplication] _isSpringBoardShowingAnAlert];
  };
  BOOL (^alertNotShown)(void) = ^BOOL(void) {
    return ![[UIApplication sharedApplication] _isSpringBoardShowingAnAlert];
  };
  GREYCondition *condition =
      [GREYCondition conditionWithName:@"WaitForAlert" block:visible ? alertShown : alertNotShown];
  return [condition waitWithTimeout:seconds];
}

- (BOOL)grey_waitForAlertExistenceWithTimeout:(CFTimeInterval)seconds {
  GREYThrowOnFailedConditionWithMessage(seconds >= 0, @"timeout must be >= 0.");
  XCUIApplication *springboardApp = [self grey_springboardApplication];
  XCUIElement *alert = [[springboardApp descendantsMatchingType:XCUIElementTypeAlert] firstMatch];
  return [alert waitForExistenceWithTimeout:seconds];
}

#pragma mark - Private

/**
 *  Ensures that a system alert is visible in the UI.
 *
 *  @param springboardApp The springboard application displaying the alerts.
 *  @param[out] error     An NSError that will be populated in case there is any issue.
 */
- (BOOL)grey_ensureAlertIsVisibleInSpringboardApp:(XCUIApplication *)springboardApp
                                            error:(NSError **)error {
  if (![self grey_waitForAlertExistenceWithTimeout:kSystemAlertVisibilityTimeout]) {
    if (error) {
      *error = [NSError errorWithDomain:kGREYSystemAlertDismissalErrorDomain
                                   code:GREYSystemAlertNotPresent
                               userInfo:nil];
      ;
    }
    return NO;
  }
  return YES;
}

/**
 *  Ensures that the alert has been dismissed by checking the XCUITest Element Hierarchy for any
 *  alerts, and checking if it is the same alert that was just dismissed.
 *
 *  @param springboardApp The springboard application displaying the alerts.
 *  @param alertText      The text of the alert that was just dismissed.
 *  @param[out] error     An NSError that will be populated in case there is any issue.
 */
- (BOOL)grey_ensureAlertDismissalInSpringboardApp:(XCUIApplication *)springboardApp
                           withDismissedAlertText:(NSString *)alertText
                                            error:(NSError **)error {
  BOOL (^alertDismissedBlock)(void) = ^BOOL(void) {
    XCUIElement *anyAlertPresent = nil;
    XCUIElementQuery *anyAlertPresentQuery =
        [springboardApp descendantsMatchingType:XCUIElementTypeAlert];
    NSString *label = nil;
    if ([anyAlertPresentQuery count]) {
      anyAlertPresent = [anyAlertPresentQuery firstMatch];
      label = anyAlertPresent ? [anyAlertPresent valueForKey:@"label"] : @"";
    }
    // Ensure that the same alert being asked for has been dismissed.
    return (![label isEqualToString:alertText]);
  };

  GREYCondition *alertDismissed =
      [GREYCondition conditionWithName:@"Alert Dismissed" block:alertDismissedBlock];
  if (![alertDismissed waitWithTimeout:kSystemAlertVisibilityTimeout pollInterval:0.5]) {
    if (error) {
      *error = [NSError errorWithDomain:kGREYSystemAlertDismissalErrorDomain
                                   code:GREYSystemAlertNotDismissed
                               userInfo:nil];
      ;
    }
    return NO;
  }
  return YES;
}

/**
 *  @return The Springboard's XCUIApplication.
 */
- (XCUIApplication *)grey_springboardApplication {
  return [[XCUIApplication alloc] initPrivateWithPath:nil bundleID:@"com.apple.springboard"];
}

@end
