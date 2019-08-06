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
  NSArray *_windows;
  BOOL _includeStatusBar;
}

+ (instancetype)providerWithWindows:(NSArray *)windows {
  return [[GREYUIWindowProvider alloc] initWithWindows:windows withStatusBar:NO];
}

+ (instancetype)providerWithAllWindowsWithStatusBar:(BOOL)includeStatusBar {
  return [[GREYUIWindowProvider alloc] initWithAllWindowsWithStatusBar:includeStatusBar];
}

- (instancetype)initWithWindows:(NSArray *)windows withStatusBar:(BOOL)includeStatusBar {
  self = [super init];
  if (self) {
    _windows = [windows copy];
    _includeStatusBar = includeStatusBar;
  }
  return self;
}

- (instancetype)initWithAllWindowsWithStatusBar:(BOOL)includeStatusBar {
  return [self initWithWindows:nil withStatusBar:includeStatusBar];
}

- (NSEnumerator *)dataEnumerator {
  GREYFatalAssertMainThread();

  if (_windows) {
    return [_windows objectEnumerator];
  } else {
    return [[[self class] allWindowsWithStatusBar:_includeStatusBar] objectEnumerator];
  }
}

+ (NSArray *)allWindowsWithStatusBar:(BOOL)includeStatusBar {
  UIApplication *sharedApp = UIApplication.sharedApplication;
  NSMutableOrderedSet *windows = [[NSMutableOrderedSet alloc] init];
  if (sharedApp.windows) {
    [windows addObjectsFromArray:sharedApp.windows];
  }

  if ([sharedApp.delegate respondsToSelector:@selector(window)] && sharedApp.delegate.window) {
    [windows addObject:sharedApp.delegate.window];
  }

  if (sharedApp.keyWindow) {
    [windows addObject:sharedApp.keyWindow];
  }

  if (includeStatusBar) {
    UIWindow *statusBarWindow;
    // Add the status bar if asked for.
    if (@available(iOS 13.0, *)) {
#if defined(__IPHONE_13_0)
      UIStatusBarManager *manager =
          [[[[UIApplication sharedApplication] keyWindow] windowScene] statusBarManager];
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
