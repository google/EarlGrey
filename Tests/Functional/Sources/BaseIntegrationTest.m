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

#import "BaseIntegrationTest.h"

#import "EarlGrey.h"
#import "GREYHostApplicationDistantObject+BaseIntegrationTest.h"

@implementation BaseIntegrationTest

- (void)setUp {
  [super setUp];
  self.application = [[XCUIApplication alloc] init];

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [EarlGrey setHostApplicationCrashHandler:[self defaultCrashHandler]];
    // EarlGrey functional test blocks creation of remote object belonging to testing process. The
    // only exception is NSArray - there is one test case verifying the eDO utility for NSArray.
    [NSObject edo_disallowRemoteInvocationWithExclusion:@[ [NSArray class], [NSEnumerator class] ]];
    [self.application launch];
  });

  for (UIScene* scene in UIApplication.sharedApplication.connectedScenes) {
    UIWindowScene* windowScene = (UIWindowScene*)scene;
    for (UIWindow* window in windowScene.windows) {
      [[window layer] setSpeed:100];
    }
  }

  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationPortrait error:nil];
}

- (void)openTestViewNamed:(NSString *)name {
  // Attempt to open the named view, the views are listed as a rows of a UITableView and tapping
  // it opens the view.
  NSError *error;
  id<GREYMatcher> cellMatcher = GREYAccessibilityLabel(name);
  [[EarlGrey selectElementWithMatcher:cellMatcher] performAction:GREYTap() error:&error];
  if (!error) {
    return;
  }
  // The view is probably not visible, scroll to top of the table view and go searching for it.
  [[EarlGrey selectElementWithMatcher:GREYKindOfClass([UITableView class])]
      performAction:GREYScrollToContentEdge(kGREYContentEdgeTop)];
  // Scroll to the cell we need and tap it.
  [[[EarlGrey selectElementWithMatcher:grey_allOf(cellMatcher, GREYInteractable(), nil)]
         usingSearchAction:GREYScrollInDirection(kGREYDirectionDown, 240)
      onElementWithMatcher:GREYKindOfClass([UITableView class])] performAction:GREYTap()];
}

- (void)tearDown {
  for (UIScene* scene in UIApplication.sharedApplication.connectedScenes) {
    UIWindowScene* windowScene = (UIWindowScene*)scene;
    for (UIWindow* window in windowScene.windows) {
      [[window layer] setSpeed:1];
    }
  }

  [[GREYHostApplicationDistantObject sharedInstance] resetNavigationStack];
  [[GREYConfiguration sharedConfiguration] reset];

  [super tearDown];
}

- (GREYHostApplicationCrashHandler)defaultCrashHandler {
  static GREYHostApplicationCrashHandler defaultCrashHandler;
  static dispatch_once_t once_token;
  dispatch_once(&once_token, ^{
    defaultCrashHandler = ^{
      NSLog(@"Test triggers app crash handler! App-under-test will be relaunched.");
      XCUIApplication *application = [[XCUIApplication alloc] init];
      [application launch];
    };
  });
  return defaultCrashHandler;
}

@end
