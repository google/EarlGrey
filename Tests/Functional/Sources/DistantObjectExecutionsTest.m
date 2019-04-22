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

#import "AppFramework/DistantObject/GREYHostApplicationDistantObject+GREYTestHelper.h"
#import "BaseIntegrationTest.h"

@interface DistantObjectExecutionsTest : BaseIntegrationTest

@end

@implementation DistantObjectExecutionsTest

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

- (void)testHostApplicationInstanceExtension {
  GREYHostApplicationDistantObject *host = GREYHostApplicationDistantObject.sharedInstance;
  XCTAssertEqualObjects([host makeAString:@"string"], @"stringmake");
  XCTAssertEqual([host testHostPortNumber],
                 GREYTestApplicationDistantObject.sharedInstance.hostPort);
}

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

- (void)testRemoteClassAlloc {
  UIView *remoteView;
  XCTAssertNoThrow(remoteView = [GREY_ALLOC_REMOTE_CLASS_IN_APP(UIView) init]);
  XCTAssertTrue([remoteView isKindOfClass:GREY_REMOTE_CLASS_IN_APP(UIView)]);
}

@end
