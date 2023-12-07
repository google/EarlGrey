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

@interface ActivityIndicatorViewTest : BaseIntegrationTest
@end

@implementation ActivityIndicatorViewTest

- (void)setUp {
  [super setUp];
  [self openTestViewNamed:@"Activity Indicator Views"];
}

- (void)testSynchronizationWithStartAndStop {
  [[EarlGrey selectElementWithMatcher:GREYButtonTitle(@"StartStop")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Status")]
      assertWithMatcher:GREYText(@"Stopped")];
}

- (void)testSynchronizationWithStartAndHide {
  [[EarlGrey selectElementWithMatcher:GREYButtonTitle(@"StartHide")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Status")]
      assertWithMatcher:GREYText(@"Hidden")];
}

- (void)testSynchronizationWithStartAndHideWithoutHidesWhenStopped {
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"HidesWhenStopped")]
      performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYButtonTitle(@"StartHide")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Status")]
      assertWithMatcher:GREYText(@"Hidden")];
}

- (void)testSynchronizationWithStartAndRemoveFromSuperview {
  [[EarlGrey selectElementWithMatcher:GREYButtonTitle(@"StartRemove")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Status")]
      assertWithMatcher:GREYText(@"Removed from superview")];
}

- (void)testSynchronizationWithHideAndStartThenStop {
  [[EarlGrey selectElementWithMatcher:GREYButtonTitle(@"HideStartStop")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Status")]
      assertWithMatcher:GREYText(@"Stopped")];
}

@end
