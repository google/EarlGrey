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

#import <UIKit/UIKit.h>

#include <objc/runtime.h>

#import "GREYSwizzler.h"
#import "SceneDelegate.h"
#import "GREYUILibUtils.h"

@implementation UIApplication (PortraitOnlyOrientationTest)

- (NSUInteger)grey_supportedInterfaceOrientationsForWindow:(UIWindow *)window {
  return UIInterfaceOrientationMaskPortrait;
}

@end

@implementation SceneDelegate (PortraitOnlyOrientationTest)

- (UIInterfaceOrientationMask)grey_supportedInterfaceOrientationsForWindowScene:
    (UIWindowScene *)windowScene {
  return UIInterfaceOrientationMaskPortrait;
}

@end

@implementation GREYHostApplicationDistantObject (PortraitOnlyOrientationTest)

- (BOOL)blockNonPortraitOrientations {
  // Swizzle UIApplication supportedInterfaceOrientationsForWindow: and SceneDelegate
  // supportedInterfaceOrientationsForWindowScene: to make orientations other than portrait
  // unsupported by the app.
  GREYSwizzler *swizzler = [[GREYSwizzler alloc] init];
  objc_setAssociatedObject(self, @selector(unblockNonPortraitOrientations), swizzler,
                           OBJC_ASSOCIATION_RETAIN);
  BOOL appSwizzle =
      [swizzler swizzleClass:[UIApplication class]
          replaceInstanceMethod:@selector(supportedInterfaceOrientationsForWindow:)
                     withMethod:@selector(grey_supportedInterfaceOrientationsForWindow:)];
  BOOL sceneSwizzle =
      [swizzler swizzleClass:[SceneDelegate class]
          replaceInstanceMethod:@selector(supportedInterfaceOrientationsForWindowScene:)
                     withMethod:@selector(grey_supportedInterfaceOrientationsForWindowScene:)];
  if (@available(iOS 16.0, *)) {
    [GREYUILibUtils.window.rootViewController setNeedsUpdateOfSupportedInterfaceOrientations];
  }
  return appSwizzle && sceneSwizzle;
}

- (BOOL)unblockNonPortraitOrientations {
  GREYSwizzler *swizzler =
      objc_getAssociatedObject(self, @selector(unblockNonPortraitOrientations));
  // Undo swizzling.
  BOOL appUnswizzle =
      [swizzler resetInstanceMethod:@selector(supportedInterfaceOrientationsForWindow:)
                              class:[UIApplication class]];
  BOOL sceneUnswizzle =
      [swizzler resetInstanceMethod:@selector(supportedInterfaceOrientationsForWindowScene:)
                              class:[SceneDelegate class]];
  if (@available(iOS 16.0, *)) {
    [GREYUILibUtils.window.rootViewController setNeedsUpdateOfSupportedInterfaceOrientations];
  }
  return appUnswizzle && sceneUnswizzle;
}

@end
