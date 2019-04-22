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

#import <objc/runtime.h>

#import "CommonLib/DistantObject/GREYTestApplicationDistantObject.h"
#import "UILib/Provider/GREYUIWindowProvider.h"

@implementation GREYHostApplicationDistantObject (RemoteTest)

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

- (UIInterfaceOrientation)appOrientation {
  return [[UIApplication sharedApplication] statusBarOrientation];
}

#pragma mark - private

/**
 *  Selector fired when a UITextFieldTextDidBeginEditingNotification notification is fired. Checks
 *  if the call is made on the main thread.
 */
- (void)grey_textFieldNotificationFiredOnMainThread {
  if ([NSThread isMainThread]) {
    objc_setAssociatedObject(self, @selector(setUpObserverForReplaceText), @(1),
                             OBJC_ASSOCIATION_RETAIN);
  }
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
