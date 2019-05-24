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

#import <XCTest/XCTest.h>

#import "TestLib/Config/GREYTestConfiguration.h"

@interface GREYTestConfigurationTest : XCTestCase
@end

@implementation GREYTestConfigurationTest

/**
 *  Test if the GREYConfiguration sharedInstance is the same as the GREYTestConfiguration one.
 */
- (void)testSharedConfigurationIsTheSameForTestAndParentConfigurations {
  GREYConfiguration *parentConfig = [GREYConfiguration sharedConfiguration];
  XCTAssertEqual([GREYTestConfiguration sharedConfiguration], parentConfig);
}

/**
 *  Test if getting the GREYConfiguration sharedInstance sets the default values in
 *  GREYTestConfiguration::init.
 */
- (void)testInitializingSharedConfigurationSetsDefaultValues {
  GREYConfiguration *configuration = [GREYConfiguration sharedConfiguration];
  double interactionTimeout =
      [configuration doubleValueForConfigKey:kGREYConfigKeyInteractionTimeoutDuration];
  double testInteractionTimeout = [[GREYTestConfiguration sharedConfiguration]
      doubleValueForConfigKey:kGREYConfigKeyInteractionTimeoutDuration];
  XCTAssertEqual(interactionTimeout, testInteractionTimeout);
}

/**
 *  Test if the @c mergedConfiguration has merged modified data while keeping the default data.
 */
- (void)testMergedConfigurationContainsFullData {
  GREYTestConfiguration *testConfiguration = [[GREYTestConfiguration alloc] init];
  [testConfiguration setValue:@(5) forConfigKey:kGREYConfigKeyInteractionTimeoutDuration];

  // These to fields are just used to test NSArray and NSDictionary here.
  NSArray *expectedArray = @[ @"a", @"b" ];
  [testConfiguration setValue:expectedArray forConfigKey:kGREYConfigKeyURLBlacklistRegex];
  NSString *expectedPath = @"a";
  [testConfiguration setValue:expectedPath forConfigKey:kGREYConfigKeyArtifactsDirLocation];

  NSDictionary *mergedDict = [testConfiguration mergedConfiguration];
  XCTAssertEqual([[mergedDict valueForKey:kGREYConfigKeyInteractionTimeoutDuration] doubleValue],
                 5);
  XCTAssertEqual([[mergedDict valueForKey:kGREYConfigKeyNSTimerMaxTrackableInterval] doubleValue],
                 1.5);
  XCTAssertTrue(
      [expectedArray isEqualToArray:[mergedDict valueForKey:kGREYConfigKeyURLBlacklistRegex]]);
  XCTAssertTrue(
      [expectedPath isEqualToString:[mergedDict valueForKey:kGREYConfigKeyArtifactsDirLocation]]);
}

@end
