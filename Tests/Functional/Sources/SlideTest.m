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

@interface SlideTest : BaseIntegrationTest

@end

@implementation SlideTest

- (void)setUp {
  [super setUp];
  [self openTestViewNamed:@"Slider Views"];
}

- (void)testSlider1SlidesCloseToZero {
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"slider1")]
      performAction:GREYMoveSliderToValue(0.125f)]
      assertWithMatcher:GREYSliderValueMatcher(
                            GREYCloseTo(0.125f, kGREYAcceptableFloatDifference))];
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"slider1")]
      performAction:GREYMoveSliderToValue(0.0f)]
      assertWithMatcher:GREYSliderValueMatcher(GREYCloseTo(0.0f, 0))];
}

- (void)testSlider2SlidesToValue {
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"slider2")]
      performAction:GREYMoveSliderToValue(15.74f)]
      assertWithMatcher:GREYSliderValueMatcher(
                            GREYCloseTo(15.74f, kGREYAcceptableFloatDifference))];
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"slider2")]
      performAction:GREYMoveSliderToValue(21.03f)]
      assertWithMatcher:GREYSliderValueMatcher(
                            GREYCloseTo(21.03f, kGREYAcceptableFloatDifference))];
}

- (void)testSlider3SlidesToClosestValue {
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"slider3")]
      performAction:GREYMoveSliderToValue(0.0f)]
      assertWithMatcher:GREYSliderValueMatcher(GREYCloseTo(0, 0))];
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"slider3")]
      performAction:GREYMoveSliderToValue(900.0f)]
      assertWithMatcher:GREYSliderValueMatcher(
                            GREYCloseTo(900.0f, kGREYAcceptableFloatDifference))];
}

- (void)testSlider4IsExactlyValue {
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"slider4")]
      performAction:GREYMoveSliderToValue(500000.0f)]
      assertWithMatcher:GREYSliderValueMatcher(
                            GREYCloseTo(500000.0f, kGREYAcceptableFloatDifference))];
}

- (void)testSlider5SnapsToValueWithSnapOnTouchUp {
  // For sliders that "stick" (have tick marks) to certain values, the tester must calculate the
  // tick value that will result by setting the slider to an arbitrary value.
  // See SliderViewController.m for details on how my slider's tick values were calculated.
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"slider5")]
      performAction:GREYMoveSliderToValue(60.0f)]
      assertWithMatcher:GREYSliderValueMatcher(
                            GREYCloseTo(60.3f, kGREYAcceptableFloatDifference))];
}

- (void)testSlider6SnapsToValueWithContinuousSnapping {
  id<GREYMatcher> firstQuadrantSliderValueMatcher =
      GREYSliderValueMatcher(GREYCloseTo(25.0f, kGREYAcceptableFloatDifference));
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"slider6")]
      performAction:GREYMoveSliderToValue(30.0f)]
      assertWithMatcher:firstQuadrantSliderValueMatcher];

  id<GREYMatcher> middleSliderValueMatcher =
      GREYSliderValueMatcher(GREYCloseTo(50.0f, kGREYAcceptableFloatDifference));
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"slider6")]
      performAction:GREYMoveSliderToValue(40.0f)] assertWithMatcher:middleSliderValueMatcher];

  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"slider6")]
      performAction:GREYMoveSliderToValue(50.0f)] assertWithMatcher:middleSliderValueMatcher];
}

- (void)testSmallSliderSnapsToAllValues {
  for (int i = 0; i <= 10; i++) {
    id<GREYMatcher> closeToMatcher = GREYCloseTo((double)i, kGREYAcceptableFloatDifference);
    [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"sliderSnap")]
        performAction:GREYMoveSliderToValue((float)i)]
        assertWithMatcher:GREYSliderValueMatcher(closeToMatcher)];
  }
}

@end
