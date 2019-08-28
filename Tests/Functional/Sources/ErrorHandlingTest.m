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

#import "BaseIntegrationTest.h"

#import "GREYError.h"
#import "GREYObjectFormatter.h"
#import "GREYHostApplicationDistantObject+ErrorHandlingTest.h"

@interface ErrorHandlingTest : BaseIntegrationTest
@end

@implementation ErrorHandlingTest

- (void)testActionErrorContainsHierarchyForFailures {
  NSError *error;
  [[EarlGrey selectElementWithMatcher:grey_keyWindow()]
      performAction:grey_scrollInDirection(kGREYDirectionUp, 10)
              error:&error];
  XCTAssertTrue([error.description containsString:@"|--<"]);
}

- (void)testAssertionErrorContainsHierarchyForFailures {
  NSError *error;
  [[EarlGrey selectElementWithMatcher:grey_keyWindow()] assertWithMatcher:grey_nil() error:&error];
  XCTAssertTrue([error.description containsString:@"|--<"]);
}

- (void)testMatcherErrorContainsHierarchyForFailures {
  NSError *error;
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"Invalid ID")] performAction:grey_tap()
                                                                                   error:&error];
  XCTAssertTrue([error.description containsString:@"|--<"]);
  error = nil;
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"Invalid ID")]
      assertWithMatcher:grey_notNil()
                  error:&error];
  XCTAssertTrue([error.description containsString:@"|--<"]);
}

- (void)testIdlingResourceContainsOnlyOneHierarchyInstance {
  [self openTestViewNamed:@"Animations"];
  double originalTimeout = GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration);
  [[GREYConfiguration sharedConfiguration] setValue:@(1)
                                       forConfigKey:kGREYConfigKeyInteractionTimeoutDuration];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"AnimationControl")]
      performAction:grey_tap()];
  NSError *error;
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"AnimationStatus")]
      assertWithMatcher:grey_text(@"Paused")
                  error:&error];

  [[GREYConfiguration sharedConfiguration] setValue:@(originalTimeout)
                                       forConfigKey:kGREYConfigKeyInteractionTimeoutDuration];
  XCTAssertEqual([self grey_hierarchyOccurrencesInErrorDescription:error.description],
                 (NSUInteger)1);
}

- (void)testSimpleErrorDoesNotContainHierarchy {
  NSError *error = GREYErrorMake(kGREYGenericErrorDomain, kGREYGenericErrorCode, @"Generic Error");
  XCTAssertFalse([error.description containsString:@""]);
}

- (void)testNestedErrorCreatedWithASimpleErrorDoesNotContainHierarchy {
  NSError *error = [[GREYHostApplicationDistantObject sharedInstance] simpleNestedError];

  XCTAssertFalse([error.description containsString:@""]);
}

- (void)testErrorPopulatedInTheAppContainsOneHierarchy {
  NSError *error = [[GREYHostApplicationDistantObject sharedInstance] errorPopulatedInTheApp];
  XCTAssertEqual([self grey_hierarchyOccurrencesInErrorDescription:error.description],
                 (NSUInteger)1);
}

- (void)testNestedErrorPopulatedInTheAppContainsOneHierarchy {
  NSError *error = [[GREYHostApplicationDistantObject sharedInstance] notedErrorPopulatedInTheApp];
  XCTAssertEqual([self grey_hierarchyOccurrencesInErrorDescription:error.description],
                 (NSUInteger)1);
}

- (void)testErrorCreatedInTheAppContainsOneHierarchy {
  NSError *error = [[GREYHostApplicationDistantObject sharedInstance] errorPopulatedInTheApp];
  XCTAssertEqual([self grey_hierarchyOccurrencesInErrorDescription:error.description],
                 (NSUInteger)1);
}

- (void)testNestedErrorInsideAnErrorWithHierarchyContainsOneHierarchy {
  NSError *error =
      [[GREYHostApplicationDistantObject sharedInstance] nestedErrorWithHierarchyCreatedInTheApp];
  XCTAssertEqual([self grey_hierarchyOccurrencesInErrorDescription:error.description],
                 (NSUInteger)1);
}

- (void)testFormattingOfErrorCreatedInTheApp {
  NSError *error = [[GREYHostApplicationDistantObject sharedInstance] errorCreatedInTheApp];
  XCTAssertNoThrow([GREYError grey_nestedDescriptionForError:error],
                   @"Failing on an error from the app did not throw an exception");
}

#pragma mark - Private

/**
 *  @c returns A NSUInteger for the number of times the UI hierarchy is present in the provided
 *             error description.
 *
 *  @param description An NSString specifying an NSError's description.
 */
- (NSUInteger)grey_hierarchyOccurrencesInErrorDescription:(NSString *)description {
  NSRegularExpression *regex =
      [NSRegularExpression regularExpressionWithPattern:@"<UIWindow"
                                                options:NSRegularExpressionCaseInsensitive
                                                  error:nil];
  return [regex numberOfMatchesInString:description
                                options:0
                                  range:NSMakeRange(0, [description length])];
}

@end
