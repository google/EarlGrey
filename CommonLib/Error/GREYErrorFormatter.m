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

#import "GREYError+Private.h"
#import "GREYError.h"
#import "GREYErrorConstants.h"

#pragma mark - UI Hierarchy Keys

static NSString *const kErrorPrefix = @"EarlGrey Encountered an Error:";

#pragma mark - Public Methods

static void LogErrorForKeyInLogger(GREYError *error, NSString *key, NSMutableString *logger) {
  if (key == kErrorFailureReasonKey) {
    NSString *exceptionReason = error.userInfo[kErrorFailureReasonKey];
    if (exceptionReason) {
      [logger appendFormat:@"\n\n%@", exceptionReason];
    }
  } else if (key == kErrorDetailRecoverySuggestionKey) {
    // There shouldn't be a recovery suggestion for a wrappeed error of an underlying error.
    if (!error.nestedError) {
      NSString *recoverySuggestion = error.userInfo[kErrorDetailRecoverySuggestionKey];
      if (recoverySuggestion) {
        [logger appendFormat:@"\n\n%@", recoverySuggestion];
      }
    }
  } else if (key == kErrorDetailElementMatcherKey) {
    NSString *elementMatcher = error.userInfo[kErrorDetailElementMatcherKey];
    if (elementMatcher) {
      [logger appendFormat:@"\n\n%@:\n%@", kErrorDetailElementMatcherKey, elementMatcher];
    }
  } else if (key == kErrorDetailConstraintRequirementKey) {
    NSString *failedConstraints = error.userInfo[kErrorDetailConstraintRequirementKey];
    if (failedConstraints) {
      [logger appendFormat:@"\n\n%@:\n%@", kErrorDetailConstraintRequirementKey, failedConstraints];
    }
  } else if (key == kErrorDetailElementDescriptionKey) {
    NSString *elementDescription = error.userInfo[kErrorDetailElementDescriptionKey];
    if (elementDescription) {
      [logger appendFormat:@"\n\n%@:\n%@", kErrorDetailElementDescriptionKey, elementDescription];
    }
  } else if (key == kErrorDetailAssertCriteriaKey) {
    NSString *assertionCriteria = error.userInfo[kErrorDetailAssertCriteriaKey];
    if (assertionCriteria) {
      [logger appendFormat:@"\n\n%@:\n%@", kErrorDetailAssertCriteriaKey, assertionCriteria];
    }
  } else if (key == kErrorDetailActionNameKey) {
    NSString *actionCriteria = error.userInfo[kErrorDetailActionNameKey];
    if (actionCriteria) {
      [logger appendFormat:@"\n\n%@:\n%@", kErrorDetailActionNameKey, actionCriteria];
    }
  } else if (key == kErrorDetailSearchActionInfoKey) {
    NSString *searchActionInfo = error.userInfo[kErrorDetailSearchActionInfoKey];
    if (searchActionInfo) {
      [logger appendFormat:@"\n\n%@", searchActionInfo];
    }
  }
}

NSString *GREYFormattedDescriptionForError(GREYError *error, BOOL containsHierarchy) {
  NSMutableString *logger = [[NSMutableString alloc] init];
  NSArray<NSString *> *keyOrder = error.keyOrder;
  NSArray<NSString *> *defaultKeyOrder = @[
    kErrorFailureReasonKey, kErrorDetailRecoverySuggestionKey, kErrorDetailElementMatcherKey,
    kErrorDetailConstraintRequirementKey, kErrorDetailElementDescriptionKey,
    kErrorDetailAssertCriteriaKey, kErrorDetailActionNameKey, kErrorDetailSearchActionInfoKey
  ];

  // add error logging for userInfo dictionary that are in the keyOrder
  for (NSString *key in keyOrder) {
    LogErrorForKeyInLogger(error, key, logger);
  }

  // add error logging for userInfo dictionary that are not in the keyOrder
  for (NSString *key in defaultKeyOrder) {
    if (![keyOrder containsObject:key]) {
      LogErrorForKeyInLogger(error, key, logger);
    }
  }

  NSArray<NSString *> *multipleElementsMatched = error.multipleElementsMatched;
  if (multipleElementsMatched) {
    [logger appendFormat:@"\n\n%@:", kErrorDetailElementsMatchedKey];
    [multipleElementsMatched
        enumerateObjectsUsingBlock:^(NSString *element, NSUInteger index, BOOL *stop) {
          // Numbered list of all elements that were matched, starting at 1.
          [logger appendFormat:@"\n\n\t%lu. %@", (unsigned long)index + 1, element];
        }];
  }

  NSString *nestedError = error.nestedError.description;
  if (nestedError) {
    [logger appendFormat:@"\n\n*********** Underlying Error ***********:\n%@", nestedError];
  }

  if (containsHierarchy) {
    NSString *hierarchy = error.appUIHierarchy;
    if (hierarchy) {
      [logger appendFormat:@"\n\n%@\n%@", kErrorDetailAppUIHierarchyHeaderKey, hierarchy];
    }
  }

  return [NSString stringWithFormat:@"%@\n", logger];
}
