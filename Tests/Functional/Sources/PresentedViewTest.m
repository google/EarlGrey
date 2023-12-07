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

#import "EarlGrey.h"
#import "BaseIntegrationTest.h"
#import "AppDelegate.h"

@interface PresentedViewTest : BaseIntegrationTest
@end

@implementation PresentedViewTest

- (void)setUp {
  [super setUp];
  [self openTestViewNamed:@"Presented Views"];
}

- (void)testDismissToResetNavController {
  AppDelegate *app =
      (AppDelegate *)[GREY_REMOTE_CLASS_IN_APP(UIApplication) sharedApplication].delegate;
  [app resetRootNavigationController];

  [[EarlGrey selectElementWithMatcher:GREYButtonTitle(@"Dismiss")] performAction:GREYTap()];
}

@end
