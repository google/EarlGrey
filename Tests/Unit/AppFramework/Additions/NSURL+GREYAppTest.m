//
// Copyright 2017 Google Inc.
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

#import "AppFramework/Additions/NSURL+GREYApp.h"
#import "CommonLib/Config/GREYConfiguration.h"

#import <XCTest/XCTest.h>

@interface NSURL_GREYAppTest : XCTestCase
@end

@implementation NSURL_GREYAppTest

// TODO: Add all the Blackist Regex tests in as soon as we are able to perform RMI calls // NOLINT
// to get the GREYConfiguration value necessary for it.

- (void)testURLsWithDataSchemeAreIgnored {
  NSURL *url = [NSURL URLWithString:@"data:"];
  XCTAssertFalse([url grey_shouldSynchronize]);
  url = [NSURL URLWithString:@"data:%20%20foo"];
  XCTAssertFalse([url grey_shouldSynchronize]);
  url = [NSURL URLWithString:
                   @"data:image/gif;base64,R0lGODdhMAAwAPAAAAAAAP///ywAAAAAMAAw"
                   @"AAAC8IyPqcvt3wCcDkiLc7C0qwyGHhSWpjQu5yqmCYsapyuvUUlvONmOZtfzgFz"
                   @"ByTB10QgxOR0TqBQejhRNzOfkVJ+5YiUqrXF5Y5lKh/DeuNcP5yLWGsEbtLiOSp"
                   @"a/TPg7JpJHxyendzWTBfX0cxOnKPjgBzi4diinWGdkF8kjdfnycQZXZeYGejmJl"
                   @"ZeGl9i2icVqaNVailT6F5iJ90m6mvuTS4OK05M0vDk0Q4XUtwvKOzrcd3iq9uis"
                   @"F81M1OIcR7lEewwcLp7tuNNkM3uNna3F2JQFo97Vriy/Xl4/f1cf5VWzXyym7PH"
                   @"hhx4dbgYKAAA7"];
  XCTAssertFalse([url grey_shouldSynchronize]);
}

- (void)testAnalyticsURLIsBlacklisted {
  [[GREYConfiguration sharedConfiguration] setValue:@[]
                                       forConfigKey:kGREYConfigKeyURLBlacklistRegex];
  // Just analytics tracking ID.
  NSString *analyticsID = @"UA-54227235-6";
  NSURL *url = [NSURL URLWithString:analyticsID];

  // Analytics on initialize does not blacklist its own URL since eDO has to be setup for it, done
  // only when XCUIApplication::launch is called. Hence, this is added to simulate that step.
  [NSURL grey_addBlacklistRegEx:analyticsID];

  XCTAssertNotNil(url);
  XCTAssertFalse([url grey_shouldSynchronize]);

  // Analytics tracking ID within a URL.
  NSString *analyticsURL = [NSString stringWithFormat:@"http://google.com/%@/foo", analyticsID];
  url = [NSURL URLWithString:analyticsURL];
  XCTAssertNotNil(url);
  XCTAssertFalse([url grey_shouldSynchronize]);
}

- (void)testBlacklistSystemURLs {
  [[GREYConfiguration sharedConfiguration] setValue:@[]
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
  [[GREYConfiguration sharedConfiguration] setValue:@[]
                                       forConfigKey:kGREYConfigKeyURLBlacklistRegex];
  NSURL *url = [NSURL URLWithString:@"http://google.com"];
  XCTAssertTrue([url grey_shouldSynchronize]);

  url = [NSURL URLWithString:@"abc.xyz"];
  XCTAssertTrue([url grey_shouldSynchronize]);
}

- (void)testBlacklistURLsCleared {
  // Set it to something then clear it.
  [[GREYConfiguration sharedConfiguration] setValue:@[ @"." ]
                                       forConfigKey:kGREYConfigKeyURLBlacklistRegex];
  [[GREYConfiguration sharedConfiguration] setValue:@[]
                                       forConfigKey:kGREYConfigKeyURLBlacklistRegex];
  NSURL *url = [NSURL URLWithString:@"abc.xyz"];
  XCTAssertTrue([url grey_shouldSynchronize]);
}

- (void)testBlacklistAllURLs {
  [[GREYConfiguration sharedConfiguration] setValue:@[ @"." ]
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
  [[GREYConfiguration sharedConfiguration] setValue:@[ @".*google\\.com" ]
                                       forConfigKey:kGREYConfigKeyURLBlacklistRegex];
  NSURL *url = [NSURL URLWithString:@"http://google.com"];
  XCTAssertNotNil(url);
  XCTAssertFalse([url grey_shouldSynchronize]);

  url = [NSURL URLWithString:@"abc.xyz"];
  XCTAssertTrue([url grey_shouldSynchronize]);
}

- (void)testBlacklistMultipleURLs {
  [[GREYConfiguration sharedConfiguration] setValue:@[ @"google\\.com", @"abc\\.xyz" ]
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
