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

#import "AppDelegate.h"

#import "MainViewController.h"
#import "SplashViewController.h"

/**
 * Restoration Handler block for the application:continueUserActivity:restorationHandler: method.
 */
#if defined(__IPHONE_12_0)
typedef void (^RestorationHandlerBlock)(NSArray<id<UIUserActivityRestoring>> *restorableObjects);
#else
typedef void (^RestorationHandlerBlock)(NSArray *_Nullable);
#endif

    // This class was created to override UINavigationController's default orientation mask
    // to allow TestApp interface to rotate to all orientations including upside down.
    @interface AllOrientationsNavigationController : UINavigationController
@end

@implementation AllOrientationsNavigationController

#if defined(__IPHONE_9_0) && (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_9_0)
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskAll;
}
#else
- (NSUInteger)supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskAll;
}
#endif  // defined(__IPHONE_9_0) && (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_9_0)

@end

@implementation AppDelegate

- (void)resetRootNavigationController {
  UIViewController *vc =
      [[MainViewController alloc] initWithNibName:@"MainViewController" bundle:nil];
  UINavigationController *nav = (UINavigationController *)self.window.rootViewController;
  nav.viewControllers = @[ vc ];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)opt {
  // Shows a custom splash screen.
  SplashViewController *splashVC = [[SplashViewController alloc] init];
  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  self.window.rootViewController = splashVC;
  [self.window makeKeyAndVisible];

  NSTimeInterval splashScreenDuration = 0.5;
  NSLog(@"Scheduling timer to fire in %g seconds.", splashScreenDuration);
  [NSTimer scheduledTimerWithTimeInterval:splashScreenDuration
                                   target:self
                                 selector:@selector(hideSpashScreenAndDisplayMainViewController)
                                 userInfo:nil
                                  repeats:NO];
  return YES;
}

- (void)hideSpashScreenAndDisplayMainViewController {
  NSLog(@"Timer fired! Removing splash screen.");
  UIViewController *vc =
      [[MainViewController alloc] initWithNibName:@"MainViewController" bundle:nil];
  UINavigationController *nav =
      [[AllOrientationsNavigationController alloc] initWithRootViewController:vc];
  [UIView transitionWithView:self.window
                    duration:0.2
                     options:UIViewAnimationOptionTransitionFlipFromLeft
                  animations:^{
                    self.window.rootViewController = nav;
                  }
                  completion:nil];
}

- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
  if ([url.scheme isEqualToString:@"ftr"]) {
    if ([url.host isEqualToString:@"views"]) {
      NSInteger row = url.pathComponents[1].integerValue;
      MainViewController *vc =
          ((UINavigationController *)self.window.rootViewController).viewControllers[0];
      [vc.tableview.delegate tableView:vc.tableview
               didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
    }
    return YES;
  }
  return NO;
}

- (BOOL)application:(UIApplication *)application
    continueUserActivity:(NSUserActivity *)userActivity
      restorationHandler:(RestorationHandlerBlock)restorationHandler {
  if (userActivity.activityType == NSUserActivityTypeBrowsingWeb) {
    NSURLComponents *components =
        [[NSURLComponents alloc] initWithURL:userActivity.webpageURL resolvingAgainstBaseURL:YES];
    // TODO: parse universal link when hermetic server is ready and we have real test // NOLINT
    // case.
    NSLog(@"universal link path: %@", components.path);
    return YES;
  }
  return NO;
}

@end
