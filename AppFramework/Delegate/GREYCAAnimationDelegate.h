//
// Copyright 2017 Google Inc.
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

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@interface GREYCAAnimationDelegate : NSObject

/**
 *  Wraps the passed in CAAnimationDelegate in a GREYSurrogateDelegate for helping in tracking
 *  the delegate's animation start and stop events for better synchronization.
 *
 *  @param delegate The CAAnimationDelegate animation delegate that is to be swizzled.
 *
 *  @return An NSObject conforming to CAAnimationDelegate.
 */
+ (id<CAAnimationDelegate>)surrogateDelegateForDelegate:(id<CAAnimationDelegate>)delegate;

/**
 *  @remark init is not an available initializer. Use surrogateDelegateForDelegate.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 *  Called when the animation begins its active duration.
 *
 *  @param animation The animation that has started.
 */
- (void)animationDidStart:(CAAnimation *)animation;

/**
 *  Called when the animation completes its active duration or is removed from the object it is
 *  attached to.
 *
 *  @param animation The animation that has stopped.
 *  @param finished  @c YES if the animation has finished, @c NO if it stopped for other reasons.
 */
- (void)animationDidStop:(CAAnimation *)animation finished:(BOOL)finished;

@end
