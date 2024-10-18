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

#include <UIKit/UIKit.h>
#include <objc/runtime.h>

#import "GREYAppStateTracker.h"
#import "GREYFatalAsserts.h"
#import "GREYAppState.h"
#import "GREYSwizzler.h"

@interface UIPresentationController (Private)

- (int)transitionDidFinish:(int)arg2;
- (int)runTransitionForCurrentStateAnimated:(int)arg2 handoffData:(id)arg3;

@end

@implementation UIPresentationController (GREYApp)

+ (void)load {
  if (@available(iOS 18, tvOS 18, *)) {
    GREYSwizzler *swizzler = [[GREYSwizzler alloc] init];
    BOOL swizzleSuccess =
        [swizzler swizzleClass:self
            replaceInstanceMethod:@selector(runTransitionForCurrentStateAnimated:handoffData:)
                       withMethod:@selector(greyswizzled_runTransitionForCurrentStateAnimated:
                                                                                  handoffData:)];
    GREYFatalAssertWithMessage(swizzleSuccess,
                               @"Cannot swizzle UIPresentationController "
                               @"runTransitionForCurrentStateAnimated:handoffData:");
    swizzleSuccess = [swizzler swizzleClass:self
                      replaceInstanceMethod:@selector(transitionDidFinish:)
                                 withMethod:@selector(greyswizzled_transitionDidFinish:)];
    GREYFatalAssertWithMessage(swizzleSuccess,
                               @"Cannot swizzle UIPresentationController transitionDidFinish:");
  }
}

- (int)greyswizzled_runTransitionForCurrentStateAnimated:(int)state handoffData:(id)data {
  GREYAppStateTrackerObject *object = TRACK_STATE_FOR_OBJECT(kGREYPendingUIAnimation, self);
  objc_setAssociatedObject(self, @selector(greyswizzled_transitionDidFinish:), object,
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  return INVOKE_ORIGINAL_IMP2(
      int, @selector(greyswizzled_runTransitionForCurrentStateAnimated:handoffData:), state, data);
}

- (int)greyswizzled_transitionDidFinish:(int)state {
  GREYAppStateTrackerObject *object =
      objc_getAssociatedObject(self, @selector(greyswizzled_transitionDidFinish:));
  UNTRACK_STATE_FOR_OBJECT(kGREYPendingUIAnimation, object);
  objc_setAssociatedObject(self, @selector(greyswizzled_transitionDidFinish:), nil,
                           OBJC_ASSOCIATION_ASSIGN);
  return INVOKE_ORIGINAL_IMP1(int, @selector(greyswizzled_transitionDidFinish:), state);
}

@end
