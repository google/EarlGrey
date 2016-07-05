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
#import <EarlGrey/GREYAnalyticsDelegate.h>
#import <EarlGrey/NSString+GREYAdditions.h>

#import "GREYBaseTest.h"
#import "GREYExposedForTesting.h"

NSString *gTestDelegateBundleId;

@interface GREYAnalyticsTestDelegate : NSObject<GREYAnalyticsDelegate>
@end

@implementation GREYAnalyticsTestDelegate

+ (void)trackEventWithTrackingID:(NSString *)trackingID
                        category:(NSString *)category
                     subCategory:(NSString *)subCategory
                           value:(NSNumber *)valueOrNil {
  gTestDelegateBundleId = subCategory;
}

@end

@interface GREYAnalyticsTest : GREYBaseTest
@end

@implementation GREYAnalyticsTest

- (void)testAnalyticsDelegateGetsAnonymizedBundleId {
  // Verify bundle ID is a non-empty string.
  NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
  XCTAssertGreaterThan([bundleId length], 0u);

  // Setup a test delegate and verify the bundle ID passed to it is anonymized.
  Class<GREYAnalyticsDelegate> previousDelegate = [GREYAnalytics delegate];
  [GREYAnalytics setDelegate:[GREYAnalyticsTestDelegate class]];
  [GREYAnalytics trackTestCaseCompletion];
  XCTAssertEqualObjects([bundleId grey_md5String], gTestDelegateBundleId);
  [GREYAnalytics setDelegate:previousDelegate];
}

@end
