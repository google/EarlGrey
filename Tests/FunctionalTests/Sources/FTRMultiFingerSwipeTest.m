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

#import "FTRBaseIntegrationTest.h"

@interface FTRMultiFingerSwipeTest : FTRBaseIntegrationTest
@end

@implementation FTRMultiFingerSwipeTest

- (CGPoint)referencePoint {
    return CGPointMake(150, 125);
}
    
- (void)setUp {
    [super setUp];
    [self openTestViewNamed:@"Multi finger swipe gestures"];
}
    
- (GREYMultiFingerSwipeAction *)swipeActionForDirection:(GREYDirection)direction usingNumberOfFingers:(NSUInteger)fingerCount {
    return [[GREYMultiFingerSwipeAction alloc] initWithDirection:direction duration:0.2 numberOfFingers:fingerCount];
}

#pragma mark - Two fingers
    
- (void)testTwoFingerSwipeLeft {
    
    GREYMultiFingerSwipeAction *multiSwipe = [self swipeActionForDirection:kGREYDirectionLeft usingNumberOfFingers:2];
    
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gestureRecognizerBox")]
     performAction:multiSwipe];
    
    [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Swiped with 2 fingers Left")]
     assertWithMatcher:grey_sufficientlyVisible()];
    
}

- (void)testTwoFingerSwipeRight {
    
    GREYMultiFingerSwipeAction *multiSwipe = [self swipeActionForDirection:kGREYDirectionRight usingNumberOfFingers:2];
    
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gestureRecognizerBox")]
     performAction:multiSwipe];
    
    [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Swiped with 2 fingers Right")]
     assertWithMatcher:grey_sufficientlyVisible()];
    
}
    
- (void)testTwoFingerSwipeUp {
    
    GREYMultiFingerSwipeAction *multiSwipe = [self swipeActionForDirection:kGREYDirectionUp usingNumberOfFingers:2];
    
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gestureRecognizerBox")]
     performAction:multiSwipe];
    
    [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Swiped with 2 fingers Up")]
     assertWithMatcher:grey_sufficientlyVisible()];
    
}
    
- (void)testTwoFingerSwipeDown {
    
    GREYMultiFingerSwipeAction *multiSwipe = [self swipeActionForDirection:kGREYDirectionDown usingNumberOfFingers:2];
    
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gestureRecognizerBox")]
     performAction:multiSwipe];
    
    [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Swiped with 2 fingers Down")]
     assertWithMatcher:grey_sufficientlyVisible()];
    
}

#pragma mark - Three fingers

- (void)testThreeFingerSwipeLeft {
    
    GREYMultiFingerSwipeAction *multiSwipe = [self swipeActionForDirection:kGREYDirectionLeft usingNumberOfFingers:3];
    
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gestureRecognizerBox")]
     performAction:multiSwipe];
    
    [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Swiped with 3 fingers Left")]
     assertWithMatcher:grey_sufficientlyVisible()];
    
}

- (void)testThreeFingerSwipeRight {
    
    GREYMultiFingerSwipeAction *multiSwipe = [self swipeActionForDirection:kGREYDirectionRight usingNumberOfFingers:3];
    
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gestureRecognizerBox")]
     performAction:multiSwipe];
    
    [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Swiped with 3 fingers Right")]
     assertWithMatcher:grey_sufficientlyVisible()];
    
}

- (void)testThreeFingerSwipeUp {
    
    GREYMultiFingerSwipeAction *multiSwipe = [self swipeActionForDirection:kGREYDirectionUp usingNumberOfFingers:3];
    
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gestureRecognizerBox")]
     performAction:multiSwipe];
    
    [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Swiped with 3 fingers Up")]
     assertWithMatcher:grey_sufficientlyVisible()];
    
}

- (void)testThreeFingerSwipeDown {
    
    GREYMultiFingerSwipeAction *multiSwipe = [self swipeActionForDirection:kGREYDirectionDown usingNumberOfFingers:3];
    
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gestureRecognizerBox")]
     performAction:multiSwipe];
    
    [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Swiped with 3 fingers Down")]
     assertWithMatcher:grey_sufficientlyVisible()];
    
}

#pragma mark - Four fingers

- (void)testFourFingerSwipeLeft {
    
    GREYMultiFingerSwipeAction *multiSwipe = [self swipeActionForDirection:kGREYDirectionLeft usingNumberOfFingers:4];
    
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gestureRecognizerBox")]
     performAction:multiSwipe];
    
    [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Swiped with 4 fingers Left")]
     assertWithMatcher:grey_sufficientlyVisible()];
    
}

- (void)testFourFingerSwipeRight {
    
    GREYMultiFingerSwipeAction *multiSwipe = [self swipeActionForDirection:kGREYDirectionRight usingNumberOfFingers:4];
    
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gestureRecognizerBox")]
     performAction:multiSwipe];
    
    [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Swiped with 4 fingers Right")]
     assertWithMatcher:grey_sufficientlyVisible()];
    
}

- (void)testFourFingerSwipeUp {
    
    GREYMultiFingerSwipeAction *multiSwipe = [self swipeActionForDirection:kGREYDirectionUp usingNumberOfFingers:4];
    
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gestureRecognizerBox")]
     performAction:multiSwipe];
    
    [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Swiped with 4 fingers Up")]
     assertWithMatcher:grey_sufficientlyVisible()];
    
}

- (void)testFourFingerSwipeDown {
    
    GREYMultiFingerSwipeAction *multiSwipe = [self swipeActionForDirection:kGREYDirectionDown usingNumberOfFingers:4];
    
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gestureRecognizerBox")]
     performAction:multiSwipe];
    
    [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Swiped with 4 fingers Down")]
     assertWithMatcher:grey_sufficientlyVisible()];
    
}


@end
