//
// Copyright 2018 Google Inc.
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

#import "GREYTouchInjector.h"

#import <QuartzCore/QuartzCore.h>
#include <mach/mach_time.h>

#import "GREYIOHIDEventTypes.h"
#import "GREYRunLoopSpinner.h"
#import "NSObject+GREYCommon.h"
#import "GREYFatalAsserts.h"
#import "GREYThrowDefines.h"
#import "GREYConfiguration.h"

/**
 *  The time interval in seconds between each touch injection.
 */
static const NSTimeInterval kTouchInjectFramerateInv = 1 / 120.0;

@implementation GREYTouchInjector {
  // Window to which touches will be delivered.
  UIWindow *_window;
  // A dispatch queue to synchronize the adding of any touches.
  dispatch_queue_t _enqueuedTouchQueue;
  // Touch objects created to start the touch sequence for every
  // touch points. It stores one UITouch object for each finger
  // in a touch event.
  NSMutableArray<UITouch *> *_ongoingTouches;
  // List of objects that aid in creation of UITouches.
  // Note, access to this needs to be dispatched to @c _enqueuedTouchQueue.
  NSMutableArray<GREYTouchInfo *> *_enqueuedTouchInfoList;
}

- (instancetype)initWithWindow:(UIWindow *)window {
  GREYThrowOnNilParameter(window);

  self = [super init];
  if (self) {
    _window = window;
    _ongoingTouches = [[NSMutableArray alloc] init];
    _enqueuedTouchQueue =
        dispatch_queue_create("com.google.earlgrey.TouchQueue", DISPATCH_QUEUE_SERIAL);
    _enqueuedTouchInfoList = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)enqueueTouchInfoForDelivery:(GREYTouchInfo *)touchInfo {
  dispatch_sync(_enqueuedTouchQueue, ^{
    [self->_enqueuedTouchInfoList addObject:touchInfo];
  });
}

- (void)waitUntilAllTouchesAreDelivered {
  __block NSArray<GREYTouchInfo *> *enqueuedTouches = nil;
  dispatch_sync(_enqueuedTouchQueue, ^{
    enqueuedTouches = [self->_enqueuedTouchInfoList copy];
  });

  [self grey_deliverTouches:enqueuedTouches];

  __block BOOL touchesAddedAfterInjectionStarted = NO;
  dispatch_sync(_enqueuedTouchQueue, ^{
    touchesAddedAfterInjectionStarted =
        ![self->_enqueuedTouchInfoList isEqualToArray:enqueuedTouches];
    [self->_enqueuedTouchInfoList removeAllObjects];
  });
  GREYThrowOnFailedConditionWithMessage(!touchesAddedAfterInjectionStarted,
                                        @"New touches were enqueued while injecting touches.");
}

- (void)grey_deliverTouches:(NSArray<GREYTouchInfo *> *)touchesList {
  if (touchesList.count == 0) {
    return;
  }

  dispatch_semaphore_t waitTouches = dispatch_semaphore_create(0);
  dispatch_queue_t touchQueue = dispatch_get_main_queue();

  NSEnumerator<GREYTouchInfo *> *touchEnumerator = [touchesList objectEnumerator];
  __block GREYTouchInfo *touchInfo = touchEnumerator.nextObject;
  __weak __block void (^weakTouchProcessBlock)(void);
  void (^touchProcessBlock)(void) = ^{
    void (^strongTouchProcessBlock)(void) = weakTouchProcessBlock;
    // If the parent method times out and returns, it will effectively kill this block execution
    // by releasing the strong reference.
    if (!strongTouchProcessBlock) {
      return;
    }

    if (!touchInfo) {
      dispatch_semaphore_signal(waitTouches);
    } else {
      NSException *injectException;
      if (![self grey_injectTouches:touchInfo
                     ongoingTouches:self->_ongoingTouches
                          exception:&injectException]) {
        dispatch_semaphore_signal(waitTouches);
        [injectException raise];
      } else {
        touchInfo = touchEnumerator.nextObject;
        NSTimeInterval deliveryTimeDeltaSinceLastTouch =
            MAX(touchInfo.deliveryTimeDeltaSinceLastTouch, kTouchInjectFramerateInv);
        dispatch_time_t nextDeliverTime = dispatch_time(
            DISPATCH_TIME_NOW, (int64_t)(deliveryTimeDeltaSinceLastTouch * NSEC_PER_SEC));
        dispatch_after(nextDeliverTime, touchQueue, strongTouchProcessBlock);
      }
    }
  };
  // Move the receiveHandler block to the heap by explicitly copying before assigning it to the
  // weak pointer as in the latest clang compiler, it's possible the weak pointer can be invalid if
  // the block hasn't been moved to the heap in time.
  // https://reviews.llvm.org/D58514
  touchProcessBlock = [touchProcessBlock copy];
  weakTouchProcessBlock = touchProcessBlock;

  NSTimeInterval deliveryTimeDeltaSinceLastTouch =
      MAX(touchInfo.deliveryTimeDeltaSinceLastTouch, kTouchInjectFramerateInv);
  dispatch_time_t firstDeliverTime =
      dispatch_time(DISPATCH_TIME_NOW, (int64_t)(deliveryTimeDeltaSinceLastTouch * NSEC_PER_SEC));
  dispatch_after(firstDeliverTime, touchQueue, touchProcessBlock);

  CFTimeInterval interactionTimeout = GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration);
  // Now wait for it to finish.
  if (![NSThread isMainThread]) {
    dispatch_time_t waitTimeout =
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interactionTimeout * NSEC_PER_SEC));
    if (dispatch_semaphore_wait(waitTouches, waitTimeout) != 0) {
      NSLog(@"Waiting on the touches to be delivered timed out.");
    }
  } else {
    // Spin the runloop if it waits on the main thread.
    // There can be cases where the injection happens on the main thread so the code can handle
    // synchronization or access the UI element in a more elegant and reliable way, i.e.
    // GREYSlideAction.
    GREYRunLoopSpinner *runLoopSpinner = [[GREYRunLoopSpinner alloc] init];
    runLoopSpinner.timeout = interactionTimeout;
    runLoopSpinner.minRunLoopDrains = 0;
    runLoopSpinner.maxSleepInterval = DBL_MAX;
    [runLoopSpinner spinWithStopConditionBlock:^BOOL {
      return dispatch_semaphore_wait(waitTouches, DISPATCH_TIME_NOW) == 0;
    }];
  }
}

#pragma mark - Private Injecting touches API's

/**
 *  Takes a GREYTouchInfo object and converts it into a UITouch. Also adds the newly created
 *  touch object and adds it to an array of ongoing touches.
 *
 *  @param touchInfo The info that is used to create the UITouch.
 *  @param event     The UIEvent for the touches injected.
 */
- (void)grey_updateUITouchObjectsFromTouchInfo:(GREYTouchInfo *)touchInfo
                                ongoingTouches:(NSMutableArray<UITouch *> *)ongoingTouches
                                     withEvent:(UIEvent *)event {
  GREYFatalAssertMainThread();
  BOOL shouldCreateTouchObjects = (ongoingTouches.count == 0);

  for (NSUInteger i = 0; i < [touchInfo.points count]; i++) {
    CGPoint touchPoint = [[touchInfo.points objectAtIndex:i] CGPointValue];

    UITouch *touch;
    if (shouldCreateTouchObjects) {
      // These values are obtained by running an app on the simulator, manually touching the screen
      // and inspecting the values of the touch object that's created.
      touch = [[UITouch alloc] init];
      [touch setWindow:_window];
      [touch setIsTap:YES];
      [touch setTapCount:1];
      [touch setIsDelayed:NO];
      [touch _setPathIndex:1];
      [touch _setPathIdentity:2];
      if ([touch respondsToSelector:@selector(_setSenderID:)]) {
        [touch _setSenderID:0x0acefade00000002 /* value sourced from trial run on simulator */];
      }
      UIView *touchView = [_window hitTest:touchPoint withEvent:event];

      [touch setView:touchView];
      [touch _setIsFirstTouchForView:YES];
      [ongoingTouches addObject:touch];
    } else {
      touch = ongoingTouches[i];
      if (!touch.view) {
        [touch setView:[_window hitTest:touchPoint withEvent:event]];
      }
    }

    // Set phase appropriate values.
    [touch setPhase:touchInfo.phase];
    [touch _setLocationInWindow:touchPoint resetPrevious:(touchInfo.phase == UITouchPhaseBegan)];
  }
}

/**
 *  Inject touches to the application.
 *
 *  @param touchInfo      The info that is used to create the UITouch.
 *  @param ongoingTouches The array of UITouches that are being injected.
 *  @param exception      The exception if it fails to inject.
 *  @return @c YES if injection succeeds, @c NO otherwise.
 */
- (BOOL)grey_injectTouches:(GREYTouchInfo *)touchInfo
            ongoingTouches:(NSMutableArray<UITouch *> *)ongoingTouches
                 exception:(NSException **)exception {
  GREYFatalAssertMainThread();
  id injectionException;
  UITouchesEvent *event = [[UIApplication sharedApplication] _touchesEvent];
  [self grey_updateUITouchObjectsFromTouchInfo:touchInfo
                                ongoingTouches:ongoingTouches
                                     withEvent:event];

  [event _clearTouches];

  CFTimeInterval touchDeliveryTime = CACurrentMediaTime();
  uint64_t deliveryTime = getMachOTimeFromSeconds(touchDeliveryTime);

  IOHIDDigitizerEventMask fingerEventMask = grey_fingerDigitizerEventMaskFromPhase(touchInfo.phase);
  // touch is 1 if finger is touching the screen.
  boolean_t isTouch =
      (touchInfo.phase != UITouchPhaseEnded) && (touchInfo.phase != UITouchPhaseCancelled) ? 1 : 0;

  IOHIDEventRef hidEvent = IOHIDEventCreateDigitizerEvent(
      kCFAllocatorDefault, deliveryTime, kIOHIDDigitizerTransducerTypeHand, 1, 2, fingerEventMask,
      0, 0, 0, 0, 0, 0, isTouch, isTouch, kIOHIDEventOptionNone);

#if TARGET_IPHONE_SIMULATOR
  IOHIDEventSetIntegerValue(hidEvent, kIOHIDEventFieldDigitizerIsDisplayIntegrated, 1);
#else
  IOHIDEventSetIntegerValue(hidEvent, kIOHIDEventFieldDigitizerIsDisplayIntegrated, 0);
#endif

  UIView *touchView = nil;
  for (NSUInteger i = 0; i < touchInfo.points.count; i++) {
    CGPoint touchPoint = [[touchInfo.points objectAtIndex:i] CGPointValue];
    IOHIDEventRef fingerEvent = IOHIDEventCreateDigitizerFingerEvent(
        kCFAllocatorDefault, deliveryTime, 1, 2, fingerEventMask, touchPoint.x, touchPoint.y, 0, 0,
        0, isTouch, isTouch, kIOHIDEventOptionNone);

#if TARGET_IPHONE_SIMULATOR
    IOHIDEventSetIntegerValue(fingerEvent, kIOHIDEventFieldDigitizerIsDisplayIntegrated, 1);
#else
    IOHIDEventSetIntegerValue(fingerEvent, kIOHIDEventFieldDigitizerIsDisplayIntegrated, 0);
#endif
    IOHIDEventAppendEvent(hidEvent, fingerEvent, 0);
    CFRelease(fingerEvent);

    UITouch *currentTouch = ongoingTouches[i];
    touchView = currentTouch.view;

    [currentTouch setTimestamp:touchDeliveryTime];
    if ([currentTouch respondsToSelector:@selector(_setHidEvent:)]) {
      [currentTouch _setHidEvent:fingerEvent];
    }
    [event _addTouch:currentTouch forDelayedDelivery:NO];
  }
  [event _setHIDEvent:hidEvent];
  CFRelease(hidEvent);

  @try {
    // Adds an autorelease pool just like the system does around event interacton.
    @autoreleasepool {
      [[UIApplication sharedApplication] sendEvent:event];
    }
  } @catch (id exception) {
    injectionException = exception;
  } @finally {
    [event _setHIDEvent:NULL];
  }
  return !injectionException;
}

/**
 *  @return event mask for the provided touch phase.
 */
static inline IOHIDDigitizerEventMask grey_fingerDigitizerEventMaskFromPhase(UITouchPhase phase) {
  IOHIDDigitizerEventMask eventMask = 0;
  if (phase != UITouchPhaseCancelled && phase != UITouchPhaseBegan && phase != UITouchPhaseEnded &&
      phase != UITouchPhaseStationary) {
    eventMask |= kIOHIDDigitizerEventPosition;
  }
  if (phase == UITouchPhaseBegan || phase == UITouchPhaseEnded || phase == UITouchPhaseCancelled) {
    eventMask |= (kIOHIDDigitizerEventTouch | kIOHIDDigitizerEventRange);
  }
  if (phase == UITouchPhaseCancelled) {
    eventMask |= kIOHIDDigitizerEventCancel;
  }
  return eventMask;
}

/**
 *  @return Converts @c seconds to mach-o time type.
 */
inline static uint64_t getMachOTimeFromSeconds(CFTimeInterval seconds) {
  mach_timebase_info_data_t info;
  kern_return_t retVal = mach_timebase_info(&info);
  if (retVal != KERN_SUCCESS) {
    NSCAssert(NO, @"mach_timebase_info failed with kern return val: %d", retVal);
  }
  uint64_t nanosecs = (uint64_t)(seconds * NSEC_PER_SEC);
  uint64_t time = (nanosecs / info.numer) * info.denom;
  return time;
}

@end
