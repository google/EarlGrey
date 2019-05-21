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

#import "Tests/Unit/AppFramework/GREYAppBaseTest.h"

#import <objc/message.h>

#import "AppFramework/Additions/UIApplication+GREYApp.h"
#import "AppFramework/Synchronization/GREYAppStateTracker.h"
#import "CommonLib/Config/GREYConfiguration.h"
#import "CommonLib/DistantObject/GREYTestApplicationDistantObject.h"
#import "CommonLib/Exceptions/GREYFrameworkException.h"
#import "CommonLib/GREYSwizzler.h"
#import "third_party/objective_c/ocmock/v3/Source/OCMock/OCMock.h"

// This is a dummy re-implementation of GREYTestApplication which is used in EarlGrey Tests.
// GREYTestApplication is a part of the TestLib and is used to make RMI calls to it for
// say touch events. However, TestLib is not part of the App Unit Tests and without this
// dummy implementation, throw compilation errors for the implementation not being found.
@implementation GREYTestApplicationDistantObject
+ (instancetype)sharedInstance {
  return nil;
}

- (uint16_t)servicePort {
  return 0;
}
@end

// Real, original / unmocked shared UIApplication.
static id gRealSharedApplication;

#pragma mark - GREYUTFailureHandler

@implementation GREYUTFailureHandler

- (void)handleException:(GREYFrameworkException *)exception details:(NSString *)details {
  NSMutableString *errorString = [[NSMutableString alloc] init];
  [errorString appendString:@"Exception thrown during unit test: "];
  [errorString appendFormat:@"%@\nReason: %@", [exception name], [exception reason]];
  if (details) {
    [errorString appendFormat:@"\nDetails:\n%@", details];
  }
  NSLog(@"%@", errorString);
  [exception raise];
}

@end

#pragma mark - GREYUIThreadExecutor Category

@interface GREYUIThreadExecutor (GREYAppBaseTest)
@property(nonatomic, assign) BOOL forceBusyPolling;
- (void)grey_resetIdlingResources;
@end

#pragma mark - GREYBaseTest

@implementation GREYAppBaseTest {
  id _mockSharedApplication;
}

+ (void)initialize {
  if (self == [GREYAppBaseTest self]) {
    gRealSharedApplication = [UIApplication sharedApplication];
  }
}

- (void)setUp {
  [super setUp];

  self.realSharedApplication = gRealSharedApplication;

  // Drain the runloop before the test starts to settle any startup busy resources.
  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];

  self.activeRunLoopMode = NSDefaultRunLoopMode;

  if (!self.useRealUIApplication) {
    // Setup Mocking for UIApplication.
    _mockSharedApplication = OCMClassMock([UIApplication class]);
    id classMockApplication = OCMClassMock([UIApplication class]);
    [OCMStub([classMockApplication sharedApplication]) andReturn:_mockSharedApplication];

    // Runloop mode is required by thread executor so we always call real implementation here.
    OCMStub([_mockSharedApplication grey_activeRunLoopMode])
        .andCall(self, @selector(activeRunLoopMode));
  }

  // Resets configuration in case it was changed by the previous test.
  [GREYConfiguration.sharedConfiguration reset];

  // Force busy polling so that the thread executor and waiting conditions do not allow the
  // main thread to sleep.
  [GREYUIThreadExecutor sharedInstance].forceBusyPolling = YES;
}

- (void)tearDown {
  self.activeRunLoopMode = nil;

  [[NSOperationQueue mainQueue] cancelAllOperations];
  [[GREYAppStateTracker sharedInstance] grey_clearState];
  // Registered idling resources can leak from one failed test to another if they're not removed on
  // failure. This can cause cascading failures. As a safety net, we remove them here.
  [[GREYUIThreadExecutor sharedInstance] grey_resetIdlingResources];
  // This drains all the pending operations in the main queue.
  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];

  _mockSharedApplication = nil;
  [super tearDown];
}

- (id)mockSharedApplication {
  NSAssert([UIApplication sharedApplication] == _mockSharedApplication,
           @"UIApplication sharedApplication isn't a mock.");
  return _mockSharedApplication;
}

@end
