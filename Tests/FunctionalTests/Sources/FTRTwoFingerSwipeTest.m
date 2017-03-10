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

@interface FTRTwoFingerSwipeTest : FTRBaseIntegrationTest
@end

@implementation FTRTwoFingerSwipeTest

- (CGPoint)referencePoint {
    return CGPointMake(150, 125);
}
    
- (void)setUp {
    [super setUp];
    [self openTestViewNamed:@"Gesture Tests"];
}
    
- (GREYMultiFingerSwipeAction *)swipeActionForDirection:(GREYDirection)direction {
    return [[GREYMultiFingerSwipeAction alloc] initWithDirection:direction duration:0.2 numberOfSwipes:2];
}
    
- (void)testTwoFingerSwipeLeft {
    
    GREYMultiFingerSwipeAction *multiSwipe = [self swipeActionForDirection:kGREYDirectionLeft];
    
    [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Grey Box")]
     performAction:multiSwipe];
    
    [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"two finger pan")]
     assertWithMatcher:grey_sufficientlyVisible()];
    
}

- (void)testTwoFingerSwipeRight {
    
    GREYMultiFingerSwipeAction *multiSwipe = [self swipeActionForDirection:kGREYDirectionRight];
    
    [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Grey Box")]
     performAction:multiSwipe];
    
    [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"two finger pan")]
     assertWithMatcher:grey_sufficientlyVisible()];
    
}
    
- (void)testTwoFingerSwipeUp {
    
    GREYMultiFingerSwipeAction *multiSwipe = [self swipeActionForDirection:kGREYDirectionUp];
    
    [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Grey Box")]
     performAction:multiSwipe];
    
    [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"two finger pan")]
     assertWithMatcher:grey_sufficientlyVisible()];
    
}
    
- (void)testTwoFingerSwipeDown {
    
    GREYMultiFingerSwipeAction *multiSwipe = [self swipeActionForDirection:kGREYDirectionDown];
    
    [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Grey Box")]
     performAction:multiSwipe];
    
    [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"two finger pan")]
     assertWithMatcher:grey_sufficientlyVisible()];
    
}


@end
