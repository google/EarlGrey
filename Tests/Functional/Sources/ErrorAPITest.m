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

#import "GREYWaitFunctions.h"
#import "EarlGrey.h"
#import "BaseIntegrationTest.h"

#import "GREYError.h"
#import "FailureHandler.h"

@interface ErrorAPITest : BaseIntegrationTest
@end

@implementation ErrorAPITest {
  id<GREYMatcher> _matcherForNonExistingTab;
}

- (void)setUp {
  [super setUp];

  [self openTestViewNamed:@"Basic Views"];
  _matcherForNonExistingTab = grey_text(@"Tab That Does Not Exist");
}

- (void)testCallAllAssertionDefines {
  GREYAssert(42, @"42 should assert fine.");
  GREYAssertTrue(1 == 1, @"1 should be equal to 1");
  GREYAssertFalse(0 == 1, @"0 shouldn't be equal to 1");
  GREYAssertEqual(1, 1, @"1 should be equal to 1");
  GREYAssertNotEqual(1, 2, @"1 should not be equal to 2");
  GREYAssertEqualObjects(@"foo", [[NSString alloc] initWithFormat:@"foo"],
                         @"strings foo must be equal");
  GREYAssertNotEqualObjects(@"foo", @"bar", @"string foo and bar must not be equal");
  GREYAssertNil(nil, @"nil should be nil");
  GREYAssertNotNil([[NSObject alloc] init], @"a valid object should not be nil");
}

- (void)testAssertionErrorAPI {
  NSError *error;

  [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")] performAction:grey_tap() error:&error];
  GREYAssertNil(error, @"Error should be nil");

  [[EarlGrey selectElementWithMatcher:_matcherForNonExistingTab] assertWithMatcher:grey_nil()
                                                                             error:&error];
  GREYAssertTrue(error.code == kGREYInteractionElementNotFoundErrorCode,
                 @"The error code should point to element not found");

  [[EarlGrey selectElementWithMatcher:_matcherForNonExistingTab] assertWithMatcher:grey_notNil()
                                                                             error:&error];
  GREYAssertTrue([error.domain isEqualToString:kGREYInteractionErrorDomain],
                 @"Domain should match");
  GREYAssertTrue(error.code == kGREYInteractionElementNotFoundErrorCode, @"Code should match");
  GREYError *greyError = (GREYError *)error;
  NSString *description = _matcherForNonExistingTab.description;
  GREYAssertTrue([greyError.userInfo[kErrorDetailElementMatcherKey] isEqualToString:description],
                 @"Description should match");
  GREYAssertEqualObjects(greyError.userInfo[kErrorDetailElementMatcherKey], description,
                         @"Description should match");

  [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")] assertWithMatcher:grey_nil()
                                                                       error:&error];
  GREYAssertTrue([error.domain isEqualToString:kGREYInteractionErrorDomain],
                 @"Domain should match");
  GREYAssertTrue(error.code == kGREYInteractionAssertionFailedErrorCode, @"Code should match");
  // Save current failure handler.
  id<GREYFailureHandler> currentFailureHandler = GetCurrentFailureHandler();
  [NSThread mainThread].threadDictionary[GREYFailureHandlerKey] = [[FailureHandler alloc] init];
  // Should throw exception.
  @try {
    [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")] assertWithMatcher:grey_nil()
                                                                         error:nil];
    GREYFail(@"Shouldn't reach this line of code");
  } @catch (GREYFrameworkException *exception) {
    // TODO(b/147239626): Propagate a more granular exception name for assertion and action errors.
    GREYAssertTrue([exception.name isEqual:kGREYInteractionErrorDomain],
                   @"Exception name should match");
  }
  // Restore failure handler.
  [NSThread mainThread].threadDictionary[GREYFailureHandlerKey] = currentFailureHandler;
}

- (void)testActionErrorAPI {
  NSError *error;

  // Element not found.
  [[EarlGrey selectElementWithMatcher:_matcherForNonExistingTab] performAction:grey_tap()
                                                                         error:&error];
  GREYAssertTrue([error.domain isEqualToString:kGREYInteractionErrorDomain],
                 @"Domain should match");
  GREYAssertTrue(error.code == kGREYInteractionElementNotFoundErrorCode, @"Code should match");
  GREYError *greyError = (GREYError *)error;
  GREYAssertEqualObjects(greyError.userInfo[kErrorDetailElementMatcherKey],
                         _matcherForNonExistingTab.description, @"Description should match");

  // grey_type on a Tab should cause action constraints to fail.
  [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")] performAction:grey_typeText(@"")
                                                                   error:&error];
  GREYAssertTrue([error.domain isEqualToString:kGREYInteractionErrorDomain],
                 @"Domain should match");
  GREYAssertTrue(error.code == kGREYInteractionActionFailedErrorCode, @"Code should match");
  // Save current failure handler.
  id<GREYFailureHandler> currentFailureHandler = GetCurrentFailureHandler();
  [NSThread mainThread].threadDictionary[GREYFailureHandlerKey] = [[FailureHandler alloc] init];
  // Should throw exception.
  @try {
    [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")] performAction:grey_typeText(@"")
                                                                     error:nil];
    GREYFail(@"Shouldn't reach this line of code");
  } @catch (GREYFrameworkException *exception) {
    // TODO(b/147239626): Propagate a more granular exception name for assertion and action errors.
    GREYAssertTrue([exception.name isEqual:kGREYInteractionErrorDomain],
                   @"Exception name should match");
  }
  // Restore failure handler.
  [NSThread mainThread].threadDictionary[GREYFailureHandlerKey] = currentFailureHandler;
}

static inline id<GREYFailureHandler> GetCurrentFailureHandler() {
  return [[[NSThread mainThread] threadDictionary] valueForKey:GREYFailureHandlerKey];
}

@end
