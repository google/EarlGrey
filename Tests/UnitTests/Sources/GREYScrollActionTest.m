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

#import <EarlGrey/GREYScrollAction.h>
#import <OCMock/OCMock.h>

#import "GREYBaseTest.h"

@interface GREYScrollActionTest : GREYBaseTest
@end

@implementation GREYScrollActionTest

- (void)testGREYScrollerFailsToCreateWithInvalidScrollAmounts {
  [self verifyGREYScrollActionInitFailsWithAmount:0.0];
  [self verifyGREYScrollActionInitFailsWithAmount:-1.0];
}

#pragma mark - Private Methods

- (void)verifyGREYScrollActionInitFailsWithAmount:(CGFloat)amount {
  GREYScrollAction *scrollAction;
  @try {
    scrollAction = [[GREYScrollAction alloc] initWithDirection:kGREYDirectionUp amount:amount];
    XCTFail(@"Should have thrown an assertion for scroll amount %f", (float)amount);
  } @catch (NSException *exception) {
    XCTAssertEqualObjects(@"Scroll 'amount' must be positive and greater than zero.",
                          [exception description],
                          @"Should throw GREYActionFailException");
  }
}

@end
