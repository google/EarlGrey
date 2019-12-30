//
// Copyright 2019 Google Inc.
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

#import "GREYHostApplicationDistantObject+ErrorHandlingTest.h"

#import "GREYAppError.h"
#import "GREYConfiguration.h"
#import "GREYConstants.h"

@implementation GREYHostApplicationDistantObject (ErrorHandlingTest)

- (NSError *)errorPopulatedInTheApp {
  NSError *error;
  I_GREYPopulateError(&error, kGREYGenericErrorDomain, kGREYGenericErrorCode, @"Foo");
  return error;
}

- (NSError *)notedErrorPopulatedInTheApp {
  NSError *error;
  I_GREYPopulateErrorNoted(&error, kGREYGenericErrorDomain, kGREYGenericErrorCode, @"Foo", @{});
  return error;
}

- (NSError *)errorCreatedInTheApp {
  return GREYErrorMakeWithHierarchy(kGREYGenericErrorDomain, kGREYGenericErrorCode, @"Foo");
}

- (NSError *)nestedErrorWithHierarchyCreatedInTheApp {
  NSError *errorWithHierarchy =
      GREYErrorMakeWithHierarchy(kGREYGenericErrorDomain, kGREYGenericErrorCode, @"Foo");
  return GREYErrorNestedMake(kGREYGenericErrorDomain, kGREYGenericErrorCode, @"Foo",
                             errorWithHierarchy);
}

- (NSError *)simpleNestedError {
  NSError *nestedError =
      GREYErrorMake(kGREYGenericErrorDomain, kGREYGenericErrorCode, @"Generic Nested Error");
  return GREYErrorNestedMake(kGREYGenericErrorDomain, kGREYGenericErrorCode, @"Generic Error",
                             nestedError);
}

- (void)induceNonTactileActionTimeoutInTheApp {
  // This is done in a dispatch_after as calling sleep() directly or in a dispatch async will block
  // any further interaction with the app until the sleep finishes. Non-tactile actions such as
  // rotation will wait for this to complete before timing out.
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                 dispatch_get_main_queue(), ^{
                   [NSThread sleepForTimeInterval:10];
                 });
}

@end
