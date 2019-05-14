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

#import "AppFramework/Assertion/GREYAssertions.h"
#import "AppFramework/Core/GREYElementFinder.h"
#import "AppFramework/Core/GREYInteraction.h"
#import "AppFramework/Matcher/GREYAllOf.h"
#import "AppFramework/Matcher/GREYMatchers.h"
#import "CommonLib/Assertion/GREYAssertion.h"
#import "CommonLib/Error/GREYErrorConstants.h"
#import "Tests/Unit/AppFramework/GREYAppBaseTest.h"
#import "third_party/objective_c/ocmock/v3/Source/OCMock/OCMock.h"

static NSMutableArray *gAppWindows;

@interface GREYAssertionsTest : GREYAppBaseTest
@end

@implementation GREYAssertionsTest

- (void)setUp {
  [super setUp];
  gAppWindows = [[NSMutableArray alloc] init];
  [[[self.mockSharedApplication stub] andReturn:gAppWindows] windows];
}

- (void)testViewHasTextWithEmptyString {
  UIView *view = [[UIView alloc] init];
  NSError *error;
  id<GREYMatcher> textMatcher = [GREYMatchers matcherForText:@""];
  [[GREYAssertions assertionWithMatcher:textMatcher] assert:view error:&error];
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(error.code, kGREYInteractionAssertionFailedErrorCode);
}

- (void)testViewHasTextWithNilOrNotSubclass {
  UIView *view = [[UIView alloc] init];
  NSError *error;
  id<GREYMatcher> textMatcher = [GREYMatchers matcherForText:@"txt"];
  [[GREYAssertions assertionWithMatcher:textMatcher] assert:view error:&error];
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(error.code, kGREYInteractionAssertionFailedErrorCode);

  error = nil;
  textMatcher = [GREYMatchers matcherForText:@"txt"];
  [[GREYAssertions assertionWithMatcher:textMatcher] assert:nil error:&error];
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(error.code, kGREYInteractionElementNotFoundErrorCode);
}

- (void)testMatchesThrowsExceptionForNilView {
  NSError *error;
  id<GREYMatcher> textMatcher = [GREYMatchers matcherForText:@""];
  [[GREYAssertions assertionWithMatcher:textMatcher] assert:nil error:&error];

  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(error.code, kGREYInteractionElementNotFoundErrorCode);
}

- (void)testViewHasTextWithText {
  NSString *textToFind = @"A String";
  NSError *error;

  UILabel *label = [[UILabel alloc] init];
  label.text = textToFind;
  id<GREYMatcher> textMatcher = [GREYMatchers matcherForText:textToFind];
  [[GREYAssertions assertionWithMatcher:textMatcher] assert:label error:&error];
  XCTAssertNil(error);
  error = nil;

  UITextField *textField = [[UITextField alloc] init];
  textField.text = textToFind;
  textMatcher = [GREYMatchers matcherForText:textToFind];
  [[GREYAssertions assertionWithMatcher:textMatcher] assert:textField error:&error];
  XCTAssertNil(error);
  error = nil;

  UITextView *textView = [[UITextView alloc] init];
  textView.text = textToFind;
  textMatcher = [GREYMatchers matcherForText:textToFind];
  [[GREYAssertions assertionWithMatcher:textMatcher] assert:textView error:nil];
  XCTAssertNil(error);
}

- (void)testViewHasTextWithWrongText {
  NSString *textToFind = @"A String";
  NSError *error;

  UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  id<GREYMatcher> textMatcher = [GREYMatchers matcherForText:textToFind];
  [[GREYAssertions assertionWithMatcher:textMatcher] assert:label error:&error];
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(error.code, kGREYInteractionAssertionFailedErrorCode);

  UITextField *textField = [[UITextField alloc] init];
  textField.text = @"";
  textMatcher = [GREYMatchers matcherForText:textToFind];
  [[GREYAssertions assertionWithMatcher:textMatcher] assert:textField error:&error];
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(error.code, kGREYInteractionAssertionFailedErrorCode);

  UITextView *textView = [[UITextView alloc] init];
  textView.text = @"A Different String";
  textMatcher = [GREYMatchers matcherForText:textToFind];
  [[GREYAssertions assertionWithMatcher:textMatcher] assert:textView error:&error];
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(error.code, kGREYInteractionAssertionFailedErrorCode);
}

- (void)testIsVisibleWithNil {
  NSError *error;
  id<GREYMatcher> sufficientlyVisibleMatcher = [GREYMatchers matcherForSufficientlyVisible];
  [[GREYAssertions assertionWithMatcher:sufficientlyVisibleMatcher] assert:nil error:&error];
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(error.code, kGREYInteractionElementNotFoundErrorCode);
}

- (void)testIsVisibleWithHalfAlphaAndHidden {
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  view.alpha = 0.5f;
  view.hidden = YES;
  NSError *error;
  id<GREYMatcher> sufficientlyVisibleMatcher = [GREYMatchers matcherForSufficientlyVisible];
  [[GREYAssertions assertionWithMatcher:sufficientlyVisibleMatcher] assert:view error:&error];
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(error.code, kGREYInteractionAssertionFailedErrorCode);
}

- (void)testIsVisibleWithAlphaAndHidden {
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  view.alpha = 1;
  view.hidden = YES;
  NSError *error;
  id<GREYMatcher> sufficientlyVisibleMatcher = [GREYMatchers matcherForSufficientlyVisible];
  [[GREYAssertions assertionWithMatcher:sufficientlyVisibleMatcher] assert:view error:&error];
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(error.code, kGREYInteractionAssertionFailedErrorCode);
}

- (void)testIsVisibleWithoutAlphaAndNotHidden {
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  view.alpha = 0;
  view.hidden = NO;
  NSError *error;
  id<GREYMatcher> sufficientlyVisibleMatcher = [GREYMatchers matcherForSufficientlyVisible];
  [[GREYAssertions assertionWithMatcher:sufficientlyVisibleMatcher] assert:view error:&error];
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(error.code, kGREYInteractionAssertionFailedErrorCode);
}

- (void)testIsVisibleWithoutAlphaAndHidden {
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  view.alpha = 0;
  view.hidden = YES;
  NSError *error;
  id<GREYMatcher> sufficientlyVisibleMatcher = [GREYMatchers matcherForSufficientlyVisible];
  [[GREYAssertions assertionWithMatcher:sufficientlyVisibleMatcher] assert:view error:&error];
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(error.code, kGREYInteractionAssertionFailedErrorCode);
}

- (void)testIsVisibleWithLessThanMinimumVisibleAlphaAndNotHidden {
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  view.alpha = 0.009f;
  view.hidden = NO;
  NSError *error;
  id<GREYMatcher> sufficientlyVisibleMatcher = [GREYMatchers matcherForSufficientlyVisible];
  [[GREYAssertions assertionWithMatcher:sufficientlyVisibleMatcher] assert:view error:&error];
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(error.code, kGREYInteractionAssertionFailedErrorCode);
}

- (void)testIsVisibleWithZeroWidth {
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 10)];
  view.alpha = 1;
  view.hidden = NO;
  NSError *error;
  id<GREYMatcher> sufficientlyVisibleMatcher = [GREYMatchers matcherForSufficientlyVisible];
  [[GREYAssertions assertionWithMatcher:sufficientlyVisibleMatcher] assert:view error:&error];
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(error.code, kGREYInteractionAssertionFailedErrorCode);
}

- (void)testIsVisibleWithZeroHeight {
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 0)];
  view.alpha = 1;
  view.hidden = NO;
  NSError *error;
  id<GREYMatcher> sufficientlyVisibleMatcher = [GREYMatchers matcherForSufficientlyVisible];
  [[GREYAssertions assertionWithMatcher:sufficientlyVisibleMatcher] assert:view error:&error];
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(error.code, kGREYInteractionAssertionFailedErrorCode);
}

- (void)testIsVisibleWithZeroWidthAndHeight {
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
  view.alpha = 1;
  view.hidden = NO;
  NSError *error;
  id<GREYMatcher> sufficientlyVisibleMatcher = [GREYMatchers matcherForSufficientlyVisible];
  [[GREYAssertions assertionWithMatcher:sufficientlyVisibleMatcher] assert:view error:&error];
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(error.code, kGREYInteractionAssertionFailedErrorCode);
}

- (void)testIsNotVisibleWithAlphaAndHidden {
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  view.alpha = 1;
  view.hidden = YES;
  NSError *error;
  id<GREYMatcher> notVisibleMatcher = [GREYMatchers matcherForNotVisible];
  [[GREYAssertions assertionWithMatcher:notVisibleMatcher] assert:view error:&error];
  XCTAssertNil(error);
}

- (void)testIsNotVisibleWithLessThanMinimumVisibleAlphaAndNotHidden {
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  view.alpha = 0.009f;
  view.hidden = NO;
  NSError *error;

  id<GREYMatcher> notVisibleMatcher = [GREYMatchers matcherForNotVisible];
  [[GREYAssertions assertionWithMatcher:notVisibleMatcher] assert:view error:&error];
  XCTAssertNil(error);
}

- (void)testIsNotVisibleWithHalfAlphaAndNotHidden {
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  view.alpha = 0.009f;
  view.hidden = NO;
  NSError *error;

  id<GREYMatcher> notVisibleMatcher = [GREYMatchers matcherForNotVisible];
  [[GREYAssertions assertionWithMatcher:notVisibleMatcher] assert:view error:&error];
  XCTAssertNil(error);
}

- (void)testIsNotVisibleWithHalfAlphaAndHidden {
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  view.alpha = 0.5f;
  view.hidden = YES;
  NSError *error;

  id<GREYMatcher> notVisibleMatcher = [GREYMatchers matcherForNotVisible];
  [[GREYAssertions assertionWithMatcher:notVisibleMatcher] assert:view error:&error];
  XCTAssertNil(error);
}

- (void)testIsNotVisibleWithoutAlphaAndNotHidden {
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  view.alpha = 0;
  view.hidden = NO;
  NSError *error;

  id<GREYMatcher> notVisibleMatcher = [GREYMatchers matcherForNotVisible];
  [[GREYAssertions assertionWithMatcher:notVisibleMatcher] assert:view error:&error];
  XCTAssertNil(error);
}

- (void)testIsNotVisibleWithoutAlphaAndHidden {
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  view.alpha = 0;
  view.hidden = YES;
  NSError *error;
  id<GREYMatcher> notVisibleMatcher = [GREYMatchers matcherForNotVisible];
  [[GREYAssertions assertionWithMatcher:notVisibleMatcher] assert:view error:&error];
  XCTAssertNil(error);
}

- (void)testAllOfMatcherWithNil {
  UIView *view = [[UIView alloc] init];
  NSError *error;

  NSArray *matcherArray = @[
    [GREYMatchers matcherForEqualTo:view],
    [GREYMatchers matcherForNotNil],
  ];
  id<GREYMatcher> allOfMatcher = [[GREYAllOf alloc] initWithMatchers:matcherArray];
  id<GREYAssertion> assertion = [GREYAssertions assertionWithMatcher:allOfMatcher];
  [assertion assert:nil error:&error];
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(error.code, kGREYInteractionElementNotFoundErrorCode);
}

- (void)testAllOfMatcherWithView {
  UIView *view = [[UIView alloc] init];
  NSArray *matcherArray = @[
    [GREYMatchers matcherForEqualTo:view],
    [GREYMatchers matcherForNotNil],
  ];
  id<GREYMatcher> allOfMatcher = [[GREYAllOf alloc] initWithMatchers:matcherArray];
  NSError *error;

  [[GREYAssertions assertionWithMatcher:allOfMatcher] assert:view error:&error];
  XCTAssertNil(error);
}

- (void)testAssertionForIsNilMatcherWithNil {
  NSError *error;
  id<GREYMatcher> matcherForNil = [GREYMatchers matcherForNil];
  [[GREYAssertions assertionWithMatcher:matcherForNil] assert:nil error:&error];
  XCTAssertNil(error);
}

- (void)testAssertionForIsNilMatcherWithView {
  NSError *error;

  UIView *view = [[UIView alloc] init];
  id<GREYMatcher> matcherForNil = [GREYMatchers matcherForNil];
  id<GREYAssertion> assertion = [GREYAssertions assertionWithMatcher:matcherForNil];
  [assertion assert:view error:&error];
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(error.code, kGREYInteractionAssertionFailedErrorCode);
}

- (void)testAssertionForIsNotNilMatcherWithNil {
  NSError *error;

  id<GREYMatcher> matcherForNotNil = [GREYMatchers matcherForNotNil];
  id<GREYAssertion> assertion = [GREYAssertions assertionWithMatcher:matcherForNotNil];
  [assertion assert:nil error:&error];
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(error.code, kGREYInteractionElementNotFoundErrorCode);
}

- (void)testAssertionForIsNotNilMatcherWithView {
  NSError *error;
  UIView *view = [[UIView alloc] init];
  id<GREYMatcher> matcherForNotNil = [GREYMatchers matcherForNotNil];
  [[GREYAssertions assertionWithMatcher:matcherForNotNil] assert:view error:&error];
  XCTAssertNil(error);
}

@end
