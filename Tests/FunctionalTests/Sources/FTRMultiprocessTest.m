//
// Copyright 2016 Google Inc.
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

#import "FTRBaseIntegrationTest.h"

@interface UIApplication (GREYExposed)
- (BOOL)_isSpringBoardShowingAnAlert;
@end

@interface FTRMultiprocessTest : FTRBaseIntegrationTest
@end

@implementation FTRMultiprocessTest

- (void)testSystemDialog {
  // Interaction with SpringBoard is not on device or before iOS 9.
  if (!TARGET_OS_SIMULATOR || !iOS9_OR_ABOVE()) {
    return;
  }
  
  [EarlGrey executeBlock:^{
    [[UIApplication sharedApplication] registerUserNotificationSettings:
        [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound |
                                                      UIUserNotificationTypeAlert |
                                                      UIUserNotificationTypeBadge)
                                          categories:nil]];
    [[UIApplication sharedApplication] registerForRemoteNotifications];
  }];

  // SpringBoard might need a second or two to receive the request and display the alert dialog.
  GREYCondition *waitForSystemAlert = [GREYCondition conditionWithName:@"WaitForSystemAlert"
                                                                 block:^BOOL() {
    return [[UIApplication sharedApplication] _isSpringBoardShowingAnAlert];
  }];
  // System alert dialog will only be shown if it has not been previously approved or rejected.
  BOOL alertIsShown = [waitForSystemAlert waitWithTimeout:2];
  if (alertIsShown) {
    [[EarlGrey systemApplication] executeBlock:^{
      id<GREYMatcher> buttonMatcher =
          grey_allOf(grey_accessibilityLabel(iOS10_OR_ABOVE() ? @"Allow" : @"OK"),
                                             grey_kindOfClass([UILabel class]),
                                             nil);
      [[EarlGrey selectElementWithMatcher:buttonMatcher] performAction:grey_tap()];
    }];
  }
}

@end
