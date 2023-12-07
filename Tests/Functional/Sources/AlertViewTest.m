//
// Copyright 2016 Google Inc.
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

@interface AlertViewTest : BaseIntegrationTest
@end

@implementation AlertViewTest

- (void)setUp {
  [super setUp];
  [self openTestViewNamed:@"Alert Views"];
}

- (void)testSimpleAlertView {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Simple Alert")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Flee")] performAction:GREYTap()];
}

- (void)testMultiOptionAlertView {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Multi-Option Alert")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Use Slingshot")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Multi-Option Alert")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Use Phaser")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Roger")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Multi-Option Alert")]
      assertWithMatcher:GREYSufficientlyVisible()];
}

- (void)testAlertViewChain {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Multi-Option Alert")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Use Phaser")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Roger")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Multi-Option Alert")]
      assertWithMatcher:GREYSufficientlyVisible()];
}

/** Verifies styled alert view pops up and interactible with EarlGrey. */
- (void)testStyledAlertView {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Styled Alert")] performAction:GREYTap()];

  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Login")]
      performAction:GREYTypeText(@"test_user")];
  [[EarlGrey selectElementWithMatcher:GREYText(@"test_user")] assertWithMatcher:GREYNotNil()];

  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Password")]
      performAction:GREYTypeText(@"test_pwd")];
  [[EarlGrey selectElementWithMatcher:GREYText(@"test_pwd")] assertWithMatcher:GREYNotNil()];

  [[EarlGrey selectElementWithMatcher:GREYText(@"Leave")] performAction:GREYTap()];
  NSError *error;
  [[EarlGrey selectElementWithMatcher:GREYText(@"Roger")] assertWithMatcher:GREYNil()
                                                                       error:&error];
  if (error) {
    [[EarlGrey selectElementWithMatcher:GREYText(@"Roger")] performAction:GREYTap()];
  }
}

@end
