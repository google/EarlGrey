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

#import <XCTest/XCTestExpectation.h>

#import "EarlGreyApp.h"
#import "GREYHostApplicationDistantObject.h"

/** GREYHostApplicationDistantObject extension for the XCTest expectation method. */
@interface GREYHostApplicationDistantObject (XCTestExpectationsTest)

/**
 *  Fulfills an expectation sent from the test side after a 1 second delay.
 *
 *  @param expectation The expectation from the test side to fulfill.
 */
- (void)fulfillExpectationAfterSmallDelay:(XCTestExpectation *)expectation;

@end
