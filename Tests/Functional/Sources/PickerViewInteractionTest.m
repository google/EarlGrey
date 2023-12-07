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
#import "BaseIntegrationTest.h"

@interface PickerViewInteractionTest : BaseIntegrationTest
@end

@implementation PickerViewInteractionTest

- (void)setUp {
  [super setUp];
  [self openTestViewNamed:@"Picker Views"];
}

- (void)testInteractionIsImpossibleIfInteractionDisabled {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Disabled")] performAction:GREYTap()];

  NSError *error;

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"InteractionDisabledPickerId")]
      performAction:GREYSetPickerColumnToValue(0, @"Green")
              error:&error];

  GREYAssertTrue([error.domain isEqual:kGREYInteractionErrorDomain], @"Error domain should match");
  GREYAssertTrue(error.code == kGREYInteractionConstraintsFailedErrorCode,
                 @"Error code should match");

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"InteractionDisabledPickerId")]
      assertWithMatcher:GREYPickerColumnSetToValue(0, @"Red")];
}

- (void)testDateOnlyPicker {
  NSString *dateString = @"1986/12/26";
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  dateFormatter.dateFormat = @"YYYY/MM/dd";
  NSDate *desiredDate = [dateFormatter dateFromString:dateString];

  [[EarlGrey selectElementWithMatcher:GREYText(@"Date")] performAction:GREYTap()];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"DatePickerId")]
      performAction:GREYSetDate(desiredDate)];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"DatePickerId")]
      assertWithMatcher:GREYDatePickerValue(desiredDate)];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"DateLabelId")]
      assertWithMatcher:GREYText(dateString)];
}

- (void)testDateUpdateCallbackIsNotInvokedIfDateDoesNotChange {
  NSString *dateString = @"1986/12/26";
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  dateFormatter.dateFormat = @"YYYY/MM/dd";
  NSDate *desiredDate = [dateFormatter dateFromString:dateString];

  [[EarlGrey selectElementWithMatcher:GREYText(@"Date")] performAction:GREYTap()];

  // Changing the date must change the label.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"DatePickerId")]
      performAction:GREYSetDate(desiredDate)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"DatePickerId")]
      assertWithMatcher:GREYDatePickerValue(desiredDate)];

  // Clearing the label to revert the changes.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"ClearDateLabelButtonId")]
      performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"DateLabelId")]
      assertWithMatcher:GREYText(@"")];

  // Executing the change date action with the same value should not change the value, thus not
  // invoking the update callback.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"DatePickerId")]
      performAction:GREYSetDate(desiredDate)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"DateLabelId")]
      assertWithMatcher:GREYText(@"")];
}

- (void)testTimeOnlyPicker {
  NSString *timeString = @"19:30:00";
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  dateFormatter.dateFormat = @"HH:mm:ss";
  NSDate *desiredTime = [dateFormatter dateFromString:timeString];

  [[EarlGrey selectElementWithMatcher:GREYText(@"Time")] performAction:GREYTap()];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"DatePickerId")]
      performAction:GREYSetDate(desiredTime)];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"DatePickerId")]
      assertWithMatcher:GREYDatePickerValue(desiredTime)];
}

- (void)testDateTimePicker {
  NSString *dateTimeString = @"1986/12/26 19:30:00";
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  dateFormatter.dateFormat = @"YYYY/MM/dd HH:mm:ss";
  NSDate *desiredDateTime = [dateFormatter dateFromString:dateTimeString];

  [[EarlGrey selectElementWithMatcher:GREYText(@"DateTime")] performAction:GREYTap()];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"DatePickerId")]
      performAction:GREYSetDate(desiredDateTime)];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"DatePickerId")]
      assertWithMatcher:GREYDatePickerValue(desiredDateTime)];
}

- (void)testCountdownTimePicker {
  NSString *timerString = @"12:30:00";
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  dateFormatter.dateFormat = @"HH:mm:ss";
  NSDate *desiredTimer = [dateFormatter dateFromString:timerString];

  [[EarlGrey selectElementWithMatcher:GREYText(@"Counter")] performAction:GREYTap()];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"DatePickerId")]
      performAction:GREYSetDate(desiredTimer)];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"DatePickerId")]
      assertWithMatcher:GREYDatePickerValue(desiredTimer)];
}

- (void)testCustomPicker {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Custom")] performAction:GREYTap()];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"CustomPickerId")]
      performAction:GREYSetPickerColumnToValue(0, @"Blue")];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"CustomPickerId")]
      performAction:GREYSetPickerColumnToValue(1, @"5")];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"CustomPickerId")]
      assertWithMatcher:GREYPickerColumnSetToValue(0, @"Blue")];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"CustomPickerId")]
      assertWithMatcher:GREYPickerColumnSetToValue(1, @"5")];
}

- (void)testPickerViewDidSelectRowInComponentIsCalled {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Custom")] performAction:GREYTap()];

  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"CustomPickerId")]
      performAction:GREYSetPickerColumnToValue(0, @"Hidden")] assertWithMatcher:GREYNotVisible()];
}

- (void)testNoPickerViewComponentDelegateMethodsAreDefined {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Custom")] performAction:GREYTap()];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"noDelegateMethodDefinedSwitch")]
      performAction:GREYTurnSwitchOn(YES)];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"CustomPickerId")]
      assertWithMatcher:GREYPickerColumnSetToValue(0, nil)];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"CustomPickerId")]
      assertWithMatcher:GREYPickerColumnSetToValue(1, nil)];
}

- (void)testViewForRowDefined {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Custom")] performAction:GREYTap()];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"viewForRowDelegateSwitch")]
      performAction:GREYTurnSwitchOn(YES)];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"CustomPickerId")]
      performAction:GREYSetPickerColumnToValue(0, @"Green")];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"CustomPickerId")]
      performAction:GREYSetPickerColumnToValue(1, @"4")];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"CustomPickerId")]
      assertWithMatcher:GREYPickerColumnSetToValue(0, @"Green")];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"CustomPickerId")]
      assertWithMatcher:GREYPickerColumnSetToValue(1, @"4")];
}

- (void)testAttributedTitleForRowDefined {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Custom")] performAction:GREYTap()];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"attributedTitleForRowDelegateSwitch")]
      performAction:GREYTurnSwitchOn(YES)];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"CustomPickerId")]
      performAction:GREYSetPickerColumnToValue(0, @"Green")];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"CustomPickerId")]
      performAction:GREYSetPickerColumnToValue(1, @"4")];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"CustomPickerId")]
      assertWithMatcher:GREYPickerColumnSetToValue(0, @"Green")];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"CustomPickerId")]
      assertWithMatcher:GREYPickerColumnSetToValue(1, @"4")];
}

- (void)testTitleForRowDefined {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Custom")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"titleForRowDelegateSwitch")]
      performAction:GREYTurnSwitchOn(YES)];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"CustomPickerId")]
      performAction:GREYSetPickerColumnToValue(0, @"Green")];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"CustomPickerId")]
      performAction:GREYSetPickerColumnToValue(1, @"4")];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"CustomPickerId")]
      assertWithMatcher:GREYPickerColumnSetToValue(0, @"Green")];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"CustomPickerId")]
      assertWithMatcher:GREYPickerColumnSetToValue(1, @"4")];
}

@end
