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

#import "PickerViewController.h"

@interface PickerViewDelegate1 : NSObject <UIPickerViewDelegate>

@property(nonatomic, retain) NSArray *customColumn1Array;
@property(nonatomic, retain) NSArray *customColumn2Array;

@end

@interface PickerViewDelegate2 : NSObject <UIPickerViewDelegate>

@property(nonatomic, retain) NSArray *customColumn1Array;
@property(nonatomic, retain) NSArray *customColumn2Array;

@end

@interface PickerViewDelegate3 : NSObject <UIPickerViewDelegate>

@property(nonatomic, retain) NSArray *customColumn1Array;
@property(nonatomic, retain) NSArray *customColumn2Array;

@end

@interface PickerViewDelegate4 : NSObject <UIPickerViewDelegate>
@end

@implementation PickerViewDelegate1

- (instancetype)init {
  self = [super init];
  if (self) {
    self.customColumn1Array = @[ @"Red", @"Green", @"Blue", @"Hidden" ];
    self.customColumn2Array = @[ @"1", @"2", @"3", @"4", @"5" ];
  }
  return self;
}

- (UIView *)pickerView:(UIPickerView *)pickerView
            viewForRow:(NSInteger)row
          forComponent:(NSInteger)component
           reusingView:(UIView *)view {
  UILabel *columnView =
      [[UILabel alloc] initWithFrame:CGRectMake(35, 0, pickerView.frame.size.width / 2,
                                                pickerView.frame.size.height)];
  columnView.text = [self titleForRow:row forComponent:component];
  columnView.textAlignment = NSTextAlignmentCenter;

  return columnView;
}

- (NSString *)titleForRow:(NSInteger)row
             forComponent:(NSInteger)component {
  switch (component) {
    case 0:
      return self.customColumn1Array[(NSUInteger)row];
      break;
    case 1:
      return self.customColumn2Array[(NSUInteger)row];
      break;
  }
  return nil;
}

@end

@implementation PickerViewDelegate2

- (instancetype)init {
  self = [super init];
  if (self) {
    self.customColumn1Array = @[ @"Red", @"Green", @"Blue", @"Hidden" ];
    self.customColumn2Array = @[ @"1", @"2", @"3", @"4", @"5" ];
  }
  return self;
}

- (NSAttributedString *)pickerView:(UIPickerView *)pickerView
             attributedTitleForRow:(NSInteger)row
                      forComponent:(NSInteger)component {
  NSString *rowTitle = [self pickerView:pickerView titleForRow:row forComponent:component];
  return [[NSAttributedString alloc] initWithString:rowTitle];
}

- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component {
  switch (component) {
    case 0:
      return self.customColumn1Array[(NSUInteger)row];
      break;
    case 1:
      return self.customColumn2Array[(NSUInteger)row];
      break;
  }
  return nil;
}

@end

@implementation PickerViewDelegate3

- (instancetype)init {
  self = [super init];
  if (self) {
    self.customColumn1Array = @[ @"Red", @"Green", @"Blue", @"Hidden" ];
    self.customColumn2Array = @[ @"1", @"2", @"3", @"4", @"5" ];
  }
  return self;
}

- (NSAttributedString *)pickerView:(UIPickerView *)pickerView
             attributedTitleForRow:(NSInteger)row
                      forComponent:(NSInteger)component {
  return nil;
}

- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component {
  switch (component) {
    case 0:
      return self.customColumn1Array[(NSUInteger)row];
      break;
    case 1:
      return self.customColumn2Array[(NSUInteger)row];
      break;
  }
  return nil;
}

@end

@implementation PickerViewDelegate4

- (UIView *)pickerView:(UIPickerView *)pickerView
            viewForRow:(NSInteger)row
          forComponent:(NSInteger)component
           reusingView:(UIView *)view {
  return nil;
}

- (NSAttributedString *)pickerView:(UIPickerView *)pickerView
             attributedTitleForRow:(NSInteger)row
                      forComponent:(NSInteger)component {
  return nil;
}

- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component {
  return nil;
}

@end

@implementation PickerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    self.customColumn1Array = @[ @"Red", @"Green", @"Blue", @"Hidden" ];
    self.customColumn2Array = @[ @"1", @"2", @"3", @"4", @"5" ];
  }
  return self;
}

- (instancetype)init {
  NSAssert(NO, @"Invalid Initializer");
  return nil;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  [self.customPicker setHidden:YES];
  [self.datePicker setHidden:YES];
  [self.interactionDisabledPicker setHidden:YES];

  self.datePicker.accessibilityIdentifier = @"DatePickerId";
  self.customPicker.accessibilityIdentifier = @"CustomPickerId";
  self.interactionDisabledPicker.accessibilityIdentifier = @"InteractionDisabledPickerId";
  self.dateLabel.accessibilityIdentifier = @"DateLabelId";
  self.clearLabelButton.accessibilityIdentifier = @"ClearDateLabelButtonId";

  self.viewForRowDelegateSwitch.accessibilityIdentifier = @"viewForRowDelegateSwitch";
  self.attributedTitleForRowDelegateSwitch.accessibilityIdentifier =
      @"attributedTitleForRowDelegateSwitch";
  self.titleForRowDelegateSwitch.accessibilityIdentifier = @"titleForRowDelegateSwitch";
  self.noDelegateMethodDefinedSwitch.accessibilityIdentifier = @"noDelegateMethodDefinedSwitch";

  [self.datePicker addTarget:self
                      action:@selector(datePickerValueChanged:)
            forControlEvents:UIControlEventValueChanged];

  self.pickerViewDelegate1 = [PickerViewDelegate1 new];
  self.pickerViewDelegate2 = [PickerViewDelegate2 new];
  self.pickerViewDelegate3 = [PickerViewDelegate3 new];
  self.pickerViewDelegate4 = [PickerViewDelegate4 new];
}

- (void)datePickerValueChanged:(id)sender {
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  dateFormatter.dateFormat = @"YYYY/MM/dd";
  self.dateLabel.text = [dateFormatter stringFromDate:self.datePicker.date];
}

- (IBAction)clearDateLabelButtonTapped:(id)sender {
  self.dateLabel.text = @"";
}

- (IBAction)valueChanged:(id)sender {
  [self.datePicker setHidden:YES];
  [self.customPicker setHidden:YES];
  [self.interactionDisabledPicker setHidden:YES];
  NSInteger selectedSegment = self.datePickerSegmentedControl.selectedSegmentIndex;

  switch (selectedSegment) {
    case 0:
      self.datePicker.datePickerMode = UIDatePickerModeDate;
      [self.datePicker setHidden:NO];
      break;
    case 1:
      self.datePicker.datePickerMode = UIDatePickerModeTime;
      [self.datePicker setHidden:NO];
      break;
    case 2:
      self.datePicker.datePickerMode = UIDatePickerModeDateAndTime;
      [self.datePicker setHidden:NO];
      break;
    case 3:
      self.datePicker.datePickerMode = UIDatePickerModeCountDownTimer;
      [self.datePicker setHidden:NO];
      break;
    case 4:
      [self.customPicker setHidden:NO];
      break;
    case 5:
      [self.interactionDisabledPicker setHidden:NO];
  }
}

- (IBAction)viewForRowDelegateSwitchToggled:(id)sender {
  self.customPicker.delegate = self.pickerViewDelegate1;
  [self.customPicker reloadAllComponents];
}

- (IBAction)attributedTitleForRowDelegateSwitchToggled:(id)sender {
  self.customPicker.delegate = self.pickerViewDelegate2;
  [self.customPicker reloadAllComponents];
}

- (IBAction)titleForRowDelegateSwitchToggled:(id)sender {
  self.customPicker.delegate = self.pickerViewDelegate3;
  [self.customPicker reloadAllComponents];
}

- (IBAction)noDelegateMethodDefinedSwitchToggled:(id)sender {
  self.customPicker.delegate = self.pickerViewDelegate4;
  [self.customPicker reloadAllComponents];
}

#pragma mark - UIPickerViewDataSource Protocol

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
  return 2;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
  switch (component) {
    case 0:
      return (NSInteger)[self.customColumn1Array count];
      break;
    case 1:
      return (NSInteger)[self.customColumn2Array count];
      break;
    default:
      NSAssert(NO, @"Invalid Picker column.");
      break;
  }
  return 0;
}

#pragma mark - UIPickerViewDelegate Protocol

- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component {
  switch (component) {
    case 0:
      return self.customColumn1Array[(NSUInteger)row];
      break;
    case 1:
      return self.customColumn2Array[(NSUInteger)row];
      break;
    default:
      NSAssert(NO, @"Invalid Picker column object to obtain a title.");
      break;
  }
  return nil;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
  return 30;
}

- (UIView *)pickerView:(UIPickerView *)pickerView
            viewForRow:(NSInteger)row
          forComponent:(NSInteger)component
           reusingView:(UIView *)view {
  UILabel *columnView =
      [[UILabel alloc] initWithFrame:CGRectMake(35, 0, self.view.frame.size.width / 3 - 35, 30)];
  columnView.text = [self pickerView:pickerView titleForRow:row forComponent:component];
  columnView.textAlignment = NSTextAlignmentCenter;
  return columnView;
}

- (void)pickerView:(UIPickerView *)pickerView
      didSelectRow:(NSInteger)row
       inComponent:(NSInteger)component {
  // If Hidden is selected, hide picker.
  if (component == 0 && [self.customColumn1Array[(NSUInteger)row] isEqualToString:@"Hidden"]) {
    [self.customPicker setHidden:YES];
  }
}

@end
