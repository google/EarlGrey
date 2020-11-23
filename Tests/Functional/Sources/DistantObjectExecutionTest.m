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

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

#import "GREYHostApplicationDistantObject+GREYTestHelper.h"
#import "GREYDistantObjectUtils.h"
#import "GREYTestApplicationDistantObject+Private.h"
#import "EarlGrey.h"
#import "GREYHostApplicationDistantObject+RemoteTest.h"
#import "BaseIntegrationTest.h"
#import "EDOClientService.h"
#import "EDOHostService.h"
#import "EDOServicePort.h"

@interface DistantObjectExecutionTest : BaseIntegrationTest
@end

@implementation DistantObjectExecutionTest

/** Checks if the successful launch of app-under-test initializes the distant object variables. */
- (void)testLaunchNoError {
  // Launch and terminate w/o any errors.
  XCTAssertNotNil(GREYHostApplicationDistantObject.sharedInstance);
  XCTAssertNotNil(GREYTestApplicationDistantObject.sharedInstance);

  EDOHostService *hostService = GREYHostApplicationDistantObject.sharedInstance.service;
  XCTAssertNotNil(hostService, @"EDOHostService is not started in the host app.");
  XCTAssertEqual(GREYTestApplicationDistantObject.sharedInstance.hostPort, hostService.port.port);

  EDOHostService *testService = GREYTestApplicationDistantObject.sharedInstance.service;
  XCTAssertEqual(GREYHostApplicationDistantObject.testPort, testService.port.port);
}

/** Verifies that the host distant object can execute code at app-under-test side. */
- (void)testHostApplicationInstanceExtension {
  GREYHostApplicationDistantObject *host = GREYHostApplicationDistantObject.sharedInstance;
  XCTAssertEqualObjects([host makeAString:@"string"], @"stringmake");
  XCTAssertEqual([host testHostPortNumber],
                 GREYTestApplicationDistantObject.sharedInstance.hostPort);
}

/** Verifies that the host distant object can configure animation speed of app-under-test. */
- (void)testAnimationSpeed {
  [[GREYHostApplicationDistantObject sharedInstance] enableFastAnimation];
  BOOL enableFastAnimationWorked =
      [[GREYHostApplicationDistantObject sharedInstance] allWindowsLayerSpeedIsGreaterThanOne];
  XCTAssertTrue(enableFastAnimationWorked, @"All Window Layer Animations were sped up");

  [[GREYHostApplicationDistantObject sharedInstance] disableFastAnimation];
  BOOL disableFastAnimationWorked =
      [[GREYHostApplicationDistantObject sharedInstance] allWindowsLayerSpeedIsEqualToOne];
  XCTAssertTrue(disableFastAnimationWorked, @"All Window Layer Animations are Equal to One");
}

/** Checks if test can create a UIView instance in app-under-test. */
- (void)testRemoteClassAlloc {
  UIView *remoteView;
  XCTAssertNoThrow(remoteView = [GREY_ALLOC_REMOTE_CLASS_IN_APP(UIView) init]);
  XCTAssertTrue([remoteView isKindOfClass:GREY_REMOTE_CLASS_IN_APP(UIView)]);
}

/**
 * Checks if test distant object will wait for eDO host ports of app-under-test to be assgiend when
 * its getter is called.
 */
- (void)testAppEDOPortsGetterWaitingForPortsToBeAssigned {
  GREYTestApplicationDistantObject *distantObject = GREYTestApplicationDistantObject.sharedInstance;
  uint16_t hostPort = distantObject.hostPort;
  uint16_t backgroundHostPort = distantObject.hostBackgroundPort;
  // Mimics the first-time launch failure by resetting host eDO ports to 0.
  [distantObject resetHostArguments];
  id appPortsSettingBlock = ^{
    distantObject.hostPort = hostPort;
    distantObject.hostBackgroundPort = backgroundHostPort;
  };
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(),
                 appPortsSettingBlock);

  XCTAssertEqual(distantObject.hostPort, hostPort);
  XCTAssertEqual(distantObject.hostBackgroundPort, backgroundHostPort);
}

/**
 * Verifies that EarlGrey performs successful applcation launch and eDO ports assignment when the
 * previous app launch failed.
 */
- (void)testAppEDOPortsCanBeResetTwice {
  GREYTestApplicationDistantObject *distantObject = GREYTestApplicationDistantObject.sharedInstance;
  // Mimics the first-time launch failure by resetting host eDO ports to 0.
  [distantObject resetHostArguments];
  [self.application launch];
  XCTAssertGreaterThan(distantObject.hostPort, 0);
  XCTAssertGreaterThan(distantObject.hostBackgroundPort, 0);
}

/** Checks if eDO ports assignment of XCUIApplication::activate is successful. */
- (void)testAppEDOPortsCanBeAssignedTwice {
  GREYTestApplicationDistantObject *distantObject = GREYTestApplicationDistantObject.sharedInstance;
  [self.application launch];
  uint16_t currentHostPort = distantObject.hostPort;
  uint16_t currentBackgroundPort = distantObject.hostBackgroundPort;
  [self.application terminate];
  [self.application activate];
  XCTAssertNotEqual(distantObject.hostPort, currentHostPort);
  XCTAssertNotEqual(distantObject.hostBackgroundPort, currentBackgroundPort);
}

/** Verifies expectation is fulfilled through a callback triggered by the app-under-test. */
- (void)testExpectationThatIsFulfilledThroughCallback {
  XCTestExpectation *expectation = [self expectationWithDescription:@"Test Expectation"];
  id callback = ^{
    [expectation fulfill];
  };
  [[GREYHostApplicationDistantObject sharedInstance] invokeRemoteBlock:callback withDelay:1];
  [self waitForExpectations:@[ expectation ] timeout:2];
}

/** Ensures the application is launched with the app component. */
- (void)testDistantObjectLaunchCheckUpdated {
  [self.application launch];
  XCTAssertTrue(GREYTestApplicationDistantObject.sharedInstance.hostLaunchedWithAppComponent,
                @"The Distant object host app must be launched with the app component.");
}

@end
