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
    [EarlGrey setRemoteExecutionsDispatchPolicy:GREYRemoteExecutionsDispatchPolicyBackground];
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
  [EarlGrey setRemoteExecutionsDispatchPolicy:GREYRemoteExecutionsDispatchPolicyMain];
  XCTAssertEqualObjects(handler.exception.name, @"com.google.earlgrey.InitializationErrorDomain");
  XCTAssertTrue([handler.exception.reason containsString:@"service was already started"]);
}

/** Verifies dispatch policy cannot be overridden after app-under-test is terminated. */
- (void)testFailedToChangeDispatchPolicyAfterAppTermination {
  BackgroundExecutionFailureHandler *handler = [self setUpFakeHandler];
  XCUIApplication *application = [[XCUIApplication alloc] init];
  [application terminate];
  [EarlGrey setRemoteExecutionsDispatchPolicy:GREYRemoteExecutionsDispatchPolicyMain];
  [application launch];
  XCTAssertEqualObjects(handler.exception.name, @"com.google.earlgrey.InitializationErrorDomain");
  XCTAssertTrue([handler.exception.reason containsString:@"service was already started"]);
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
