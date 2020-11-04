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

#import "NSRunLoop+GREYApp.h"

#include <objc/runtime.h>

#import "GREYNSTimerIdlingResource.h"
#import "GREYFatalAsserts.h"
#import "GREYConfigKey.h"
#import "GREYConfiguration.h"
#import "GREYConstants.h"
#import "GREYSwizzler.h"

/** Class for NSBlock which denotes recurrent timers from not being tracked.*/
static Class gBlockClass;

@implementation NSRunLoop (GREYApp)

+ (void)load {
  gBlockClass = NSClassFromString(@"NSBlock");
  GREYSwizzler *swizzler = [[GREYSwizzler alloc] init];
  BOOL swizzleSuccess = [swizzler swizzleClass:self
                         replaceInstanceMethod:@selector(addTimer:forMode:)
                                    withMethod:@selector(greyswizzled_addTimer:forMode:)];
  GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle NSRunLoop addTimer:forMode:");
}

#pragma mark - Swizzled Implementation

- (void)greyswizzled_addTimer:(NSTimer *)timer forMode:(NSString *)mode {
  // We track all short, non-repeating NSTimers that are added to the main thread.
  if ([NSThread isMainThread]) {
    // TODO(b/171823723): We also do not track blocks being passed as userInfo as this can have
    // issues when timers with custom blocks are passed in because of recursive calls to the same
    // block.
    id ignoreTracking = objc_getAssociatedObject(timer, kNSTimerIgnoreTrackingKey);
    if (!ignoreTracking && timer.timeInterval == 0 &&
        GREY_CONFIG_DOUBLE(kGREYConfigKeyNSTimerMaxTrackableInterval) >=
            [timer.fireDate timeIntervalSinceNow] &&
        ![timer.userInfo isKindOfClass:gBlockClass]) {
      NSString *name = [NSString stringWithFormat:@"IdlingResource For Timer on Mode: %@", mode];
      // Set an associated object on the timer to ensure we don't keep re-tracking timers being
      // added in a loop.
      objc_setAssociatedObject(timer, kNSTimerIgnoreTrackingKey, @(YES),
                               OBJC_ASSOCIATION_RETAIN_NONATOMIC);
      [GREYNSTimerIdlingResource trackTimer:timer name:name removeOnIdle:YES];
    }
  }
  INVOKE_ORIGINAL_IMP2(void, @selector(greyswizzled_addTimer:forMode:), timer, mode);
}

@end
