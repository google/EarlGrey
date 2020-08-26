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

#import "UIApplication+GREYApp.h"

#include <objc/runtime.h>

#import "GREYAppStateTracker.h"
#import "GREYAppStateTrackerObject.h"
#import "GREYFatalAsserts.h"
#import "GREYAppleInternals.h"
#import "GREYDefines.h"
#import "GREYSwizzler.h"

/**
 * List for all the runloop modes that have been pushed and unpopped using UIApplication's push/pop
 * runloop mode methods. The most recently pushed runloop mode is at the end of the list.
 */
static NSMutableArray<NSString *> *gRunLoopModes;

@implementation UIApplication (GREYApp)

+ (void)load {
  gRunLoopModes = [[NSMutableArray alloc] init];

  GREYSwizzler *swizzler = [[GREYSwizzler alloc] init];
  SEL originalSel = @selector(endIgnoringInteractionEvents);
  SEL swizzledSel = @selector(greyswizzled_endIgnoringInteractionEvents);
  BOOL swizzleSuccess = [swizzler swizzleClass:self
                         replaceInstanceMethod:originalSel
                                    withMethod:swizzledSel];
  GREYFatalAssertWithMessage(swizzleSuccess,
                             @"Cannot swizzle UIApplication endIgnoringInteractionEvents");
  originalSel = @selector(beginIgnoringInteractionEvents);
  swizzledSel = @selector(greyswizzled_beginIgnoringInteractionEvents);
  swizzleSuccess = [swizzler swizzleClass:self
                    replaceInstanceMethod:originalSel
                               withMethod:swizzledSel];
  GREYFatalAssertWithMessage(swizzleSuccess,
                             @"Cannot swizzle UIApplication beginIgnoringInteractionEvents");
  if (iOS12_OR_ABOVE()) {
    originalSel = @selector(_pushRunLoopMode:requester:reason:);
    swizzledSel = @selector(greyswizzled_pushRunLoopMode:requester:reason:);
    swizzleSuccess = [swizzler swizzleClass:self
                      replaceInstanceMethod:originalSel
                                 withMethod:swizzledSel];
    GREYFatalAssertWithMessage(swizzleSuccess,
                               @"Cannot swizzle UIApplication _pushRunLoopMode:requester:reason:");
    originalSel = @selector(_popRunLoopMode:requester:reason:);
    swizzledSel = @selector(greyswizzled_popRunLoopMode:requester:reason:);
    swizzleSuccess = [swizzler swizzleClass:self
                      replaceInstanceMethod:originalSel
                                 withMethod:swizzledSel];
    GREYFatalAssertWithMessage(swizzleSuccess,
                               @"Cannot swizzle UIApplication _pushRunLoopMode:requester:reason:");
  } else {
    swizzleSuccess = [swizzler swizzleClass:self
                      replaceInstanceMethod:@selector(pushRunLoopMode:requester:)
                                 withMethod:@selector(greyswizzled_pushRunLoopMode:requester:)];
    GREYFatalAssertWithMessage(swizzleSuccess,
                               @"Cannot swizzle UIApplication pushRunLoopMode:requester:");
    swizzleSuccess = [swizzler swizzleClass:self
                      replaceInstanceMethod:@selector(popRunLoopMode:requester:)
                                 withMethod:@selector(greyswizzled_popRunLoopMode:requester:)];
    GREYFatalAssertWithMessage(swizzleSuccess,
                               @"Cannot swizzle UIApplication popRunLoopMode:requester:");
  }
}

- (NSString *)grey_activeRunLoopMode {
  @synchronized(gRunLoopModes) {
    // could be nil.
    return [gRunLoopModes lastObject];
  }
}

#pragma mark - Swizzled Implementation

- (void)greyswizzled_beginIgnoringInteractionEvents {
  INVOKE_ORIGINAL_IMP(void, @selector(greyswizzled_beginIgnoringInteractionEvents));
  GREYAppStateTrackerObject *object =
      TRACK_STATE_FOR_OBJECT(kGREYIgnoringSystemWideUserInteraction, self);
  objc_setAssociatedObject(self, @selector(greyswizzled_beginIgnoringInteractionEvents), object,
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)greyswizzled_endIgnoringInteractionEvents {
  INVOKE_ORIGINAL_IMP(void, @selector(greyswizzled_endIgnoringInteractionEvents));
  // begin/end can be nested, instead of keeping the count, simply use isIgnoringInteractionEvents.
  if (!self.isIgnoringInteractionEvents) {
    GREYAppStateTrackerObject *object =
        objc_getAssociatedObject(self, @selector(greyswizzled_beginIgnoringInteractionEvents));
    UNTRACK_STATE_FOR_OBJECT(kGREYIgnoringSystemWideUserInteraction, object);
    objc_setAssociatedObject(self, @selector(greyswizzled_beginIgnoringInteractionEvents), nil,
                             OBJC_ASSOCIATION_ASSIGN);
  }
}

- (void)greyswizzled_pushRunLoopMode:(NSString *)mode requester:(id)requester {
  [self grey_pushRunLoopMode:mode];
  INVOKE_ORIGINAL_IMP2(void, @selector(greyswizzled_pushRunLoopMode:requester:), mode, requester);
}

- (void)greyswizzled_popRunLoopMode:(NSString *)mode requester:(id)requester {
  [self grey_popRunLoopMode:mode];
  INVOKE_ORIGINAL_IMP2(void, @selector(greyswizzled_popRunLoopMode:requester:), mode, requester);
}

/** Internal push runloop method added post iOS 12.*/
- (void)greyswizzled_pushRunLoopMode:(NSString *)mode
                           requester:(id)requester
                              reason:(NSString *)reason {
  [self grey_pushRunLoopMode:mode];
  INVOKE_ORIGINAL_IMP3(void, @selector(greyswizzled_pushRunLoopMode:requester:reason:), mode,
                       requester, reason);
}

/** Internal pop runloop method added post iOS 12.*/
- (void)greyswizzled_popRunLoopMode:(NSString *)mode
                          requester:(id)requester
                             reason:(NSString *)reason {
  [self grey_popRunLoopMode:mode];
  INVOKE_ORIGINAL_IMP3(void, @selector(greyswizzled_popRunLoopMode:requester:reason:), mode,
                       requester, reason);
}

#pragma mark - Private

- (void)grey_pushRunLoopMode:(NSString *)mode {
  @synchronized(gRunLoopModes) {
    [gRunLoopModes addObject:mode];
  }
}

- (void)grey_popRunLoopMode:(NSString *)mode {
  @synchronized(gRunLoopModes) {
    NSString *topOfStackMode = [gRunLoopModes lastObject];
    if (![topOfStackMode isEqual:mode]) {
      NSLog(@"Mode being popped: %@ isn't top of stack: %@", mode, topOfStackMode);
      abort();
    }
    [gRunLoopModes removeLastObject];
  }
}

@end
