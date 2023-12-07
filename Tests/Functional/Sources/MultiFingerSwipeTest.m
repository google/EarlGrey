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

@interface MultiFingerSwipeTest : BaseIntegrationTest
@end

@implementation MultiFingerSwipeTest

- (void)setUp {
  [super setUp];
  [self openTestViewNamed:@"Multi finger swipe gestures"];
}

#pragma mark - Two fingers

- (void)testTwoFingerSwipeLeft {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gestureRecognizerBox")]
      performAction:GREYMultiFingerSwipeFastInDirection(kGREYDirectionLeft, 2)];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Swiped with 2 fingers Left")]
      assertWithMatcher:GREYSufficientlyVisible()];
}

- (void)testTwoFingerSwipeRight {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gestureRecognizerBox")]
      performAction:GREYMultiFingerSwipeFastInDirection(kGREYDirectionRight, 2)];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Swiped with 2 fingers Right")]
      assertWithMatcher:GREYSufficientlyVisible()];
}

- (void)testTwoFingerSwipeUp {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gestureRecognizerBox")]
      performAction:GREYMultiFingerSwipeFastInDirection(kGREYDirectionUp, 2)];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Swiped with 2 fingers Up")]
      assertWithMatcher:GREYSufficientlyVisible()];
}

- (void)testTwoFingerSwipeDown {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gestureRecognizerBox")]
      performAction:GREYMultiFingerSwipeFastInDirection(kGREYDirectionDown, 2)];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Swiped with 2 fingers Down")]
      assertWithMatcher:GREYSufficientlyVisible()];
}

#pragma mark - Three fingers

- (void)testThreeFingerSwipeLeft {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gestureRecognizerBox")]
      performAction:GREYMultiFingerSwipeFastInDirection(kGREYDirectionLeft, 3)];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Swiped with 3 fingers Left")]
      assertWithMatcher:GREYSufficientlyVisible()];
}

- (void)testThreeFingerSwipeRight {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gestureRecognizerBox")]
      performAction:GREYMultiFingerSwipeFastInDirection(kGREYDirectionRight, 3)];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Swiped with 3 fingers Right")]
      assertWithMatcher:GREYSufficientlyVisible()];
}

- (void)testThreeFingerSwipeUp {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gestureRecognizerBox")]
      performAction:GREYMultiFingerSwipeFastInDirection(kGREYDirectionUp, 3)];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Swiped with 3 fingers Up")]
      assertWithMatcher:GREYSufficientlyVisible()];
}

- (void)testThreeFingerSwipeDown {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gestureRecognizerBox")]
      performAction:GREYMultiFingerSwipeFastInDirection(kGREYDirectionDown, 3)];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Swiped with 3 fingers Down")]
      assertWithMatcher:GREYSufficientlyVisible()];
}

#pragma mark - Four fingers

- (void)testFourFingerSwipeLeft {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gestureRecognizerBox")]
      performAction:GREYMultiFingerSwipeFastInDirection(kGREYDirectionLeft, 4)];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Swiped with 4 fingers Left")]
      assertWithMatcher:GREYSufficientlyVisible()];
}

- (void)testFourFingerSwipeRight {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gestureRecognizerBox")]
      performAction:GREYMultiFingerSwipeFastInDirection(kGREYDirectionRight, 4)];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Swiped with 4 fingers Right")]
      assertWithMatcher:GREYSufficientlyVisible()];
}

- (void)testFourFingerSwipeUp {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gestureRecognizerBox")]
      performAction:GREYMultiFingerSwipeFastInDirection(kGREYDirectionUp, 4)];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Swiped with 4 fingers Up")]
      assertWithMatcher:GREYSufficientlyVisible()];
}

- (void)testFourFingerSwipeDown {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gestureRecognizerBox")]
      performAction:GREYMultiFingerSwipeFastInDirection(kGREYDirectionDown, 4)];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Swiped with 4 fingers Down")]
      assertWithMatcher:GREYSufficientlyVisible()];
}

@end
