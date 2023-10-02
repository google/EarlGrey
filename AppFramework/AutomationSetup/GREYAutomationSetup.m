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

#import "GREYAutomationSetup.h"
#import <Foundation/Foundation.h>

#import "GREYAppleInternals.h"

#pragma mark - Automation Setup

@implementation GREYAutomationSetup

+ (void)load {
  // Force software keyboard.
  static NSArray<NSString *> *legacyTargets;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    legacyTargets = @[
    ];
  });
  BOOL deferKeyboardChange = YES;
  NSString *packagePath = NSProcessInfo.processInfo.environment[@"TEST_UNDECLARED_OUTPUTS_DIR"];
  for (NSString *legacyTarget in legacyTargets) {
    if ([packagePath containsString:legacyTarget]) {
      deferKeyboardChange = NO;
    }
  }
  if (deferKeyboardChange) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [[UIKeyboardImpl sharedInstance] setAutomaticMinimizationEnabled:NO];
    });
  } else {
    [[UIKeyboardImpl sharedInstance] setAutomaticMinimizationEnabled:NO];
  }
}

@end
