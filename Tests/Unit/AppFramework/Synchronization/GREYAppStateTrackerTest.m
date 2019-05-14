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

#import "AppFramework/Synchronization/GREYAppStateTracker.h"

#import "CommonLib/Config/GREYConfiguration.h"
#import "Tests/Unit/AppFramework/GREYAppBaseTest.h"

@interface GREYAppStateTrackerTest : GREYAppBaseTest

@end

@implementation GREYAppStateTrackerTest

- (void)tearDown {
  [super tearDown];
  [GREYConfiguration.sharedConfiguration reset];
}

- (void)testLastKnownStateChangedAfterOnStateChange {
  // NS_VALID_UNTIL_END_OF_SCOPE required so obj1 and obj2 are valid until end of the current scope.
  NS_VALID_UNTIL_END_OF_SCOPE NSObject *obj1 = [[NSObject alloc] init];

  XCTAssertEqual([[GREYAppStateTracker sharedInstance] grey_lastKnownStateForObject:obj1],
                 kGREYIdle, @"By default current state should always be in kGREYIdle");

  GREYAppStateTrackerObject *elementID1 = TRACK_STATE_FOR_OBJECT(kGREYPendingCAAnimation, obj1);

  XCTAssertEqual([[GREYAppStateTracker sharedInstance] grey_lastKnownStateForObject:obj1],
                 kGREYPendingCAAnimation, @"State should be kGREYPendingCAAnimation");

  NS_VALID_UNTIL_END_OF_SCOPE NSObject *obj2 = [[NSObject alloc] init];
  GREYAppStateTrackerObject *elementID2 = TRACK_STATE_FOR_OBJECT(kGREYPendingDrawLayoutPass, obj2);

  XCTAssertEqual([[GREYAppStateTracker sharedInstance] grey_lastKnownStateForObject:obj1],
                 kGREYPendingCAAnimation, @"State should be kGREYPendingCAAnimation");
  XCTAssertEqual([[GREYAppStateTracker sharedInstance] grey_lastKnownStateForObject:obj2],
                 kGREYPendingDrawLayoutPass, @"State should be kGREYPendingDrawCycle");

  UNTRACK_STATE_FOR_OBJECT(kGREYPendingCAAnimation, elementID1);

  XCTAssertEqual([[GREYAppStateTracker sharedInstance] grey_lastKnownStateForObject:obj1],
                 kGREYIdle, @"State should be kGREYIdle");
  XCTAssertEqual([[GREYAppStateTracker sharedInstance] grey_lastKnownStateForObject:obj2],
                 kGREYPendingDrawLayoutPass, @"State should be kGREYPendingDrawCycle");

  UNTRACK_STATE_FOR_OBJECT(kGREYPendingDrawLayoutPass, elementID2);

  XCTAssertEqual([[GREYAppStateTracker sharedInstance] grey_lastKnownStateForObject:obj1],
                 kGREYIdle, @"State should be kGREYIdle");
  XCTAssertEqual([[GREYAppStateTracker sharedInstance] grey_lastKnownStateForObject:obj2],
                 kGREYIdle, @"State should be kGREYIdle");
}

- (void)testCurrentStateAfterOnStateChange {
  NSObject *obj1 = [[NSObject alloc] init];
  NSObject *obj2 = [[NSObject alloc] init];

  XCTAssertEqual([[GREYAppStateTracker sharedInstance] currentState], kGREYIdle,
                 @"By default current state should always be in kGREYIdle");

  GREYAppStateTrackerObject *elementID1 = TRACK_STATE_FOR_OBJECT(kGREYPendingCAAnimation, obj1);

  XCTAssertEqual([[GREYAppStateTracker sharedInstance] currentState], kGREYPendingCAAnimation,
                 @"State should be kGREYPendingCAAnimation");

  GREYAppStateTrackerObject *elementID2 = TRACK_STATE_FOR_OBJECT(kGREYPendingDrawLayoutPass, obj2);

  XCTAssertEqual([[GREYAppStateTracker sharedInstance] currentState],
                 kGREYPendingCAAnimation | kGREYPendingDrawLayoutPass,
                 @"State should be kGREYPendingCAAnimation and kGREYPendingDrawCycle");

  UNTRACK_STATE_FOR_OBJECT(kGREYPendingCAAnimation, elementID1);

  XCTAssertEqual([[GREYAppStateTracker sharedInstance] currentState], kGREYPendingDrawLayoutPass,
                 @"State should be kGREYPendingDrawCycle");

  UNTRACK_STATE_FOR_OBJECT(kGREYPendingDrawLayoutPass, elementID2);

  XCTAssertEqual([[GREYAppStateTracker sharedInstance] currentState], kGREYIdle,
                 @"State should be kGREYIdle");
}

- (void)testDescriptionInVerboseMode {
  NSObject *obj1 = [[NSObject alloc] init];

  NSString *desc = [[GREYAppStateTracker sharedInstance] description];
  XCTAssertTrue([desc rangeOfString:@"Idle"].location != NSNotFound,
                @"No state transition, should report Idle state in description");

  TRACK_STATE_FOR_OBJECT(kGREYPendingCAAnimation, obj1);

  desc = [[GREYAppStateTracker sharedInstance] description];
  XCTAssertTrue([desc rangeOfString:@"Waiting for CAAnimations to finish"].location != NSNotFound,
                @"Should report that it is waiting on CAAnimation to finish");

  NSString *obj1ClassAndMemory = [NSString stringWithFormat:@"<%@: %p>", [obj1 class], obj1];
  NSString *obj1FullStateDesc = [NSString
      stringWithFormat:@"%@ => %@", obj1ClassAndMemory, @"Waiting for CAAnimations to finish"];
  XCTAssertTrue([desc rangeOfString:obj1FullStateDesc].location != NSNotFound,
                @"Should report exactly what object is in what state.");
}

- (void)testDeallocatedObjectClearsState {
  @autoreleasepool {
    __autoreleasing NSObject *obj = [[NSObject alloc] init];
    TRACK_STATE_FOR_OBJECT(kGREYPendingUIWebViewAsyncRequest, obj);
    XCTAssertEqual([[GREYAppStateTracker sharedInstance] grey_lastKnownStateForObject:obj],
                   kGREYPendingUIWebViewAsyncRequest);
  }
  // obj should dealloc and clear all associations, causing state tracker to untrack all states
  // associated to it.
  XCTAssertEqual(kGREYIdle, [[GREYAppStateTracker sharedInstance] currentState]);
}

- (void)testAppStateEfficiency {
  CFTimeInterval testStartTime = CACurrentMediaTime();

  // Make a really big UIView hierarchy.
  UIView *view = [[UIView alloc] init];
  for (int i = 0; i < 15000; i++) {
    [view addSubview:[[UIView alloc] init]];
  }

  // With efficient state tracking, this test should complete in under .5 seconds. To avoid test
  // flakiness, just make sure that it is under 10 seconds.
  XCTAssertLessThan(CACurrentMediaTime() - testStartTime, 10,
                    @"This test should complete in less than than 10 seconds.");
}

- (void)testIgnoreStateAndTrack {
  [GREYConfiguration.sharedConfiguration setValue:@(kGREYPendingCAAnimation)
                                     forConfigKey:kGREYConfigKeyIgnoreAppStates];
  {
    NS_VALID_UNTIL_END_OF_SCOPE NSObject *obj = [[NSObject alloc] init];
    TRACK_STATE_FOR_OBJECT(kGREYPendingCAAnimation, obj);
    XCTAssertTrue(GREYAppStateTracker.sharedInstance.isIdleNow);
  }
}

- (void)testIgnoreStateWithTrackedObject {
  {
    NS_VALID_UNTIL_END_OF_SCOPE NSObject *obj = [[NSObject alloc] init];
    TRACK_STATE_FOR_OBJECT(kGREYPendingCAAnimation, obj);
    XCTAssertFalse(GREYAppStateTracker.sharedInstance.isIdleNow);
    [GREYConfiguration.sharedConfiguration setValue:@(kGREYPendingCAAnimation)
                                       forConfigKey:kGREYConfigKeyIgnoreAppStates];
    XCTAssertTrue(GREYAppStateTracker.sharedInstance.isIdleNow);
  }
}

- (void)testStopIgnoringStateBetweenSyncAndUntrack {
  [GREYConfiguration.sharedConfiguration setValue:@(kGREYPendingCAAnimation)
                                     forConfigKey:kGREYConfigKeyIgnoreAppStates];
  {
    NS_VALID_UNTIL_END_OF_SCOPE NSObject *obj = [[NSObject alloc] init];
    GREYAppStateTrackerObject *objId = TRACK_STATE_FOR_OBJECT(kGREYPendingCAAnimation, obj);
    [GREYConfiguration.sharedConfiguration setValue:@(~kGREYPendingCAAnimation)
                                       forConfigKey:kGREYConfigKeyIgnoreAppStates];
    XCTAssertFalse(GREYAppStateTracker.sharedInstance.isIdleNow);
    UNTRACK_STATE_FOR_OBJECT(kGREYPendingCAAnimation, objId);
    XCTAssertTrue(GREYAppStateTracker.sharedInstance.isIdleNow);
  }
}

- (void)testIgnoringMultipleStates {
  GREYAppState testIgnoreStates = kGREYPendingViewsToAppear | kGREYPendingViewsToDisappear;
  [GREYConfiguration.sharedConfiguration setValue:@(testIgnoreStates)
                                     forConfigKey:kGREYConfigKeyIgnoreAppStates];
  {
    NS_VALID_UNTIL_END_OF_SCOPE NSObject *obj = [[NSObject alloc] init];
    TRACK_STATE_FOR_OBJECT(kGREYPendingViewsToAppear, obj);
    TRACK_STATE_FOR_OBJECT(kGREYPendingViewsToDisappear, obj);
    XCTAssertTrue([GREYAppStateTracker.sharedInstance isIdleNow]);
  }
}

- (void)testIgnoringOneStateAndTrackingAnotherState {
  [GREYConfiguration.sharedConfiguration setValue:@(kGREYPendingViewsToAppear)
                                     forConfigKey:kGREYConfigKeyIgnoreAppStates];
  {
    NS_VALID_UNTIL_END_OF_SCOPE NSObject *obj = [[NSObject alloc] init];
    TRACK_STATE_FOR_OBJECT(kGREYPendingViewsToDisappear, obj);
    XCTAssertFalse([GREYAppStateTracker.sharedInstance isIdleNow]);
  }
}

#pragma mark - Private

- (GREYAppStateTrackerObject *)grey_trackStateForTesting:(GREYAppState)state onObject:(id)object {
  XCTAssert(object != nil, @"The object for tracking cannot be nil.");
  GREYAppStateTrackerObject *objId = TRACK_STATE_FOR_OBJECT(state, object);
  return objId;
}

@end
