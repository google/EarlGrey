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

#import <XCTest/XCTest.h>

#import "GREYWaitFunctions.h"
#import "EarlGrey.h"
#import "BaseIntegrationTest.h"

@interface ConditionTest : BaseIntegrationTest

@end

@implementation ConditionTest

- (void)setUp {
  [super setUp];
  [self openTestViewNamed:@"Animations"];
}

- (void)tearDown {
  [[EarlGrey selectElementWithMatcher:grey_buttonTitle(@"EarlGrey TestApp")]
      performAction:grey_tap()];
  [super tearDown];
}

- (void)testViewAppearanceTogglingWithGREYCondition {
  // Tap on a button that will make a view disappear after 1 seconds.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"toggleButton")]
      performAction:grey_tap()];

  GREYCondition* condition = [GREYCondition
      conditionWithName:@"waitTillDisappear"
                  block:^BOOL() {
                    NSError* error = nil;
                    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"viewToToggle")]
                        assertWithMatcher:grey_notVisible()
                                    error:&error];
                    return error == nil;
                  }];
  GREYAssertTrue([condition waitWithTimeout:2], @"Element Must be Present before the timeout.");
}

- (void)testGREYConditionFailingWithAnAbsentView {
  GREYCondition* condition = [GREYCondition
      conditionWithName:@"improperCondition"
                  block:^BOOL() {
                    NSError* error = nil;
                    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"non-existent-view")]
                        assertWithMatcher:grey_notVisible()
                                    error:&error];
                    return error == nil;
                  }];
  GREYAssertTrue([condition waitWithTimeout:2],
                 @"Element must not be visible in the allotted time.");
}

@end
