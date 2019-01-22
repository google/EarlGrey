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

#import "FTRBaseIntegrationTest.h"

#import "GREYHostApplicationDistantObject+BaseIntegrationTest.h"

@implementation FTRBaseIntegrationTest {
  // This variable holds the current failure handler before any tests sully it.
  id<GREYFailureHandler> _currentFailureHandler;
}

- (void)setUp {
  [super setUp];
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    self.application = [[XCUIApplication alloc] init];
    [self.application launch];
  });
  _currentFailureHandler =
      [[[NSThread currentThread] threadDictionary] valueForKey:kGREYFailureHandlerKey];
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationPortrait error:nil];
}

- (void)openTestViewNamed:(NSString *)name {
  // Attempt to open the named view, the views are listed as a rows of a UITableView and tapping
  // it opens the view.
  NSError *error;
  id<GREYMatcher> cellMatcher = grey_accessibilityLabel(name);
  [[EarlGrey selectElementWithMatcher:cellMatcher] performAction:grey_tap() error:&error];
  if (!error) {
    return;
  }
  // The view is probably not visible, scroll to top of the table view and go searching for it.
  [[EarlGrey selectElementWithMatcher:grey_kindOfClass([UITableView class])]
      performAction:grey_scrollToContentEdge(kGREYContentEdgeTop)];
  // Scroll to the cell we need and tap it.
  [[[EarlGrey selectElementWithMatcher:grey_allOf(cellMatcher, grey_interactable(), nil)]
         usingSearchAction:grey_scrollInDirection(kGREYDirectionDown, 240)
      onElementWithMatcher:grey_kindOfClass([UITableView class])] performAction:grey_tap()];
}

- (void)tearDown {
  [[GREYHostApplicationDistantObject sharedInstance] resetNavigationStack];
  [[GREYConfiguration sharedConfiguration] reset];
  [EarlGrey setFailureHandler:_currentFailureHandler];

  [super tearDown];
}

@end
