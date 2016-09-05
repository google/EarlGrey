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

#import <EarlGrey/GREYFrameworkException.h>
#import <EarlGrey/XCTestCase+GREYAdditions.h>

#import "GREYBaseTest.h"

#pragma mark - Example tests

static NSString * const kGREYSampleExceptionName = @"GREYSampleException";
static NSString * const kXCTestCaseInterruptionExceptionName = @"_XCTestCaseInterruptionException";

@interface GREYSampleTests : XCTestCase

@end

@implementation GREYSampleTests

- (void)setUp {
  [super setUp];
  // Use the default failure handler in the example testcases.
  [EarlGrey setFailureHandler:nil];
}

- (void)tearDown {
  // Reset the failure handler to unit test failure handler.
  [EarlGrey setFailureHandler:[[GREYUTFailureHandler alloc] init]];
  [super tearDown];
}

- (void)failUsingGREYAssert {
  GREYAssert(NO, @"Failing test with EarlGrey assertion");
}

- (void)failUsingNSAssert {
  NSAssert(NO, @"Failing test with NSAssert");
}

- (void)failUsingRecordFailureWithDescription {
  [self recordFailureWithDescription:@"Test Failure"
                              inFile:@"XCTestCase+GREYAdditionsTest.m"
                              atLine:0
                            expected:NO];
}

- (void)failByRaisingException {
  [[NSException exceptionWithName:kGREYSampleExceptionName
                           reason:@"Failure from exception test"
                         userInfo:nil] raise];
}

- (void)successfulTest {
  GREYAssert(YES, @"Test should pass");
}

@end

#pragma mark - Actual Tests

@interface XCTestCase_GREYAdditionsTest : GREYBaseTest
@end

@implementation XCTestCase_GREYAdditionsTest

- (void)testGreyStatusIsFailedAfterGreyAssertFailure {
  GREYSampleTests *failingTest =
      [GREYSampleTests testCaseWithSelector:@selector(failUsingGREYAssert)];
  XCTAssertThrowsSpecificNamed([failingTest invokeTest],
                               NSException,
                               kXCTestCaseInterruptionExceptionName);

  NSAssert(failingTest.grey_status == kGREYXCTestCaseStatusFailed,
           @"Test should have failed from GREYAssert failure");
}

- (void)testGreyStatusIsFailedAfterNSAssertFailure {
  GREYSampleTests *failingTest =
      [GREYSampleTests testCaseWithSelector:@selector(failUsingNSAssert)];
  XCTAssertThrowsSpecificNamed([failingTest invokeTest],
                               NSException,
                               NSInternalInconsistencyException);

  NSAssert(failingTest.grey_status == kGREYXCTestCaseStatusFailed,
           @"Test should have failed from NSAssert failure");
}

- (void)testGreyStatusIsFailedAfterRecordFailureWithDescription {
  GREYSampleTests *failingTest =
      [GREYSampleTests testCaseWithSelector:@selector(failUsingRecordFailureWithDescription)];
  [failingTest invokeTest];
  NSAssert(failingTest.grey_status == kGREYXCTestCaseStatusFailed,
           @"Test should have failed from RecordFailureWithDescription");
}


- (void)testGreyStatusIsFailedAfterUncaughtException {
  GREYSampleTests *failingTest =
      [GREYSampleTests testCaseWithSelector:@selector(failByRaisingException)];
  XCTAssertThrowsSpecificNamed([failingTest invokeTest],
                               NSException,
                               kGREYSampleExceptionName);

  NSAssert(failingTest.grey_status == kGREYXCTestCaseStatusFailed,
           @"Test should have failed from uncaught exception");
}

- (void)testGreyStatusIsPassedAfterSuccessfulTest {
  GREYSampleTests *successfulTest =
      [GREYSampleTests testCaseWithSelector:@selector(successfulTest)];
  [successfulTest invokeTest];
  NSAssert(successfulTest.grey_status == kGREYXCTestCaseStatusPassed,
           @"Test should have passed");
}

- (void)testTestStatusIsFailedOnWillTeardownAfterGreyAssertFailure {
  SEL willTearDownObserverSEL = @selector(verifyTestStatusIsFailedOnWillTearDown:);
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:willTearDownObserverSEL
                                               name:kGREYXCTestCaseInstanceWillTearDown
                                             object:nil];

  GREYSampleTests *failingTest =
      [GREYSampleTests testCaseWithSelector:@selector(failUsingGREYAssert)];
  XCTAssertThrowsSpecificNamed([failingTest invokeTest],
                               NSException,
                               kXCTestCaseInterruptionExceptionName);

  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:kGREYXCTestCaseInstanceWillTearDown
                                                object:nil];
}

- (void)testTestStatusIsFailedOnWillTeardownAfterRecordFailureWithDescription {
  SEL willTearDownObserverSEL = @selector(verifyTestStatusIsFailedOnWillTearDown:);
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:willTearDownObserverSEL
                                               name:kGREYXCTestCaseInstanceWillTearDown
                                             object:nil];

  GREYSampleTests *failingTest =
      [GREYSampleTests testCaseWithSelector:@selector(failUsingRecordFailureWithDescription)];
  [failingTest invokeTest];

  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:kGREYXCTestCaseInstanceWillTearDown
                                                object:nil];
}

- (void)testTestStatusIsUnknownOnWillTeardownAfterSuccessfulTest {
  SEL willTearDownObserverSEL = @selector(verifyTestStatusIsUnknownOnWillTearDown:);
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:willTearDownObserverSEL
                                               name:kGREYXCTestCaseInstanceWillTearDown
                                             object:nil];

  GREYSampleTests *successfulTest =
      [GREYSampleTests testCaseWithSelector:@selector(successfulTest)];
  [successfulTest invokeTest];

  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:kGREYXCTestCaseInstanceWillTearDown
                                                object:nil];
}

#pragma mark - Helper methods

- (void)verifyTestStatusIsFailedOnWillTearDown:(NSNotification *)notification {
  XCTestCase *testCase = (XCTestCase *)[notification object];
  NSAssert(testCase.grey_status == kGREYXCTestCaseStatusFailed,
           @"TestCase status should be failed on WillTearDown notification.");
}

- (void)verifyTestStatusIsUnknownOnWillTearDown:(NSNotification *)notification {
  XCTestCase *testCase = (XCTestCase *)[notification object];
  NSAssert(testCase.grey_status == kGREYXCTestCaseStatusUnknown,
           @"TestCase status should be unknown on WillTearDown notification.");
}

@end
