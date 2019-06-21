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

#import "XCUIApplication+GREYTest.h"

#include <objc/runtime.h>

#import "GREYHostApplicationDistantObject+GREYTestHelper.h"
#import "GREYFatalAsserts.h"
#import "GREYTestApplicationDistantObject+Private.h"
#import "GREYTestApplicationDistantObject.h"
#import "GREYSwizzler.h"
#import "XCUIApplication+GREYEnvironment.h"

@implementation XCUIApplication (GREYTest)

+ (void)load {
  GREYSwizzler *swizzler = [[GREYSwizzler alloc] init];
  BOOL swizzleSuccess = [swizzler swizzleClass:[XCUIApplication class]
                         replaceInstanceMethod:@selector(launch)
                                    withMethod:@selector(grey_launch)];
  GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle XCUIApplication launch");
}

- (void)grey_launch {
  // Setup the Launch Environments.
  [self grey_configureApplicationForLaunch];
  // Setup the Launch Arguments for eDO.
  NSMutableArray<NSString *> *launchArgs = [self.launchArguments mutableCopy];
  if (!launchArgs) {
    launchArgs = [[NSMutableArray alloc] init];
  }
  [launchArgs addObjectsFromArray:@[
    @"-edoTestPort",
    @([GREYTestApplicationDistantObject.sharedInstance servicePort]).stringValue,
    @"-IsRunningEarlGreyTest",
    @"YES",
  ]];
  self.launchArguments = launchArgs;

  // Resets the port number before each relaunch.
  GREYTestApplicationDistantObject *testDistantObject =
      GREYTestApplicationDistantObject.sharedInstance;
  testDistantObject.hostPort = 0;
  testDistantObject.hostBackgroundPort = 0;
  INVOKE_ORIGINAL_IMP(void, @selector(grey_launch));
}

@end
