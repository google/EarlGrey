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

#import "GREYBaseAction.h"

#import "NSObject+GREYApp.h"
#import "GREYInteraction.h"
#import "GREYAppError.h"
#import "GREYSyncAPI.h"
#import "NSObject+GREYCommon.h"
#import "GREYThrowDefines.h"
#import "GREYConfiguration.h"
#import "GREYError+Private.h"
#import "GREYErrorConstants.h"
#import "GREYObjectFormatter.h"
#import "NSError+GREYCommon.h"
#import "GREYMatcher.h"
#import "GREYStringDescription.h"

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

- (BOOL)satisfiesConstraintsForElement:(id)element error:(__strong NSError **)error {
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
      NSMutableDictionary<NSString *, id> *errorDetails = [[NSMutableDictionary alloc] init];

      errorDetails[kErrorDetailActionNameKey] = _name;
      errorDetails[kErrorDetailElementDescriptionKey] = description;
      errorDetails[kErrorDetailConstraintRequirementKey] = mismatchDetail;
      errorDetails[kErrorDetailRecoverySuggestionKey] =
          @"Adjust element properties so that it matches the failed constraint(s).";

      GREYError *interactionError = GREYErrorMakeWithHierarchy(
          kGREYInteractionErrorDomain, kGREYInteractionConstraintsFailedErrorCode,
          @"Cannot perform action due to constraint(s) failure.");
      interactionError.errorInfo = errorDetails;

      *error = interactionError;
      return NO;
    }
    return YES;
  }
}

#pragma mark - GREYAction

// The perform:error: method has to be implemented by the subclass.
- (BOOL)perform:(id)element error:(__strong NSError **)error {
  [self doesNotRecognizeSelector:_cmd];
  return NO;
}

- (NSString *)name {
  return _name;
}

- (BOOL)shouldRunOnMainThread {
  return YES;
}

#pragma mark - GREYDiagnosable

// By default, all GREYBaseAction have no diagnosticsID. If you are subclassing GREYBaseAction and
// want its metrics to be tracked, override this method and give it an identifier. This is for
// INTERNAL USE only.
- (NSString *)diagnosticsID {
  return nil;
}

@end
