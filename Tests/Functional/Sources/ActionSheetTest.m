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

@interface ActionSheetTest : BaseIntegrationTest
@end

@implementation ActionSheetTest

- (void)setUp {
  [super setUp];
  [self openTestViewNamed:@"Action Sheets"];
}

- (void)testSimpleActionSheet {
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"simpleActionSheetButton")]
      performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Action Sheet")]
      assertWithMatcher:GREYSufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Simple Button")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Action Sheet Button Pressed")]
      assertWithMatcher:GREYSufficientlyVisible()];

  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"simpleActionSheetButton")]
      performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Action Sheet")]
      assertWithMatcher:GREYSufficientlyVisible()];
  // TODO: Add custom tap support for when adding iPad support. // NOLINT
  [[EarlGrey selectElementWithMatcher:GREYText(@"Cancel")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Actions Verified Here")]
      assertWithMatcher:GREYSufficientlyVisible()];
}

- (void)testMultipleActionSheet {
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"multipleActionSheetButton")]
      performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Action Sheet")]
      assertWithMatcher:GREYSufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Simple Button")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Action Sheet Button Pressed")]
      assertWithMatcher:GREYSufficientlyVisible()];

  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"multipleActionSheetButton")]
      performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Action Sheet")]
      assertWithMatcher:GREYSufficientlyVisible()];
  // TODO: Add custom tap support for when adding iPad support. // NOLINT
  [[EarlGrey selectElementWithMatcher:GREYText(@"Cancel")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Actions Verified Here")]
      assertWithMatcher:GREYSufficientlyVisible()];

  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"multipleActionSheetButton")]
      performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Action Sheet")]
      assertWithMatcher:GREYSufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:GREYText(@"Hide Button")] performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"multipleActionSheetButton")]
      assertWithMatcher:GREYNotVisible()];
}

@end
