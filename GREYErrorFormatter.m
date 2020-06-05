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

#import "GREYErrorFormatter.h"

#import "GREYObjectFormatter.h"
#import "GREYInteraction.h"
#import "GREYErrorConstants.h"
#import "NSError+GREYCommon.h"
#import "GREYError+Private.h"

@interface GREYErrorFormatter ()

@property(readonly, nonatomic) GREYError *error;

@end

@implementation GREYErrorFormatter

#pragma mark - Init

- (instancetype)initWithError:(GREYError *)error {
  self = [super init];
  if (self) {
    _error = error;
  }
  return self;
}

#pragma mark - Public Methods

- (NSString *)formattedDescription {
  if (GREYShouldUseErrorFormatterForError(_error)) {
    return [self elementNotFoundDescription];
  }
  return [GREYObjectFormatter formatDictionary:[_error grey_descriptionDictionary]
                                        indent:kGREYObjectFormatIndent
                                     hideEmpty:YES
                                      keyOrder:nil];
}

#pragma mark - Private Methods

- (NSString *)elementNotFoundDescription {
  NSMutableArray<NSString *> *logger = [[NSMutableArray alloc] init];
  
  NSString *exceptionReason = _error.localizedDescription;
  [logger addObject:[NSString stringWithFormat:@"\n%@\n", exceptionReason]];
  
  NSString *recoverySuggestion = _error.userInfo[kErrorDetailRecoverySuggestionKey];
  if (recoverySuggestion) {
    [logger addObject:[NSString stringWithFormat:@"%@\n", recoverySuggestion]];
  }
  
  NSString *elementMatcher = _error.userInfo[kErrorDetailElementMatcherKey];
  if (elementMatcher) {
    [logger addObject:[NSString stringWithFormat:@"Element Matcher:\n%@\n", elementMatcher]];
  }
  
  NSString *searchActionInfo = _error.userInfo[kErrorDetailSearchActionInfoKey];
  if (searchActionInfo) {
    [logger addObject:[NSString stringWithFormat:@"Search Action Info\n%@\n", searchActionInfo]];
  }
  
  for (NSString *key in _error.appScreenshots.allKeys) {
    NSString *screenshotPath = _error.appScreenshots[key];
    [logger addObject:[NSString stringWithFormat:@"%@: %@\n", key, screenshotPath]];
  }
  
  NSString *nestedError = _error.nestedError.description;
  if (nestedError) {
    [logger addObject:[NSString stringWithFormat:@"Underlying Error: \n%@\n", nestedError]];
  }
  
  NSString *UIHierarchy = GREYFormattedHierarchy(_error.appUIHierarchy);
  if (UIHierarchy) {
    [logger addObject:UIHierarchy];
  }
  
  NSArray<NSString *> *stackTrace = _error.stackTrace;
  if (stackTrace) {
    [logger addObject:[NSString stringWithFormat:@"Stack Trace: %@\n", stackTrace]];
  }
  
  return [logger componentsJoinedByString:@"\n"];
}

#pragma mark - Static Functions

NSString *GREYFormattedHierarchy(NSString * hierarchy) {
  if (!hierarchy) {
    return nil;
  }
  NSMutableArray<NSString*> *logger = [[NSMutableArray alloc] init];
  
  [logger addObject:@"UI Hierarchy (ordered by window level, back to front):\n"];
  
  NSString *windowLegend = @"[Window 1]";
  NSString *axLegend = @"[AX]";
  NSString *uieLegend = @"[UIE]";
  
  NSDictionary<NSString *, NSString *> *legendLabels = @{
    windowLegend : @"Back-Most Window",
    axLegend : @"Accessibility",
    uieLegend : @"User Interaction Enabled"
  };
  NSArray<NSString *> *keyOrder = @[ windowLegend, axLegend, uieLegend ];
  
  NSString *legendDescription = [GREYObjectFormatter formatDictionary:legendLabels
                                                               indent:kGREYObjectFormatIndent
                                                            hideEmpty:NO
                                                             keyOrder:keyOrder];
  [logger addObject:[NSString stringWithFormat:@"%@: %@\n", @"Legend", legendDescription]];
  [logger addObject:hierarchy];
  return [logger componentsJoinedByString:@"\n"];
}

BOOL GREYShouldUseErrorFormatterForError(GREYError *error) {
  return [error.domain isEqualToString:kGREYInteractionErrorDomain] &&
  error.code == kGREYInteractionElementNotFoundErrorCode;
}

@end
