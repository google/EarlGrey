//
// Copyright 2018 Google Inc.
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

#import "GREYHostApplicationDistantObject+AnimationsTest.h"
#import "GREYUILibUtils.h"

@implementation GREYHostApplicationDistantObject (AnimationsTest)

- (UIView *)viewWithAnimatingSublayerAddedToView:(UIView *)view forKeyPath:(NSString *)keyPath {
  CGRect appFrame = [[GREYUILibUtils screen] bounds];
  UIView *blueView = [[UIView alloc]
      initWithFrame:CGRectMake(appFrame.size.width / 2, appFrame.size.height / 2, 100, 100)];
  blueView.layer.frame = blueView.frame;
  [blueView setBackgroundColor:[UIColor blueColor]];

  CALayer *subLayer = [[CALayer alloc] init];
  subLayer.frame =
      CGRectMake(0, 0, blueView.layer.frame.size.width / 2, blueView.layer.frame.size.height / 2);
  subLayer.backgroundColor = [UIColor yellowColor].CGColor;
  CALayer *subSubLayer = [[CALayer alloc] init];
  subSubLayer.frame =
      CGRectMake(0, 0, blueView.layer.frame.size.width / 2, blueView.layer.frame.size.height / 2);
  subSubLayer.backgroundColor = [UIColor greenColor].CGColor;
  [blueView.layer addSublayer:subLayer];
  [subLayer addSublayer:subSubLayer];
  [view addSubview:blueView];
  [view bringSubviewToFront:blueView];

  [CATransaction begin];
  CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
  animation.duration = 5;
  animation.fromValue = @(0.0);
  animation.toValue = @(M_PI * 2.0);
  [subSubLayer addAnimation:animation forKey:keyPath];
  [CATransaction commit];
  return blueView;
}

@end
