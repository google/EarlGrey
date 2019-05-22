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

#import "AppFramework/Additions/NSObject+GREYApp.h"
#import "CommonLib/Config/GREYConfiguration.h"
#import "Tests/Unit/AppFramework/GREYAppBaseTest.h"
#import "third_party/objective_c/ocmock/v3/Source/OCMock/OCMock.h"

@interface NSObject_GREYAppAdditionsTest : GREYAppBaseTest
@end

@implementation NSObject_GREYAppAdditionsTest {
  BOOL _delayedExecution;
  NSUInteger _delayedExecutionCount;
  NSUInteger _delayedExecutionWithParamCount;
  NSUInteger _delayedExecutionWithoutParamCount;
}

- (void)setUp {
  [super setUp];
  _delayedExecution = NO;
  _delayedExecutionCount = 0;
  _delayedExecutionWithParamCount = 0;
  _delayedExecutionWithoutParamCount = 0;
}

- (void)testPerformSelectorAfterDelayOnMainThreadIsTracked {
  double delay = GREY_CONFIG_DOUBLE(kGREYConfigKeyDelayedPerformMaxTrackableDuration) / 2;
  [self performSelector:@selector(grey_delayedExecutionSelector:) withObject:self afterDelay:delay];

  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];
  XCTAssertTrue(_delayedExecution);
  XCTAssertEqual(_delayedExecutionCount, 1u);
}

- (void)testPerformSelectorAfterDelayWithBlockObjectOnMainThreadIsTracked {
  double delay = GREY_CONFIG_DOUBLE(kGREYConfigKeyDelayedPerformMaxTrackableDuration) / 2;
  __block BOOL performed = NO;
  [[self class] performSelector:@selector(grey_delayedExecutionSelectorBlockParam:)
                     withObject:^{
                       performed = YES;
                     }
                     afterDelay:delay];

  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];
  XCTAssertTrue(performed);
}

- (void)testPerformSelectorAfterDelayOnMainThreadIsTracked_nilObject {
  double delay = GREY_CONFIG_DOUBLE(kGREYConfigKeyDelayedPerformMaxTrackableDuration) / 2;
  [self performSelector:@selector(grey_delayedExecutionSelector) withObject:nil afterDelay:delay];

  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];
  XCTAssertTrue(_delayedExecution);
  XCTAssertEqual(_delayedExecutionCount, 1u);
}

- (void)testMultiplePerformSelectorAfterDelayOnMainThreadIsTracked {
  double delay = GREY_CONFIG_DOUBLE(kGREYConfigKeyDelayedPerformMaxTrackableDuration) / 2;
  [self performSelector:@selector(grey_delayedExecutionSelector:) withObject:self afterDelay:delay];
  [self performSelector:@selector(grey_delayedExecutionSelector:) withObject:self afterDelay:delay];
  [self performSelector:@selector(grey_delayedExecutionSelector:) withObject:self afterDelay:0];
  [self performSelector:@selector(grey_delayedExecutionSelector:) withObject:self afterDelay:0];

  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];
  XCTAssertTrue(_delayedExecution);
  XCTAssertEqual(_delayedExecutionCount, 4u);
}

- (void)testMultiplePerformSelectorAfterDelayOnMainThreadIsTracked_nilObject {
  double delay = GREY_CONFIG_DOUBLE(kGREYConfigKeyDelayedPerformMaxTrackableDuration) / 2;
  [self performSelector:@selector(grey_delayedExecutionSelector) withObject:nil afterDelay:delay];
  [self performSelector:@selector(grey_delayedExecutionSelector) withObject:nil afterDelay:delay];
  [self performSelector:@selector(grey_delayedExecutionSelector) withObject:nil afterDelay:0];
  [self performSelector:@selector(grey_delayedExecutionSelector) withObject:nil afterDelay:0];

  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];
  XCTAssertTrue(_delayedExecution);
  XCTAssertEqual(_delayedExecutionCount, 4u);
}

- (void)testPerformSelectorAfterDelayOnMainThreadIsNotTrackedAfterCancel {
  [self performSelector:@selector(grey_delayedExecutionSelector:) withObject:self afterDelay:0];
  [NSObject cancelPreviousPerformRequestsWithTarget:self];

  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];
  XCTAssertFalse(_delayedExecution);
  XCTAssertEqual(_delayedExecutionCount, 0u);

  double delay = GREY_CONFIG_DOUBLE(kGREYConfigKeyDelayedPerformMaxTrackableDuration) / 2;
  [self performSelector:@selector(grey_delayedExecutionSelector:) withObject:self afterDelay:delay];
  [NSObject cancelPreviousPerformRequestsWithTarget:self
                                           selector:@selector(grey_delayedExecutionSelector:)
                                             object:self];

  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];
  XCTAssertFalse(_delayedExecution);
  XCTAssertEqual(_delayedExecutionCount, 0u);
}

- (void)testPerformSelectorAfterDelayOnMainThreadIsNotTrackedAfterCancel_nilObject {
  [self performSelector:@selector(grey_delayedExecutionSelector) withObject:nil afterDelay:0];
  [NSObject cancelPreviousPerformRequestsWithTarget:self];

  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];
  XCTAssertFalse(_delayedExecution);
  XCTAssertEqual(_delayedExecutionCount, 0u);

  double delay = GREY_CONFIG_DOUBLE(kGREYConfigKeyDelayedPerformMaxTrackableDuration) / 2;
  [self performSelector:@selector(grey_delayedExecutionSelector:) withObject:self afterDelay:delay];
  [NSObject cancelPreviousPerformRequestsWithTarget:self
                                           selector:@selector(grey_delayedExecutionSelector:)
                                             object:self];

  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];
  XCTAssertFalse(_delayedExecution);
  XCTAssertEqual(_delayedExecutionCount, 0u);
}

- (void)testMultiplePerformSelectorAfterDelayOnMainThreadAfterCancel {
  double delay = GREY_CONFIG_DOUBLE(kGREYConfigKeyDelayedPerformMaxTrackableDuration) / 2;
  // This will be executed.
  [self performSelector:@selector(grey_delayedExecutionSelector:) withObject:self afterDelay:delay];
  // This will be executed.
  [self performSelector:@selector(grey_delayedExecutionSelector:) withObject:self afterDelay:delay];
  // This will be cancelled.
  [self performSelector:@selector(grey_delayedExecutionSelector) withObject:nil afterDelay:delay];
  // This will be cancelled.
  [self performSelector:@selector(grey_delayedExecutionSelector) withObject:nil afterDelay:0];
  [NSObject cancelPreviousPerformRequestsWithTarget:self
                                           selector:@selector(grey_delayedExecutionSelector)
                                             object:nil];

  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];
  XCTAssertTrue(_delayedExecution);
  XCTAssertEqual(_delayedExecutionWithoutParamCount, 0u);
  XCTAssertEqual(_delayedExecutionWithParamCount, 2u);
  XCTAssertEqual(_delayedExecutionCount, 2u);
}

- (void)testCancelPerformSelectorAfterDelayOnMainThread {
  XCTAssertNoThrow([NSObject cancelPreviousPerformRequestsWithTarget:self
                                                            selector:@selector(setUp)
                                                              object:self]);
  XCTAssertNoThrow(
      [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(setUp) object:nil]);
  XCTAssertNoThrow([NSObject cancelPreviousPerformRequestsWithTarget:self]);
}

- (void)testCancelPerformSelectorAfterDelayOnBackgroundThread {
  NSOperationQueue *backgroundQ = [[NSOperationQueue alloc] init];
  XCTestExpectation *expectation = [self expectationWithDescription:@"backgroundQ finished."];
  [backgroundQ addOperationWithBlock:^{
    XCTAssertNoThrow([NSObject cancelPreviousPerformRequestsWithTarget:self
                                                              selector:@selector(setUp)
                                                                object:self]);
    XCTAssertNoThrow([NSObject cancelPreviousPerformRequestsWithTarget:self
                                                              selector:@selector(setUp)
                                                                object:nil]);
    XCTAssertNoThrow([NSObject cancelPreviousPerformRequestsWithTarget:self]);
    [expectation fulfill];
  }];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testPerformSelectorAfterMaxDelayOnMainThreadIsNotTracked {
  double delay = GREY_CONFIG_DOUBLE(kGREYConfigKeyDelayedPerformMaxTrackableDuration) * 2;
  [self performSelector:@selector(grey_delayedExecutionSelector:) withObject:self afterDelay:delay];

  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];
  XCTAssertFalse(_delayedExecution);
}

- (void)testPerformSelectorAfterDelayOnBackgroundThreadIsNotTracked {
  double delay = GREY_CONFIG_DOUBLE(kGREYConfigKeyDelayedPerformMaxTrackableDuration) / 2;
  NSOperationQueue *backgroundQ = [[NSOperationQueue alloc] init];
  XCTestExpectation *expectation = [self expectationWithDescription:@"backgroundQ finished."];
  [backgroundQ addOperationWithBlock:^{
    [self performSelector:@selector(grey_delayedExecutionSelector:)
               withObject:self
               afterDelay:delay];
    [expectation fulfill];
  }];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
  XCTAssertFalse(_delayedExecution);
}

- (void)testCustomObjectDescription {
  CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"foo"];
  XCTAssertTrue([[animation grey_stateTrackerDescription] containsString:@"CABasicAnimation: "]);
}

#pragma mark - Private

+ (void)grey_delayedExecutionSelectorBlockParam:(void (^)(void))block {
  block();
}

- (void)grey_delayedExecutionSelector {
  _delayedExecution = YES;
  _delayedExecutionWithoutParamCount++;
  _delayedExecutionCount++;
}

- (void)grey_delayedExecutionSelector:(id)selfParam {
  XCTAssertEqual(selfParam, self, @"Must pass in self as the first param to selector.");
  _delayedExecution = YES;
  _delayedExecutionWithParamCount++;
  _delayedExecutionCount++;
}

@end
