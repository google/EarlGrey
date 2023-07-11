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

#import "GREYUIWindowProvider.h"

#import "GREYFatalAsserts.h"
#import "GREYAppleInternals.h"
#import "GREYUILibUtils.h"

/** @return The first responder view by searching from @c view. */
static UIView *GetFirstResponderSubview(UIView *view) {
  if ([view isFirstResponder]) {
    return view;
  }

  for (UIView *subview in [view subviews]) {
    UIView *firstResponder = GetFirstResponderSubview(subview);
    if (firstResponder) {
      return firstResponder;
    }
  }

  return nil;
}

@implementation GREYUIWindowProvider {
  NSArray<UIWindow *> *_windows;
  BOOL _includeStatusBar;
}

+ (UIWindow *)keyWindowForSharedApplication {
  return GREYUILibUtilsGetApplicationKeyWindow(UIApplication.sharedApplication);
}

+ (instancetype)providerWithWindows:(NSArray<UIWindow *> *)windows {
  return [[GREYUIWindowProvider alloc] initWithWindows:windows withStatusBar:NO];
}

+ (instancetype)providerWithAllWindowsWithStatusBar:(BOOL)includeStatusBar {
  return [[GREYUIWindowProvider alloc] initWithAllWindowsWithStatusBar:includeStatusBar];
}

- (instancetype)initWithWindows:(NSArray<UIWindow *> *)windows
                  withStatusBar:(BOOL)includeStatusBar {
  self = [super init];
  if (self) {
    _windows = [windows copy];
    _includeStatusBar = includeStatusBar;
  }
  return self;
}

- (instancetype)initWithAllWindowsWithStatusBar:(BOOL)includeStatusBar {
  self = [self initWithWindows:@[] withStatusBar:includeStatusBar];
  if (self) {
    // Cannot pass in nil to the designated initializer.
    _windows = nil;
  }
  return self;
}

- (NSEnumerator *)dataEnumerator {
  GREYFatalAssertMainThread();
  if (_windows) {
    return [_windows objectEnumerator];
  } else {
    return [[[self class] allWindowsWithStatusBar:_includeStatusBar] objectEnumerator];
  }
}

+ (NSArray *)windowsFromLevelOfWindow:(UIWindow *)window withStatusBar:(BOOL)includeStatusBar {
  NSArray<UIWindow *> *windows = [self allWindowsWithStatusBar:includeStatusBar];
  NSUInteger index = [windows indexOfObject:window];
  NSRange range = NSMakeRange(0, index + 1);
  return [windows subarrayWithRange:range];
}

+ (NSArray<UIWindow *> *)allWindowsWithStatusBar:(BOOL)includeStatusBar {
  UIApplication *sharedApp = UIApplication.sharedApplication;
  NSMutableOrderedSet<UIWindow *> *windows =
      [NSMutableOrderedSet orderedSetWithArray:GREYUILibUtilsGetAllWindowsFromConnectedScenes()];

  if ([sharedApp.delegate respondsToSelector:@selector(window)] && sharedApp.delegate.window) {
    [windows addObject:sharedApp.delegate.window];
  }

  UIWindow *keyWindow = [GREYUIWindowProvider keyWindowForSharedApplication];
  if (keyWindow) {
    [windows addObject:keyWindow];
  }

  if (@available(iOS 16, *)) {
    UIResponder *firstResponder = GetFirstResponderSubview(keyWindow);
    UIView *inputView = firstResponder.inputView;
    if (inputView.window) {
      UIWindow *inputViewWindow = inputView.window;
      [inputViewWindow setWindowLevel:UIWindowLevelNormal];
      [windows addObject:inputViewWindow];
    }
    UIView *inputAccessoryView = firstResponder.inputAccessoryView;
    if (inputAccessoryView.window && ![windows containsObject:inputAccessoryView.window]) {
      [windows addObject:inputView.window];
    }
    UIWindow *keyboardWindow = GREYUILibUtilsGetKeyboardWindow();
    if (keyboardWindow) {
      [keyboardWindow setWindowLevel:UIWindowLevelNormal];
      [windows addObject:keyboardWindow];
    }
  }

  if (includeStatusBar) {
    UIWindow *statusBarWindow;
    // Add the status bar if asked for.
    if (@available(iOS 13.0, *)) {
#if TARGET_OS_IOS && defined(__IPHONE_13_0)
      // Check if any status bar is already present in the application's views.
      BOOL statusBarPresent = NO;
      for (UIWindow *window in windows) {
        if (window.windowLevel == UIWindowLevelStatusBar) {
          statusBarPresent = YES;
          break;
        }
      }
      // Create a local status bar and add it to the windows array for iteration.
      if (!statusBarPresent) {
        UIStatusBarManager *manager = [[keyWindow windowScene] statusBarManager];
        UIView *localStatusBar = (UIView *)[manager createLocalStatusBar];
        if (!localStatusBar) {
          CGRect statusBarFrame = manager.statusBarFrame;
          localStatusBar = [[UIView alloc] initWithFrame:statusBarFrame];
        }
        statusBarWindow = [[UIWindow alloc] initWithFrame:localStatusBar.frame];
        [statusBarWindow addSubview:localStatusBar];
        [statusBarWindow setHidden:NO];
        statusBarWindow.windowLevel = UIWindowLevelStatusBar;
      }
#endif  // TARGET_OS_IOS && defined(__IPHONE_13_0)
    } else {
      statusBarWindow = sharedApp.statusBarWindow;
    }

    if (statusBarWindow) {
      [windows addObject:statusBarWindow];
    }
  }

  // After sorting, reverse the windows because they need to appear from front to back.
  return [[windows sortedArrayWithOptions:NSSortStable
                          usingComparator:^NSComparisonResult(id obj1, id obj2) {
                            if ([obj1 windowLevel] < [obj2 windowLevel]) {
                              return -1;
                            } else if ([obj1 windowLevel] == [obj2 windowLevel]) {
                              return 0;
                            } else {
                              return 1;
                            }
                          }] reverseObjectEnumerator]
      .allObjects;
}

@end
