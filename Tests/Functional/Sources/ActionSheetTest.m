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
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"simpleActionSheetButton")]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Action Sheet")]
      assertWithMatcher:grey_sufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Simple Button")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Action Sheet Button Pressed")]
      assertWithMatcher:grey_sufficientlyVisible()];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"simpleActionSheetButton")]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Action Sheet")]
      assertWithMatcher:grey_sufficientlyVisible()];
  // TODO: Add custom tap support for when adding iPad support. // NOLINT
  [[EarlGrey selectElementWithMatcher:grey_text(@"Cancel")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Actions Verified Here")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

- (void)testMultipleActionSheet {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"multipleActionSheetButton")]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Action Sheet")]
      assertWithMatcher:grey_sufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Simple Button")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Action Sheet Button Pressed")]
      assertWithMatcher:grey_sufficientlyVisible()];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"multipleActionSheetButton")]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Action Sheet")]
      assertWithMatcher:grey_sufficientlyVisible()];
  // TODO: Add custom tap support for when adding iPad support. // NOLINT
  [[EarlGrey selectElementWithMatcher:grey_text(@"Cancel")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Actions Verified Here")]
      assertWithMatcher:grey_sufficientlyVisible()];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"multipleActionSheetButton")]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Action Sheet")]
      assertWithMatcher:grey_sufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Hide Button")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"multipleActionSheetButton")]
      assertWithMatcher:grey_notVisible()];
}

@end
