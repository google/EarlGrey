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

#pragma mark - GREYErrorFormatterKeys

/**
 * Keys used by GREYErrorFormatter to format a GREYError's userInfo properties.
 * These states are not mutually exclusive and can be combined together using Bitwise-OR to
 * represent multiple states.
 * If more than 32 options exists, change the bitshifted values to UL.
 */
typedef NS_OPTIONS(NSUInteger, GREYErrorFormatterKeys) {
  GREYErrorFormatterNone = 0,
  /**
   * Exception Reason
   */
  GREYErrorFormatterExceptionReasonKey = 1 << 0,
  /**
   * Recovery Suggestion
   */
  GREYErrorFormatterRecoverySuggestionKey = 1 << 1,
  /**
   * Element Matcher
   */
  GREYErrorFormatterElementMatcherKey = 1 << 2,
  /**
   * Search API Info
   */
  GREYErrorFormatterSearchActionInfoKey = 1 << 3,
  /**
   * Assertion Criteria, or Action Name
   */
  GREYErrorFormatterCriteriaKey = 1 << 4,
  /**
   * Underlying ("Nested") Error
   */
  GREYErrorFormatterUnderlyingErrorKey = 1 << 5,
};

#pragma mark - Private Variables

@interface GREYErrorFormatter ()
@property(readonly, nonatomic) GREYError *error;
@property(readonly, nonatomic) NSUInteger keys;
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
- (NSUInteger)loggerKeys {
  if (_keys) {
    return _keys;
  }
  if ([_error.domain isEqualToString:kGREYInteractionErrorDomain] &&
       _error.code == kGREYInteractionElementNotFoundErrorCode) {
     _keys = GREYErrorFormatterExceptionReasonKey |
             GREYErrorFormatterRecoverySuggestionKey |
             GREYErrorFormatterElementMatcherKey |
             GREYErrorFormatterCriteriaKey |
             GREYErrorFormatterSearchActionInfoKey |
             GREYErrorFormatterUnderlyingErrorKey;
    return _keys;
  }
  GREYFatalAssertWithMessage(false, @"Error Domain and Code Not Yet Supported");
}

- (NSString *)loggerDescriptionForKeys:(NSUInteger)keys {
  NSMutableArray<NSString *> *logger = [[NSMutableArray alloc] init];
  
  if (keys & GREYErrorFormatterExceptionReasonKey) {
    NSString *exceptionReason = _error.localizedDescription;
    [logger addObject:[NSString stringWithFormat:@"\n%@", exceptionReason]];
  }
  
  if (keys & GREYErrorFormatterRecoverySuggestionKey) {
    NSString *recoverySuggestion = _error.userInfo[kErrorDetailRecoverySuggestionKey];
    if (recoverySuggestion) {
      [logger addObject:recoverySuggestion];
    }
  }
  
  if (keys & GREYErrorFormatterElementMatcherKey) {
    NSString *elementMatcher = _error.userInfo[kErrorDetailElementMatcherKey];
    if (elementMatcher) {
      [logger addObject:[NSString stringWithFormat:@"%@:\n%@", kErrorDetailElementMatcherKey,
                         elementMatcher]];
    }
  }
  
  if (keys & GREYErrorFormatterCriteriaKey) {
    NSString *assertionCriteria = _error.userInfo[kErrorDetailAssertCriteriaKey];
    if (assertionCriteria) {
      [logger addObject:[NSString stringWithFormat:@"%@: %@", kErrorDetailAssertCriteriaKey,
                         assertionCriteria]];
    }
    NSString *actionCriteria = _error.userInfo[kErrorDetailActionNameKey];
    if (actionCriteria) {
      [logger addObject:[NSString stringWithFormat:@"%@: %@", kErrorDetailActionNameKey,
                         actionCriteria]];
    }
  }
  
  if (keys & GREYErrorFormatterSearchActionInfoKey) {
    NSString *searchActionInfo = _error.userInfo[kErrorDetailSearchActionInfoKey];
    if (searchActionInfo) {
      [logger addObject:[NSString stringWithFormat:@"%@\n%@", kErrorDetailSearchActionInfoKey,
                         searchActionInfo]];
    }
  }
  
  if (keys & GREYErrorFormatterUnderlyingErrorKey) {
    NSString *nestedError = _error.nestedError.description;
    if (nestedError) {
      [logger addObject:[NSString stringWithFormat:@"Underlying Error:\n%@", nestedError]];
    }
  }

  return [NSString stringWithFormat:@"%@\n", [logger componentsJoinedByString:@"\n\n"]];
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
