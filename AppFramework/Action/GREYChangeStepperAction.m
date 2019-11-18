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

#import "GREYChangeStepperAction.h"

#import "GREYBaseAction.h"
#import "GREYTapper.h"
#import "NSObject+GREYApp.h"
#import "GREYElementFinder.h"
#import "GREYInteraction.h"
#import "GREYAppError.h"
#import "GREYAllOf.h"
#import "GREYMatchers.h"
#import "GREYSyncAPI.h"
#import "GREYErrorConstants.h"
#import "GREYObjectFormatter.h"
#import "NSError+GREYCommon.h"
#import "GREYConstants.h"
#import "GREYDefines.h"
#import "GREYElementProvider.h"

/**
 *  Helper Class containing the increment and decrement buttons on the stepper.
 */
@interface GREYStepperButtons : NSObject
/**
 *  A UIButton signifying the increment button on a UIStepper.
 */
@property(nonatomic, nonnull) UIButton *plusButton;
/**
 *  A UIButton signifying the decrement button on a UIStepper.
 */
@property(nonatomic, nonnull) UIButton *minusButton;
@end

@implementation GREYStepperButtons
/**
 *  Custom initializer for the class.
 *
 *  @param plusButton  A UIButton signifying the increment button on the stepper.
 *  @param minusButton A UIButton signifying the decrement button on the stepper.
 *
 *  @return A GREYStepperButtons object with the increment and decrement buttons set.
 *
 */
- (instancetype)initWithPlusButton:(UIButton *)plusButton minusButton:(UIButton *)minusButton {
  self = [super init];
  if (self) {
    _plusButton = plusButton;
    _minusButton = minusButton;
  }
  return self;
}
@end

@implementation GREYChangeStepperAction {
  /**
   *  The value by which the stepper should change.
   */
  double _value;
  /**
   *  Identifier used for diagnostics.
   */
  NSString *_diagnosticsID;
}

- (instancetype)initWithValue:(double)value {
  id<GREYMatcher> systemAlertShownMatcher = [GREYMatchers matcherForSystemAlertViewShown];
  NSArray *constraintMatchers = @[
    [GREYMatchers matcherForInteractable],
    [GREYMatchers matcherForNegation:systemAlertShownMatcher],
    [GREYMatchers matcherForKindOfClass:[UIStepper class]]
  ];
  NSString *name = [NSString stringWithFormat:@"Change stepper to %g", value];
  self = [super initWithName:name
                 constraints:[[GREYAllOf alloc] initWithMatchers:constraintMatchers]];
  if (self) {
    _diagnosticsID = name;
    _value = value;
  }
  return self;
}

#pragma mark - GREYAction

- (BOOL)perform:(UIStepper *)stepper error:(__strong NSError **)error {
  __block BOOL satisfiesContraints = NO;
  grey_dispatch_sync_on_main_thread(^{
    satisfiesContraints = [self satisfiesConstraintsForElement:stepper error:error];
  });
  if (!satisfiesContraints) {
    return NO;
  }
  // Check if the value to update the stepper to is valid or not.
  __block BOOL isStepperValueInvalid = NO;
  grey_dispatch_sync_on_main_thread(^{
    isStepperValueInvalid =
        (self->_value > stepper.maximumValue || self->_value < stepper.minimumValue);
  });
  if (isStepperValueInvalid) {
    // Throw an error for an invalid stepper value.
    return [self grey_getError:error forStepper:stepper];
  }
  // Calculate how to update the stepper based on its current value and tap on the required stepper
  // button.
  [self grey_setValue:_value forStepper:stepper error:error];
  return YES;
}

#pragma mark - Private

/**
 *  Calculates the stepper's current value and updates it to the value it is to be changed to.
 *  @param      stepper The UIStepper to be queried.
 *  @param[out] error   Error that will be populated on failure.
 *
 *  @return @c YES if the @c stepper was updated correctly.
 */
- (BOOL)grey_setValue:(double)value
           forStepper:(UIStepper *)stepper
                error:(__strong NSError **)error {
  GREYStepperButtons *buttons = [self grey_stepperButtonsForStepper:stepper error:error];
  if (!buttons) {
    return NO;
  }
  UIButton *minusButton = buttons.minusButton;
  UIButton *plusButton = buttons.plusButton;
  double currentValue = [self grey_stepperValue:stepper];
  double stepperStepValue = [self grey_stepperStepValue:stepper];
  while (currentValue != value) {
    UIButton *buttonToPress = (currentValue < value) ? plusButton : minusButton;
    if (![GREYTapper tapOnElement:buttonToPress
                     numberOfTaps:1
                         location:[buttonToPress grey_accessibilityActivationPointRelativeToFrame]
                            error:error]) {
      return NO;
    }
    double changedValue = [self grey_stepperValue:stepper];
    BOOL stepperValueChangedCorrectly = NO;
    if ((currentValue < value)) {
      stepperValueChangedCorrectly = (changedValue == currentValue + stepperStepValue);
    } else {
      stepperValueChangedCorrectly = (changedValue == currentValue - stepperStepValue);
    }
    if (!stepperValueChangedCorrectly) {
      NSString *description = [NSString stringWithFormat:
                                            @"Failed to exactly step to %lf "
                                            @"from current value %lf and step %lf.",
                                            value, changedValue, stepperStepValue];
      I_GREYPopulateError(error, kGREYInteractionErrorDomain, kGREYInteractionActionFailedErrorCode,
                          description);
      return NO;
    }
    currentValue = changedValue;
  }
  return YES;
}

/**
 *  Checks the current UIStepper's value and the value required to find out the correct increment /
 *  decrement buttons on the UIStepper.
 *
 *  @param      stepper The UIStepper to be queried.
 *  @param[out] error   Error that will be populated on failure.
 *
 *  @return A GREYStepperButtons object with both the plusButton and minusButton property set,
 *          @c nil if there is any error.
 */
- (GREYStepperButtons *)grey_stepperButtonsForStepper:(UIStepper *)stepper
                                                error:(__strong NSError **)error {
  __block UIButton *foundPlusButton;
  __block UIButton *foundMinusButton;
  grey_dispatch_sync_on_main_thread(^{
    GREYElementProvider *stepperProvider =
        [GREYElementProvider providerWithRootElements:@[ stepper ]];
    GREYElementFinder *buttonFinder = [[GREYElementFinder alloc]
        initWithMatcher:[GREYMatchers matcherForAccessibilityLabel:@"Increment"]];
    foundPlusButton = [buttonFinder elementsMatchedInProvider:stepperProvider].firstObject;
    buttonFinder = [[GREYElementFinder alloc]
        initWithMatcher:[GREYMatchers matcherForAccessibilityLabel:@"Decrement"]];
    foundMinusButton = [buttonFinder elementsMatchedInProvider:stepperProvider].firstObject;
  });

  if (!(foundMinusButton && foundPlusButton)) {
    NSString *description = [NSString stringWithFormat:@"Failed to find stepper buttons "
                                                       @"in [Stepper]"];
    NSDictionary<NSString *, NSString *> *glossary = @{@"[Stepper]" : [stepper description]};

    I_GREYPopulateErrorNoted(error, kGREYInteractionErrorDomain,
                             kGREYInteractionActionFailedErrorCode, description, glossary);
    return nil;
  }
  return
      [[GREYStepperButtons alloc] initWithPlusButton:foundPlusButton minusButton:foundMinusButton];
}

/**
 *  Sets the provided error value or logs it if no error provided for setting the value for the
 *  provided @c stepper.
 *
 *  @param[out] error Error that will be populated on failure.
 *  @param      stepper    A UIStepper to be queried.
 *
 *  @return @c NO indicating that an error has been set.
 */
- (BOOL)grey_getError:(__strong NSError **)error forStepper:(UIStepper *)stepper {
  NSMutableDictionary *errorDetails = [[NSMutableDictionary alloc] init];

  errorDetails[kErrorDetailActionNameKey] = self.name;
  errorDetails[kErrorDetailStepperKey] = [stepper description];
  errorDetails[kErrorDetailUserValueKey] = [NSString stringWithFormat:@"%lf", _value];
  errorDetails[kErrorDetailStepMaxValueKey] =
      [NSString stringWithFormat:@"%lf", stepper.maximumValue];
  errorDetails[kErrorDetailStepMinValueKey] =
      [NSString stringWithFormat:@"%lf", stepper.minimumValue];
  errorDetails[kErrorDetailRecoverySuggestionKey] =
      @"Make sure the value for stepper lies "
      @"in appropriate range";

  NSArray *keyOrder = @[
    kErrorDetailActionNameKey, kErrorDetailStepperKey, kErrorDetailUserValueKey,
    kErrorDetailStepMaxValueKey, kErrorDetailStepMinValueKey, kErrorDetailRecoverySuggestionKey
  ];

  NSString *reasonDetail = [GREYObjectFormatter formatDictionary:errorDetails
                                                          indent:kGREYObjectFormatIndent
                                                       hideEmpty:YES
                                                        keyOrder:keyOrder];
  NSString *reason = [NSString stringWithFormat:
                                   @"Cannot set stepper value due to "
                                   @"invalid user input.\n"
                                   @"Exception with Action: %@\n",
                                   reasonDetail];
  I_GREYPopulateError(error, kGREYInteractionErrorDomain, kGREYInteractionActionFailedErrorCode,
                      reason);
  return NO;
}

/**
 *  Gets the value of the provided stepper.
 *
 *  @param stepper A UIStepper to be queried.
 *
 *  @return A double specifying the value of the stepper.
 */
- (double)grey_stepperValue:(UIStepper *)stepper {
  __block double stepperValue;
  grey_dispatch_sync_on_main_thread(^{
    stepperValue = stepper.value;
  });
  return stepperValue;
}

/**
 *  Gets the stepValue of the provided stepper.
 *
 *  @param stepper A UIStepper to be queried.
 *
 *  @return A double specifying the stepValue of the stepper.
 */
- (double)grey_stepperStepValue:(UIStepper *)stepper {
  __block double stepperStepValue;
  grey_dispatch_sync_on_main_thread(^{
    stepperStepValue = stepper.stepValue;
  });
  return stepperStepValue;
}

#pragma mark - GREYDiagnosable

- (NSString *)diagnosticsID {
  return _diagnosticsID;
}

@end
