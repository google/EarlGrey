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

#import "GREYPickerAction.h"

#import "UIView+GREYApp.h"
#import "GREYInteraction.h"
#import "GREYAppError.h"
#import "GREYFailureScreenshotter.h"
#import "GREYTimedIdlingResource.h"
#import "GREYAllOf.h"
#import "GREYMatchers.h"
#import "GREYSyncAPI.h"
#import "GREYError.h"
#import "NSError+GREYCommon.h"
#import "GREYDefines.h"
#import "GREYElementHierarchy.h"

@implementation GREYPickerAction {
  /**
   * The column being modified of the UIPickerView.
   */
  NSInteger _column;
  /**
   * The value to modify the column of the UIPickerView.
   */
  NSString *_value;
}

- (instancetype)initWithColumn:(NSInteger)column value:(NSString *)value {
  NSString *name =
      [NSString stringWithFormat:@"Set picker column %ld to value '%@'", (long)column, value];
  id<GREYMatcher> systemAlertNotShownMatcher = [GREYMatchers matcherForSystemAlertViewShown];
  NSArray *constraintMatchers = @[
    [GREYMatchers matcherForInteractable], [GREYMatchers matcherForUserInteractionEnabled],
    [GREYMatchers matcherForNegation:systemAlertNotShownMatcher],
#if TARGET_OS_IOS
    [GREYMatchers matcherForKindOfClass:[UIPickerView class]]
#endif
  ];
  self = [super initWithName:name
                 constraints:[[GREYAllOf alloc] initWithMatchers:constraintMatchers]];
  if (self) {
    _column = column;
    _value = value;
  }
  return self;
}

#pragma mark - GREYAction

#if TARGET_OS_IOS
- (BOOL)perform:(UIPickerView *)pickerView error:(__strong NSError **)error {
  __block BOOL retVal = NO;
  grey_dispatch_sync_on_main_thread(^{
    // We manipulate the picker view on the main thread.
    retVal = [self grey_perform:pickerView error:error];
  });
  return retVal;
}
#endif

#pragma mark - Private

#if TARGET_OS_IOS
- (BOOL)grey_perform:(UIPickerView *)pickerView error:(__strong NSError **)error {
  if (![self satisfiesConstraintsForElement:pickerView error:error]) {
    return NO;
  }

  id<UIPickerViewDataSource> dataSource = pickerView.dataSource;
  NSInteger componentCount = [dataSource numberOfComponentsInPickerView:pickerView];

  if (componentCount < _column) {
    NSMutableString *description =
        [NSMutableString stringWithFormat:@"Failed to find Picker Column."];
    [description appendFormat:@"\n\nColumn: %lu", (unsigned long)_column];
    [description appendFormat:@"\n\nPicker: %@\n", [pickerView description]];
    I_GREYPopulateError(error, kGREYInteractionErrorDomain, kGREYInteractionActionFailedErrorCode,
                        description);
    return NO;
  }

  NSInteger columnRowCount = [dataSource pickerView:pickerView numberOfRowsInComponent:_column];

  SEL titleForRowSelector = @selector(pickerView:titleForRow:forComponent:);
  SEL attributedTitleForRowSelector = @selector(pickerView:attributedTitleForRow:forComponent:);
  SEL viewForRowSelector = @selector(pickerView:viewForRow:forComponent:reusingView:);

  for (NSInteger rowIndex = 0; rowIndex < columnRowCount; rowIndex++) {
    NSString *rowTitle;
    id<UIPickerViewDelegate> delegate = pickerView.delegate;
    if ([delegate respondsToSelector:titleForRowSelector]) {
      rowTitle = [delegate pickerView:pickerView titleForRow:rowIndex forComponent:_column];
    } else if ([delegate respondsToSelector:attributedTitleForRowSelector]) {
      NSAttributedString *attributedTitle = [delegate pickerView:pickerView
                                           attributedTitleForRow:rowIndex
                                                    forComponent:_column];
      rowTitle = attributedTitle.string;
    } else if ([delegate respondsToSelector:viewForRowSelector]) {
      UIView *rowView = [delegate pickerView:pickerView
                                  viewForRow:rowIndex
                                forComponent:_column
                                 reusingView:nil];
      if (![rowView isKindOfClass:[UILabel class]]) {
        NSArray *labels = [rowView grey_childrenAssignableFromClass:[UILabel class]];
        UILabel *label = (labels.count > 0 ? labels[0] : nil);
        rowTitle = label.text;
      } else {
        rowTitle = [((UILabel *)rowView) text];
      }
    }
    if ([rowTitle isEqualToString:_value]) {
      [pickerView selectRow:rowIndex inComponent:_column animated:YES];
      if ([delegate respondsToSelector:@selector(pickerView:didSelectRow:inComponent:)]) {
        [delegate pickerView:pickerView didSelectRow:rowIndex inComponent:_column];
      }
      // UIPickerView does a delayed animation. We don't track delayed animations, therefore we have
      // to track it manually
      [GREYTimedIdlingResource resourceForObject:pickerView
                           thatIsBusyForDuration:0.5
                                            name:@"UIPickerView"];
      return YES;
    }
  }
  I_GREYPopulateError(error, kGREYInteractionErrorDomain, kGREYInteractionActionFailedErrorCode,
                      @"UIPickerView does not contain desired value!");
  return NO;
}
#endif

#pragma mark - GREYDiagnosable

- (NSString *)diagnosticsID {
  return GREYCorePrefixedDiagnosticsID(@"picker");
}

@end
