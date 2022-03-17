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
#import "GREYFatalAsserts.h"
#import "GREYAppState.h"
#import "GREYAppleInternals.h"
#import "GREYDefines.h"
#import "GREYLogger.h"
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

  if (GREYVerboseLoggingEnabledForLevel(kGREYVerboseLogTypeSendTouchEvent)) {
    originalSel = @selector(sendEvent:);
    swizzledSel = @selector(greyswizzled_sendEvent:);
    swizzleSuccess = [swizzler swizzleClass:self
                      replaceInstanceMethod:originalSel
                                 withMethod:swizzledSel];
    GREYFatalAssertWithMessage(swizzleSuccess,
                               @"Cannot swizzle UIApplication beginIgnoringInteractionEvents");
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

// EarlGrey should continue tracking UIApplication's deprecated -beginIgnoringInteractionEvents and
// -endIgnoringInteractionEvents because it synchronizes UIViewController's -presentViewController:
// animated:completion:. The UIView's alternative property doesn't capture the same events.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  // begin/end can be nested, instead of keeping the count, simply use isIgnoringInteractionEvents.
  BOOL isIgnoringInteractionEvents = self.isIgnoringInteractionEvents;
#pragma clang diagnostic pop

  if (!isIgnoringInteractionEvents) {
    GREYAppStateTrackerObject *object =
        objc_getAssociatedObject(self, @selector(greyswizzled_beginIgnoringInteractionEvents));
    UNTRACK_STATE_FOR_OBJECT(kGREYIgnoringSystemWideUserInteraction, object);
    objc_setAssociatedObject(self, @selector(greyswizzled_beginIgnoringInteractionEvents), nil,
                             OBJC_ASSOCIATION_ASSIGN);
  }
}

- (void)greyswizzled_sendEvent:(UIEvent *)event {
  if (event.type == UIEventTypeTouches) {
    UITouch *anyTouch = event.allTouches.anyObject;
    if (anyTouch.phase == UITouchPhaseBegan) {
      GREYLogVerbose(@"Touch began at view %@", anyTouch.view.description);
    } else if (anyTouch.phase == UITouchPhaseMoved) {
      GREYLogVerbose(@"Touch moved at view %@", anyTouch.view.description);
    } else if (anyTouch.phase == UITouchPhaseStationary) {
      GREYLogVerbose(@"Touch stationed at view %@", anyTouch.view.description);
    } else if (anyTouch.phase == UITouchPhaseEnded) {
      GREYLogVerbose(@"Touch ended at view %@", anyTouch.view.description);
    }
  }
  INVOKE_ORIGINAL_IMP1(void, @selector(greyswizzled_sendEvent:), event);
}

@end
