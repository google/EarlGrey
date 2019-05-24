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

#import "AppFramework/Event/GREYTouchInjector.h"
#import "third_party/objective_c/ocmock/v3/Source/OCMock/OCMock.h"

@interface GREYTouchInjectorTest : XCTestCase
@property(nonatomic, readonly) NSArray<GREYTouchInfo *> *sampleTouches;
@end

@implementation GREYTouchInjectorTest {
  id _applicationMock;
  id _applicationClassMock;
}

- (void)setUp {
  _applicationMock = OCMPartialMock(UIApplication.sharedApplication);
  _applicationClassMock = OCMClassMock([UIApplication class]);
  OCMStub([_applicationClassMock sharedApplication]).andReturn(_applicationMock);
}

- (void)tearDown {
  [_applicationMock stopMocking];
  [_applicationClassMock stopMocking];
  _applicationMock = nil;
  _applicationClassMock = nil;
}

- (void)testInjectOnMainThread {
  NSArray<GREYTouchInfo *> *touches = self.sampleTouches;

  __block NSUInteger numOfDelivered = 0;
  __block CFTimeInterval previousDeliveryTime = CFAbsoluteTimeGetCurrent();
  OCMStub([_applicationMock sendEvent:[OCMArg checkWithBlock:^BOOL(UIEvent *event) {
                              CFTimeInterval currentTime = CFAbsoluteTimeGetCurrent();
                              GREYTouchInfo *touchInfo = touches[numOfDelivered];
                              XCTAssertGreaterThanOrEqual(
                                  currentTime - previousDeliveryTime,
                                  touchInfo.deliveryTimeDeltaSinceLastTouch);
                              XCTAssertEqual(touchInfo.phase, event.allTouches.anyObject.phase);

                              previousDeliveryTime = currentTime;
                              ++numOfDelivered;
                              return YES;
                            }]]);

  GREYTouchInjector *touchInjector =
      [[GREYTouchInjector alloc] initWithWindow:UIApplication.sharedApplication.keyWindow];
  for (GREYTouchInfo *touch in touches) {
    [touchInjector enqueueTouchInfoForDelivery:touch];
  }
  [touchInjector waitUntilAllTouchesAreDelivered];

  XCTAssertEqual(numOfDelivered, touches.count);
}

- (void)testInjectOneByOne {
  NSArray<GREYTouchInfo *> *touches = self.sampleTouches;
  XCTestExpectation *touchExpectation = [self expectationWithDescription:@"Touch delivered"];

  // UITouch object should stay alive for the same injector.
  __block NSUInteger numOfDelivered = 0;
  __block UITouch *singleTouch = nil;
  OCMStub([_applicationMock sendEvent:[OCMArg checkWithBlock:^BOOL(UIEvent *event) {
                              if (!singleTouch) {
                                singleTouch = event.allTouches.anyObject;
                              }
                              XCTAssertEqual(singleTouch, event.allTouches.anyObject);
                              XCTAssertEqual(event.allTouches.count, 1U);

                              ++numOfDelivered;
                              return YES;
                            }]]);
  dispatch_queue_t touchQueue =
      dispatch_queue_create("com.google.egtest.touch", DISPATCH_QUEUE_SERIAL);

  GREYTouchInjector *touchInjector =
      [[GREYTouchInjector alloc] initWithWindow:UIApplication.sharedApplication.keyWindow];
  dispatch_async(touchQueue, ^{
    for (GREYTouchInfo *touch in touches) {
      [touchInjector enqueueTouchInfoForDelivery:touch];
      [touchInjector waitUntilAllTouchesAreDelivered];
    }
    [touchExpectation fulfill];
  });

  [self waitForExpectationsWithTimeout:10 handler:nil];
  XCTAssertEqual(numOfDelivered, touches.count);
}

- (void)testInjectSequence {
  NSArray<GREYTouchInfo *> *touches = self.sampleTouches;
  XCTestExpectation *touchExpectation = [self expectationWithDescription:@"Touch delivered"];

  __block NSUInteger numOfDelivered = 0;
  __block CFTimeInterval previousDeliver = CFAbsoluteTimeGetCurrent();
  OCMStub([_applicationMock sendEvent:[OCMArg checkWithBlock:^BOOL(UIEvent *event) {
                              CFTimeInterval current = CFAbsoluteTimeGetCurrent();
                              GREYTouchInfo *touchInfo = touches[numOfDelivered];
                              XCTAssertGreaterThanOrEqual(
                                  current - previousDeliver,
                                  touchInfo.deliveryTimeDeltaSinceLastTouch);
                              XCTAssertEqual(touchInfo.phase, event.allTouches.anyObject.phase);

                              previousDeliver = current;
                              ++numOfDelivered;
                              return YES;
                            }]]);
  dispatch_queue_t touchQueue =
      dispatch_queue_create("com.google.egtest.touch", DISPATCH_QUEUE_SERIAL);

  GREYTouchInjector *touchInjector =
      [[GREYTouchInjector alloc] initWithWindow:UIApplication.sharedApplication.keyWindow];
  dispatch_async(touchQueue, ^{
    for (GREYTouchInfo *touch in touches) {
      [touchInjector enqueueTouchInfoForDelivery:touch];
    }
    [touchInjector waitUntilAllTouchesAreDelivered];
    [touchExpectation fulfill];
  });

  [self waitForExpectationsWithTimeout:10 handler:nil];
  XCTAssertEqual(numOfDelivered, touches.count);
}

- (void)testInjectorInjectOnceAtATime {
  NSArray<GREYTouchInfo *> *touches = self.sampleTouches;

  GREYTouchInjector *touchInjector =
      [[GREYTouchInjector alloc] initWithWindow:UIApplication.sharedApplication.keyWindow];
  dispatch_semaphore_t continueDelivery = dispatch_semaphore_create(0);
  __block NSUInteger numOfDelivered = 0;
  OCMStub([_applicationMock
      sendEvent:[OCMArg checkWithBlock:^BOOL(UIEvent *event) {
        if (numOfDelivered == 0) {
          dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // Additional enqueues should raise an exception during the touch delivery.
            for (GREYTouchInfo *touch in touches) {
              [touchInjector enqueueTouchInfoForDelivery:touch];
            }
            dispatch_semaphore_signal(continueDelivery);
          });
          dispatch_semaphore_wait(continueDelivery, DISPATCH_TIME_FOREVER);
        }
        ++numOfDelivered;
        return YES;
      }]]);
  dispatch_queue_t touchQueue =
      dispatch_queue_create("com.google.egtest.touch", DISPATCH_QUEUE_SERIAL);

  XCTestExpectation *touchExpectation = [self expectationWithDescription:@"Touch delivered"];
  dispatch_async(touchQueue, ^{
    for (GREYTouchInfo *touch in touches) {
      [touchInjector enqueueTouchInfoForDelivery:touch];
    }
    XCTAssertThrows([touchInjector waitUntilAllTouchesAreDelivered]);
    [touchExpectation fulfill];
  });

  [self waitForExpectationsWithTimeout:10 handler:nil];
  XCTAssertEqual(numOfDelivered, touches.count);
}

- (void)testInjectorInjectManyTimes {
  NSArray<GREYTouchInfo *> *touches = self.sampleTouches;

  __block NSUInteger numOfBatches = 50;
  NSMutableSet<UITouch *> *ongoingTouches = [[NSMutableSet alloc] init];
  OCMStub([_applicationMock sendEvent:[OCMArg checkWithBlock:^(UIEvent *event) {
                              for (UITouch *touch in event.allTouches) {
                                if (![ongoingTouches containsObject:touch]) {
                                  [ongoingTouches addObject:touch];
                                }
                              }
                              return YES;
                            }]]);
  dispatch_queue_t touchQueue =
      dispatch_queue_create("com.google.egtest.touch", DISPATCH_QUEUE_CONCURRENT);

  XCTestExpectation *touchExpectation = [self expectationWithDescription:@"Touch delivered"];
  touchExpectation.expectedFulfillmentCount = numOfBatches;

  for (NSUInteger i = numOfBatches; i > 0; --i) {
    dispatch_async(touchQueue, ^{
      GREYTouchInjector *touchInjector =
          [[GREYTouchInjector alloc] initWithWindow:UIApplication.sharedApplication.keyWindow];
      for (GREYTouchInfo *touch in touches) {
        [touchInjector enqueueTouchInfoForDelivery:touch];
      }
      [touchInjector waitUntilAllTouchesAreDelivered];
      [touchExpectation fulfill];
    });
  }

  [self waitForExpectationsWithTimeout:10 handler:nil];
  XCTAssertEqual(numOfBatches, ongoingTouches.count);
}

- (void)testInjectOnDifferentThreads {
  NSArray<GREYTouchInfo *> *touches = self.sampleTouches;
  NSMutableSet<UITouch *> *ongoingTouches = [[NSMutableSet alloc] init];

  __block NSUInteger numOfDelivered = 0;
  OCMStub([_applicationMock sendEvent:[OCMArg checkWithBlock:^BOOL(UIEvent *event) {
                              for (UITouch *touch in event.allTouches) {
                                if (![ongoingTouches containsObject:touch]) {
                                  [ongoingTouches addObject:touch];
                                }
                              }
                              ++numOfDelivered;
                              return YES;
                            }]]);

  NSArray<GREYTouchInjector *> *touchInjectors = @[
    [[GREYTouchInjector alloc] initWithWindow:UIApplication.sharedApplication.keyWindow],
    [[GREYTouchInjector alloc] initWithWindow:UIApplication.sharedApplication.keyWindow],
    [[GREYTouchInjector alloc] initWithWindow:UIApplication.sharedApplication.keyWindow],
    [[GREYTouchInjector alloc] initWithWindow:UIApplication.sharedApplication.keyWindow],
  ];
  XCTestExpectation *touchExpectation = [self expectationWithDescription:@"Touch delivered"];
  touchExpectation.expectedFulfillmentCount = touchInjectors.count;

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [touchInjectors
        enumerateObjectsWithOptions:NSEnumerationConcurrent
                         usingBlock:^(GREYTouchInjector *injector, NSUInteger idx, BOOL *stop) {
                           [touches enumerateObjectsWithOptions:NSEnumerationConcurrent
                                                     usingBlock:^(GREYTouchInfo *touch,
                                                                  NSUInteger idx, BOOL *stop) {
                                                       [injector enqueueTouchInfoForDelivery:touch];
                                                     }];
                           [injector waitUntilAllTouchesAreDelivered];
                           [touchExpectation fulfill];
                         }];
  });

  [self waitForExpectationsWithTimeout:10 handler:nil];
  XCTAssertEqual(ongoingTouches.count, touchInjectors.count);
  XCTAssertEqual(numOfDelivered, touchInjectors.count * touches.count);
}

- (NSArray<GREYTouchInfo *> *)sampleTouches {
  return @[
    [[GREYTouchInfo alloc] initWithPoints:@[ [NSValue valueWithCGPoint:CGPointMake(10, 10)] ]
                                    phase:UITouchPhaseBegan
          deliveryTimeDeltaSinceLastTouch:0],
    [[GREYTouchInfo alloc] initWithPoints:@[ [NSValue valueWithCGPoint:CGPointMake(10, 11)] ]
                                    phase:UITouchPhaseMoved
          deliveryTimeDeltaSinceLastTouch:0.1],
    [[GREYTouchInfo alloc] initWithPoints:@[ [NSValue valueWithCGPoint:CGPointMake(10, 12)] ]
                                    phase:UITouchPhaseMoved
          deliveryTimeDeltaSinceLastTouch:0.1],
    [[GREYTouchInfo alloc] initWithPoints:@[ [NSValue valueWithCGPoint:CGPointMake(10, 12)] ]
                                    phase:UITouchPhaseEnded
          deliveryTimeDeltaSinceLastTouch:0.1],
  ];
}

@end
