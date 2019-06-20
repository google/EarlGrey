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

#import "AppFramework/DistantObject/GREYHostApplicationDistantObject+GREYTestHelper.h"
#import "CommonLib/Additions/NSString+GREYCommon.h"
#import "TestLib/Analytics/GREYAnalytics.g3only.h"
#import "TestLib/XCTestCase/XCTestCase+GREYTest.h"

@interface GREYAnalytics (GREYExposedForTesting)
- (void)grey_testCaseInstanceDidTearDown;
@end

@interface GREYAnalyticsTestDelegate : NSObject <GREYAnalyticsDelegate>

@property(nonatomic, assign) NSInteger count;
@property(nonatomic, strong) NSString *clientID;
@property(nonatomic, strong) NSString *bundleID;
@property(nonatomic, strong) NSString *subCategory;

@end

@implementation GREYAnalyticsTestDelegate

- (void)trackEventWithTrackingID:(NSString *)trackingID
                        clientID:(NSString *)clientID
                        category:(NSString *)category
                          action:(NSString *)subCategory
                           value:(NSString *)value {
  _clientID = clientID;
  _bundleID = category;
  _subCategory = subCategory;
  _count += 1;
}

@end

@interface AnalyticsTest : BaseIntegrationTest
@end

@implementation AnalyticsTest {
  // Reference to the previous analytics delegate that this test overrides (used to restore later).
  id<GREYAnalyticsDelegate> _previousDelegate;
  // The test delegate that saves data passed in for verification.
  GREYAnalyticsTestDelegate *_testDelegate;
  XCUIApplication *_application;
}

- (void)setUp {
  [super setUp];
  _previousDelegate = [[GREYAnalytics sharedAnalytics] delegate];
  _testDelegate = [[GREYAnalyticsTestDelegate alloc] init];
  [[GREYAnalytics sharedAnalytics] setDelegate:_testDelegate];
}

- (void)tearDown {
  [[GREYAnalytics sharedAnalytics] setDelegate:_previousDelegate];
  [super tearDown];
}

/**
 *  Test case to check if the delegate gets the right bundle ID value.
 */
- (void)testAnalyticsDelegateGetsCorrectBundleID {
  // Verify bundle ID is a non-empty string.
  NSString *bundleID =
      [[[GREYHostApplicationDistantObject sharedInstance] appBundleID] grey_md5String];
  XCTAssertGreaterThan([bundleID length], 0u);

  [self greytest_simulateTestExecution];
  XCTAssertEqualObjects(bundleID, _testDelegate.bundleID);
  XCTAssertEqual(_testDelegate.count, 1);
}

/**
 *  Checks if the analytics delegate receives the correct test case value.
 */
- (void)testAnalyticsDelegateGetsTestCase {
  [self greytest_simulateTestExecution];

  // Verify the testcase name passed to the delegate is md5ed.
  NSString *testCase = [[NSString stringWithFormat:@"%@::%@", [self grey_testClassName],
                                                   [self grey_testMethodName]] grey_md5String];
  NSString *testCaseId = [NSString stringWithFormat:@"TestCase_%@", testCase];
  NSString *expectedTestCaseId = @"TestCase_507e7b3f9744090a26a1581e127f281b";
  XCTAssertEqualObjects(testCaseId, expectedTestCaseId);
  XCTAssertEqualObjects(_testDelegate.subCategory, expectedTestCaseId);
  XCTAssertEqual(_testDelegate.count, 1);
}

/**
 *  Checks if changing the analytics enabled value toggles the sending of the analytics.
 */
- (void)testAnalyticsChange {
  // Ensure Analytics is enabled in the beginning.
  XCTAssertTrue(GREY_CONFIG_BOOL(kGREYConfigKeyAnalyticsEnabled));
  [self greytest_simulateTestExecution];
  XCTAssertEqual(_testDelegate.count, 1);

  // Ensure Analytics is turned off, on setting it as so with the XCTestCase.
  [[GREYConfiguration sharedConfiguration] setValue:@(NO)
                                       forConfigKey:kGREYConfigKeyAnalyticsEnabled];
  XCTAssertFalse(GREY_CONFIG_BOOL(kGREYConfigKeyAnalyticsEnabled));
  [self greytest_simulateTestExecution];
  XCTAssertEqual(_testDelegate.count, 1);

  // Ensure Analytics is turned on, on setting it as so with the XCTestCase.
  [[GREYConfiguration sharedConfiguration] setValue:@(YES)
                                       forConfigKey:kGREYConfigKeyAnalyticsEnabled];
  XCTAssertTrue(GREY_CONFIG_BOOL(kGREYConfigKeyAnalyticsEnabled));
  [self greytest_simulateTestExecution];
  XCTAssertEqual(_testDelegate.count, 2);
}

#pragma mark - Private

/**
 *  Simulates the test execution to trigger analytics.
 */
- (void)greytest_simulateTestExecution {
  [[GREYAnalytics sharedAnalytics] didInvokeEarlGrey];
  [[GREYAnalytics sharedAnalytics] grey_testCaseInstanceDidTearDown];
}

@end
