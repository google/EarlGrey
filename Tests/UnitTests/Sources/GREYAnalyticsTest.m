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

#import <EarlGrey/GREYAnalytics.h>
#import <EarlGrey/NSString+GREYAdditions.h>
#import <EarlGrey/XCTestCase+GREYAdditions.h>

#import "GREYBaseTest.h"
#import "GREYExposedForTesting.h"

@interface GREYAnalyticsTestDelegate : NSObject<GREYAnalyticsDelegate>

@property(nonatomic, strong) NSString *userID;
@property(nonatomic, strong) NSString *bundleID;
@property(nonatomic, strong) NSString *subCategory;

@end

@implementation GREYAnalyticsTestDelegate

- (void)trackEventWithTrackingID:(NSString *)trackingID
                          userID:(NSString *)userID
                        category:(NSString *)category
                     subCategory:(NSString *)subCategory
                           value:(NSNumber *)valueOrNil {
  _userID = userID;
  _bundleID = category;
  _subCategory = subCategory;
}

@end

@interface GREYAnalyticsTest : GREYBaseTest
@end

@implementation GREYAnalyticsTest {
  id<GREYAnalyticsDelegate> _previousDelegate;
  GREYAnalyticsTestDelegate *_testDelegate;
}

- (void)setUp {
  [super setUp];

  _previousDelegate = [[GREYAnalytics sharedInstance] delegate];
  _testDelegate = [[GREYAnalyticsTestDelegate alloc] init];
  [[GREYAnalytics sharedInstance] setDelegate:_testDelegate];
}

- (void)tearDown {
  [[GREYAnalytics sharedInstance] setDelegate:_previousDelegate];

  [super tearDown];
}

- (void)testAnalyticsDelegateGetsAnonymizedBundleID {
  // Verify bundle ID is a non-empty string.
  NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
  XCTAssertGreaterThan([bundleID length], 0u);

  // Verify the bundle ID passed to the test delegate is anonymized.
  [[GREYAnalytics sharedInstance] didInvokeEarlGrey];
  [[GREYAnalytics sharedInstance] grey_testCaseInstanceDidTearDown];
  XCTAssertEqualObjects([bundleID grey_md5String], _testDelegate.bundleID);
}

- (void)testAnalyticsDelegateGetsTestCaseMD5 {
  // Simulate execution of a test.
  [[GREYAnalytics sharedInstance] didInvokeEarlGrey];
  [[GREYAnalytics sharedInstance] grey_testCaseInstanceDidTearDown];

  // Verify the testcase name is md5ed.
  NSString *testCase = [NSString stringWithFormat:@"%@::%@",
                                                  [self grey_testClassName],
                                                  [self grey_testMethodName]];
  NSString *testCaseId = [NSString stringWithFormat:@"TestCase_%@", [testCase grey_md5String]];
  NSString *expectedTestCaseId = @"TestCase_5f844eaf0aeace73b955acc9f896800f";
  XCTAssertEqualObjects(testCaseId, expectedTestCaseId);
  XCTAssertEqualObjects(_testDelegate.subCategory, expectedTestCaseId);
}

- (void)testAnalyticsDelegateGetsAnonymousUserId {
  // Simulate execution of a test.
  [[GREYAnalytics sharedInstance] didInvokeEarlGrey];
  [[GREYAnalytics sharedInstance] grey_testCaseInstanceDidTearDown];

  // Verify the user name contains anonymous data. Note that this string must be modified if the
  // test class name, test case name or the test app's bundle ID changes.
  NSString *expectedUserId = @"a5ea15f5a9b787bd05a536fa2d7f2fa6_bb7702caaa7d45bc58266ec969431d80";
  XCTAssertEqualObjects(_testDelegate.userID, expectedUserId,
                        @"Either the user ID is not being anonymized or the test class, test "
                        @"method or test app's bundle ID has changed.");
}

#pragma mark - Private

/**
 *  @return The testcase count present in the given Analytics Event sub-category value.
 */
- (NSInteger)greytest_getTestCaseCountFromSubCategory:(NSString *)subCategoryValue {
  // Subcategory is in the following format: TestCase_<count>, we must extract <count>.
  NSString *testCaseCountString =
      [[subCategoryValue lowercaseString] componentsSeparatedByString:@"testcase_"][1];
  return [testCaseCountString integerValue];
}

@end
