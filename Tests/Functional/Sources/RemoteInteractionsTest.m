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
#import "EarlGrey.h"
#import "BaseIntegrationTest.h"

/**
 * Tests to ensure the behavior of remotely created assertion and matcher blocks.
 */
@interface RemoteInteractionsTest : BaseIntegrationTest
@end

@implementation RemoteInteractionsTest

- (void)testSimpleRemoteAssertionBlockInTest {
  __block BOOL foo = NO;
  GREYAssertionBlock *assertionBlock =
      [GREYAssertionBlock assertionWithName:@"Test"
                    assertionBlockWithError:^BOOL(id element, NSError *__strong *errorOrNil) {
                      XCTAssertTrue(YES);
                      XCTAssertFalse(foo);
                      foo = YES;
                      XCTAssertTrue(foo);
                      NSArray *array = @[ @(1), @(2) ];
                      XCTAssertEqualObjects(array[0], @(1));
                      XCTAssertEqualObjects(array[1], @(2));
                      if ((UIView *)element != nil) {
                        return YES;
                      } else {
                        return NO;
                      }
                    }];
  XCTAssertEqualObjects([assertionBlock name], @"Test");
  [[EarlGrey selectElementWithMatcher:grey_keyWindow()] assert:assertionBlock];
}

- (void)testSimpleRemoteAssertionBlockError {
  GREYAssertionBlock *assertionBlock =
      [GREYAssertionBlock assertionWithName:@"Test"
                    assertionBlockWithError:^BOOL(id element, NSError *__strong *errorOrNil) {
                      return NO;
                    }];
  XCTAssertEqualObjects([assertionBlock name], @"Test");
  NSError *error;
  [[EarlGrey selectElementWithMatcher:grey_keyWindow()] assert:assertionBlock error:&error];
  XCTAssertNotNil(error);
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
}

- (void)testSimpleRemoteMatcherBlockInTest {
  __block BOOL foo = NO;
  [[EarlGrey selectElementWithMatcher:grey_keyWindow()] assertWithMatcher:GREYNotNil()];
  GREYElementMatcherBlock *matcherBlock = [GREYElementMatcherBlock
      matcherWithMatchesBlock:^BOOL(id _Nonnull element) {
        XCTAssertTrue(YES);
        XCTAssertFalse(foo);
        foo = YES;
        XCTAssertTrue(foo);
        if ((UIView *)element != nil) {
          return YES;
        } else {
          return NO;
        }
      }
      descriptionBlock:^(id<GREYDescription> _Nonnull description) {
        [description appendText:@"Test Block"];
      }];
  XCTAssertEqualObjects([matcherBlock description], @"Test Block");
  [[EarlGrey selectElementWithMatcher:grey_keyWindow()] assertWithMatcher:matcherBlock];
}

- (void)testSimpleRemoteMatcherMadeWithSeparateBlocksInTest {
  __block BOOL foo = NO;
  GREYMatchesBlock matches = ^BOOL(UIView *view) {
    XCTAssertTrue(YES);
    XCTAssertFalse(foo);
    foo = YES;
    XCTAssertTrue(foo);
    return view != nil;
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:@"Test Block"];
  };
  id<GREYMatcher> matcherBlock = [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches
                                                                      descriptionBlock:describe];
  XCTAssertEqualObjects([matcherBlock description], @"Test Block");
  [[EarlGrey selectElementWithMatcher:grey_keyWindow()] assertWithMatcher:matcherBlock];
}

- (void)testSimpleRemoteMatcherError {
  GREYElementMatcherBlock *matcherBlock = [GREYElementMatcherBlock
      matcherWithMatchesBlock:^BOOL(id _Nonnull element) {
        return NO;
      }
      descriptionBlock:^(id<GREYDescription> _Nonnull description) {
        [description appendText:@"Test Block"];
      }];
  NSError *error;
  [[EarlGrey selectElementWithMatcher:matcherBlock] assertWithMatcher:GREYNotNil() error:&error];
  XCTAssertNotNil(error);
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
  [[EarlGrey selectElementWithMatcher:grey_keyWindow()] assertWithMatcher:matcherBlock
                                                                    error:&error];
  XCTAssertNotNil(error);
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
}

- (void)testSimpleRemoteMatcherWithEarlGreyCombinationMatchers {
  GREYElementMatcherBlock *allOfMatcherBlock = [GREYElementMatcherBlock
      matcherWithMatchesBlock:^BOOL(id _Nonnull element) {
        return YES;
      }
      descriptionBlock:^(id<GREYDescription> _Nonnull description) {
        [description appendText:@"Test"];
      }];
  [[EarlGrey selectElementWithMatcher:grey_allOf(grey_keyWindow(), allOfMatcherBlock, nil)]
      assertWithMatcher:grey_allOf(GREYNotNil(), allOfMatcherBlock, nil)];

  GREYElementMatcherBlock *anyOfMatcherBlock = [GREYElementMatcherBlock
      matcherWithMatchesBlock:^BOOL(id _Nonnull element) {
        return [element isKindOfClass:GREY_REMOTE_CLASS_IN_APP(UITableView)];
      }
      descriptionBlock:^(id<GREYDescription> _Nonnull description) {
        [description appendText:@"Test"];
      }];
  [[[EarlGrey selectElementWithMatcher:grey_anyOf(anyOfMatcherBlock, GREYNotNil(), nil)] atIndex:0]
      assertWithMatcher:grey_anyOf(anyOfMatcherBlock, GREYNotNil(), nil)];
}

- (void)testErrorsOnSimpleRemoteMatcherWithEarlGreyCombinationMatchers {
  GREYElementMatcherBlock *allOfMatcherBlock = [GREYElementMatcherBlock
      matcherWithMatchesBlock:^BOOL(id _Nonnull element) {
        return NO;
      }
      descriptionBlock:^(id<GREYDescription> _Nonnull description) {
        [description appendText:@"Test"];
      }];
  NSError *error;
  [[EarlGrey selectElementWithMatcher:grey_allOf(grey_keyWindow(), allOfMatcherBlock, nil)]
      assertWithMatcher:grey_allOf(GREYNotNil(), allOfMatcherBlock, nil)
                  error:&error];
  XCTAssertNotNil(error);
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);

  GREYElementMatcherBlock *anyOfMatcherBlock = [GREYElementMatcherBlock
      matcherWithMatchesBlock:^BOOL(id _Nonnull element) {
        return NO;
      }
      descriptionBlock:^(id<GREYDescription> _Nonnull description) {
        [description appendText:@"Test"];
      }];
  [[[EarlGrey selectElementWithMatcher:grey_anyOf(anyOfMatcherBlock, GREYNotNil(), nil)] atIndex:0]
      assertWithMatcher:grey_anyOf(anyOfMatcherBlock, GREYNotNil(), nil)
                  error:&error];
  XCTAssertNotNil(error);
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
}

@end
