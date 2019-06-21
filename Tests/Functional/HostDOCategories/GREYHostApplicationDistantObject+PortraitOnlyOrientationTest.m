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

#import "GREYHostApplicationDistantObject+PortraitOnlyOrientationTest.h"

#include "objc/runtime.h"

#import <UIKit/UIKit.h>

#import "GREYSwizzler.h"

@implementation UIApplication (PortraitOnlyOrientationTest)

- (NSUInteger)grey_supportedInterfaceOrientationsForWindow:(UIWindow *)window {
  return UIInterfaceOrientationMaskPortrait;
}

@end

@implementation GREYHostApplicationDistantObject (PortraitOnlyOrientationTest)

- (BOOL)blockNonPortraitOrientations {
  // Swizzle UIApplication supportedInterfaceOrientationsForWindow: to make orientations other than
  // portrait unsupported by the app.
  GREYSwizzler *swizzler = [[GREYSwizzler alloc] init];
  objc_setAssociatedObject(self, @selector(unblockNonPortraitOrientations), swizzler,
                           OBJC_ASSOCIATION_RETAIN);
  BOOL swizzle = [swizzler swizzleClass:[UIApplication class]
                  replaceInstanceMethod:@selector(supportedInterfaceOrientationsForWindow:)
                             withMethod:@selector(grey_supportedInterfaceOrientationsForWindow:)];
  return swizzle;
}

- (BOOL)unblockNonPortraitOrientations {
  GREYSwizzler *swizzler =
      objc_getAssociatedObject(self, @selector(unblockNonPortraitOrientations));
  // Undo swizzling.
  BOOL swizzle1 = [swizzler resetInstanceMethod:@selector(supportedInterfaceOrientationsForWindow:)
                                          class:[UIApplication class]];
  BOOL swizzle2 =
      [swizzler resetInstanceMethod:@selector(grey_supportedInterfaceOrientationsForWindow:)
                              class:[UIApplication class]];
  return swizzle1 && swizzle2;
}

@end
