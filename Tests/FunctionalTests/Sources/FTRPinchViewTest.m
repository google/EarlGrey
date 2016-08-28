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
#import "FTRImageViewController.h"

@interface FTRPinchViewTest : FTRBaseIntegrationTest
@end

@implementation FTRPinchViewTest {
  // Image view frame before pinch action is callled.
  CGRect _imageViewFrameBeforePinch;
  // Image view frame after pinch action is callled.
  CGRect _imageViewFrameAfterPinch;
}

- (void)setUp {
  [super setUp];
  [self openTestViewNamed:@"Pinch Tests"];
}

- (void)testImageViewFrameSizeOnZoomingFastOutward {
  _imageViewFrameBeforePinch = [self imageViewFrame];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Image View")]
      performAction:grey_pinchFastInDirection(kGREYPinchDirectionOutward)];
  _imageViewFrameAfterPinch = [self imageViewFrame];
  XCTAssertGreaterThan(_imageViewFrameAfterPinch.size.width,
                       _imageViewFrameBeforePinch.size.width,
                       @"Frame size of image view should increase on pinching outward");
  XCTAssertGreaterThan(_imageViewFrameAfterPinch.size.height,
                       _imageViewFrameBeforePinch.size.height,
                       @"Frame size of image view should increase on pinching outward");
}

- (void)testImageViewFrameSizeOnZoomingSlowOutward {
  _imageViewFrameBeforePinch = [self imageViewFrame];
  NSLog(@"image view frame before pinch = %@", NSStringFromCGRect(_imageViewFrameBeforePinch));
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Image View")]
      performAction:grey_pinchSlowInDirection(kGREYPinchDirectionOutward)];
  _imageViewFrameAfterPinch = [self imageViewFrame];
  NSLog(@"image view frame after pinch = %@", NSStringFromCGRect(_imageViewFrameAfterPinch));
  XCTAssertGreaterThan(_imageViewFrameAfterPinch.size.width,
                       _imageViewFrameBeforePinch.size.width,
                       @"Frame size of image view should increase on pinching outward");
  XCTAssertGreaterThan(_imageViewFrameAfterPinch.size.height,
                       _imageViewFrameBeforePinch.size.height,
                       @"Frame size of image view should increase on pinching outward");
}

- (void)testImageViewFrameSizeOnZoomingFastInward {
  _imageViewFrameBeforePinch = [self imageViewFrame];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Image View")]
      performAction:grey_pinchFastInDirection(kGREYPinchDirectionInward)];
  _imageViewFrameAfterPinch = [self imageViewFrame];
  XCTAssertLessThan(_imageViewFrameAfterPinch.size.width,
                    _imageViewFrameBeforePinch.size.width,
                    @"Frame size of image view should decrease on pinching inward");
  XCTAssertLessThan(_imageViewFrameAfterPinch.size.height,
                    _imageViewFrameBeforePinch.size.height,
                    @"Frame size of image view should decrease on pinching inward");
}

- (void)testImageViewFrameSizeOnZoomingSlowInward {
  _imageViewFrameBeforePinch = [self imageViewFrame];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Image View")]
      performAction:grey_pinchSlowInDirection(kGREYPinchDirectionInward)];
  _imageViewFrameAfterPinch = [self imageViewFrame];
  XCTAssertLessThan(_imageViewFrameAfterPinch.size.width,
                    _imageViewFrameBeforePinch.size.width,
                    @"Frame size of image view should decrease on pinching inward");
  XCTAssertLessThan(_imageViewFrameAfterPinch.size.height,
                    _imageViewFrameBeforePinch.size.height,
                    @"Frame size of image view should decrease on pinching inward");
}

#pragma mark - Private

// Returns the image view controller frame.
- (CGRect)imageViewFrame {
  UIWindow *delegateWindow = [UIApplication sharedApplication].delegate.window;
  UINavigationController *rootNC = (UINavigationController *)[delegateWindow rootViewController];

  FTRImageViewController *imageVC = nil;
  for (UIViewController *controller in rootNC.viewControllers) {
    if ([controller isKindOfClass:[FTRImageViewController class]]) {
      imageVC = (FTRImageViewController *)controller;
    }
  }
  return imageVC.view.frame;
}

@end
