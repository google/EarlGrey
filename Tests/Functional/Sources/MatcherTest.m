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

@interface MatcherTest : BaseIntegrationTest
@end

@implementation MatcherTest

- (void)testDescendantMatcherWithBasicViews {
  [self openTestViewNamed:@"Basic Views"];

  id<GREYMatcher> matchesAccessibleViewParentOfSimpleLabel =
      grey_allOf(GREYDescendant(GREYAccessibilityLabel(@"Simple Label")),
                 GREYAccessibilityLabel(@"tab2Container"), nil);

  [[EarlGrey selectElementWithMatcher:matchesAccessibleViewParentOfSimpleLabel]
      assertWithMatcher:GREYNotNil()];

  id<GREYMatcher> matchesChildOfParentOfSimpleLabel =
      grey_allOf(GREYAncestor(matchesAccessibleViewParentOfSimpleLabel),
                 GREYKindOfClass([UISwitch class]), nil);
  [[EarlGrey selectElementWithMatcher:matchesChildOfParentOfSimpleLabel]
      assertWithMatcher:GREYAccessibilityLabel(@"Switch")];
}

- (void)testUserInteractionEnabledMatcherForBasicView {
  [self openTestViewNamed:@"Basic Views"];

  [[EarlGrey selectElementWithMatcher:GREYText(@"Tab 2")] performAction:GREYTap()];

  // Simple Label has user interaction enabled set to NO in xib.
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Simple Label")]
      assertWithMatcher:GREYNot(GREYUserInteractionEnabled())];

  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Switch")]
      assertWithMatcher:GREYUserInteractionEnabled()];
}

- (void)testDescendantMatcherWithTableViews {
  [self openTestViewNamed:@"Table Views"];

  id<GREYMatcher> descendantRowMatcher =
      grey_allOf(GREYKindOfClass([UITableViewCell class]),
                 GREYDescendant(GREYAccessibilityLabel(@"Row 1")), nil);

  [[EarlGrey selectElementWithMatcher:descendantRowMatcher] assertWithMatcher:GREYNotNil()];
}

- (void)testDescendantMatcherWithAccessibilityViews {
  [self openTestViewNamed:@"Accessibility Views"];

  id<GREYMatcher> matchesParentOfSquare =
      grey_allOf(GREYDescendant(GREYAccessibilityValue(@"SquareElementValue")),
                 GREYKindOfClassName(@"AccessibleView"), nil);

  [[EarlGrey selectElementWithMatcher:matchesParentOfSquare]
      assertWithMatcher:GREYDescendant(GREYAccessibilityLabel(@"SquareElementLabel"))];
}

- (void)testLayoutWithFloatingPoint {
  [self openTestViewNamed:@"Layout Tests"];

  // Set frame for first view.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"topTextbox")]
      performAction:GREYReplaceText(@"{{10,164.333333333333314},{100,38.666666666666671}}")];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"button")] performAction:GREYTap()];

  // Set frame for second view.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"topTextbox")]
      performAction:GREYReplaceText(@"{{10,124.000000000000004},{100,24.333333333333336}}")];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"button")] performAction:GREYTap()];

  // Layout constaint object to check the accuracy of floating point math.
  GREYLayoutConstraint *below =
      [GREYLayoutConstraint layoutConstraintWithAttribute:kGREYLayoutAttributeTop
                                                relatedBy:kGREYLayoutRelationEqual
                                     toReferenceAttribute:kGREYLayoutAttributeBottom
                                               multiplier:1.0
                                                 constant:16];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"elementID")]
      assertWithMatcher:GREYLayout(@[ below ], grey_accessibilityID(@"referenceElementID"))];
}

@end
