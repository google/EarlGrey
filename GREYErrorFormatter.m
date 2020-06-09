//
// Copyright 2020 Google Inc.
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

#pragma mark - String Constants

static NSString *const kUnderlyingErrorKey                       = @"Underlying Error";
static NSString *const kHierarchyWindowLegendKey                 = @"[Window 1]";
static NSString *const kHierarchyAcessibilityLegendKey           = @"[AX]";
static NSString *const kHierarchyUserInteractionEnabledLegendKey = @"[UIE]";
static NSString *const kHierarchyBackWindowKey                   = @"Back-Most Window";
static NSString *const kHierarchyAccessibilityKey                = @"Accessibility";
static NSString *const kHierarchyUserInteractionEnabledKey       = @"User Interaction Enabled";
static NSString *const kHierarchyLegendKey                       = @"Legend";
static NSString *const kHierarchyHeaderKey                       = @"UI Hierarchy (ordered by wind"
                                                                   @"ow level, back to front):\n";

#pragma mark - Private Variables

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
    [logger addObject:[NSString stringWithFormat:@"%@:\n%@\n", kErrorDetailElementMatcherKey,
                       elementMatcher]];
  }
  
  NSString *searchActionInfo = _error.userInfo[kErrorDetailSearchActionInfoKey];
  if (searchActionInfo) {
    [logger addObject:[NSString stringWithFormat:@"%@\n%@\n", kErrorDetailSearchActionInfoKey,
                       searchActionInfo]];
  }
  
  for (NSString *key in _error.appScreenshots.allKeys) {
    NSString *screenshotPath = _error.appScreenshots[key];
    [logger addObject:[NSString stringWithFormat:@"%@: %@\n", key, screenshotPath]];
  }
  
  NSString *nestedError = _error.nestedError.description;
  if (nestedError) {
    [logger addObject:[NSString stringWithFormat:@"%@: \n%@\n", kUnderlyingErrorKey, nestedError]];
  }
  
  NSString *UIHierarchy = GREYFormattedHierarchy(_error.appUIHierarchy);
  if (UIHierarchy) {
    [logger addObject:UIHierarchy];
  }
  
  NSArray<NSString *> *stackTrace = _error.stackTrace;
  if (stackTrace) {
    [logger addObject:[NSString stringWithFormat:@"%@: %@\n", kErrorStackTraceKey, stackTrace]];
  }
  
  return [logger componentsJoinedByString:@"\n"];
}

#pragma mark - Static Functions

NSString *GREYFormattedHierarchy(NSString * hierarchy) {
  if (!hierarchy) {
    return nil;
  }
  NSMutableArray<NSString*> *logger = [[NSMutableArray alloc] init];
  [logger addObject:kHierarchyHeaderKey];
  NSString *windowLegend = kHierarchyWindow1Key;
  NSString *axLegend = kHierarchyAcessibilityShortKey;
  NSString *uieLegend = kHierarchyUserInteractionEnabledShortKey;
  NSDictionary<NSString *, NSString *> *legendLabels = @{
    windowLegend : kHierarchyBackWindowKey,
    axLegend : kHierarchyAccessibilityKey,
    uieLegend : kHierarchyUserInteractionEnabledKey
  };
  NSArray<NSString *> *keyOrder = @[ windowLegend, axLegend, uieLegend ];
  NSString *legendDescription = [GREYObjectFormatter formatDictionary:legendLabels
                                                               indent:kGREYObjectFormatIndent
                                                            hideEmpty:NO
                                                             keyOrder:keyOrder];
  [logger addObject:[NSString stringWithFormat:@"%@: %@\n", kHierarchyLegendKey,
                     legendDescription]];
  [logger addObject:hierarchy];
  return [logger componentsJoinedByString:@"\n"];
}

BOOL GREYShouldUseErrorFormatterForError(GREYError *error) {
  return [error.domain isEqualToString:kGREYInteractionErrorDomain] &&
          error.code == kGREYInteractionElementNotFoundErrorCode;
}

@end
