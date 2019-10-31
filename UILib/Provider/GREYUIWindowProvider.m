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
#import "GREYDefines.h"

@implementation GREYUIWindowProvider {
  NSArray<UIWindow *> *_windows;
  BOOL _includeStatusBar;
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
  NSMutableOrderedSet<UIWindow *> *windows = [[NSMutableOrderedSet alloc] init];
  if (sharedApp.windows) {
    [windows addObjectsFromArray:sharedApp.windows];
  }

  if ([sharedApp.delegate respondsToSelector:@selector(window)] && sharedApp.delegate.window) {
    [windows addObject:sharedApp.delegate.window];
  }

  UIWindow *keyWindow = GREYGetApplicationKeyWindow(sharedApp);
  if (keyWindow) {
    [windows addObject:keyWindow];
  }

  if (includeStatusBar) {
    UIWindow *statusBarWindow;
    // Add the status bar if asked for.
    if (@available(iOS 13.0, *)) {
#if defined(__IPHONE_13_0)
      UIStatusBarManager *manager = [[keyWindow windowScene] statusBarManager];
      id localStatusBar = [manager createLocalStatusBar];
      UIView *statusBar = [localStatusBar statusBar];
      statusBarWindow = [[UIWindow alloc] initWithFrame:statusBar.frame];
      [statusBarWindow addSubview:statusBar];
      [statusBarWindow setHidden:NO];
      statusBarWindow.windowLevel = UIWindowLevelStatusBar;
#endif
    } else {
      statusBarWindow = sharedApp.statusBarWindow;
    }

    if (statusBarWindow) {
      [windows addObject:statusBarWindow];
    }
  }

  // After sorting, reverse the windows because they need to appear from top-most to bottom-most.
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

#pragma mark - Private

/**
 *  A dummy method to resolve the statusBar call.
 */
- (UIView *)statusBar {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

@end

UIWindow *GREYGetApplicationKeyWindow(UIApplication *application) {
#if defined(__IPHONE_13_0)
  NSArray<UIWindow *> *windows = application.windows;
  NSPredicate *windowFilter =
      [NSPredicate predicateWithBlock:^BOOL(id _Nullable evaluatedObject,
                                            NSDictionary<NSString *, id> *_Nullable bindings) {
        return ((UIWindow *)evaluatedObject).isKeyWindow;
      }];
  NSArray<UIWindow *> *keyWindows = [windows filteredArrayUsingPredicate:windowFilter];
  GREYFatalAssertWithMessage(keyWindows.count <= 1, @"Expected 0 or 1 keywindow but found %lu",
                             keyWindows.count);
  return keyWindows.firstObject;
#else
  return [application keyWindow];
#endif
}
