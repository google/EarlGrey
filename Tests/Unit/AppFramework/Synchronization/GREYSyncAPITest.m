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

#import "AppFramework/Additions/UIApplication+GREYApp.h"
#import "AppFramework/Synchronization/GREYSyncAPI.h"
#import "CommonLib/GREYAppleInternals.h"
#import "Tests/Unit/AppFramework/GREYAppBaseTest.h"
#import "third_party/objective_c/ocmock/v3/Source/OCMock/OCMock.h"

@interface GREYSyncAPITest : GREYAppBaseTest

@end

@implementation GREYSyncAPITest

- (void)setUp {
  // Don't mock UIApplication here. NSPersistentStoreCoordinator uses dispatch_once to cache the
  // value of sharedApplication and since our mocks are discarded in tearDown, store coordinator
  // ends up holding a dangling pointer.
  self.useRealUIApplication = YES;
  [super setUp];
}

- (void)testPushAndPopRunLoopModes {
  id originalSharedApplication = self.realSharedApplication;
  if (!self.realSharedApplication) {
    self.realSharedApplication = [UIApplication sharedApplication];
  }
  XCTAssertNil([self.realSharedApplication grey_activeRunLoopMode], @"should be nil");
  [self.realSharedApplication pushRunLoopMode:@"Boo" requester:self];
  XCTAssertEqualObjects([self.realSharedApplication grey_activeRunLoopMode], @"Boo",
                        @"should be equal");
  [self.realSharedApplication pushRunLoopMode:@"Foo"];
  XCTAssertEqualObjects([self.realSharedApplication grey_activeRunLoopMode], @"Foo",
                        @"should be equal");
  [self.realSharedApplication popRunLoopMode:@"Foo"];
  XCTAssertEqualObjects([self.realSharedApplication grey_activeRunLoopMode], @"Boo",
                        @"should be equal");
  [self.realSharedApplication popRunLoopMode:@"Boo" requester:self];
  XCTAssertNotEqualObjects([self.realSharedApplication grey_activeRunLoopMode], @"Boo",
                           @"should not be equal");
  XCTAssertNotEqualObjects([self.realSharedApplication grey_activeRunLoopMode], @"Foo",
                           @"should not be equal");
  self.realSharedApplication = originalSharedApplication;
}

- (void)testExecuteSyncOnMainThread {
  XCTestExpectation *expectsExecuted = [self expectationWithDescription:@"Executed the block."];
  grey_dispatch_sync_on_main_thread(^{
    XCTAssertTrue([NSThread isMainThread], @"Must be on the main thread");
    [expectsExecuted fulfill];
  });
  [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testExecuteSyncOnBackgroundQueue {
  XCTestExpectation *expectsExecuted = [self expectationWithDescription:@"Executed the block."];
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    XCTAssertFalse([NSThread isMainThread], @"Must not be on the main thread");
    grey_dispatch_sync_on_main_thread(^{
      XCTAssertTrue([NSThread isMainThread], @"Must be on the main thread");
      [expectsExecuted fulfill];
    });
  });
  [self waitForExpectationsWithTimeout:5 handler:nil];
}

@end
