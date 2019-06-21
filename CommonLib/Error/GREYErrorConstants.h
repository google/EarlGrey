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

#import "GREYDefines.h"

/**
 *  Extern variables specifying the error keys for a base action.
 */
GREY_EXTERN NSString *const kErrorDetailElementDescriptionKey;
GREY_EXTERN NSString *const kErrorDetailConstraintRequirementKey;
GREY_EXTERN NSString *const kErrorDetailConstraintDetailsKey;

/**
 *  Extern variables specifying the error domain for GREYElementInteraction.
 */
GREY_EXTERN NSString *const kGREYInteractionErrorDomain;
GREY_EXTERN NSString *const kGREYWillPerformActionNotification;
GREY_EXTERN NSString *const kGREYDidPerformActionNotification;
GREY_EXTERN NSString *const kGREYWillPerformAssertionNotification;
GREY_EXTERN NSString *const kGREYDidPerformAssertionNotification;

/**
 *  Error domain for synthetic event injection failures.
 */
GREY_EXTERN NSString *const kGREYSyntheticEventInjectionErrorDomain;

/**
 * Extern variables specifying the error domain for Keyboard interactions
 */
GREY_EXTERN NSString *const kGREYKeyboardDismissalErrorDomain;

/**
 * Extern variables specifying the error domain for deeplink interactions
 */
GREY_EXTERN NSString *const kGREYDeeplinkErrorDomain;

/**
 *  Error code for deeplink open actions.
 */
typedef NS_ENUM(NSInteger, GREYDeeplinkTestErrorCode) {
  /**
   *  The deeplink is not supported.
   */
  GREYDeeplinkNotSupported = 1,
};

/**
 *  Extern variables specifying the user info keys for any notifications.
 */
GREY_EXTERN NSString *const kGREYActionUserInfoKey;
GREY_EXTERN NSString *const kGREYActionElementUserInfoKey;
GREY_EXTERN NSString *const kGREYActionErrorUserInfoKey;
GREY_EXTERN NSString *const kGREYAssertionUserInfoKey;
GREY_EXTERN NSString *const kGREYAssertionElementUserInfoKey;
GREY_EXTERN NSString *const kGREYAssertionErrorUserInfoKey;

/**
 *  Internal variables specifying the detail keys for error details.
 */
GREY_EXTERN NSString *const kErrorDetailElementMatcherKey;

/**
 *  Internal variables specifying the detail keys for the app UI hierarchy.
 */
GREY_EXTERN NSString *const kErrorDetailAppUIHierarchyKey;

/**
 *  Internal variables specifying the detail keys for the app screenshots.
 */
GREY_EXTERN NSString *const kErrorDetailAppScreenshotsKey;

/**
 *  The error domain for pinch action related errors.
 */
GREY_EXTERN NSString *const kGREYPinchErrorDomain;

/**
 *  Extern variables specifying the user info keys for a pinch action.
 */
GREY_EXTERN NSString *const kErrorDetailElementKey;
GREY_EXTERN NSString *const kErrorDetailWindowKey;

/**
 *  Extern variables specifying the error keys for a change stepper action.
 */
GREY_EXTERN NSString *const kErrorDetailStepperKey;
GREY_EXTERN NSString *const kErrorDetailUserValueKey;
GREY_EXTERN NSString *const kErrorDetailStepMaxValueKey;
GREY_EXTERN NSString *const kErrorDetailStepMinValueKey;

/**
 *  Extern variables specifying the error keys for XCUITest actions.
 */
GREY_EXTERN NSString *const kErrorDetailForegroundApplicationFailed;

/**
 *  Error code for keyboard dismissal actions.
 */
typedef NS_ENUM(NSInteger, GREYKeyboardDismissalErrorCode) {
  /**
   *  The keyboard dismissal failed.
   */
  GREYKeyboardDismissalFailedErrorCode = 1,
};
