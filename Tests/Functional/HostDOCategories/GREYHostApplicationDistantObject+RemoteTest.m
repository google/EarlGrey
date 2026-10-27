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
#import "GREYHostApplicationDistantObject+RemoteTest.h"

#include <UIKit/UIKit.h>
#include <objc/runtime.h>

#import "GREYAction.h"
#import "GREYActionBlock.h"
#import "GREYActions.h"
#import "GREYSyncAPI.h"
#import "GREYAssertionBlock.h"
#import "GREYDistantObjectUtils.h"
#import "GREYTestApplicationDistantObject.h"
#import "GREYDescription.h"
#import "GREYElementMatcherBlock.h"
#import "GREYUIWindowProvider.h"

/** BOOL to specify that the orientation has changed. */
static BOOL gOrientationChangeNotificationReceived;

@implementation GREYHostApplicationDistantObject (RemoteTest)

- (void)addObserverForOrientationChanged {
  gOrientationChangeNotificationReceived = NO;
  [[NSNotificationCenter defaultCenter] addObserverForName:UIDeviceOrientationDidChangeNotification
                                                    object:nil
                                                     queue:nil
                                                usingBlock:^(NSNotification *_Nonnull note) {
                                                  gOrientationChangeNotificationReceived = YES;
                                                }];
}

- (BOOL)didOrientationChange {
  return gOrientationChangeNotificationReceived;
}

- (NSString *)makeAString:(NSString *)str {
  return [str stringByAppendingString:@"make"];
}

- (uint16_t)testHostPortNumber {
  return GREYTestApplicationDistantObject.sharedInstance.hostPort;
}

- (BOOL)allWindowsLayerSpeedIsGreaterThanOne {
  for (UIWindow *window in [GREYUIWindowProvider allWindowsWithStatusBar:NO]) {
    if ([[window layer] speed] <= 1) {
      return NO;
    }
  }
  return YES;
}

- (BOOL)allWindowsLayerSpeedIsEqualToOne {
  for (UIWindow *window in [GREYUIWindowProvider allWindowsWithStatusBar:NO]) {
    if ([[window layer] speed] != 1) {
      return NO;
    }
  }
  return YES;
}

- (id<GREYMatcher>)matcherForFirstElement {
  __block BOOL firstMatch = YES;
  GREYMatchesBlock matches = ^BOOL(id element) {
    if (firstMatch) {
      firstMatch = NO;
      return YES;
    } else {
      return NO;
    }
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:@"First Element Matched."];
  };
  return [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe];
}

- (id<GREYAction>)actionForGettingTextFromMatchedElement {
  // Setup an action that grabs a label and returns its text.
  __block NSString *text;
  id actionBlock = ^(UILabel *element, __strong NSError **errorOrNil) {
    __block BOOL isEqual = NO;
    grey_dispatch_sync_on_main_thread(^{
      text = element.text;
      isEqual = [text isEqualToString:@"OFF"];
    });
    return isEqual;
  };
  return [GREYActionBlock actionWithName:@"GetSampleLabelText" performBlock:actionBlock];
}

- (id<GREYAction>)actionForTapOnAccessibleElement {
  return [GREYActionBlock actionWithName:@"Get Accessibility Identifier"
                            performBlock:^(id element, __strong NSError **errorOrNil) {
                              __block NSString *label;
                              grey_dispatch_sync_on_main_thread(^{
                                label = ((UIAccessibilityElement *)element).accessibilityLabel;
                              });
                              if (label == nil) {
                                return NO;
                              }
                              [[GREYActions actionForTap] perform:element error:nil];
                              return YES;
                            }];
}

- (id<GREYAssertion>)assertionThatAlphaIsGreaterThanZero {
  return [GREYAssertionBlock assertionWithName:@"Has Alpha"
                       assertionBlockWithError:^BOOL(id element, __strong NSError **errorOrNil) {
                         return ((UIView *)element).alpha > 0;
                       }];
}

- (void)setUpObserverForReplaceText {
  objc_setAssociatedObject(self, @selector(setUpObserverForReplaceText), @(0),
                           OBJC_ASSOCIATION_RETAIN);
  SEL notificationFiredSelector = @selector(grey_textFieldNotificationFiredOnMainThread);
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:notificationFiredSelector
                                               name:UITextFieldTextDidBeginEditingNotification
                                             object:nil];
}

- (BOOL)textFieldTextDidBeginEditingNotificationFiredOnMainThread {
  NSNumber *notificationFired =
      objc_getAssociatedObject(self, @selector(setUpObserverForReplaceText));
  return [notificationFired boolValue];
}

- (void)resetsAppLaunchingHandler {
  objc_setAssociatedObject(self, @selector(appLaunchingHandlerIsInvoked), @(0),
                           OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)appLaunchingHandlerIsInvoked {
  NSNumber *appLaunchingHandled =
      objc_getAssociatedObject(self, @selector(appLaunchingHandlerIsInvoked));
  return [appLaunchingHandled boolValue];
}

- (UIInterfaceOrientation)appOrientation {
  UIApplication *sharedApp = [UIApplication sharedApplication];
  return sharedApp.windows.firstObject.windowScene.interfaceOrientation;
}

- (void)invokeRemoteBlock:(void (^)(void))block withDelay:(int64_t)delay {
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay * (int64_t)NSEC_PER_SEC), dispatch_get_main_queue(),
                 block);
}

- (id<GREYAction>)actionForObservingControlEvents {
  return [GREYActionBlock
      actionWithName:@"Observe UIControlEvents"
        performBlock:^BOOL(id element, __strong NSError **errorOrNil) {
          if (![element isKindOfClass:[UIControl class]]) {
            return NO;
          }
          UIControl *control = (UIControl *)element;
          grey_dispatch_sync_on_main_thread(^{
            objc_setAssociatedObject(self, @selector(observedControlEvents), @(0),
                                     OBJC_ASSOCIATION_RETAIN);
            [control removeTarget:self action:NULL forControlEvents:UIControlEventAllEvents];
            [control addTarget:self
                          action:@selector(grey_didReceiveEditingDidBegin)
                forControlEvents:UIControlEventEditingDidBegin];
            [control addTarget:self
                          action:@selector(grey_didReceiveEditingChanged)
                forControlEvents:UIControlEventEditingChanged];
            [control addTarget:self
                          action:@selector(grey_didReceiveEditingDidEnd)
                forControlEvents:UIControlEventEditingDidEnd];
            [control addTarget:self
                          action:@selector(grey_didReceiveEditingDidEndOnExit)
                forControlEvents:UIControlEventEditingDidEndOnExit];
            [control addTarget:self
                          action:@selector(grey_didReceivePrimaryActionTriggered)
                forControlEvents:UIControlEventPrimaryActionTriggered];
          });
          return YES;
        }];
}

- (UIControlEvents)observedControlEvents {
  __block UIControlEvents events = 0;
  grey_dispatch_sync_on_main_thread(^{
    NSNumber *stored = objc_getAssociatedObject(self, @selector(observedControlEvents));
    events = [stored unsignedIntegerValue];
  });
  return events;
}

#pragma mark - private

/**
 * Selector fired when a UITextFieldTextDidBeginEditingNotification notification is fired. Checks
 * if the call is made on the main thread.
 */
- (void)grey_textFieldNotificationFiredOnMainThread {
  if ([NSThread isMainThread]) {
    objc_setAssociatedObject(self, @selector(setUpObserverForReplaceText), @(1),
                             OBJC_ASSOCIATION_RETAIN);
  }
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/**
 * `GREYHostApplicationDistantObject.application(:didFinishLaunchingWithOptions:)` is an equivalence
 * of the same function in `UIApplicationDelegate`.
 */
- (void)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey, id> *)options {
  objc_setAssociatedObject(self, @selector(appLaunchingHandlerIsInvoked), @(1),
                           OBJC_ASSOCIATION_RETAIN);
}

- (void)grey_recordControlEvent:(UIControlEvents)event {
  NSNumber *stored = objc_getAssociatedObject(self, @selector(observedControlEvents));
  UIControlEvents updated = [stored unsignedIntegerValue] | event;
  objc_setAssociatedObject(self, @selector(observedControlEvents), @(updated),
                           OBJC_ASSOCIATION_RETAIN);
}

- (void)grey_didReceiveEditingDidBegin {
  [self grey_recordControlEvent:UIControlEventEditingDidBegin];
}

- (void)grey_didReceiveEditingChanged {
  [self grey_recordControlEvent:UIControlEventEditingChanged];
}

- (void)grey_didReceiveEditingDidEnd {
  [self grey_recordControlEvent:UIControlEventEditingDidEnd];
}

- (void)grey_didReceiveEditingDidEndOnExit {
  [self grey_recordControlEvent:UIControlEventEditingDidEndOnExit];
}

- (void)grey_didReceivePrimaryActionTriggered {
  [self grey_recordControlEvent:UIControlEventPrimaryActionTriggered];
}

@end
