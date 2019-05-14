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

#import "CommonLib/GREYAppleInternals.h"
#import "Tests/Unit/UILib/GREYBaseTest.h"
#import "UILib/Provider/GREYUIWindowProvider.h"
#import "third_party/objective_c/ocmock/v3/Source/OCMock/OCMock.h"

static NSMutableArray *gAppWindows;

@interface GREYUIWindowProviderTest : GREYBaseTest

@end

@implementation GREYUIWindowProviderTest
- (void)setUp {
  [super setUp];

  gAppWindows = [[NSMutableArray alloc] init];
  [[[self.mockSharedApplication stub] andReturn:gAppWindows] windows];
}

- (void)testDataEnumeratorContainsAllApplicationWindows {
  GREYUIWindowProvider *provider = [GREYUIWindowProvider providerWithAllWindowsWithStatusBar:NO];
  XCTAssertEqual([[[provider dataEnumerator] allObjects] count], 0u,
                 @"App doesn't contain any windows");

  [gAppWindows addObject:[[UIWindow alloc] init]];
  XCTAssertEqualObjects(gAppWindows, [[provider dataEnumerator] allObjects],
                        @"App should contain exactly one window");

  [gAppWindows addObject:[[UIWindow alloc] init]];
  // Since we added the 2nd window last, it will be on top of all windows so the ordering needs
  // to be reversed since window provider will return windows from top - bottom level.
  XCTAssertEqualObjects([[gAppWindows reverseObjectEnumerator] allObjects],
                        [[provider dataEnumerator] allObjects], @"App should contain two windows");
}

- (void)testDataEnumeratorContainsWindowInitializedWith {
  GREYUIWindowProvider *provider = [GREYUIWindowProvider providerWithWindows:gAppWindows];
  [gAppWindows addObject:[[UIWindow alloc] init]];
  XCTAssertEqual([[[provider dataEnumerator] allObjects] count], 0u,
                 @"App shouldn't contain any windows because initializing provider with data should"
                  "make a copy of that data");

  provider = [GREYUIWindowProvider providerWithWindows:gAppWindows];
  XCTAssertEqualObjects(gAppWindows, [[provider dataEnumerator] allObjects],
                        @"App should contain same windows as initialized with.");

  [gAppWindows addObject:[[UIWindow alloc] init]];
  provider = [GREYUIWindowProvider providerWithWindows:gAppWindows];
  XCTAssertEqualObjects(gAppWindows, [[provider dataEnumerator] allObjects],
                        @"App should contain same windows as initialized with.");
}

- (void)testDataEnumeratorContainsKeyWindow {
  UIWindow *window = [[UIWindow alloc] init];
  [[[self.mockSharedApplication stub] andReturn:window] keyWindow];

  GREYUIWindowProvider *provider = [GREYUIWindowProvider providerWithAllWindowsWithStatusBar:NO];
  XCTAssertEqual([[[provider dataEnumerator] allObjects] count], 1u,
                 @"App should contain exactly one window");
  XCTAssertEqualObjects(window, [[[provider dataEnumerator] allObjects] firstObject],
                        @"Only keyWindow should be in the window provider");
}

- (void)testDataEnumeratorContainsAppDelegateWindow {
  UIWindow *window = [[UIWindow alloc] init];
  id delegate = [OCMockObject mockForProtocol:@protocol(UIApplicationDelegate)];
  [[[self.mockSharedApplication stub] andReturn:delegate] delegate];
  [[[delegate stub] andReturn:window] window];

  GREYUIWindowProvider *provider = [GREYUIWindowProvider providerWithAllWindowsWithStatusBar:NO];
  XCTAssertEqual([[[provider dataEnumerator] allObjects] count], 1u,
                 @"App should contain exactly one window");
  XCTAssertEqualObjects(window, [[[provider dataEnumerator] allObjects] firstObject],
                        @"Only delegate window should be in the window provider");
}

// TODO: Add all the removed Status Bar Tests in to the app component once available, // NOLINT
// they are removed since it is to be moved to the app component.

@end
