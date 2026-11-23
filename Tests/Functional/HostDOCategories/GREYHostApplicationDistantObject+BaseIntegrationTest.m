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

#import "GREYHostApplicationDistantObject+BaseIntegrationTest.h"

#import "ExposedForTesting.h"

static UINavigationController *NavigationControllerFromWindow(UIWindow *window) {
  if ([window.rootViewController isKindOfClass:[UINavigationController class]]) {
    return (UINavigationController *)window.rootViewController;
  }
  return window.rootViewController.navigationController;
}

@implementation GREYHostApplicationDistantObject (BaseIntegrationTest)

- (BOOL)hasForegroundKeyWindow {
  return GREYUILibUtils.window != nil;
}

- (void)resetNavigationStack {
  UINavigationController *navController = NavigationControllerFromWindow(GREYUILibUtils.window);
  if (!navController) {
    for (UIWindow *window in GREYUILibUtilsGetAllWindowsFromConnectedScenes()) {
      navController = NavigationControllerFromWindow(window);
      if (navController) {
        break;
      }
    }
  }
  if (navController.presentedViewController) {
    [navController dismissViewControllerAnimated:NO completion:nil];
  }
  [navController.view.layer removeAllAnimations];
  [navController popToRootViewControllerAnimated:NO];
  UIView *rootView = navController.topViewController.view;
  if ([rootView isKindOfClass:[UITableView class]]) {
    UITableView *tableView = (UITableView *)rootView;
    [tableView setContentOffset:CGPointMake(0, -tableView.adjustedContentInset.top) animated:NO];
  } else {
    for (UIView *subview in rootView.subviews) {
      if ([subview isKindOfClass:[UITableView class]]) {
        UITableView *tableView = (UITableView *)subview;
        [tableView setContentOffset:CGPointMake(0, -tableView.adjustedContentInset.top)
                           animated:NO];
      }
    }
  }
}

@end
