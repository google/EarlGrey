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

#import <Foundation/Foundation.h>

#import <EarlGrey/GREYAnalyticsDelegate.h>

/**
 *  Provides methods for tracking EarlGrey usage using Google Analytics.
 *
 *  @remark To opt out of Analytics use GREYConfiguration and set config value for
 *          @c kGREYConfigKeyAnalyticsEnabled to @c NO before the instance tear down method
 *          XCTestCase::tearDown method returns. Sample code to opt out of analytics:
 *          @code
 *          [[GREYConfiguration sharedInstance] setValue:@(NO)
 *                                          forConfigKey:kGREYConfigKeyAnalyticsEnabled];
 *          @endcode
 */
@interface GREYAnalytics : NSObject<GREYAnalyticsDelegate>

/**
 *  @return The singleton instance.
 */
+ (instancetype)sharedInstance;

/**
 *  @return The current delegate.
 */
- (id<GREYAnalyticsDelegate>)delegate;

/**
 *  Sets a delegate for custom handling of analytics payload data. To reset GREYAnalytics to its
 *  default behavior pass @c nil.
 */
- (void)setDelegate:(id<GREYAnalyticsDelegate>)delegate;

/**
 *  Called when an EarlGrey invocation occurs using any @code [EarlGrey XXX] @endcode statements.
 */
- (void)didInvokeEarlGrey;

/**
 *  Sends an Analytics Event hit based on protocol specified in:
 *  @see https://developers.google.com/analytics/devguides/collection/protocol/v1/devguide#event
 *
 *  @param trackingID  The tracking ID for the created Analytics Event payload.
 *  @param clientID    The client ID for the created Analytics Event payload.
 *  @param category    The category value to be used for the created Analytics Event payload.
 *  @param subCategory The sub-category value to be used for the created Analytics Event payload.
 *  @param valueOrNil  The value to be used for the created Analytics Event payload. The value
 *                     can be @c nil to indicate that value is not to be added to the payload.
 */
+ (void)sendEventHitWithTrackingID:(NSString *)trackingID
                          clientID:(NSString *)clientID
                          category:(NSString *)category
                       subCategory:(NSString *)subCategory
                             value:(NSNumber *)valueOrNil;

@end
