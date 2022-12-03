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

#import "ExposedForTesting.h"

/** GREYHostApplicationDistantObject extension for the animations tests. */
@interface GREYHostApplicationDistantObject (AnimationsTest)

/**
 * @return An added UIView in the center of the screen whose layer has two nested sublayers with the
 *         last one animated.
 *
 * @param view    The View to which an animation is going to be added.
 * @param keyPath The keyPath for the added CAAnimation.
 */
- (UIView *)viewWithAnimatingSublayerAddedToView:(UIView *)view forKeyPath:(NSString *)keyPath;
@end
