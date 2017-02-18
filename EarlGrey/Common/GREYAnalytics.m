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

#import "Common/GREYAnalytics.h"

#import <XCTest/XCTest.h>

#import "Additions/NSString+GREYAdditions.h"
#import "Additions/NSURL+GREYAdditions.h"
#import "Additions/XCTestCase+GREYAdditions.h"
#import "Common/GREYAnalyticsDelegate.h"
#import "Common/GREYConfiguration.h"
#import "Common/GREYLogger.h"

/**
 *  The Analytics tracking ID that receives EarlGrey usage data.
 */
static NSString *const kGREYAnalyticsTrackingID = @"UA-54227235-2";

/**
 *  The event category under which the analytics data is to be sent.
 */
static NSString *const kAnalyticsInvocationCategory = @"Test Invocation";

/**
 *  The endpoint that receives EarlGrey usage data.
 */
static NSString *const kTrackingEndPoint = @"https://ssl.google-analytics.com";

@implementation GREYAnalytics {
  // Overriden GREYAnalytics delegate for custom handling of analytics.
  __weak id<GREYAnalyticsDelegate> _delegate;
  // Once set, analytics will be sent on next XCTestCase tearDown.
  BOOL _earlgreyWasCalledInXCTestContext;
}

+ (void)initialize {
  if (self == [GREYAnalytics class]) {
    NSString *analyticsRegEx = [NSString stringWithFormat:@".*%@.*", kGREYAnalyticsTrackingID];
    [NSURL grey_addBlacklistRegEx:analyticsRegEx];
  }
}

+ (instancetype)sharedInstance {
  static GREYAnalytics *sharedInstance = nil;
  static dispatch_once_t token = 0;
  dispatch_once(&token, ^{
    sharedInstance = [[GREYAnalytics alloc] initOnce];
  });
  return sharedInstance;
}

- (instancetype)initOnce {
  self = [super init];
  if (self) {
    _delegate = nil;
    _earlgreyWasCalledInXCTestContext = NO;
    // Register as an observer for kGREYXCTestCaseInstanceDidTearDown.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(grey_testCaseInstanceDidTearDown)
                                                 name:kGREYXCTestCaseInstanceDidTearDown
                                               object:nil];
  }
  return self;
}

- (void)didInvokeEarlGrey {
  // Track only if EarlGrey is called in the context of a test case.
  if ([XCTestCase grey_currentTestCase]) {
    _earlgreyWasCalledInXCTestContext = YES;
  }
}

- (void)setDelegate:(id<GREYAnalyticsDelegate>)delegate {
  _delegate = delegate;
}

- (id<GREYAnalyticsDelegate>)delegate {
  // The default delegate is self.
  return _delegate ? _delegate : self;
}

+ (void)sendEventHitWithTrackingID:(NSString *)trackingID
                          clientID:(NSString *)clientID
                          category:(NSString *)category
                       subCategory:(NSString *)subCategory
                             value:(NSNumber *)valueOrNil {
  if ([category length] == 0 || [subCategory length] == 0) {
    NSMutableArray *missingFields = [[NSMutableArray alloc] init];
    if ([category length] == 0) {
      [missingFields addObject:@"category"];
    }
    if ([subCategory length] == 0) {
      [missingFields addObject:@"sub-category"];
    }
    GREYLogVerbose(@"Failed to send analytics because the following fields were not provided: %@.",
                   missingFields);
    return;
  }

  // Initialize the payload with version(=1), tracking ID, client ID, category and sub category.
  NSMutableString *payload =
      [[NSMutableString alloc] initWithFormat:@"collect?v=1&tid=%@&cid=%@&t=event&ec=%@&ea=%@",
                                              trackingID, clientID, category, subCategory];
  // Append event value if present.
  if (valueOrNil) {
    [payload appendFormat:@"&ev=%@", valueOrNil];
  }

  // Return an url-encoded payload.
  NSCharacterSet *allowedCharacterSet = [NSCharacterSet URLQueryAllowedCharacterSet];
  NSString *encodedPayload =
      [payload stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];

  NSURL *url = [NSURL URLWithString:encodedPayload
                      relativeToURL:[NSURL URLWithString:kTrackingEndPoint]];

  [[[NSURLSession sharedSession] dataTaskWithURL:url
                               completionHandler:^(NSData *data,
                                                   NSURLResponse *response,
                                                   NSError *error) {
    if (error) {
      // Failed to send analytics data, but since the test might be running in a sandboxed
      // environment it's not a good idea to freeze or throw assertions, let's just log and
      // move on.
      GREYLogVerbose(@"Failed to send analytics data due to %@.", error);
    }
  }] resume];
}

#pragma mark - GREYAnalyticsDelegate

- (void)trackEventWithTrackingID:(NSString *)trackingID
                        clientID:(NSString *)clientID
                        category:(NSString *)category
                     subCategory:(NSString *)subCategory
                           value:(NSNumber *)valueOrNil {
  [GREYAnalytics sendEventHitWithTrackingID:trackingID
                                   clientID:clientID
                                   category:category
                                subCategory:subCategory
                                      value:valueOrNil];
}

#pragma mark - Private

/**
 *  Usage data is sent via Google Analytics indicating completion of a test case, if a delegate is
 *  specified it is invoked to handle the analytics instead.
 *  EarlGrey uses Google Analytics's event tracking with *anonymized* bundle ID (md5) as the
 *  category and "TestCase_{x}" as the sub-category where 'x' is the current test case count.
 */
- (void)grey_testCaseInstanceDidTearDown {
  if (_earlgreyWasCalledInXCTestContext) {
    // Reset var to track multiple test case invocations.
    _earlgreyWasCalledInXCTestContext = NO;

    if (GREY_CONFIG_BOOL(kGREYConfigKeyAnalyticsEnabled)) {
      NSString *bundleIDMD5 = [[[NSBundle mainBundle] bundleIdentifier] grey_md5String];
      if (!bundleIDMD5) {
        // If bundle ID is not available we use a placeholder.
        bundleIDMD5 = @"<Missing Bundle ID>";
      }
      XCTestCase *testCase = [XCTestCase grey_currentTestCase];
      NSString *testCaseMD5 =
          [[NSString stringWithFormat:@"%@::%@",
                                      [testCase grey_testClassName],
                                      [testCase grey_testMethodName]] grey_md5String];
      NSString *subCategory = [NSString stringWithFormat:@"TestCase_%@", testCaseMD5];
      NSString *clientID =
          [[NSString stringWithFormat:@"%@_%@", bundleIDMD5, testCaseMD5] grey_md5String];
      [self.delegate trackEventWithTrackingID:kGREYAnalyticsTrackingID
                                     clientID:clientID
                                     category:bundleIDMD5
                                  subCategory:subCategory
                                        value:@([[XCTestSuite defaultTestSuite] testCaseCount])];
    }
  }
}

@end
