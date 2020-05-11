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

#import "GREYHostApplicationDistantObject+BasicInteractionTest.h"

#include <objc/runtime.h>

#import "GREYActionsShorthand.h"
#import "GREYMatchersShorthand.h"
#import "GREYElementHierarchy.h"

/**
 * A sample view controller that's set as the root for testing purposes.
 */
static UIViewController *gViewController;

@implementation GREYHostApplicationDistantObject (BasicInteractionTest)

- (void)addToMutableArray:(NSMutableArray *)array afterTime:(NSTimeInterval)seconds {
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)),
                 dispatch_get_main_queue(), ^{
                   [array addObject:@(1)];
                 });
}

- (NSString *)labelText {
  return objc_getAssociatedObject(self, @selector(labelText));
}

- (NSString *)elementHierarchyString {
  return [GREYElementHierarchy hierarchyString];
}

- (id<GREYAction>)actionToGetLabelText {
  id actionBlock = ^(UILabel *element, __strong NSError **errorOrNil) {
    grey_dispatch_sync_on_main_thread(^{
      objc_setAssociatedObject(self, @selector(labelText), element.text, OBJC_ASSOCIATION_RETAIN);
    });
    return YES;
  };
  return [GREYActionBlock actionWithName:@"GetSampleLabelText" performBlock:actionBlock];
}

- (UIWindow *)setupGestureRecognizer {
  UITapGestureRecognizer *tapGestureRecognizer =
      [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(ftr_dismissWindow:)];
  tapGestureRecognizer.numberOfTapsRequired = 1;

  // Create a custom window that dismisses itself when tapped.
  UIWindow *topMostWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  [topMostWindow addGestureRecognizer:tapGestureRecognizer];

  topMostWindow.accessibilityIdentifier = @"TopMostWindow";
  topMostWindow.isAccessibilityElement = YES;
  topMostWindow.backgroundColor = [UIColor greenColor];
  [topMostWindow makeKeyAndVisible];
  return topMostWindow;
}

- (UIViewController *)originalVCAfterSettingNewVCAsRoot {
  UIWindow *currentWindow = [[UIApplication sharedApplication].delegate window];
  UIViewController *originalVC = currentWindow.rootViewController;

  gViewController = [[UIViewController alloc] init];
  [currentWindow setRootViewController:gViewController];
  return originalVC;
}

- (UIViewController *)originalVCAfterSettingRootVCInAnotherWindow:(UIWindow *)otherWindow {
  UIWindow *currentWindow = [[UIApplication sharedApplication].delegate window];
  UIViewController *originalVC = currentWindow.rootViewController;

  otherWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  [otherWindow setRootViewController:originalVC];
  [currentWindow setRootViewController:nil];
  return originalVC;
}

- (void)setRootViewController:(UIViewController *)viewController {
  UIWindow *currentWindow = [[UIApplication sharedApplication].delegate window];
  [currentWindow setRootViewController:viewController];
}

- (void)setRootViewController:(UIViewController *)viewController inWindow:(UIWindow *)window {
  [window setRootViewController:viewController];
}

- (id<GREYAction>)actionForCheckingIfElementHidden {
  return [GREYActionBlock actionWithName:@"PerformIfVisibleElseFail"
                            performBlock:^(id element, __strong NSError **errorOrNil) {
                              __block BOOL isNotHidden;
                              grey_dispatch_sync_on_main_thread(^{
                                isNotHidden = ![element isHidden];
                              });
                              return isNotHidden;
                            }];
}

- (id<GREYAssertion>)assertionForCheckingIfElementPresent {
  return [GREYAssertionBlock assertionWithName:@"ConditionalTapIfElementExists"
                       assertionBlockWithError:^BOOL(id element, NSError *__strong *errorOrNil) {
                         return element ? YES : NO;
                       }];
}

- (id<GREYAction>)actionToHideOrUnhideBlock:(BOOL)hide {
  return [GREYActionBlock actionWithName:@"hideOrUnhideTab2"
                            performBlock:^BOOL(id element, NSError *__strong *error) {
                              __block UIView *superView = element;
                              grey_dispatch_sync_on_main_thread(^{
                                superView.hidden = hide;
                              });
                              return YES;
                            }];
}

- (id<GREYAction>)actionToMakeOpaque:(BOOL)makeOpaque {
  return [GREYActionBlock actionWithName:@"makeTab2Opaque"
                            performBlock:^BOOL(id element, NSError *__strong *error) {
                              __block UIView *superView = element;
                              grey_dispatch_sync_on_main_thread(^{
                                superView.alpha = makeOpaque ? 1 : 0;
                              });
                              return YES;
                            }];
}

- (id<GREYAction>)actionToMakeWindowOpaque:(BOOL)makeOpaque {
  return [GREYActionBlock actionWithName:@"unhideTab2"
                            performBlock:^BOOL(id element, NSError *__strong *error) {
                              __block UIView *view = element;
                              grey_dispatch_sync_on_main_thread(^{
                                UIWindow *window = view.window;
                                window.alpha = makeOpaque ? 1 : 0;
                              });
                              return YES;
                            }];
}

- (id<GREYAction>)sampleShorthandAction {
  return grey_tap();
}

- (id<GREYMatcher>)sampleShorthandMatcher {
  return grey_keyWindow();
}

#pragma mark - Private

- (void)ftr_dismissWindow:(UITapGestureRecognizer *)sender {
  [sender.view setHidden:YES];
}

@end
