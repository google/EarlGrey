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

#import "TestLib/Analytics/GREYAnalytics.h"
#import "TestLib/Analytics/GREYAnalyticsDelegate.h"
#import "TestLib/EarlGreyImpl/EarlGrey.h"

/**
 *  Holds the original analytics delegate that was present before the test began. We use this to
 *  restore analytics delegate when done testing.
 */
static id<GREYAnalyticsDelegate> gOriginalAnalyticsDelegate;

/**
 *  A simple Analytics delegate that aborts the test if hit.
 */
@interface FTRAnalyticsClassTearDownOptOutTestDelegate : NSObject <GREYAnalyticsDelegate>
@end

@implementation FTRAnalyticsClassTearDownOptOutTestDelegate

#pragma mark - Private

- (void)trackEventWithTrackingID:(NSString *)trackingID
                        clientID:(NSString *)clientID
                        category:(NSString *)category
                          action:(NSString *)action
                           value:(NSString *)value {
  abort();
}

@end

/**
 *  A test that checks the behavior of the Analytics delegate in the class level tearDown.
 */
@interface FTRAnalyticsClassTearDownOptOutTest : XCTestCase
@end

@implementation FTRAnalyticsClassTearDownOptOutTest

- (void)setUp {
  [super setUp];
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    XCUIApplication *application = [[XCUIApplication alloc] init];
    [application launch];
  });

  gOriginalAnalyticsDelegate = [[GREYAnalytics sharedAnalytics] delegate];
  // Set Analytics delegate to the test's delegate.
  id<GREYAnalyticsDelegate> testDelegate =
      [[FTRAnalyticsClassTearDownOptOutTestDelegate alloc] init];
  [[GREYAnalytics sharedAnalytics] setDelegate:testDelegate];
}

- (void)testEarlGreyAnalyticsDelegateInClassLevelTearDown {
  // Invoke EarlGrey to set the analytics to be sent. The analytics information will be sent at
  // -tearDown.
  [[EarlGrey selectElementWithMatcher:grey_keyWindow()] assertWithMatcher:grey_notNil()];
  // Turn off Analytics Config. The Analytics delegate will no longer be called.
  [[GREYConfiguration sharedConfiguration] setValue:@(NO)
                                       forConfigKey:kGREYConfigKeyAnalyticsEnabled];
  [[EarlGrey selectElementWithMatcher:grey_keyWindow()] assertWithMatcher:grey_notNil()];
}

+ (void)tearDown {
  [[GREYConfiguration sharedConfiguration] setValue:@(YES)
                                       forConfigKey:kGREYConfigKeyAnalyticsEnabled];
  // Perform another trivial EarlGrey interaction. This will not trigger the analytics delegate
  // since the analytics events are processed in after test completes (i.e. instance level
  // -tearDown is invoked).
  [[EarlGrey selectElementWithMatcher:grey_keyWindow()] assertWithMatcher:grey_notNil()];

  // Reset the original delegate back.
  [[GREYAnalytics sharedAnalytics] setDelegate:gOriginalAnalyticsDelegate];
  [super tearDown];
}

@end
