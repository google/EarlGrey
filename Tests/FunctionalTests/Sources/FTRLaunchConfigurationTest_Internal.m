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

#import <XCTest/XCTest.h>
#import "googlemac/iPhone/Shared/Testing/Utils/Sources/ITUIOSTestUtil.h"
#import "TestLib/XCTestCase/XCUIApplication+GREYEnvironment.h"

@interface FTRLaunchConfigurationTest : XCTestCase
@end

@implementation FTRLaunchConfigurationTest

- (void)testLaunchEnvironmentInDifferentScenarios {
  if (![ITUIOSTestUtil isOnForge]) {
    return;
  }
  XCUIApplication *application = [[XCUIApplication alloc] init];
  // Check case when application is launched.
  XCTAssertEqualObjects(application.launchEnvironment, @{});
  [application launch];
  [self grey_assertCoverageVarsPresentInEnvironment:application.launchEnvironment];

  // Check condition for an empty dictionary. Similar to launching the application.
  application.launchEnvironment = @{};
  XCTAssertEqualObjects(application.launchEnvironment, @{});
  [application grey_configureApplicationForLaunch];
  [self grey_assertCoverageVarsPresentInEnvironment:application.launchEnvironment];
}

#pragma mark - private

- (void)grey_assertCoverageVarsPresentInEnvironment:(NSDictionary *)dict {
  XCTAssertNotNil(dict[@"TEST_UNDECLARED_OUTPUTS_DIR"]);
  XCTAssertNotNil(dict[@"GCOV_PREFIX"]);
  XCTAssertNotNil(dict[@"GCOV_PREFIX_STRIP"]);
}

@end
