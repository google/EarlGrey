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

#import "GREYBaseTest.h"
#import "GREYExposedForTesting.h"

@interface GREYAnalyticsTestDelegate : NSObject<GREYAnalyticsDelegate>

@property(nonatomic, strong) NSString *bundleID;
@property(nonatomic, strong) NSString *subCategory;

@end

@implementation GREYAnalyticsTestDelegate

- (void)trackEventWithTrackingID:(NSString *)trackingID
                        category:(NSString *)category
                     subCategory:(NSString *)subCategory
                           value:(NSNumber *)valueOrNil {
  _bundleID = category;
  _subCategory = subCategory;
}

@end

@interface GREYAnalyticsTest : GREYBaseTest
@end

@implementation GREYAnalyticsTest

- (void)testAnalyticsDelegateGetsAnonymizedBundleID {
  // Verify bundle ID is a non-empty string.
  NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
  XCTAssertGreaterThan([bundleID length], 0u);

  // Setup a test delegate and verify the bundle ID passed to it is anonymized.
  id<GREYAnalyticsDelegate> previousDelegate = [[GREYAnalytics sharedInstance] delegate];
  GREYAnalyticsTestDelegate *testDelegate = [[GREYAnalyticsTestDelegate alloc] init];
  [[GREYAnalytics sharedInstance] setDelegate:testDelegate];
  [[GREYAnalytics sharedInstance] didInvokeEarlGrey];
  [[GREYAnalytics sharedInstance] grey_testCaseInstanceDidTearDown];
  XCTAssertEqualObjects([bundleID grey_md5String], testDelegate.bundleID);
  [[GREYAnalytics sharedInstance] setDelegate:previousDelegate];
}

- (void)testAnalyticsDelegateGetsTestCaseCount {
  // Setup a test delegate.
  id<GREYAnalyticsDelegate> previousDelegate = [[GREYAnalytics sharedInstance] delegate];
  GREYAnalyticsTestDelegate *testDelegate = [[GREYAnalyticsTestDelegate alloc] init];
  [[GREYAnalytics sharedInstance] setDelegate:testDelegate];

  // Simulate execution of a test.
  [[GREYAnalytics sharedInstance] didInvokeEarlGrey];
  [[GREYAnalytics sharedInstance] grey_testCaseInstanceDidTearDown];

  // Verify the testcase name includes a count.
  XCTAssertTrue([[testDelegate.subCategory lowercaseString] hasPrefix:@"testcase_"]);
  XCTAssertGreaterThanOrEqual(
      [self greytest_getTestCaseCountFromSubCategory:testDelegate.subCategory], 1);
  [[GREYAnalytics sharedInstance] setDelegate:previousDelegate];
}

- (void)testAnalyticsDelegateTestCaseCountIncrements {
  // Setup a test delegate.
  id<GREYAnalyticsDelegate> previousDelegate = [[GREYAnalytics sharedInstance] delegate];
  GREYAnalyticsTestDelegate *testDelegate = [[GREYAnalyticsTestDelegate alloc] init];
  [[GREYAnalytics sharedInstance] setDelegate:testDelegate];

  // Simulate execution of first test.
  [[GREYAnalytics sharedInstance] didInvokeEarlGrey];
  [[GREYAnalytics sharedInstance] grey_testCaseInstanceDidTearDown];
  NSInteger firstTestCaseCount =
      [self greytest_getTestCaseCountFromSubCategory:testDelegate.subCategory];

  // Simulate execution of second test.
  [[GREYAnalytics sharedInstance] didInvokeEarlGrey];
  [[GREYAnalytics sharedInstance] grey_testCaseInstanceDidTearDown];
  NSInteger secondTestCaseCount =
      [self greytest_getTestCaseCountFromSubCategory:testDelegate.subCategory];
  [[GREYAnalytics sharedInstance] setDelegate:previousDelegate];

  XCTAssertEqual(secondTestCaseCount - firstTestCaseCount, 1);
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
