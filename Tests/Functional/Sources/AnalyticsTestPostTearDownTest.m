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
 *  Holds the test analytics delegate used for intercepting analytics requests.
 */
static id<GREYAnalyticsDelegate> gTestAnalyticsDelegate;

/**
 *  The current total number of analytics hits recieved.
 */
static NSInteger gTotalHitsReceived;

/**
 *  A simple Analytics Delegate that increments a counter for each analytics hit which can be
 *  counted.
 */
@interface AnalyticsTestPostTearDownTestDelegate : NSObject <GREYAnalyticsDelegate>
@end

@implementation AnalyticsTestPostTearDownTestDelegate

#pragma mark - Private

- (void)trackEventWithTrackingID:(NSString *)trackingID
                        clientID:(NSString *)clientID
                        category:(NSString *)category
                          action:(NSString *)action
                           value:(NSString *)value {
  gTotalHitsReceived += 1;
}

@end

/**
 *  A test that ensures that the analytics delegate is not triggered after -tearDown.
 */
@interface AnalyticsTestPostTearDownTest : XCTestCase
@end

@implementation AnalyticsTestPostTearDownTest

- (void)setUp {
  [super setUp];
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    XCUIApplication *application = [[XCUIApplication alloc] init];
    [application launch];
  });
  gTotalHitsReceived = 0;
  gOriginalAnalyticsDelegate = [[GREYAnalytics sharedAnalytics] delegate];
  // Set Analytics delegate to the test's delegate.
  gTestAnalyticsDelegate = [[AnalyticsTestPostTearDownTestDelegate alloc] init];
  [[GREYAnalytics sharedAnalytics] setDelegate:gTestAnalyticsDelegate];
}

- (void)testEarlGreyAnalyticsDelegateInClassLevelTearDown {
  // Invoke EarlGrey to get one call to the Analytics Delegate.
  [[EarlGrey selectElementWithMatcher:grey_keyWindow()] assertWithMatcher:grey_notNil()];
}

+ (void)tearDown {
  // If analytics is moved to calls being sent at the end of the test-suite, then the following
  // assertion will fail.
  if (gTotalHitsReceived != 1) {
    abort();
  }

  // This invocation will not cause an increase in the total analytics hits since the analytics
  // hit is sent at -tearDown.
  [[EarlGrey selectElementWithMatcher:grey_keyWindow()] assertWithMatcher:grey_notNil()];

  // Ensures the previous assertion did not cause an invocation to be sent.
  if (gTotalHitsReceived != 1) {
    abort();
  }
  [[GREYAnalytics sharedAnalytics] setDelegate:gOriginalAnalyticsDelegate];
  [super tearDown];
}

@end
