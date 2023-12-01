//
// Copyright 2022 Google Inc.
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
#import "GREYHostApplicationDistantObject+TwistViewTest.h"
#import "BaseIntegrationTest.h"

// Adjust if this test is flaky.
static const CGFloat kRotationAccuracyThreshold = 0.1;

/**
 * @return The image view controller frame.
 */
static CGFloat GetCurrentGestureViewRotation(void) {
  GREYHostApplicationDistantObject *host = GREYHostApplicationDistantObject.sharedInstance;
  return [host rotationForTwistView];
}

/**
 * Verifies that a view has been rotated by approximately @c expectedAngleDelta degrees based on
 * its rotation angle before and after the twist gesture (within +/- @c kRotationAccuracyThreshold).
 *
 * @param rotationBeforeTwist The view's rotation before the twist gesture.
 * @param rotationAfterTwist  The view's rotation after the twist gesture.
 * @param expectedAngleDelta  The expected relative rotation.
 *
 * @return YES if the angle delta is within a reasonable margin of error of the expected value,
 *         else NO.
 */
static BOOL VerifyRotationAngle(CGFloat rotationBeforeTwist, CGFloat rotationAfterTwist,
                                CGFloat expectedAngleDelta) {
  CGFloat computedRotation = rotationAfterTwist - rotationBeforeTwist;
  CGFloat error = fabs(computedRotation - expectedAngleDelta);
  return error < kRotationAccuracyThreshold;
}

@interface TwistViewTest : BaseIntegrationTest
@end

@implementation TwistViewTest

- (void)setUp {
  [super setUp];
  [self openTestViewNamed:@"Gesture Tests"];
}

- (void)testFastClockwiseRotation {
  CGFloat angleDelta = -kGREYTwistAngleDefault;
  CGFloat rotationBeforeTwist = GetCurrentGestureViewRotation();
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Grey Box")]
      performAction:grey_twistFastWithAngle(angleDelta)];
  CGFloat rotationAfterTwist = GetCurrentGestureViewRotation();
  BOOL success = VerifyRotationAngle(rotationBeforeTwist, rotationAfterTwist, angleDelta);
  GREYAssert(success, @"Rotation before twist - %@ and after twist - %@ must differ by < %@.",
             @(rotationBeforeTwist), @(rotationAfterTwist), @(angleDelta));
}

- (void)testFastCounterClockwiseRotation {
  CGFloat angleDelta = kGREYTwistAngleDefault;
  CGFloat rotationBeforeTwist = GetCurrentGestureViewRotation();
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Grey Box")]
      performAction:grey_twistFastWithAngle(angleDelta)];
  CGFloat rotationAfterTwist = GetCurrentGestureViewRotation();
  BOOL success = VerifyRotationAngle(rotationBeforeTwist, rotationAfterTwist, angleDelta);
  GREYAssert(success, @"Rotation before twist - %@ and after twist - %@ must differ by < %@.",
             @(rotationBeforeTwist), @(rotationAfterTwist), @(angleDelta));
}

- (void)testSlowClockwiseRotation {
  CGFloat angleDelta = -kGREYTwistAngleDefault;
  CGFloat rotationBeforeTwist = GetCurrentGestureViewRotation();
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Grey Box")]
      performAction:grey_twistSlowWithAngle(angleDelta)];
  CGFloat rotationAfterTwist = GetCurrentGestureViewRotation();
  BOOL success = VerifyRotationAngle(rotationBeforeTwist, rotationAfterTwist, angleDelta);
  GREYAssert(success, @"Rotation before twist - %@ and after twist - %@ must differ by < %@.",
             @(rotationBeforeTwist), @(rotationAfterTwist), @(angleDelta));
}

- (void)testSlowCounterClockwiseRotation {
  CGFloat angleDelta = kGREYTwistAngleDefault;
  CGFloat rotationBeforeTwist = GetCurrentGestureViewRotation();
  [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"Grey Box")]
      performAction:grey_twistSlowWithAngle(angleDelta)];
  CGFloat rotationAfterTwist = GetCurrentGestureViewRotation();
  BOOL success = VerifyRotationAngle(rotationBeforeTwist, rotationAfterTwist, angleDelta);
  GREYAssert(success, @"Rotation before twist - %@ and after twist - %@ must differ by < %@.",
             @(rotationBeforeTwist), @(rotationAfterTwist), @(angleDelta));
}

@end
