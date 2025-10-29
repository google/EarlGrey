//
// Copyright 2025 Google Inc.
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

#import "SceneDelegate.h"

#import "MainViewController.h"
#import "SplashViewController.h"

@interface UINavigationController ()

- (UIGestureRecognizer *)interactiveContentPopGestureRecognizer API_AVAILABLE(ios(26.0));

@end

// This class was created to override UINavigationController's default orientation mask
// to allow TestApp interface to rotate to all orientations including upside down.
@interface AllOrientationsNavigationController : UINavigationController
@end

@implementation AllOrientationsNavigationController

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskAll;
}

@end

@implementation SceneDelegate

- (void)resetRootNavigationController {
  UIViewController *vc = [[MainViewController alloc] initWithNibName:@"MainViewController"
                                                              bundle:nil];
  UINavigationController *nav = (UINavigationController *)self.window.rootViewController;
  nav.viewControllers = @[ vc ];
}

- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions {
  // Shows a custom splash screen.
  SplashViewController *splashVC = [[SplashViewController alloc] init];
  UIWindowScene *windowScene = (UIWindowScene *)scene;
  self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
  self.window.rootViewController = splashVC;
  [self.window makeKeyAndVisible];

  NSTimeInterval splashScreenDuration = 0.5;
  NSLog(@"Scheduling timer to fire in %g seconds.", splashScreenDuration);
  [NSTimer scheduledTimerWithTimeInterval:splashScreenDuration
                                   target:self
                                 selector:@selector(hideSpashScreenAndDisplayMainViewController)
                                 userInfo:nil
                                  repeats:NO];
  if (connectionOptions.URLContexts.count > 0) {
    [self scene:scene openURLContexts:connectionOptions.URLContexts];
  }
}

- (void)hideSpashScreenAndDisplayMainViewController {
  NSLog(@"Timer fired! Removing splash screen.");
  UIViewController *vc = [[MainViewController alloc] initWithNibName:@"MainViewController"
                                                              bundle:nil];
  UINavigationController *nav =
      [[AllOrientationsNavigationController alloc] initWithRootViewController:vc];
  if (@available(iOS 26, *)) {
    nav.interactiveContentPopGestureRecognizer.enabled = NO;
  }
  [UIView transitionWithView:self.window
                    duration:0.2
                     options:UIViewAnimationOptionTransitionFlipFromLeft
                  animations:^{
                    self.window.rootViewController = nav;
                  }
                  completion:nil];
}

- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts {
  NSURL *url = URLContexts.allObjects.firstObject.URL;
  if ([url.scheme isEqualToString:@"ftr"]) {
    if ([url.host isEqualToString:@"views"]) {
      NSInteger row = url.pathComponents[1].integerValue;
      MainViewController *vc =
          ((UINavigationController *)self.window.rootViewController).viewControllers[0];
      [vc.tableview.delegate tableView:vc.tableview
               didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
    }
  }
}

- (void)scene:(UIScene *)scene continueUserActivity:(NSUserActivity *)userActivity {
  if (userActivity.activityType == NSUserActivityTypeBrowsingWeb) {
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:userActivity.webpageURL
                                               resolvingAgainstBaseURL:YES];
    // TODO: parse universal link when hermetic server is ready and we have real test // NOLINT
    // case.
    NSLog(@"universal link path: %@", components.path);
  }
}

@end
