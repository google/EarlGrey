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

#pragma mark - Class Methods

+ (NSString *)formattedHierarchy:(nonnull NSString *)hierarchy {
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
  if ([_error.domain isEqualToString:kGREYInteractionErrorDomain] &&
      _error.code == kGREYInteractionElementNotFoundErrorCode) {
    return [self elementNotFoundDescription];
  }
  
  // The error code is not yet supported by GREYErrorFormatter
  return [GREYObjectFormatter formatDictionary:[_error grey_descriptionDictionary]
                                        indent:kGREYObjectFormatIndent
                                     hideEmpty:YES
                                      keyOrder:nil];
}

+ (NSArray *)grey_nestedErrorDictionariesForError:(NSError *)error {
  if (!error) {
    return nil;
  }

  NSMutableArray *errorStack = [[NSMutableArray alloc] init];
  NSError *underlyingError = error.userInfo[NSUnderlyingErrorKey];
  if (underlyingError) {
    NSArray *errorDescriptions = [GREYErrorFormatter grey_nestedErrorDictionariesForError:underlyingError];
    [errorStack addObjectsFromArray:errorDescriptions];
  }

  NSDictionary *descriptions = [error grey_descriptionDictionary];
  // For GREYError, we need to remove some of the fields.
  if ([error isKindOfClass:[GREYError class]]) {
    NSMutableDictionary *mutableDescriptions = [descriptions mutableCopy];
    [mutableDescriptions removeObjectForKey:kErrorUserInfoKey];
    [mutableDescriptions removeObjectForKey:kErrorErrorInfoKey];
    [mutableDescriptions removeObjectForKey:kErrorStackTraceKey];
    [mutableDescriptions removeObjectForKey:kErrorAppUIHierarchyKey];
    [mutableDescriptions removeObjectForKey:kErrorAppScreenShotsKey];
    descriptions = mutableDescriptions;
  }
  [errorStack addObject:descriptions];

  return errorStack;
}

+ (NSString *)grey_nestedDescriptionForError:(NSError *)error {
  NSArray *descriptions = [GREYErrorFormatter grey_nestedErrorDictionariesForError:error];
  if (descriptions.count == 0) {
    return @"";
  }

  NSArray *keyOrder = @[
    kErrorDescriptionKey, kErrorDomainKey, kErrorCodeKey, kErrorFileNameKey, kErrorFunctionNameKey,
    kErrorLineKey, kErrorTestCaseClassNameKey, kErrorTestCaseMethodNameKey
  ];

  return [GREYObjectFormatter formatArray:descriptions
                                   indent:kGREYObjectFormatIndent
                                 keyOrder:keyOrder];
}

#pragma mark - Private Methods

- (NSString *)elementNotFoundDescription {
  NSMutableArray<NSString *> *logger = [[NSMutableArray alloc] init];
  
  // exception reason
  [logger addObject:[NSString stringWithFormat:@"\n%@\n", _error.localizedDescription]];

  // recovery suggestion
  if (_error.userInfo[kErrorDetailRecoverySuggestionKey]) {
    [logger addObject:[NSString stringWithFormat:@"%@\n",
                       _error.userInfo[kErrorDetailRecoverySuggestionKey]]];
  }
  
  // element matcher
  if (_error.userInfo[kErrorDetailElementMatcherKey]) {
    [logger addObject:[NSString stringWithFormat:@"Element Matcher:\n%@\n",
                       _error.userInfo[kErrorDetailElementMatcherKey]]];
  }

  // search api info, pretty printed (if it was a search)
  if (_error.userInfo[kErrorDetailSearchActionInfoKey]) {
    [logger addObject:[NSString stringWithFormat:@"Search Action Info\n%@\n",
                       _error.userInfo[kErrorDetailSearchActionInfoKey]]];
  }
  
  // screenshots
  for (NSString *key in _error.appScreenshots.allKeys) {
    [logger addObject:[NSString stringWithFormat:@"%@: %@\n", key, _error.appScreenshots[key]]];
  }
  
  // nested error
  if (_error.nestedError) {
    [logger addObject:[NSString stringWithFormat:@"Underlying Error: \n%@\n",
                       _error.nestedError.description]];
  }
  
  // UI hierarchy
  if (_error.appUIHierarchy) {
    [logger addObject:[GREYErrorFormatter formattedHierarchy:_error.appUIHierarchy]];
  }

  // stack trace
  if (_error.stackTrace) {
    [logger addObject:[NSString stringWithFormat:@"Stack Trace: %@\n", _error.stackTrace]];
  }
  
  return [logger componentsJoinedByString:@"\n"];
}

- (NSDictionary *)grey_descriptionDictionary {
  NSMutableDictionary *descriptionDictionary = [[_error grey_descriptionDictionary] mutableCopy];

  if (!descriptionDictionary) {
    return nil;
  }

  descriptionDictionary[kErrorTestCaseClassNameKey] = _error.testCaseClassName;
  descriptionDictionary[kErrorTestCaseMethodNameKey] = _error.testCaseMethodName;
  descriptionDictionary[kErrorFileNameKey] = [_error.filePath lastPathComponent];
  descriptionDictionary[kErrorLineKey] = [NSString stringWithFormat:@"%ld", (unsigned long)_error.line];
  descriptionDictionary[kErrorFunctionNameKey] = _error.functionName;
  descriptionDictionary[kErrorUserInfoKey] = _error.userInfo;
  descriptionDictionary[kErrorErrorInfoKey] = _error.errorInfo;
  descriptionDictionary[kErrorStackTraceKey] = _error.stackTrace;
  descriptionDictionary[kErrorAppUIHierarchyKey] = _error.appUIHierarchy;
  descriptionDictionary[kErrorAppScreenShotsKey] = _error.appScreenshots;

  return descriptionDictionary;
}

@end
