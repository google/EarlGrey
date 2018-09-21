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

#import "TestLib/EarlGreyImpl/XCUIApplication+GREYTest.h"

#include <objc/runtime.h>

#import "AppFramework/DistantObject/GREYHostApplicationDistantObject+GREYTestHelper.h"
#import "CommonLib/Assertion/GREYFatalAsserts.h"
#import "CommonLib/Config/GREYConfiguration.h"
#import "CommonLib/DistantObject/GREYTestApplicationDistantObject.h"
#import "CommonLib/GREYSwizzler.h"
#import "TestLib/Analytics/GREYAnalytics.h"
#import "TestLib/XCTestCase/XCUIApplication+GREYEnvironment.h"

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
    @"-edoTestPort", @([GREYTestApplicationDistantObject.sharedInstance servicePort]).stringValue
  ]];
  self.launchArguments = launchArgs;

  INVOKE_ORIGINAL_IMP(void, @selector(grey_launch));
}

@end
