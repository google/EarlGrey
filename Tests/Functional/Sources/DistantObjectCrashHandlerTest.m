//
// Copyright 2020 Google Inc.
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

#import "EarlGrey.h"
#import "BaseIntegrationTest.h"

/**
 * The dummy test case which will be used by DistantObjectCrashHandlerTest to mimic the lifecycle of
 * the test case.
 */
@interface DistantObjectCrashHandlerDummyTest : XCTestCase
@end

@implementation DistantObjectCrashHandlerDummyTest
@end

/**
 * Test cases for checking that EarlGrey throws exception and calls crash handler when
 * app-under-test has crashed.
 */
@interface DistantObjectCrashHandlerTest : BaseIntegrationTest
@end

@implementation DistantObjectCrashHandlerTest {
  DistantObjectCrashHandlerDummyTest *_dummyTest;
}

- (void)setUp {
  _dummyTest = [[DistantObjectCrashHandlerDummyTest alloc] init];
  static dispatch_once_t once_token;
  dispatch_once(&once_token, ^{
    // Trigger EG2's swizzling on DistantObjectCrashHandlerDummyTest's -setUp and -tearDown method.
    [_dummyTest invokeTest];
  });
  [super setUp];
}

- (void)tearDown {
  [EarlGrey setHostApplicationCrashHandler:[self defaultCrashHandler]];
  if (!GREYTestApplicationDistantObject.sharedInstance.hostActiveWithAppComponent) {
    [self.application launch];
  }
  [super tearDown];
}

/**
 * Tests GREYTestApplicationDistantObject throws an exception when test makes eDO call but the
 * app-under-test is not active.
 */
- (void)testDistantObjectThrowsExceptionOnAppTerminated {
  [self.application terminate];

  GREYFrameworkException *exception;
  @try {
    __unused UIView *view = GREY_ALLOC_REMOTE_CLASS_IN_APP(UIView);
  } @catch (GREYFrameworkException *capturedException) {
    exception = capturedException;
  }
  XCTAssertEqualObjects(exception.name, @"GenericFailureException");
  XCTAssertTrue([exception.reason containsString:@"App crashed and disconnected."]);
}

/** Ensures uncommon eDO error is provided with instructions. */
- (void)testDistantObjectThrowsExceptionWithBadRequest {
  XCTSkip(@"b/327270471 - Fix failure introduced with Xcode 15");
  [self.application terminate];

  // There is no easy way to reproduce other eDO error code without accessing eDO's private APIs,
  // thus here the test will call error handler directly.
  EDOClientErrorHandler greyErrorHandler = EDOSetClientErrorHandler(^(NSError *error){
  });
  [self addTeardownBlock:^{
    EDOSetClientErrorHandler(greyErrorHandler);
  }];
  NSError *error = [NSError errorWithDomain:@"dummy error" code:0 userInfo:nil];
  GREYFrameworkException *exception;
  @try {
    greyErrorHandler(error);
  } @catch (GREYFrameworkException *capturedException) {
    exception = capturedException;
  }
  XCTAssertEqualObjects(exception.name, @"GenericFailureException");
  XCTAssertTrue([exception.reason
      containsString:
          @"eDO invocation in the EarlGrey test-process failed with an uncommon error code: 0."]);

  error = [NSError errorWithDomain:@"dummy error" code:-999 userInfo:nil];
  @try {
    greyErrorHandler(error);
  } @catch (GREYFrameworkException *capturedException) {
    exception = capturedException;
  }
  XCTAssertEqualObjects(exception.name, @"GenericFailureException");
  XCTAssertTrue(
      [exception.reason containsString:@"Please check the application logs to debug further."]);
}

/**
 * Tests EarlGrey's host application crash handler is called when EarlGrey detects the crash of the
 * app-under-test at the -tearDown of the same test case.
 */
- (void)testInvokesCrashHandlerAtTearDown {
  [self.application terminate];
  [_dummyTest setUp];

  __block BOOL isHandlerCalled = NO;
  [EarlGrey setHostApplicationCrashHandler:^{
    isHandlerCalled = YES;
  }];
  XCTAssertThrows(GREY_ALLOC_REMOTE_CLASS_IN_APP(UIView));

  [_dummyTest tearDown];
  XCTAssertTrue(isHandlerCalled);
}

/**
 * Tests EarlGrey's host application crash handler is called when EarlGrey detects the crash of the
 * app-under-test at the -setUp of the next test case.
 */
- (void)testInvokesCrashHandlerAtSetUp {
  [self.application terminate];
  [_dummyTest setUp];
  [_dummyTest tearDown];

  __block BOOL isHandlerCalled = NO;
  [EarlGrey setHostApplicationCrashHandler:^{
    isHandlerCalled = YES;
  }];
  XCTAssertThrows(GREY_ALLOC_REMOTE_CLASS_IN_APP(UIView));

  [_dummyTest setUp];
  XCTAssertTrue(isHandlerCalled);
}

/** Tests crash handler is not called when it is set after EarlGrey first detected app's crash. */
- (void)testCrashHandlerNotInvokedIfSetAfterCrash {
  [self.application terminate];
  [EarlGrey setHostApplicationCrashHandler:nil];
  DistantObjectCrashHandlerDummyTest *dummyTest = [[DistantObjectCrashHandlerDummyTest alloc] init];
  [dummyTest setUp];

  __block BOOL isHandlerCalled = NO;
  XCTAssertThrows(GREY_ALLOC_REMOTE_CLASS_IN_APP(UIView));

  [dummyTest tearDown];
  [EarlGrey setHostApplicationCrashHandler:^{
    isHandlerCalled = YES;
  }];
  [dummyTest setUp];
  [dummyTest tearDown];
  XCTAssertFalse(isHandlerCalled);
}

/**
 * Tests EarlGrey's host application crash handler is called once for each launch of
 * app-under-test.
 */
- (void)testInvokesCrashHandlerOncePerLaunch {
  [self.application terminate];
  [_dummyTest setUp];

  __block NSUInteger handlerInvocationCount = 0;
  [EarlGrey setHostApplicationCrashHandler:^{
    handlerInvocationCount++;
  }];
  XCTAssertThrows(GREY_ALLOC_REMOTE_CLASS_IN_APP(UIView));

  [_dummyTest tearDown];
  [_dummyTest setUp];
  [_dummyTest tearDown];
  XCTAssertEqual(handlerInvocationCount, 1);

  [self.application launch];
  [self.application terminate];
  XCTAssertThrows(GREY_ALLOC_REMOTE_CLASS_IN_APP(UIView));
  [_dummyTest setUp];
  [_dummyTest tearDown];

  XCTAssertEqual(handlerInvocationCount, 2);
}

/**
 * Tests EarlGrey's host application crash handler is not called if EarlGrey's
 * EDOClientErrorHandler is overridden.
 */
- (void)testCrashHandlerIsNotInvokedWhenOverrideEDOErrorHandler {
  [self.application terminate];

  __block BOOL isErrorHandlerCalled = NO;
  EDOClientErrorHandler greyErrorHandler = EDOSetClientErrorHandler(^(NSError *error) {
    isErrorHandlerCalled = YES;
  });
  [self addTeardownBlock:^{
    EDOSetClientErrorHandler(greyErrorHandler);
  }];

  [_dummyTest setUp];

  __block BOOL isCrashHandlerCalled = NO;
  [EarlGrey setHostApplicationCrashHandler:^{
    isCrashHandlerCalled = YES;
  }];
  XCTAssertNil(GREY_REMOTE_CLASS_IN_APP_OR_NIL(UIView));

  [_dummyTest tearDown];
  XCTAssertTrue(isErrorHandlerCalled);
  XCTAssertFalse(isCrashHandlerCalled);
}

/** Verifies EarlGrey reports stale remote object with clear error message. */
- (void)testCrashHandlerReportsStaleRemoteObjectError {
  NSObject *remoteObject = [[GREY_REMOTE_CLASS_IN_APP(NSObject) alloc] init];

  // Relaunch app-under-test to make `remoteObject` stale.
  XCUIApplication *application = [[XCUIApplication alloc] init];
  [application launch];

  XCTAssertGreaterThan(GREYTestApplicationDistantObject.sharedInstance.hostPort, 0);
  NSException *edoError = nil;
  @try {
    [remoteObject description];
  } @catch (NSException *e) {
    edoError = e;
  }
  XCTAssertTrue([edoError.description containsString:@"Stale remote object is used"]);
}

@end
