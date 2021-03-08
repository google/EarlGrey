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
  [super setUp];
  _dummyTest = [[DistantObjectCrashHandlerDummyTest alloc] init];
  static dispatch_once_t once_token;
  dispatch_once(&once_token, ^{
    // Trigger EG2's swizzling on DistantObjectCrashHandlerDummyTest's -setUp and -tearDown method.
    [_dummyTest invokeTest];
  });
  [self.application terminate];
}

- (void)tearDown {
  [EarlGrey setHostApplicationCrashHandler:[self defaultCrashHandler]];
  [self.application launch];
  [super tearDown];
}

/**
 * Tests GREYTestApplicationDistantObject throws an exception when test makes eDO call but the
 * app-under-test is not active.
 */
- (void)testDistantObjectThrowsException {
  GREYFrameworkException *exception;
  @try {
    __unused UIView *view = GREY_ALLOC_REMOTE_CLASS_IN_APP(UIView);
  } @catch (GREYFrameworkException *capturedException) {
    exception = capturedException;
  }
  XCTAssertEqualObjects(exception.name, @"GenericFailureException");
  XCTAssertTrue([exception.reason containsString:@"App crashed and disconnected."]);
}

/**
 * Tests EarlGrey's host application crash handler is called when EarlGrey detects the crash of the
 * app-under-test at the -tearDown of the same test case.
 */
- (void)testInvokesCrashHandlerAtTearDown {
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
  XCTAssertNil(GREY_ALLOC_REMOTE_CLASS_IN_APP(UIView));

  [_dummyTest tearDown];
  XCTAssertTrue(isErrorHandlerCalled);
  XCTAssertFalse(isCrashHandlerCalled);
}

@end
