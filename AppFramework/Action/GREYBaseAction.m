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

#import "AppFramework/Action/GREYBaseAction.h"

#import "AppFramework/Additions/NSObject+GREYApp.h"
#import "AppFramework/Core/GREYInteraction.h"
#import "AppFramework/Error/GREYAppError.h"
#import "AppFramework/Error/GREYAppFailureHandler.h"
#import "AppFramework/Synchronization/GREYSyncAPI.h"
#import "CommonLib/Additions/NSObject+GREYCommon.h"
#import "CommonLib/Assertion/GREYAssertionDefines.h"
#import "CommonLib/Assertion/GREYThrowDefines.h"
#import "CommonLib/Config/GREYConfiguration.h"
#import "CommonLib/Error/GREYError+Internal.h"
#import "CommonLib/Error/GREYErrorConstants.h"
#import "CommonLib/Error/GREYObjectFormatter.h"
#import "CommonLib/Error/NSError+GREYCommon.h"
#import "CommonLib/Matcher/GREYMatcher.h"
#import "CommonLib/Matcher/GREYStringDescription.h"

@implementation GREYBaseAction {
  NSString *_name;
  id<GREYMatcher> _constraints;
}

- (instancetype)initWithName:(NSString *)name constraints:(id<GREYMatcher>)constraints {
  GREYThrowOnNilParameter(name);

  self = [super init];
  if (self) {
    _name = [name copy];
    _constraints = constraints;
  }
  return self;
}

- (BOOL)satisfiesConstraintsForElement:(id)element error:(__strong NSError **)errorOrNil {
  if (!_constraints || !GREY_CONFIG_BOOL(kGREYConfigKeyActionConstraintsEnabled)) {
    return YES;
  } else {
    GREYStringDescription *mismatchDetail = [[GREYStringDescription alloc] init];
    __block BOOL constraintsMatched = NO;
    __block NSString *description;
    grey_dispatch_sync_on_main_thread(^{
      constraintsMatched = [self->_constraints matches:element describingMismatchTo:mismatchDetail];
      if (!constraintsMatched) {
        description = [element grey_description];
      }
    });

    if (!constraintsMatched) {
      NSMutableDictionary *errorDetails = [[NSMutableDictionary alloc] init];

      errorDetails[kErrorDetailActionNameKey] = _name;
      errorDetails[kErrorDetailElementDescriptionKey] = description;
      errorDetails[kErrorDetailConstraintRequirementKey] = mismatchDetail;
      errorDetails[kErrorDetailConstraintDetailsKey] = [_constraints description];
      errorDetails[kErrorDetailRecoverySuggestionKey] =
          @"Adjust element properties so that it matches the failed constraint(s).";

      GREYError *error = GREYErrorMakeWithHierarchy(
          kGREYInteractionErrorDomain, kGREYInteractionConstraintsFailedErrorCode,
          @"Cannot perform action due to constraint(s) failure.");
      error.errorInfo = errorDetails;

      if (errorOrNil) {
        *errorOrNil = error;
      } else {
        NSArray *keyOrder = @[
          kErrorDetailActionNameKey, kErrorDetailConstraintRequirementKey,
          kErrorDetailElementDescriptionKey, kErrorDetailConstraintDetailsKey,
          kErrorDetailRecoverySuggestionKey
        ];

        NSString *reasonDetail = [GREYObjectFormatter formatDictionary:errorDetails
                                                                indent:2
                                                             hideEmpty:YES
                                                              keyOrder:keyOrder];

        NSString *reason = [NSString stringWithFormat:
                                         @"Cannot perform action due to constraint(s) failure.\n"
                                         @"Exception with Action: %@\n",
                                         reasonDetail];

        I_GREYActionFail(reason, @"");
      }
      return NO;
    }
    return YES;
  }
}

#pragma mark - GREYAction

// The perform:error: method has to be implemented by the subclass.
- (BOOL)perform:(id)element error:(__strong NSError **)errorOrNil {
  [self doesNotRecognizeSelector:_cmd];
  return NO;
}

- (NSString *)name {
  return _name;
}

@end
