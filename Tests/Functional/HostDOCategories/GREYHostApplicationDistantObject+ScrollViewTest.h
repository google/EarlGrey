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

#import <UIKit/UIKit.h>

#import "EarlGreyApp.h"
#import "GREYHostApplicationDistantObject.h"

/** GREYHostApplicationDistantObject extension for the scroll view test. */
@interface GREYHostApplicationDistantObject (ScrollViewTest)

/**
 *  @return A GREYAction that makes a setContentOffset:animated: call on an element of type
 *          UIScrollView.
 */
- (id<GREYAction>)actionForSetScrollViewContentOffSet:(CGPoint)offset animated:(BOOL)animated;

/**
 *  @return A GREYAction that toggles UIScrollView.bounces.
 */
- (id<GREYAction>)actionForToggleBounces;

/**
 *  @return A GREYAssertion that the scroll view is partially visible.
 */
- (id<GREYAssertion>)assertionWithPartiallyVisible;

@end
