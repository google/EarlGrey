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

#include <stddef.h>

#import "EarlGrey.h"
#import "GREYHostApplicationDistantObject+RemoteTest.h"

@interface BackgroundExecutionFailureHandler : NSObject <GREYFailureHandler>

@property(nonatomic, readonly) GREYFrameworkException *exception;

@end

@interface DistantObjectBackgroundExecutionTest : XCTestCase
@end

@implementation DistantObjectBackgroundExecutionTest

- (void)setUp {
  [super setUp];
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [EarlGrey setRemoteExecutionDispatchPolicy:GREYRemoteExecutionDispatchPolicyBackground];
    XCUIApplication *application = [[XCUIApplication alloc] init];
    [application launch];
  });
}

/** Verifies that the remote call from app-under-test is executed in background queue. */
- (void)testCallbackRunsOnBackgroundThread {
  XCTestExpectation *expectation = [self expectationWithDescription:@"Test Expectation"];
  id block = ^{
    NSString *executeQueueName =
        [NSString stringWithUTF8String:dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL)];
    XCTAssertEqualObjects(executeQueueName, @"com.google.earlgrey.TestDO");
    [expectation fulfill];
  };
  [GREYHostApplicationDistantObject.sharedInstance invokeRemoteBlock:block withDelay:0];
  [self waitForExpectations:@[ expectation ] timeout:1];
}

/** Verifies test case execution will not block the remote call from app-under-test. */
- (void)testCallbackIsNotBlockedByTestExecution {
  __block NSUInteger count = 0;
  id block = ^{
    count++;
  };
  for (NSUInteger index = 0; index < 10; ++index) {
    [GREYHostApplicationDistantObject.sharedInstance invokeRemoteBlock:block withDelay:0];
  }
  XCTAssertGreaterThan(count, 0);
}

/** Verifies dispatch policy cannot be overridden after app-under-test launch. */
- (void)testFailedToChangeDispatchPolicyAfterAppLaunch {
  BackgroundExecutionFailureHandler *handler = [self setUpFakeHandler];
  [EarlGrey setRemoteExecutionDispatchPolicy:GREYRemoteExecutionDispatchPolicyMain];
  XCTAssertEqualObjects(handler.exception.name, @"com.google.earlgrey.InitializationErrorDomain");
  XCTAssertTrue([handler.exception.reason
      containsString:@"You cannot set dispatch policy after XCUIApplication::launch."]);
}

/** Verifies dispatch policy cannot be overridden after app-under-test is terminated. */
- (void)testFailedToChangeDispatchPolicyAfterAppTermination {
  BackgroundExecutionFailureHandler *handler = [self setUpFakeHandler];
  XCUIApplication *application = [[XCUIApplication alloc] init];
  [application terminate];
  [EarlGrey setRemoteExecutionDispatchPolicy:GREYRemoteExecutionDispatchPolicyMain];
  [application launch];
  XCTAssertEqualObjects(handler.exception.name, @"com.google.earlgrey.InitializationErrorDomain");
  XCTAssertTrue([handler.exception.reason
      containsString:@"You cannot set dispatch policy after XCUIApplication::launch."]);
}

#pragma mark - private

- (BackgroundExecutionFailureHandler *)setUpFakeHandler {
  BackgroundExecutionFailureHandler *handler = [[BackgroundExecutionFailureHandler alloc] init];
  id<GREYFailureHandler> defaultHandler =
      [[[NSThread currentThread] threadDictionary] valueForKey:GREYFailureHandlerKey];
  [NSThread currentThread].threadDictionary[GREYFailureHandlerKey] = handler;
  [self addTeardownBlock:^{
    [NSThread currentThread].threadDictionary[GREYFailureHandlerKey] = defaultHandler;
  }];
  return handler;
}

@end

@implementation BackgroundExecutionFailureHandler

- (void)handleException:(GREYFrameworkException *)exception details:(NSString *)details {
  _exception = exception;
}

- (void)setInvocationFile:(NSString *)fileName andInvocationLine:(NSUInteger)lineNumber {
  // no-op.
}

@end
