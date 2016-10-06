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
#import <EarlGrey/NSURL+GREYAdditions.h>

#import "GREYBaseTest.h"
#import "GREYExposedForTesting.h"

@interface NSURL_GREYAdditionsTest : GREYBaseTest
@end

@implementation NSURL_GREYAdditionsTest

- (void)testAnalyticsURLIsBlacklisted {
  [[GREYConfiguration sharedInstance] setValue:@[]
                                  forConfigKey:kGREYConfigKeyURLBlacklistRegex];
  // Just analytics tracking ID.
  NSString *analyticsID = @"UA-54227235-2";
  NSURL *url = [NSURL URLWithString:analyticsID];
  XCTAssertNotNil(url);
  XCTAssertFalse([url grey_shouldSynchronize]);

  // Analytics tracking ID within a URL.
  NSString *analyticsURL = [NSString stringWithFormat:@"http://google.com/%@/foo", analyticsID];
  url = [NSURL URLWithString:analyticsURL];
  XCTAssertNotNil(url);
  XCTAssertFalse([url grey_shouldSynchronize]);
}

- (void)testBlacklistSystemURLs {
  [[GREYConfiguration sharedInstance] setValue:@[]
                                  forConfigKey:kGREYConfigKeyURLBlacklistRegex];
  NSString *regEx = @".*foo.*";
  [NSURL grey_addBlacklistRegEx:regEx];

  NSURL *url = [NSURL URLWithString:regEx];
  XCTAssertNotNil(url);
  XCTAssertFalse([url grey_shouldSynchronize]);

  url = [NSURL URLWithString:[NSString stringWithFormat:@"http://google.com/%@/", regEx]];
  XCTAssertNotNil(url);
  XCTAssertFalse([url grey_shouldSynchronize]);
}

- (void)testBlacklistNoURLs {
  [[GREYConfiguration sharedInstance] setValue:@[]
                                  forConfigKey:kGREYConfigKeyURLBlacklistRegex];
  NSURL *url = [NSURL URLWithString:@"http://google.com"];
  XCTAssertTrue([url grey_shouldSynchronize]);

  url = [NSURL URLWithString:@"abc.xyz"];
  XCTAssertTrue([url grey_shouldSynchronize]);
}

- (void)testBlacklistURLsCleared {
  // Set it to something then clear it.
  [[GREYConfiguration sharedInstance] setValue:@[@"."]
                                  forConfigKey:kGREYConfigKeyURLBlacklistRegex];
  [[GREYConfiguration sharedInstance] setValue:@[]
                                  forConfigKey:kGREYConfigKeyURLBlacklistRegex];
  NSURL *url = [NSURL URLWithString:@"abc.xyz"];
  XCTAssertTrue([url grey_shouldSynchronize]);
}

- (void)testBlacklistAllURLs {
  [[GREYConfiguration sharedInstance] setValue:@[@"."]
                                  forConfigKey:kGREYConfigKeyURLBlacklistRegex];
  NSURL *url = [NSURL URLWithString:@"http://google.com"];
  XCTAssertNotNil(url);
  XCTAssertFalse([url grey_shouldSynchronize]);

  url = [NSURL URLWithString:@"abc.xyz"];
  XCTAssertNotNil(url);
  XCTAssertFalse([url grey_shouldSynchronize]);

  url = [NSURL URLWithString:@"file://localhost:8080"];
  XCTAssertNotNil(url);
  XCTAssertFalse([url grey_shouldSynchronize]);
}

- (void)testBlacklistSpecificURL {
  [[GREYConfiguration sharedInstance] setValue:@[@".*google\\.com"]
                                  forConfigKey:kGREYConfigKeyURLBlacklistRegex];
  NSURL *url = [NSURL URLWithString:@"http://google.com"];
  XCTAssertNotNil(url);
  XCTAssertFalse([url grey_shouldSynchronize]);

  url = [NSURL URLWithString:@"abc.xyz"];
  XCTAssertTrue([url grey_shouldSynchronize]);
}

- (void)testBlacklistMultipleURLs {
  [[GREYConfiguration sharedInstance] setValue:@[ @"google\\.com", @"abc\\.xyz" ]
                                  forConfigKey:kGREYConfigKeyURLBlacklistRegex];

  NSURL *url = [NSURL URLWithString:@"google.com"];
  XCTAssertNotNil(url);
  XCTAssertFalse([url grey_shouldSynchronize]);

  url = [NSURL URLWithString:@"abc.xyz"];
  XCTAssertNotNil(url);
  XCTAssertFalse([url grey_shouldSynchronize]);

  url = [NSURL URLWithString:@"youtube.com"];
  XCTAssertTrue([url grey_shouldSynchronize]);
}

@end
