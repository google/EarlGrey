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
#import "GREYFatalAsserts.h"

#pragma mark - String Constants

/**
 * All keys that can be added to the description logger in GREYErrorFormatter.
 */
static NSString *const kErrorFormatterExceptionReasonKey    = @"Exception Reason";
static NSString *const kErrorFormatterRecoverySuggestionKey = @"Recovery Suggestion";
static NSString *const kErrorFormatterElementMatcherKey     = @"Element Matcher";
static NSString *const kErrorFormatterSearchActionInfoKey   = @"Search Action Info";
static NSString *const kErrorFormatterUnderlyingErrorKey    = @"Underlying Error";

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
    return [self loggerDescriptionForKeys:[self loggerKeys]];
  }
  return [GREYObjectFormatter formatDictionary:[_error grey_descriptionDictionary]
                                        indent:kGREYObjectFormatIndent
                                     hideEmpty:YES
                                      keyOrder:nil];
}

#pragma mark - Private Methods

// The keys whose values should be supplied in the formatted error output.
- (NSSet<NSString *> *)loggerKeys {
  if ([_error.domain isEqualToString:kGREYInteractionErrorDomain] &&
       _error.code == kGREYInteractionElementNotFoundErrorCode) {
    return [[NSSet alloc] initWithArray:@[kErrorFormatterExceptionReasonKey,
                                          kErrorFormatterRecoverySuggestionKey,
                                          kErrorFormatterElementMatcherKey,
                                          kErrorFormatterSearchActionInfoKey,
                                          kErrorFormatterUnderlyingErrorKey]];
  }
  GREYFatalAssertWithMessage(false, @"Error Domain and Code Not Yet Supported");
}

- (NSString *)loggerDescriptionForKeys:(NSSet<NSString *> *)keys {
  NSMutableArray<NSString *> *logger = [[NSMutableArray alloc] init];
  
  if ([keys containsObject:kErrorFormatterExceptionReasonKey]) {
    NSString *exceptionReason = _error.localizedDescription;
    [logger addObject:[NSString stringWithFormat:@"\n%@", exceptionReason]];
  }
  
  if ([keys containsObject:kErrorFormatterRecoverySuggestionKey]) {
    NSString *recoverySuggestion = _error.userInfo[kErrorDetailRecoverySuggestionKey];
    if (recoverySuggestion) {
      [logger addObject:recoverySuggestion];
    }
  }
  
  if ([keys containsObject:kErrorFormatterElementMatcherKey]) {
    NSString *elementMatcher = _error.userInfo[kErrorDetailElementMatcherKey];
    if (elementMatcher) {
      [logger addObject:[NSString stringWithFormat:@"%@:\n%@", kErrorDetailElementMatcherKey,
                         elementMatcher]];
    }
  }
  
  if ([keys containsObject:kErrorFormatterSearchActionInfoKey]) {
    NSString *searchActionInfo = _error.userInfo[kErrorDetailSearchActionInfoKey];
    if (searchActionInfo) {
      [logger addObject:[NSString stringWithFormat:@"%@\n%@", kErrorDetailSearchActionInfoKey,
                         searchActionInfo]];
    }
  }
  
  if ([keys containsObject:kErrorFormatterUnderlyingErrorKey]) {
    NSString *nestedError = _error.nestedError.description;
    if (nestedError) {
      [logger addObject:[NSString stringWithFormat:@"%@:\n%@", kErrorFormatterUnderlyingErrorKey,
                         nestedError]];
    }
  }
  
  return [logger componentsJoinedByString:@"\n\n"];
}

#pragma mark - Functions

BOOL GREYShouldUseErrorFormatterForError(GREYError *error) {
  return [error.domain isEqualToString:kGREYInteractionErrorDomain] &&
          error.code == kGREYInteractionElementNotFoundErrorCode;
}

BOOL GREYShouldUseErrorFormatterForExceptionReason(NSString *reason) {
  return [reason containsString:@"the desired element was not found"];
}

@end
