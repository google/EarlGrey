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

UIWindow *GREYUILibUtilsGetApplicationKeyWindow(UIApplication *application) {
  // New API only available on Xcode 13+
#if (defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 120000) || \
    (defined(__TV_OS_VERSION_MAX_ALLOWED) && __TV_OS_VERSION_MAX_ALLOWED >= 150000) ||       \
    (defined(__WATCH_OS_VERSION_MAX_ALLOWED) && __WATCH_OS_VERSION_MAX_ALLOWED >= 150000) || \
    (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 150000)
  if (@available(iOS 15.0, *)) {
    // There can be multiple key windows on iOS 15 because they are now bound to UIScene.
    // This may indicate that all the active scenes can receive keyboard/system events at the same
    // time, we currently only return the first key window for testing purposes. We shall evaluate
    // how EarlGrey can support multiple key windows later.
    // TODO(b/191156739): Support multiple key windows.
    NSSet<UIScene *> *scenes = application.connectedScenes;
    NSPredicate *filter = [NSPredicate
        predicateWithBlock:^BOOL(UIWindowScene *scene, NSDictionary<NSString *, id> *unused) {
          if (![scene isKindOfClass:UIWindowScene.class]) {
            return NO;
          } else if (scene.activationState != UISceneActivationStateForegroundActive) {
            return NO;
          } else {
            return scene.keyWindow != nil;
          }
        }];
    NSSet<UIScene *> *keyScenes = [scenes filteredSetUsingPredicate:filter];
    return ((UIWindowScene *)keyScenes.anyObject).keyWindow;
  }
#endif

  if (@available(iOS 13.0, *)) {
    NSArray<UIWindow *> *windows = application.windows;
    NSPredicate *windowFilter =
        [NSPredicate predicateWithBlock:^BOOL(UIWindow *window,
                                              NSDictionary<NSString *, id> *_Nullable bindings) {
          return window.isKeyWindow;
        }];
    NSArray<UIWindow *> *keyWindows = [windows filteredArrayUsingPredicate:windowFilter];
    if ([keyWindows count] > 0) {
      // On iOS 15+, it's possible to have multiple key windows. If any key windows are found, we
      // we only return the first one.
      return keyWindows.firstObject;
    } else if ([windows count] > 1) {
      // In case of no key window being found but there are windows still present, we assume that
      // there are more than just one window present, with the first being the former key window. We
      // check to see if the last window also is a full-fledged UIWindow with the same frame as the
      // first one to set that as the key window. (This behavior is seen especially in the case of
      // toast views pre-iOS 16.)
      UIWindow *firstWindow = [windows firstObject];
      UIWindow *lastWindow = [windows lastObject];
      if (CGRectEqualToRect(firstWindow.frame, lastWindow.frame) &&
          [lastWindow isMemberOfClass:[UIWindow class]]) {
        return lastWindow;
      }
    }
    return nil;
  } else {
    // This API is deprecated in iOS 13, so we suppress warning here in case its minimum required
    // SDKs are lower.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [application keyWindow];
#pragma clang diagnostic pop
  }
}

@implementation GREYUILibUtils

+ (UIScreen *)screen {
  UIScreen *screen;

  if (@available(iOS 13.0, *)) {
    UIWindow *window = [self window];
    screen = window.windowScene.screen;
    // This check is added in case there is an issue with getting the screen i.e. if the screen
    // hasn't come up.
    if (!screen) {
      if (@available(iOS 16.0, *)) {
        //
      } else {
        screen = [UIScreen mainScreen];
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

@end
