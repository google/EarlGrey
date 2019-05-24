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

#import <XCTest/XCTest.h>

#import "CommonLib/Exceptions/GREYFailureHandler.h"
#import "CommonLib/Exceptions/GREYFrameworkException.h"
#import "TestLib/XCTestCase/XCTestCase+GREYTest.h"

GREY_EXPORT id<GREYFailureHandler> grey_getTestFailureHandler();

// Setter for the failure handler for this test.
GREY_EXPORT void grey_setTestFailureHandler(id<GREYFailureHandler> handler);

#pragma mark - Example tests

static NSString *const kGREYTestFailureHandlerKey = @"SampleFailureHandler";
static NSString *const kGREYSampleExceptionName = @"GREYSampleException";

static NSString *gXCTestCaseInterruptionExceptionName;

#pragma mark - Failure Handler

// Failure handler for the XCTestCase+GREYTest Tests.
@interface GREYUTFailureHandler : NSObject <GREYFailureHandler> {
  NSString *_fileName;
  NSUInteger _lineNumber;
}

@end

@implementation GREYUTFailureHandler

- (void)setInvocationFile:(NSString *)fileName andInvocationLine:(NSUInteger)lineNumber {
  _fileName = fileName;
  _lineNumber = lineNumber;
}

- (void)handleException:(GREYFrameworkException *)exception details:(NSString *)details {
  [exception raise];
}

@end

#pragma mark - Example tests

@interface GREYSampleTests : XCTestCase

@property(nonatomic, assign) BOOL failInSetUp;
@property(nonatomic, assign) BOOL failInTearDown;

@end

/**
 *  Generates a kGREYAssertionFailedException with the provided @c __description if the expression
 *  @c __a1 evaluates to @c NO.
 *
 *  @param __a1          The expression that should be evaluated.
 *  @param __description Description to print if @c __a1 evaluates to @c NO. May be a format
 *                       string, in which case the variable args will be required.
 *  @param ...           Variable args for @c __description if it is a format string.
 */
#define I_GREYTestAssertTrue(__a1, __description, ...)                            \
  ({                                                                              \
    if (!(__a1)) {                                                                \
      id<GREYFailureHandler> failureHandler__ = grey_getTestFailureHandler();     \
      GREYFrameworkException *exception__ =                                       \
          [GREYFrameworkException exceptionWithName:kGREYAssertionFailedException \
                                             reason:(__description)];             \
      [failureHandler__ handleException:exception__ details:@""];                 \
    }                                                                             \
  })

@implementation GREYSampleTests

+ (void)initialize {
  if (self == [GREYSampleTests class]) {
    NSOperatingSystemVersion iOS11OrAbove = {
        .majorVersion = 11, .minorVersion = 0, .patchVersion = 0};
    if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:iOS11OrAbove]) {
      gXCTestCaseInterruptionExceptionName = @"NSInternalInconsistencyException";
    } else {
      gXCTestCaseInterruptionExceptionName = @"_XCTestCaseInterruptionException";
    }
  }
}

- (void)setUp {
  [super setUp];
  grey_setTestFailureHandler(nil);
  if (self.failInSetUp) {
    I_GREYTestAssertTrue(NO, @"Induced failure in setUp.");
  }
}

- (void)tearDown {
  [super tearDown];
  if (self.failInTearDown) {
    I_GREYTestAssertTrue(NO, @"Induced failure in tearDown.");
  }
}

- (void)failUsingGREYAssert {
  I_GREYTestAssertTrue(NO, @"Failing test with GREYAssert.");
}

- (void)failUsingNSAssert {
  NSAssert(NO, @"Failing test with NSAssert.");
}

- (void)failUsingRecordFailureWithDescription {
  [self recordFailureWithDescription:@"Test Failure"
                              inFile:@"XCTestCase+GREYTestTest.m"
                              atLine:0
                            expected:NO];
}

- (void)failByRaisingException {
  [[NSException exceptionWithName:kGREYSampleExceptionName
                           reason:@"Failure from exception test"
                         userInfo:nil] raise];
}

- (void)successfulTest {
  XCTAssertTrue(YES, @"Test should pass.");
}

@end

#pragma mark - Actual Tests

@interface XCTestCase_GREYTestAdditionsTest : XCTestCase
@end

@implementation XCTestCase_GREYTestAdditionsTest

- (void)setUp {
  [super setUp];
  grey_setTestFailureHandler([[GREYUTFailureHandler alloc] init]);
}

- (void)tearDown {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  grey_setTestFailureHandler(nil);
  [super tearDown];
}

// TODO: Ensure all invokeTest calls have the specific _XCTestCaseInterruptionException thrown.
- (void)testGreyStatusIsFailedAfterGreyAssertFailure {
  GREYSampleTests *failingTest =
      [GREYSampleTests testCaseWithSelector:@selector(failUsingGREYAssert)];
  XCTAssertThrows([failingTest invokeTest]);

  NSAssert(failingTest.grey_status == kGREYXCTestCaseStatusFailed,
           @"Test should have failed from GREYAssert failure");
}

- (void)testGreyStatusIsFailedAfterNSAssertFailure {
  GREYSampleTests *failingTest =
      [GREYSampleTests testCaseWithSelector:@selector(failUsingNSAssert)];
  XCTAssertThrows([failingTest invokeTest]);

  NSAssert(failingTest.grey_status == kGREYXCTestCaseStatusFailed,
           @"Test should have failed from NSAssert failure");
}

- (void)testGreyStatusIsFailedAfterRecordFailureWithDescription {
  GREYSampleTests *failingTest =
      [GREYSampleTests testCaseWithSelector:@selector(failUsingRecordFailureWithDescription)];
  XCTestRun *testRun = [XCTestRun testRunWithTest:failingTest];
  NSAssert(testRun, @"Test Run cannot be nil.");
  [[testRun test] performTest:testRun];
  NSAssert(failingTest.grey_status == kGREYXCTestCaseStatusFailed,
           @"Test should have failed from RecordFailureWithDescription");
  XCTAssertTrue(YES);
}

- (void)testGreyStatusIsFailedAfterUncaughtException {
  GREYSampleTests *failingTest =
      [GREYSampleTests testCaseWithSelector:@selector(failByRaisingException)];
  XCTAssertThrows([failingTest invokeTest]);

  NSAssert(failingTest.grey_status == kGREYXCTestCaseStatusFailed,
           @"Test should have failed from uncaught exception");
}

- (void)testGreyStatusIsPassedAfterSuccessfulTest {
  GREYSampleTests *successfulTest =
      [GREYSampleTests testCaseWithSelector:@selector(successfulTest)];
  [successfulTest invokeTest];
  NSAssert(successfulTest.grey_status == kGREYXCTestCaseStatusPassed, @"Test should have passed");
}

- (void)testTestStatusIsFailedOnWillTeardownAfterGREYAssertFailure {
  SEL willTearDownObserverSEL = @selector(verifyTestStatusIsFailedOnWillTearDown:);
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:willTearDownObserverSEL
                                               name:kGREYXCTestCaseInstanceWillTearDown
                                             object:nil];

  GREYSampleTests *failingTest =
      [GREYSampleTests testCaseWithSelector:@selector(failUsingGREYAssert)];
  XCTAssertThrows([failingTest invokeTest]);

  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:kGREYXCTestCaseInstanceWillTearDown
                                                object:nil];
}

- (void)testTestStatusIsFailedOnWillTeardownAfterNSAssertFailure {
  SEL willTearDownObserverSEL = @selector(verifyTestStatusIsFailedOnWillTearDown:);
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:willTearDownObserverSEL
                                               name:kGREYXCTestCaseInstanceWillTearDown
                                             object:nil];

  GREYSampleTests *failingTest =
      [GREYSampleTests testCaseWithSelector:@selector(failUsingNSAssert)];
  XCTAssertThrows([failingTest invokeTest]);

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
  XCTestRun *testRun = [XCTestRun testRunWithTest:failingTest];
  NSAssert(testRun, @"Test Run cannot be nil.");
  [[testRun test] performTest:testRun];
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:kGREYXCTestCaseInstanceWillTearDown
                                                object:nil];
}

- (void)testTestStatusIsFailedOnWillTeardownAfterUncaughtException {
  SEL willTearDownObserverSEL = @selector(verifyTestStatusIsFailedOnWillTearDown:);
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:willTearDownObserverSEL
                                               name:kGREYXCTestCaseInstanceWillTearDown
                                             object:nil];

  GREYSampleTests *failingTest =
      [GREYSampleTests testCaseWithSelector:@selector(failByRaisingException)];
  XCTAssertThrows([failingTest invokeTest]);

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

- (void)testPassedSetUpSendsNotifications {
  GREYSampleTests *passingTest = [GREYSampleTests testCaseWithSelector:@selector(successfulTest)];

  __block BOOL willSetUpCalled = NO;
  void (^willSetUpBlock)(NSNotification *) = ^(NSNotification *_Nonnull note) {
    willSetUpCalled = YES;
    XCTAssertEqual(note.object, passingTest);
  };

  __block BOOL didSetUpCalled = NO;
  void (^didSetUpBlock)(NSNotification *) = ^(NSNotification *_Nonnull note) {
    didSetUpCalled = YES;
    XCTAssertEqual(note.object, passingTest);
  };
  id notificationID1 =
      [[NSNotificationCenter defaultCenter] addObserverForName:kGREYXCTestCaseInstanceWillSetUp
                                                        object:nil
                                                         queue:nil
                                                    usingBlock:willSetUpBlock];
  id notificationID2 =
      [[NSNotificationCenter defaultCenter] addObserverForName:kGREYXCTestCaseInstanceDidSetUp
                                                        object:nil
                                                         queue:nil
                                                    usingBlock:didSetUpBlock];

  [passingTest invokeTest];
  XCTAssertTrue(willSetUpCalled);
  XCTAssertTrue(didSetUpCalled);

  [[NSNotificationCenter defaultCenter] removeObserver:notificationID1];
  [[NSNotificationCenter defaultCenter] removeObserver:notificationID2];
}

- (void)testFailedSetUpSendsNotifications {
  GREYSampleTests *failingSetUpTest =
      [GREYSampleTests testCaseWithSelector:@selector(successfulTest)];
  failingSetUpTest.failInSetUp = YES;

  __block BOOL willSetUpCalled = NO;
  void (^willSetUpBlock)(NSNotification *) = ^(NSNotification *_Nonnull note) {
    willSetUpCalled = YES;
    XCTAssertEqual(note.object, failingSetUpTest);
  };

  __block BOOL didSetUpCalled = NO;
  void (^didSetUpBlock)(NSNotification *) = ^(NSNotification *_Nonnull note) {
    didSetUpCalled = YES;
    XCTAssertEqual(note.object, failingSetUpTest);
  };
  id notificationID1 =
      [[NSNotificationCenter defaultCenter] addObserverForName:kGREYXCTestCaseInstanceWillSetUp
                                                        object:nil
                                                         queue:nil
                                                    usingBlock:willSetUpBlock];
  id notificationID2 =
      [[NSNotificationCenter defaultCenter] addObserverForName:kGREYXCTestCaseInstanceDidSetUp
                                                        object:nil
                                                         queue:nil
                                                    usingBlock:didSetUpBlock];

  XCTAssertThrows([failingSetUpTest invokeTest]);
  XCTAssertTrue(willSetUpCalled);
  XCTAssertFalse(didSetUpCalled);

  [[NSNotificationCenter defaultCenter] removeObserver:notificationID1];
  [[NSNotificationCenter defaultCenter] removeObserver:notificationID2];
}

- (void)testPassedTearDownSendsNotifications {
  GREYSampleTests *passingTest = [GREYSampleTests testCaseWithSelector:@selector(successfulTest)];

  __block BOOL willTearDownCalled = NO;
  void (^willTearDownBlock)(NSNotification *) = ^(NSNotification *_Nonnull note) {
    willTearDownCalled = YES;
    XCTAssertEqual(note.object, passingTest);
  };

  __block BOOL didTearDownCalled = NO;
  void (^didTearDownBlock)(NSNotification *) = ^(NSNotification *_Nonnull note) {
    didTearDownCalled = YES;
    XCTAssertEqual(note.object, passingTest);
  };
  id notificationID1 =
      [[NSNotificationCenter defaultCenter] addObserverForName:kGREYXCTestCaseInstanceWillTearDown
                                                        object:nil
                                                         queue:nil
                                                    usingBlock:willTearDownBlock];
  id notificationID2 =
      [[NSNotificationCenter defaultCenter] addObserverForName:kGREYXCTestCaseInstanceDidTearDown
                                                        object:nil
                                                         queue:nil
                                                    usingBlock:didTearDownBlock];

  [passingTest invokeTest];
  XCTAssertTrue(willTearDownCalled);
  XCTAssertTrue(didTearDownCalled);

  [[NSNotificationCenter defaultCenter] removeObserver:notificationID1];
  [[NSNotificationCenter defaultCenter] removeObserver:notificationID2];
}

- (void)testFailedTearDownSendsNotifications {
  GREYSampleTests *failingTearDownTest =
      [GREYSampleTests testCaseWithSelector:@selector(successfulTest)];
  failingTearDownTest.failInTearDown = YES;

  __block BOOL willTearDownCalled = NO;
  void (^willTearDownBlock)(NSNotification *) = ^(NSNotification *_Nonnull note) {
    willTearDownCalled = YES;
    XCTAssertEqual(note.object, failingTearDownTest);
  };

  __block BOOL didTearDownCalled = NO;
  void (^didTearDownBlock)(NSNotification *) = ^(NSNotification *_Nonnull note) {
    didTearDownCalled = YES;
    XCTAssertEqual(note.object, failingTearDownTest);
  };
  id notificationID1 =
      [[NSNotificationCenter defaultCenter] addObserverForName:kGREYXCTestCaseInstanceWillTearDown
                                                        object:nil
                                                         queue:nil
                                                    usingBlock:willTearDownBlock];
  id notificationID2 =
      [[NSNotificationCenter defaultCenter] addObserverForName:kGREYXCTestCaseInstanceDidTearDown
                                                        object:nil
                                                         queue:nil
                                                    usingBlock:didTearDownBlock];

  XCTAssertThrows([failingTearDownTest invokeTest]);
  XCTAssertTrue(willTearDownCalled);
  XCTAssertFalse(didTearDownCalled);

  [[NSNotificationCenter defaultCenter] removeObserver:notificationID1];
  [[NSNotificationCenter defaultCenter] removeObserver:notificationID2];
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

#pragma mark - Failure Handler Utilities

inline void grey_setTestFailureHandler(id<GREYFailureHandler> handler) {
  @synchronized(kGREYTestFailureHandlerKey) {
    if (handler) {
      NSMutableDictionary *TLSDict = [[NSThread mainThread] threadDictionary];
      [TLSDict setValue:handler forKey:kGREYTestFailureHandlerKey];
    }
  }
}

// Gets the failure handler. Must be called from main thread otherwise behavior is undefined.
inline id<GREYFailureHandler> grey_getTestFailureHandler() {
  assert([NSThread isMainThread]);
  NSMutableDictionary *TLSDict = [[NSThread mainThread] threadDictionary];
  return [TLSDict valueForKey:kGREYTestFailureHandlerKey];
}
