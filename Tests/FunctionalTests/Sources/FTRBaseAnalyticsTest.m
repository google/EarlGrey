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

#import "FTRBaseAnalyticsTest.h"

#import "CommonLib/Config/GREYConfiguration.h"
#import "TestLib/Analytics/GREYAnalytics.h"
#import "TestLib/Analytics/GREYAnalyticsDelegate.h"
#import "TestLib/EarlGreyImpl/EarlGrey.h"
#import "FTRBaseIntegrationTest.h"

/**
 *  A constant used for asserting mismatched analytics hits, this is set to be a global to allow for
 *  the assertions themselves be tested.
 */
NSString *const kFTRAnalyticsHitsMisMatchedPrefix = @"Mismatched Analytics Hits";

/**
 *  Holds the original config setting for analytics that was present before the test began. We use
 *  this to restore analytics setting when done testing.
 */
static id<GREYAnalyticsDelegate> gOriginalAnalyticsSetting;

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
 *  The total number of analytics hits expected by the end of test.
 */
static NSInteger gTotalHitsExpected;

@interface FTRBaseAnalyticsTest () <GREYAnalyticsDelegate>
@end

@implementation FTRBaseAnalyticsTest

+ (void)setUp {
  [super setUp];
  // Assert there are no leaking hits.
  if (gTotalHitsReceived != 0) {
    NSLog(@"gTotalHitsReceived must was %d, it must be 0 at the start of test, non zero values"
          @"indicate leaking hits.",
          (int)gTotalHitsReceived);
    abort();
  }

  // Save analytics settings so that tests can modify it.
  gOriginalAnalyticsSetting = GREY_CONFIG(kGREYConfigKeyAnalyticsEnabled);
  gOriginalAnalyticsDelegate = [[GREYAnalytics sharedAnalytics] delegate];

  // Set Analytics delegate to the test's delegate.
  gTestAnalyticsDelegate = [[FTRBaseAnalyticsTest alloc] init];
  [[GREYAnalytics sharedAnalytics] setDelegate:gTestAnalyticsDelegate];
}

- (void)setUp {
  [super setUp];
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    XCUIApplication *application = [[XCUIApplication alloc] init];
    [application launch];
  });
}

+ (void)classSpecificTearDown {
  // Assert that the expected number of hits are received.
  if (gTotalHitsExpected != gTotalHitsReceived) {
    NSLog(@"%@, Received %d count, expected %d", kFTRAnalyticsHitsMisMatchedPrefix,
          (int)gTotalHitsReceived, (int)gTotalHitsExpected);
    abort();
  }

  gTotalHitsReceived = 0;

  // Restore analytics to its original settings.
  [[GREYConfiguration sharedConfiguration] setValue:gOriginalAnalyticsSetting
                                       forConfigKey:kGREYConfigKeyAnalyticsEnabled];
  [[GREYAnalytics sharedAnalytics] setDelegate:gOriginalAnalyticsDelegate];
  gTestAnalyticsDelegate = nil;
}

+ (void)tearDown {
  [self classSpecificTearDown];
  [super tearDown];
}

+ (void)setExpectedAnalyticsRequestsCount:(NSInteger)count {
  gTotalHitsExpected = count;
}

#pragma mark - Private

- (void)trackEventWithTrackingID:(NSString *)trackingID
                        clientID:(NSString *)clientID
                        category:(NSString *)category
                          action:(NSString *)action
                           value:(NSString *)value {
  NSAssert([NSThread isMainThread],
           @"The tests expects that Analytics delegate is invoked on "
           @"main thread.");
  gTotalHitsReceived += 1;
}

@end
