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

#import "GREYErrorConstants.h"
#import "GREYError.h"

NSString *const kErrorDetailStepperKey = @"Stepper";
NSString *const kErrorDetailUserValueKey = @"UserValue";
NSString *const kErrorDetailStepMaxValueKey = @"Stepper Max Value";
NSString *const kErrorDetailStepMinValueKey = @"Stepper Min Value";

NSString *const kErrorDetailElementDescriptionKey = @"Element Description";
NSString *const kErrorDetailConstraintRequirementKey = @"Failed Constraint(s)";
NSString *const kErrorDetailConstraintDetailsKey = @"All Constraint(s)";

NSString *const kGREYWillPerformActionNotification = @"GREYWillPerformActionNotification";
NSString *const kGREYDidPerformActionNotification = @"GREYDidPerformActionNotification";
NSString *const kGREYWillPerformAssertionNotification = @"GREYWillPerformAssertionNotification";
NSString *const kGREYDidPerformAssertionNotification = @"GREYDidPerformAssertionNotification";
NSString *const kGREYWillPerformSynchronizationNotification =
    @"GREYWillPerformSynchronizationNotification";
NSString *const kGREYDidPerformSynchronizationNotification =
    @"GREYDidPerformSynchronizationNotification";

NSString *const kGREYInteractionErrorDomain = @"com.google.earlgrey.ElementInteractionErrorDomain";
NSString *const kGREYPinchErrorDomain = @"com.google.earlgrey.PinchErrorDomain";
NSString *const kGREYSyntheticEventInjectionErrorDomain =
    @"com.google.earlgrey.SyntheticEventInjectionErrorDomain";
NSString *const kGREYUIThreadExecutorErrorDomain =
    @"com.google.earlgrey.GREYUIThreadExecutorErrorDomain";
NSString *const kGREYTwistErrorDomain = @"com.google.earlgrey.TwistErrorDomain";

NSString *const kGREYKeyboardDismissalErrorDomain = @"com.google.earlgrey.KeyboardDismissalDomain";

NSString *const kGREYDeeplinkErrorDomain = @"com.google.earlgrey.kGREYDeeplinkErrorDomain";

NSString *const kGREYIntializationErrorDomain = @"com.google.earlgrey.InitializationErrorDomain";

NSString *const kGREYScrollErrorDomain = @"com.google.earlgrey.ScrollErrorDomain";

NSString *const kGREYSystemAlertDismissalErrorDomain = @"com.google.earlgrey.SystemAlertDismissal";
NSString *const kGREYActivitySheetHandlingErrorDomain =
    @"com.google.earlgrey.ActivitySheetHandling";

NSString *const kGREYActionUserInfoKey = @"kGREYActionUserInfoKey";
NSString *const kGREYActionElementUserInfoKey = @"kGREYActionElementUserInfoKey";
NSString *const kGREYActionErrorUserInfoKey = @"kGREYActionErrorUserInfoKey";
NSString *const kGREYAssertionUserInfoKey = @"kGREYAssertionUserInfoKey";
NSString *const kGREYAssertionElementUserInfoKey = @"kGREYAssertionElementUserInfoKey";
NSString *const kGREYAssertionErrorUserInfoKey = @"kGREYAssertionErrorUserInfoKey";

NSString *const kErrorDetailForegroundApplicationFailed =
    @"kErrorDetailForegroundApplicationFailed";

NSString *const kErrorDetailAppUIHierarchyHeaderKey = @"UI Hierarchy (Back to front):\n";
NSString *const kErrorDetailElementMatcherKey = @"Element Matcher";
NSString *const kErrorDetailAppUIHierarchyKey = @"App UI Hierarchy";
NSString *const kErrorDetailAppScreenshotsKey = @"App Screenshots";

NSString *const kErrorDetailElementKey = @"Element";
NSString *const kErrorDetailWindowKey = @"Window";

NSArray<NSString *> *GREYErrorDetailsKeyOrder(void) {
  return @[
    kErrorDetailAssertCriteriaKey,
    kErrorDetailActionNameKey,
    kErrorFailureReasonKey,
    kErrorDetailElementMatcherKey,
    kErrorDetailRecoverySuggestionKey,
  ];
}
