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

#import <UIKit/UIKit.h>

/**
 *  View controller with a view to which custom layers with animations are added.
 */
@interface ActiveAnimationsViewController : UIViewController

/**
 *  An simple activity indicator.
 */
@property(nonatomic, retain) IBOutlet UIActivityIndicatorView *activityIndicator;

/**
 *  A square red UIView with no animations or so.
 */
@property(nonatomic, retain) IBOutlet UIView *animatingView;

/**
 *  Starts / stops the @c activityIndicator.
 */
@property(nonatomic, retain) IBOutlet UIButton *animateActivityIndicatorButton;

/**
 *  Rotates the @c animatingView twice around itself for 4 seconds.
 */
@property(nonatomic, retain) IBOutlet UIButton *animateAnimatingViewButton;

/**
 *  Hides / Unhides the @c activityIndicator.
 */
@property(nonatomic, retain) IBOutlet UIButton *hideActivityIndicatorButton;

/**
 *  Hides / Unhides the @c animatingView.
 */
@property(nonatomic, retain) IBOutlet UIButton *hideAnimatingViewButton;

/**
 *  Adds 4 sublayers that cover the animating view. If present, each sublayer will rotate
 *  similar to the @c animatingView except one which will rotate 8 seconds.
 */
@property(nonatomic, retain) IBOutlet UIButton *addMoreLayersToAnimatingViewButton;

/**
 *  Adds 4 sublayers one after the other in the left quadrant of the animating view. If present,
 *  each sublayer will rotate similar to the @c animatingView except one which will rotate 8
 *  seconds.
 */
@property(nonatomic, retain) IBOutlet UIButton *addMoreRecurringLayersButton;

/**
 *  Hides two of the added layers, one of which has the longer animation of 8 seconds.
 */
@property(nonatomic, retain) IBOutlet UIButton *hideCertainLayersButton;

/**
 *  Adds an animation to the @c animatingView which will adds another animation on completion.
 */
@property(nonatomic, retain) IBOutlet UIButton *specialAnimationsButton;

@end
