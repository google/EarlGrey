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

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

#import "GREYConstants.h"

/**
 *  Error code for system alert dismissal actions.
 */
typedef NS_ENUM(NSUInteger, GREYSystemAlertDismissalErrorCode) {
  /**
   *  System alert accept button not found.
   */
  GREYSystemAlertAcceptButtonNotFound,
  /**
   *  System alert denial button not found.
   */
  GREYSystemAlertDenialButtonNotFound,
  /**
   *  System alert custom button Not found.
   */
  GREYSystemAlertCustomButtonNotFound,
  /**
   *  System alert text was not correctly typed.
   */
  GREYSystemAlertTextNotTypedCorrectly,
  /**
   *  System alert was not visible.
   */
  GREYSystemAlertNotPresent,
  /**
   *  System alert was not dismissed.
   */
  GREYSystemAlertNotDismissed,
};

/**
 *  Enum for specifying the type of System Alert Present
 */
typedef NS_ENUM(NSUInteger, GREYSystemAlertType) {
  /**
   *  System Alert Type for accessing the location - a two button dialog without
   *  an "Always Allow" button.
   */
  GREYSystemAlertTypeLocation,
  /**
   *  System Alert Type for accessing the location whenever the app is in use (Background Location)
   *  - a three button dialog, with an "Always Allow" button.
   */
  GREYSystemAlertTypeBackgroundLocation,
  /**
   *  System Alert Type for Calendar.
   */
  GREYSystemAlertTypeCalendar,
  /**
   *  System Alert Type for Camera.
   */
  GREYSystemAlertTypeCamera,
  /**
   *  System Alert Type for Photos.
   */
  GREYSystemAlertTypePhotos,
  /**
   *  System Alert Type for Microphone.
   */
  GREYSystemAlertTypeMicrophone,
  /**
   *  System Alert Type for Reminders.
   */
  GREYSystemAlertTypeReminder,
  /**
   *  System Alert Type for Notifications (APNS).
   */
  GREYSystemAlertTypeNotifications,
  /**
   *  System Alert Type for Contacts.
   */
  GREYSystemAlertTypeContacts,
  /**
   *  System Alert Type for Motion Activity.
   */
  GREYSystemAlertTypeMotionActivity,
  /**
   *  Unknown System Alert Type.
   */
  GREYSystemAlertTypeUnknown,
};

/**
 *  Error dismissal domain for the system alert dismissal actions.
 */
GREY_EXTERN NSString *const kGREYSystemAlertDismissalErrorDomain;

/**
 *  Timeout for a system alert to be present.
 */
GREY_EXTERN CFTimeInterval const kSystemAlertVisibilityTimeout;

@interface XCTestCase (GREYSystemAlertHandler)

/**
 *  @return An NSString denoting the text contained within the System Alert.
 *
 *  @param[out] error Error that will be populated on failure if no System Alert shows up. The
 *                    return value will be @c NULL on error regardless if the error is passed in.
 */
- (NSString *)grey_systemAlertTextWithError:(NSError **)error;

/**
 *  @return The GREYSystemAlertType of the alert being displayed. Will wait for any springboard
 *          animations to completed before the alert is displayed.
 *
 *  @throws NSInternalInconsistencyException if the alert doesn't appear.
 */
- (GREYSystemAlertType)grey_systemAlertType;

/**
 *  Similar to the default interruption handler provided by XCUITest. Will automatically accept
 *  any System Alert that is brought up in the provided @c application by allowing it before
 *  proceeding to the next statement.
 *
 *  @param[out] error Error that will be populated on failure. If @c NULL, the test
 *                    failure will be reported.
 *
 *  @return @c YES if the alert is dismissed correctly, @c NO otherwise.
 *
 *  @throws GREYFrameworkException if the alert dismissal fails and @c error is @c NULL.
 */
- (BOOL)grey_acceptSystemDialogWithError:(NSError **)error NS_SWIFT_NOTHROW;

/**
 *  Denies all System Alerts by clicking on the button with <b>"Don't Allow"</b> as its label.
 *  In case the denial button is something else, please use the
 *  @c GREYSystemAlertHandler:grey_tapSystemDialogButtonWithText:withButtonsPressedOrder:error
 *  method.
 *
 *  @param[out] error Error that will be populated on failure. If @c NULL, the test
 *                    failure will be reported.
 *
 *  @return @c YES if the alert is dismissed correctly, @c NO otherwise.
 */
- (BOOL)grey_denySystemDialogWithError:(NSError **)error NS_SWIFT_NOTHROW;

/**
 *  Taps on a System Alert Button based on the button's text.
 *
 *  @param text       The text contained in the title of the system alert button to be tapped on.
 *  @param[out] error Error that will be populated on failure. If @c NULL, the test
 *                    failure will be reported.
 *
 *  @return @c YES if the alert is dismissed correctly, @c NO otherwise.
 *
 *  @throws NSInternalInconsistencyException if the alert being dismissed is a background location
 *          alert after a location alert has already been handled.
 */
- (BOOL)grey_tapSystemDialogButtonWithText:(NSString *)text
                                     error:(NSError **)error NS_SWIFT_NOTHROW;

/**
 *  Types in a textfield in a System Alert.
 *
 *  @param textToType      The text to be typed in the textfield.
 *  @param placeholderText The text displayed in the textfield to be typed in.
 *  @param[out] error      Error that will be populated on failure. If @c NULL, the test
 *                         failure will be reported.
 *
 *  @return @c YES if the alert is dismissed correctly, @c NO otherwise.
 */
- (BOOL)grey_typeSystemAlertText:(NSString *)textToType
              forPlaceholderText:(NSString *)placeholderText
                           error:(NSError **)error NS_SWIFT_NOTHROW;

/**
 *  @return Waits until an alert is visible or not based on the passed in boolean value, or until
 *          a specified period has passed.
 *
 *  @param visible Boolean specifying whether the API should check if an alert is visible or not.
 *  @param seconds CFTimeInterval specifying the longest period in seconds to wait for. Please
 *                 use "kSystemAlertVisibilityTimeout" for its default value, and only use a custom
 *                 value shorter than "kSystemAlertVisibilityTimeout" when system alerts are very
 *                 unlikely to appear in your tests.
 */
- (BOOL)grey_waitForAlertVisibility:(BOOL)visible withTimeout:(CFTimeInterval)seconds;

@end
