//
// Copyright 2022 Google Inc.
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

#import "GREYUILibUtils.h"

#import "GREYAppleInternals.h"

UIWindow *GREYUILibUtilsGetApplicationKeyWindow(UIApplication *application) {
  if (@available(iOS 13.0, *)) {
    // First pass: Find key window in active scenes.
    for (UIScene *scene in application.connectedScenes) {
      if (scene.activationState == UISceneActivationStateForegroundActive &&
          [scene isKindOfClass:[UIWindowScene class]]) {
        UIWindowScene *windowScene = (UIWindowScene *)scene;
        for (UIWindow *w in windowScene.windows) {
          if (w.isKeyWindow) {
            return w;
          }
        }
#if (defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 120000) || \
    (defined(__TV_OS_VERSION_MAX_ALLOWED) && __TV_OS_VERSION_MAX_ALLOWED >= 150000) ||       \
    (defined(__WATCH_OS_VERSION_MAX_ALLOWED) && __WATCH_OS_VERSION_MAX_ALLOWED >= 150000) || \
    (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 150000)
        if (@available(iOS 15.0, tvOS 15.0, *)) {
          if (windowScene.keyWindow) {
            return windowScene.keyWindow;
          }
        }
#endif
      }
    }
    // Second pass fallback: Active/foreground window scene's first window.
    for (UIScene *scene in application.connectedScenes) {
      if (scene.activationState == UISceneActivationStateForegroundActive &&
          [scene isKindOfClass:[UIWindowScene class]]) {
        UIWindowScene *windowScene = (UIWindowScene *)scene;
        if (windowScene.windows.count > 0) {
          return windowScene.windows.firstObject;
        }
      }
    }
    return nil;
  }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  return [application keyWindow];
#pragma clang diagnostic pop
}

/** @return The UIWindow for the keyboard. */
UIWindow *GREYUILibUtilsGetKeyboardWindow() {
  return [(UIView *)[UIKeyboardImpl sharedInstance] window];
}

/** @return An array of UIWindow related to the connected scenes. */
NSArray<UIWindow *> *GREYUILibUtilsGetAllWindowsFromConnectedScenes() {
  UIApplication *sharedApp = UIApplication.sharedApplication;
  NSMutableArray<UIWindow *> *windows = [[NSMutableArray alloc] init];
  if (@available(iOS 16.0, *)) {
    for (UIScene *scene in sharedApp.connectedScenes) {
      if ([scene isKindOfClass:[UIWindowScene class]]) {
        UIWindowScene *windowScene = (UIWindowScene *)scene;
        [windows addObjectsFromArray:windowScene.windows];
      }
    }
  } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (sharedApp.windows) {
      [windows addObjectsFromArray:sharedApp.windows];
    }
#pragma clang diagnostic pop
  }

  return windows;
}

@implementation GREYUILibUtils

+ (UIScreen *)screen {
  UIScreen *screen;

  if (@available(iOS 13.0, *)) {
    UIWindow *window = [self window];
    screen = window.windowScene.screen;
    if (!screen) {
      for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive &&
            [scene isKindOfClass:[UIWindowScene class]]) {
          screen = ((UIWindowScene *)scene).screen;
          if (screen) break;
        }
      }
    }
    if (!screen) {
      if (UIApplication.sharedApplication.connectedScenes.count == 0) {
        screen = [UIScreen mainScreen];
      } else {
        if (@available(iOS 16.0, *)) {
          // Do not return mainScreen on iOS 16+ when inactive to allow visibility checker to fail.
        } else {
          screen = [UIScreen mainScreen];
        }
      }
    }
  } else {
    screen = [UIScreen mainScreen];
  }

  return screen;
}

+ (UIWindow *)window {
  return GREYUILibUtilsGetApplicationKeyWindow(UIApplication.sharedApplication);
}

+ (NSSet<UIScene *> *)connectedScenes API_AVAILABLE(ios(13.0)) {
  return UIApplication.sharedApplication.connectedScenes;
}

+ (CGRect)scaledKeyboardFrame {
  UIWindow *keyboardWindow = GREYUILibUtilsGetKeyboardWindow();
  if (!keyboardWindow || !keyboardWindow.subviews.count) {
    return CGRectNull;
  }
  UIView *inputSetContainerView = keyboardWindow.subviews[0];
  if (!inputSetContainerView.subviews.count) {
    return CGRectNull;
  }
  UIView *inputSetHostView = inputSetContainerView.subviews[0];
  CGRect frame = [inputSetHostView frame];
  CGFloat scale = [self screen].scale;
  return CGRectMake(CGRectGetMinX(frame) * scale, CGRectGetMinY(frame) * scale,
                    CGRectGetWidth(frame) * scale, CGRectGetHeight(frame) * scale);
}

@end
