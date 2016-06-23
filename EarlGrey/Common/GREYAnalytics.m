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
#import "Additions/XCTestCase+GREYAdditions.h"
#import "Common/GREYAnalyticsDelegate.h"

/**
 *  The Analytics tracking ID that receives EarlGrey usage data.
 */
static NSString *const kTrackingID = @"UA-54227235-2";

/**
 *  The event category under which the analytics data is to be sent.
 */
static NSString *const kAnalyticsInvocationCategory = @"Test Invocation";

/**
 *  The endpoint that receives EarlGrey usage data.
 */
static NSString *const kTrackingEndPoint = @"https://ssl.google-analytics.com";

/**
 *  The currently set GREYAnalytics delegate for custom handling of analytics.
 */
Class<GREYAnalyticsDelegate> gAnalyticsDelegate;

@interface GREYAnalytics ()<GREYAnalyticsDelegate>
@end

@implementation GREYAnalytics

+ (void)setDelegate:(Class<GREYAnalyticsDelegate>)delegate {
  gAnalyticsDelegate = delegate;
}

+ (Class<GREYAnalyticsDelegate>)delegate {
  // The default delegate is self.
  return gAnalyticsDelegate ? gAnalyticsDelegate : self;
}

+ (void)trackTestCaseCompletion {
  NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
  // If bundle ID is available use an MD5 of it otherwise use a placeholder.
  bundleID = bundleID ? [bundleID grey_md5String] : @"<Missing bundle ID>";
  NSNumber *testCaseCount = @([[XCTestSuite defaultTestSuite] testCaseCount]);

  [self.delegate trackEventWithTrackingID:kTrackingID
                                 category:kAnalyticsInvocationCategory
                              subCategory:bundleID
                                    value:testCaseCount];
}

#pragma mark - GREYAnalyticsDelegate

/**
 *  Creates an Analytics Event payload based on @c kPayloadFormat and URL encodes it.
 *  @see https://developers.google.com/analytics/devguides/collection/protocol/v1/devguide#event for
 *  more info on Analytics Events and its parameters.
 *
 *  @param category    The category value to be used for the created Analytics Event payload.
 *  @param subCategory The sub-category value to be used for the created Analytics Event payload.
 *  @param valueOrNil  The value to be used for the created Analytics Event payload. The value
 *                     can be @c nil to indicate that value is not to be added to the payload.
 *
 *  @return A URL encoded string for the Analytics Event payload with the specified parameters.
 */
+ (void)trackEventWithTrackingID:(NSString *)trackingID
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
    NSLog(@"Failed to send analytics because the following fields were not provided: %@.",
          missingFields);
    return;
  }

  // Initialize the payload with version(=1), tracking ID, client ID, category and sub category.
  NSMutableString *payload =
      [[NSMutableString alloc] initWithFormat:@"collect?v=1&tid=%@&cid=%@&t=event&ec=%@&ea=%@",
                                              trackingID, @(arc4random()), category, subCategory];
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
      NSLog(@"Failed to send analytics data due to %@.", error);
    }
  }] resume];
}

@end
