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

#import <UIKit/UIKit.h>
#import "EarlGrey.h"
#import "GREYHostApplicationDistantObject+GestureTest.h"
#import "BaseIntegrationTest.h"

@interface GestureTest : BaseIntegrationTest
@end

@implementation GestureTest

- (void)setUp {
  [super setUp];
  [self openTestViewNamed:@"Gesture Tests"];
}

- (void)testSingleTap {
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Grey Box")]
      performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"single tap")]
      assertWithMatcher:GREYSufficientlyVisible()];
}

- (void)testSingleTapAtPoint {
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Grey Box")]
      performAction:GREYTapAtPoint(CGPointMake(12.0, 50.0))];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"single tap")]
      assertWithMatcher:GREYSufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"x:12.0 - y:50.0")]
      assertWithMatcher:GREYSufficientlyVisible()];

  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Grey Box")]
      performAction:GREYTapAtPoint(CGPointZero)];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"single tap")]
      assertWithMatcher:GREYSufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"x:0.0 - y:0.0")]
      assertWithMatcher:GREYSufficientlyVisible()];
}

- (void)testDoubleTap {
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Grey Box")]
      performAction:GREYDoubleTap()];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"double tap")]
      assertWithMatcher:GREYSufficientlyVisible()];
}

- (void)testDoubleTapAtPoint {
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Grey Box")]
      performAction:GREYDoubleTapAtPoint(CGPointMake(50, 50))];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"double tap")]
      assertWithMatcher:GREYSufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"x:50.0 - y:50.0")]
      assertWithMatcher:GREYSufficientlyVisible()];

  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Grey Box")]
      performAction:GREYDoubleTapAtPoint(CGPointMake(125, 10))];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"double tap")]
      assertWithMatcher:GREYSufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"x:125.0 - y:10.0")]
      assertWithMatcher:GREYSufficientlyVisible()];
}

- (void)testLongPress {
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Grey Box")]
      performAction:GREYLongPress()];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"single long press")]
      assertWithMatcher:GREYSufficientlyVisible()];
}

- (void)testLongPressWithDuration {
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Grey Box")]
      performAction:GREYLongPressWithDuration(1.0)];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"single long press")]
      assertWithMatcher:GREYSufficientlyVisible()];
}

- (void)testLongPressWithDurationAtPoint {
  EDORemoteVariable<NSValue *> *remoteBounds = [[EDORemoteVariable alloc] init];
  id<GREYAction> boundsFinder =
      [GREYHostApplicationDistantObject.sharedInstance actionForFindingElementBounds:remoteBounds];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Grey Box")]
      performAction:boundsFinder];

  CGRect targetBounds = remoteBounds.object.CGRectValue;
  // Verify tapping outside the bounds does not cause long press.
  CGFloat midX = CGRectGetMidX(targetBounds);
  CGFloat midY = CGRectGetMidY(targetBounds);
  CGPoint outsidePoints[4] = {CGPointMake(CGRectGetMinX(targetBounds) - 1, midY),
                              CGPointMake(CGRectGetMaxX(targetBounds) + 1, midY),
                              CGPointMake(midX, CGRectGetMinY(targetBounds) - 1),
                              CGPointMake(midX, CGRectGetMaxY(targetBounds) + 1)};
  for (NSInteger i = 0; i < 4; i++) {
    [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Grey Box")]
        performAction:GREYLongPressAtPointWithDuration(outsidePoints[i], 1.0)];
    [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"single long press")]
        assertWithMatcher:GREYNil()];
  }

  // Verify that tapping inside the bounds causes the long press.
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Grey Box")]
      performAction:GREYLongPressAtPointWithDuration(CGPointMake(midX, midX), 1.0)];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"single long press")]
      assertWithMatcher:GREYSufficientlyVisible()];
}

- (void)testSwipeWorksInAllDirectionsInPortraitMode {
  [self assertSwipeWorksInAllDirections];
}

- (void)testSwipeWorksInAllDirectionsInUpsideDownMode {
  if (@available(iOS 16.0, *)) {
    // PortraitUpsideDown mode is unavailable in iOS16
    return;
  }
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationPortraitUpsideDown error:nil];
  [self assertSwipeWorksInAllDirections];
}

- (void)testSwipeWorksInAllDirectionsInLandscapeLeftMode {
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeLeft error:nil];
  [self assertSwipeWorksInAllDirections];
}

- (void)testSwipeWorksInAllDirectionsInLandscapeRightMode {
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeRight error:nil];
  [self assertSwipeWorksInAllDirections];
}

- (void)testSwipeOnWindow {
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Window swipes start here")]
      performAction:GREYSwipeFastInDirection(kGREYDirectionUp)];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"swipe up on window")]
      assertWithMatcher:GREYSufficientlyVisible()];

  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Window swipes start here")]
      performAction:GREYSwipeFastInDirection(kGREYDirectionDown)];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"swipe down on window")]
      assertWithMatcher:GREYSufficientlyVisible()];

  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Window swipes start here")]
      performAction:GREYSwipeFastInDirection(kGREYDirectionLeft)];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"swipe left on window")]
      assertWithMatcher:GREYSufficientlyVisible()];

  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Window swipes start here")]
      performAction:GREYSwipeFastInDirection(kGREYDirectionRight)];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"swipe right on window")]
      assertWithMatcher:GREYSufficientlyVisible()];
}

- (void)testSwipeWithLocationForAllDirections {
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Grey Box")]
      performAction:GREYSwipeFastInDirectionWithStartPoint(kGREYDirectionUp, 0.25, 0.25)];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"swipe up")]
      assertWithMatcher:GREYSufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"x:54.0 - y:49.0")]
      assertWithMatcher:GREYSufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Grey Box")]
      performAction:GREYSwipeFastInDirectionWithStartPoint(kGREYDirectionDown, 0.75, 0.75)];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"swipe down")]
      assertWithMatcher:GREYSufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"x:162.0 - y:147.0")]
      assertWithMatcher:GREYSufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Grey Box")]
      performAction:GREYSwipeFastInDirectionWithStartPoint(kGREYDirectionLeft, 0.875, 0.5)];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"swipe left")]
      assertWithMatcher:GREYSufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"x:189.0 - y:98.0")]
      assertWithMatcher:GREYSufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Grey Box")]
      performAction:GREYSwipeFastInDirectionWithStartPoint(kGREYDirectionRight, 0.125, 0.75)];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"swipe right")]
      assertWithMatcher:GREYSufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"x:27.0 - y:147.0")]
      assertWithMatcher:GREYSufficientlyVisible()];
}

- (void)testPinchWorksInAllDirectionsInPortraitMode {
  [self assertPinchWorksInAllDirections];
}

- (void)testPinchWorksInAllDirectionsInUpsideDownMode {
  if (@available(iOS 16.0, *)) {
    // PortraitUpsideDown mode is unavailable in iOS16
    return;
  }
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationPortraitUpsideDown error:nil];
  [self assertPinchWorksInAllDirections];
}

- (void)testPinchWorksInAllDirectionsInLandscapeLeftMode {
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeLeft error:nil];
  [self assertPinchWorksInAllDirections];
}

- (void)testPinchWorksInAllDirectionsInLandscapeRightMode {
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeRight error:nil];
  [self assertPinchWorksInAllDirections];
}

#pragma mark - Private

// Asserts that swipe works in all directions by verifying if the swipe gestures are correctly
// recognized.
- (void)assertSwipeWorksInAllDirections {
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Grey Box")]
      performAction:GREYSwipeFastInDirection(kGREYDirectionUp)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gesture")]
      assertWithMatcher:GREYText(@"swipe up")];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Grey Box")]
      performAction:GREYSwipeSlowInDirection(kGREYDirectionDown)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gesture")]
      assertWithMatcher:GREYText(@"swipe down")];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Grey Box")]
      performAction:GREYSwipeFastInDirection(kGREYDirectionLeft)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gesture")]
      assertWithMatcher:GREYText(@"swipe left")];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Grey Box")]
      performAction:GREYSwipeSlowInDirection(kGREYDirectionRight)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gesture")]
      assertWithMatcher:GREYText(@"swipe right")];
}

// Asserts that Pinch works in all directions by verifying if the pinch gestures are correctly
// recognized.
- (void)assertPinchWorksInAllDirections {
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Grey Box")]
      performAction:GREYPinchFastInDirectionAndAngle(kGREYPinchDirectionOutward,
                                                      kGREYPinchAngleDefault)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gesture")]
      assertWithMatcher:GREYText(@"pinch out")];
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Grey Box")]
      performAction:GREYPinchSlowInDirectionAndAngle(kGREYPinchDirectionInward,
                                                      kGREYPinchAngleDefault)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gesture")]
      assertWithMatcher:GREYText(@"pinch in")];
}

@end
