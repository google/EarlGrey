//
// Copyright 2021 Google Inc.
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

#import "ActiveAnimationsViewController.h"

@implementation ActiveAnimationsViewController {
  NSMutableArray *_animatingViewSubLayers;
  NSMutableArray *_animatingViewRecurringSublayers;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.activityIndicator.hidesWhenStopped = NO;
  self.activityIndicator.isAccessibilityElement = YES;
  self.activityIndicator.accessibilityIdentifier = @"activityIndicator";
  self.animatingView.accessibilityIdentifier = @"animatingView";
  self.animateAnimatingViewButton.accessibilityIdentifier = @"animateAnimatingViewButton";
  self.animateActivityIndicatorButton.accessibilityIdentifier = @"animateActivityIndicatorButton";
  self.hideAnimatingViewButton.accessibilityIdentifier = @"hideAnimatingViewButton";
  self.hideActivityIndicatorButton.accessibilityIdentifier = @"hideActivityIndicatorButton";
  self.addMoreLayersToAnimatingViewButton.accessibilityIdentifier = @"addMoreLayersButton";
  self.addMoreRecurringLayersButton.accessibilityIdentifier = @"addMoreRecurringLayersButton";
  self.hideCertainLayersButton.accessibilityIdentifier = @"hideCertainLayersButton";
  self.specialAnimationsButton.accessibilityIdentifier = @"specialAnimationsButton";

  [self.animateAnimatingViewButton addTarget:self
                                      action:@selector(animateAnimatingView)
                            forControlEvents:UIControlEventTouchUpInside];
  [self.animateActivityIndicatorButton addTarget:self
                                          action:@selector(animateActivityIndicator)
                                forControlEvents:UIControlEventTouchUpInside];
  [self.hideAnimatingViewButton addTarget:self
                                   action:@selector(hideAnimatingView)
                         forControlEvents:UIControlEventTouchUpInside];
  [self.hideActivityIndicatorButton addTarget:self
                                       action:@selector(hideActivityIndicator)
                             forControlEvents:UIControlEventTouchUpInside];
  [self.addMoreLayersToAnimatingViewButton addTarget:self
                                              action:@selector(addMoreLayersToAnimatingView)
                                    forControlEvents:UIControlEventTouchUpInside];
  [self.addMoreRecurringLayersButton addTarget:self
                                        action:@selector(addMoreLayersToFirstAnimatingViewQuadrant)
                              forControlEvents:UIControlEventTouchUpInside];
  [self.hideCertainLayersButton addTarget:self
                                   action:@selector(toggleCertainLayersBeingHidden)
                         forControlEvents:UIControlEventTouchUpInside];
  [self.specialAnimationsButton addTarget:self
                                   action:@selector(addSpecialAnimation)
                         forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - Button Handlers

- (void)hideActivityIndicator {
  self.activityIndicator.hidden = !self.activityIndicator.hidden;
}

- (void)hideAnimatingView {
  self.animatingView.hidden = !self.animatingView.hidden;
}

- (void)animateActivityIndicator {
  self.activityIndicator.isAnimating ? [self.activityIndicator stopAnimating]
                                     : [self.activityIndicator startAnimating];
}

/**
 *  Adds animations to the animatingView's layer and any sublayers if needed. Each animation
 *  is of 4 seconds except the last one added to the sublayers which is 8.
 */
- (void)animateAnimatingView {
  NSArray *subAnimationsArray = _animatingViewSubLayers ?: _animatingViewRecurringSublayers;
  if ([self.animatingView.layer animationForKey:@"rotateView"]) {
    [self.animatingView.layer removeAnimationForKey:@"rotateView"];
    if (subAnimationsArray) {
      for (CALayer *layer in subAnimationsArray) {
        [layer removeAnimationForKey:@"rotateView"];
      }
    }
  } else {
    [self addAnimationToLayer:self.animatingView.layer withDuration:4];
    if (subAnimationsArray) {
      for (NSUInteger i = 0; i < subAnimationsArray.count; i++) {
        CALayer *layer = subAnimationsArray[i];
        if (layer == [subAnimationsArray lastObject]) {
          [self addAnimationToLayer:layer withDuration:8];
        } else {
          [self addAnimationToLayer:layer withDuration:4];
        }
      }
    }
  }
}

- (void)addMoreLayersToAnimatingView {
  _animatingViewSubLayers = [[NSMutableArray alloc] init];
  [self addQuadrantLayersToLayer:self.animatingView.layer heldInArray:_animatingViewSubLayers];
}

- (void)addMoreLayersToFirstAnimatingViewQuadrant {
  _animatingViewRecurringSublayers = [[NSMutableArray alloc] init];
  [self addRecurringLayersToLayer:self.animatingView.layer
                      heldInArray:_animatingViewRecurringSublayers];
}

#pragma mark - Custom animation methods

/**
 *  Adds four quadrant layers on the @c animatingView's layer.
 *
 *  @param layer A CALayer to add the recurring layers to.
 *  @param array An NSMutableArray to store the added layers to.
 */
- (void)addQuadrantLayersToLayer:(CALayer *)layer heldInArray:(NSMutableArray *)array {
  CALayer *subLayer1 = [[CALayer alloc] init];
  subLayer1.frame = CGRectMake(0, 0, layer.frame.size.width / 2, layer.frame.size.height / 2);
  subLayer1.backgroundColor = [UIColor blueColor].CGColor;
  [array addObject:subLayer1];

  CALayer *subLayer2 = [[CALayer alloc] init];
  subLayer2.frame = CGRectMake(layer.frame.size.width / 2, 0, layer.frame.size.width / 2,
                               layer.frame.size.height / 2);
  subLayer2.backgroundColor = [UIColor yellowColor].CGColor;
  [array addObject:subLayer2];

  CALayer *subLayer3 = [[CALayer alloc] init];
  subLayer3.frame = CGRectMake(0, layer.frame.size.height / 2, layer.frame.size.width / 2,
                               layer.frame.size.height / 2);
  subLayer3.backgroundColor = [UIColor greenColor].CGColor;
  [array addObject:subLayer3];

  CALayer *subLayer4 = [[CALayer alloc] init];
  subLayer4.frame = CGRectMake(layer.frame.size.width / 2, layer.frame.size.height / 2,
                               layer.frame.size.width / 2, layer.frame.size.height / 2);
  subLayer4.backgroundColor = [UIColor cyanColor].CGColor;
  [array addObject:subLayer4];

  [layer addSublayer:subLayer1];
  [layer addSublayer:subLayer2];
  [layer addSublayer:subLayer3];
  [layer addSublayer:subLayer4];
}

/**
 *  Adds layers one on top of another to the specified @c layer.
 *
 *  @param layer A CALayer to add the recurring layers to.
 *  @param array An NSMutableArray to store the added layers to.
 */
- (void)addRecurringLayersToLayer:(CALayer *)layer heldInArray:(NSMutableArray *)array {
  [array addObject:layer];
  for (int i = 0; i < 4; i++) {
    CALayer *subLayer = [[CALayer alloc] init];
    subLayer.frame = [self rectWithProportionSmallerThanCGRect:layer.frame byAmount:i];
    subLayer.backgroundColor =
        (i % 2 == 0) ? [UIColor orangeColor].CGColor : [UIColor magentaColor].CGColor;
    [[array lastObject] addSublayer:subLayer];
    [array addObject:subLayer];
  }
}

/**
 *  @return A CGRect which a size proportionally smaller to specified @c frame by the specified
 *          @amount.
 *
 *  @param frame  The frame to make proportionally smaller.
 *  @param amount The proportion to make the CGRect smaller.
 */
- (CGRect)rectWithProportionSmallerThanCGRect:(CGRect)frame byAmount:(CGFloat)amount {
  return CGRectMake(0, 0, frame.size.width / (amount + 1), frame.size.height / (amount + 1));
}

/**
 *  Adds an animation to the @c layer with the specified duration.
 *
 *  @param layer    A CALayer to add the animation to.
 *  @param duration The duration of the animation.
 */
- (void)addAnimationToLayer:(CALayer *)layer withDuration:(CFTimeInterval)duration {
  [layer addAnimation:[self animationWithDuration:duration] forKey:@"rotateView"];
}

/**
 *  Hides two of the added layers, one of which has the longer animation of 8 seconds.
 */
- (void)toggleCertainLayersBeingHidden {
  NSArray *subAnimationsArray = _animatingViewSubLayers ?: _animatingViewRecurringSublayers;
  NSAssert(subAnimationsArray, @"No Sublayers Present");
  for (NSUInteger i = 0; i < subAnimationsArray.count; i++) {
    CALayer *layer = subAnimationsArray[i];
    if (i % 2 != 0) {
      layer.hidden = !layer.hidden;
    }
  }
}

/**
 *  Adds an animation to the @c animatingView which will adds another animation on completion.
 */
- (void)addSpecialAnimation {
  [CATransaction begin];
  [CATransaction setCompletionBlock:^{
    [self.animatingView.layer addAnimation:[self animationWithDuration:12] forKey:@"rotateView"];
  }];
  [self.animatingView.layer addAnimation:[self animationWithDuration:5] forKey:@"rotateView"];
  [CATransaction commit];
}

/**
 *  @return A CABasicAnimation which rotates twice around itself in the specified @c duration.
 *
 *  @param duration The duration of the animation.
 */
- (CABasicAnimation *)animationWithDuration:(NSTimeInterval)duration {
  CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
  animation.duration = duration;
  animation.fromValue = @(0.0);
  animation.toValue = @(M_PI * 2.0);
  return animation;
}

@end
