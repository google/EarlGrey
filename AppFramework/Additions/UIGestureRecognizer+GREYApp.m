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

#import "UIGestureRecognizer+GREYApp.h"

#import <UIKit/UIGestureRecognizerSubclass.h>
#include <objc/runtime.h>

#import "GREYAppStateTracker.h"
#import "GREYAppStateTrackerObject.h"
#import "GREYFatalAsserts.h"
#import "GREYAppState.h"
#import "GREYDefines.h"
#import "GREYLogger.h"
#import "GREYSwizzler.h"

static Class gKeyboardPinchGestureRecognizerClass;
static NSSet<Class> *gDisabledGestureRecognizers;

@implementation UIGestureRecognizer (GREYApp)

+ (void)load {
  gKeyboardPinchGestureRecognizerClass = NSClassFromString(@"UIKeyboardPinchGestureRecognizer");
  gDisabledGestureRecognizers = nil;
  GREYSwizzler *swizzler = [[GREYSwizzler alloc] init];
  BOOL swizzled;
  // _setDirty is not available in iOS 18+ UIKit.
  if (!iOS18_OR_ABOVE()) {
    swizzled = [swizzler swizzleClass:self
                replaceInstanceMethod:NSSelectorFromString(@"_setDirty")
                           withMethod:@selector(greyswizzled_setDirty)];
    GREYFatalAssertWithMessage(swizzled, @"Failed to swizzle UIGestureRecognizer _setDirty");
  }

  swizzled = [swizzler swizzleClass:self
              replaceInstanceMethod:NSSelectorFromString(@"_resetGestureRecognizer")
                         withMethod:@selector(greyswizzled_resetGestureRecognizer)];
  GREYFatalAssertWithMessage(swizzled,
                             @"Failed to swizzle UIGestureRecognizer _resetGestureRecognizer");

  swizzled = [swizzler swizzleClass:self
              replaceInstanceMethod:@selector(setState:)
                         withMethod:@selector(greyswizzled_setState:)];
  GREYFatalAssertWithMessage(swizzled, @"Failed to swizzle UIGestureRecognizer setState:");

  swizzled = [swizzler swizzleClass:self
              replaceInstanceMethod:@selector(shouldReceiveEvent:)
                         withMethod:@selector(greyswizzled_shouldReceiveEvent:)];
  GREYFatalAssertWithMessage(swizzled, @"Failed to swizzle UIGestureRecognizer setState:");
}

#pragma mark - Swizzled Implementation

- (void)greyswizzled_setDirty {
  INVOKE_ORIGINAL_IMP(void, @selector(greyswizzled_setDirty));
  BOOL isAKeyboardPinchGestureOnIPad =
      ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad &&
       [self isKindOfClass:gKeyboardPinchGestureRecognizerClass]);
  if (!isAKeyboardPinchGestureOnIPad && self.state != UIGestureRecognizerStateFailed) {
    GREYAppStateTrackerObject *object =
        TRACK_STATE_FOR_OBJECT(kGREYPendingGestureRecognition, self);
    object.objectDescription =
        [NSString stringWithFormat:@"%@\n Delegate: %@\n", object.objectDescription, self.delegate];
    objc_setAssociatedObject(self, @selector(greyswizzled_setState:), object,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }
}

- (void)greyswizzled_resetGestureRecognizer {
  GREYAppStateTrackerObject *object =
      objc_getAssociatedObject(self, @selector(greyswizzled_setState:));
  UNTRACK_STATE_FOR_OBJECT(kGREYPendingGestureRecognition, object);
  objc_setAssociatedObject(self, @selector(greyswizzled_setState:), nil, OBJC_ASSOCIATION_ASSIGN);
  INVOKE_ORIGINAL_IMP(void, @selector(greyswizzled_resetGestureRecognizer));
}

- (void)greyswizzled_setState:(UIGestureRecognizerState)state {
  // This is needed only for a few cases where reset isn't called on the gesture recognizer when
  // keyboard is shown. We need to manually untrack when state is set to failed.
  if (state == UIGestureRecognizerStateFailed) {
    GREYAppStateTrackerObject *object =
        objc_getAssociatedObject(self, @selector(greyswizzled_setState:));
    UNTRACK_STATE_FOR_OBJECT(kGREYPendingGestureRecognition, object);
    objc_setAssociatedObject(self, @selector(greyswizzled_setState:), nil, OBJC_ASSOCIATION_ASSIGN);
  } else if (iOS18_OR_ABOVE()) {
    // Temporary fix for _setDirty not being available in iOS 18+ UIKit.
    // TODO: b/346414832 - Remove this once permanent fix is in place.
    BOOL isAKeyboardPinchGestureOnIPad =
        ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad &&
         [self isKindOfClass:gKeyboardPinchGestureRecognizerClass]);
    if (!isAKeyboardPinchGestureOnIPad) {
      GREYAppStateTrackerObject *object =
          TRACK_STATE_FOR_OBJECT(kGREYPendingGestureRecognition, self);
      object.objectDescription = [NSString
          stringWithFormat:@"%@\n Delegate: %@\n", object.objectDescription, self.delegate];
      objc_setAssociatedObject(self, @selector(greyswizzled_setState:), object,
                               OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
  }
  INVOKE_ORIGINAL_IMP1(void, @selector(greyswizzled_setState:), state);
}

- (BOOL)greyswizzled_shouldReceiveEvent:(id)event {
  Class recognizerClass = [self class];
  if ([gDisabledGestureRecognizers containsObject:recognizerClass]) {
    GREYLogVerbose(@"%@ is ignored by EarlGrey intentionally.", NSStringFromClass(recognizerClass));
    return NO;
  }
  return INVOKE_ORIGINAL_IMP1(BOOL, @selector(greyswizzled_shouldReceiveEvent:), event);
}

@end

void GREYPerformBlockWithGestureRecognizerDisabled(NSArray<Class> *gestureRecognizerClasses,
                                                   void (^block)(void)) {
  if (![NSThread isMainThread]) {
    [[NSAssertionHandler currentHandler]
        handleFailureInFunction:@"GREYPerformBlockWithGestureRecognizerDisabled"
                           file:@__FILE__
                     lineNumber:__LINE__
                    description:@"GREYPerformBlockWithGestureRecognizerDisabled must be called on "
                                @"main thread. This is an EarlGrey programming error, please file "
                                @"a bug to EarlGrey team."];
  }
  if (gDisabledGestureRecognizers) {
    [[NSAssertionHandler currentHandler]
        handleFailureInFunction:@"GREYPerformBlockWithGestureRecognizerDisabled"
                           file:@__FILE__
                     lineNumber:__LINE__
                    description:
                        @"GREYPerformBlockWithGestureRecognizerDisabled is not reentrant. This is "
                        @"an EarlGrey programming error, please file a bug to EarlGrey team"];
  }
  gDisabledGestureRecognizers = [NSSet setWithArray:gestureRecognizerClasses];
  block();
  gDisabledGestureRecognizers = nil;
}
