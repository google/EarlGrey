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
#include <objc/runtime.h>

#import "GREYIOHIDEventTypes.h"
#import "GREYRunLoopSpinner.h"
#import "GREYFatalAsserts.h"
#import "GREYThrowDefines.h"
#import "GREYTouchInfo.h"
#import "GREYConstants.h"
#import "GREYLogger.h"

/**
 * The time interval between frames, assuming a frame rate of 120 FPS.
 */
static const NSTimeInterval kTouchInjectFramerateInv = 1 / 120.0;

/**
 * The time interval after the last touch injection.
 */
static const NSTimeInterval kDelayAfterLastTouchEvent = kTouchInjectFramerateInv;

/**
 * The minimal delay between any two touch events.
 *
 * Depends on weather the `fast_tap_events` environment variable exists, it could be zero or
 * `kTouchInjectFramerateInv`.
 */
static NSTimeInterval MinimumDelayBetweenTouchEvents(void) {
  static NSTimeInterval minimumDelay;
  static dispatch_once_t dispatch_once_predicate;
  dispatch_once(&dispatch_once_predicate, ^(void) {
    NSDictionary<NSString *, NSString *> *env = NSProcessInfo.processInfo.environment;
    minimumDelay = env[kFastTapEnvironmentVariableName] ? 0.0 : kTouchInjectFramerateInv;
  });
  return minimumDelay;
}

/**
 * Returns the adjusted `touchInfo.deliveryTimeDeltaSinceLastTouch` so it's greater than or equal to
 * the minimum delay.
 *
 * @see MinimumDelayBetweenTouchEvents()
 */
static NSTimeInterval AdjustedDeliveryTimeDelta(GREYTouchInfo *touchInfo) {
  NSTimeInterval minimumDelay = MinimumDelayBetweenTouchEvents();
  NSTimeInterval originalDelta = touchInfo.deliveryTimeDeltaSinceLastTouch;
  return originalDelta >= minimumDelay ? originalDelta : minimumDelay;
}

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

- (void)waitUntilAllTouchesAreDeliveredWithTimeout:(NSTimeInterval)timeout {
  __block NSArray<GREYTouchInfo *> *enqueuedTouches = nil;
  dispatch_sync(_enqueuedTouchQueue, ^{
    enqueuedTouches = [self->_enqueuedTouchInfoList copy];
  });

  [self grey_deliverTouches:enqueuedTouches timeout:timeout];

  __block BOOL touchesAddedAfterInjectionStarted = NO;
  dispatch_sync(_enqueuedTouchQueue, ^{
    touchesAddedAfterInjectionStarted =
        ![self->_enqueuedTouchInfoList isEqualToArray:enqueuedTouches];
    [self->_enqueuedTouchInfoList removeAllObjects];
  });
  GREYThrowOnFailedConditionWithMessage(!touchesAddedAfterInjectionStarted,
                                        @"New touches were enqueued while injecting touches.");
}

- (void)grey_deliverTouches:(NSArray<GREYTouchInfo *> *)touchesList
                    timeout:(NSTimeInterval)timeout {
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
      do {
        NSException *injectException;
        if (![self grey_injectTouches:touchInfo
                       ongoingTouches:self->_ongoingTouches
                            exception:&injectException]) {
          dispatch_semaphore_signal(waitTouches);
          [injectException raise];
        } else {
          touchInfo = touchEnumerator.nextObject;
        }
      } while (touchInfo && AdjustedDeliveryTimeDelta(touchInfo) <= 0.0);

      NSTimeInterval deliveryTimeDeltaSinceLastTouch =
          touchInfo ? AdjustedDeliveryTimeDelta(touchInfo) : kDelayAfterLastTouchEvent;
      dispatch_time_t nextDeliverTime = dispatch_time(
          DISPATCH_TIME_NOW, (int64_t)(deliveryTimeDeltaSinceLastTouch * NSEC_PER_SEC));
      dispatch_after(nextDeliverTime, touchQueue, strongTouchProcessBlock);
    }
  };
  // Move the receiveHandler block to the heap by explicitly copying before assigning it to the
  // weak pointer as in the latest clang compiler, it's possible the weak pointer can be invalid if
  // the block hasn't been moved to the heap in time.
  // https://reviews.llvm.org/D58514
  touchProcessBlock = [touchProcessBlock copy];
  weakTouchProcessBlock = touchProcessBlock;

  NSTimeInterval deliveryTimeDeltaBeforeFirstTouch = AdjustedDeliveryTimeDelta(touchInfo);
  dispatch_time_t firstDeliverTime =
      dispatch_time(DISPATCH_TIME_NOW, (int64_t)(deliveryTimeDeltaBeforeFirstTouch * NSEC_PER_SEC));
  dispatch_after(firstDeliverTime, touchQueue, touchProcessBlock);

  // Now wait for it to finish.
  if (![NSThread isMainThread]) {
    dispatch_time_t waitTimeout =
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC));
    if (dispatch_semaphore_wait(waitTouches, waitTimeout) != 0) {
      GREYLog(@"Waiting on the touches to be delivered timed out.");
    }
  } else {
    // Spin the runloop if it waits on the main thread.
    // There can be cases where the injection happens on the main thread so the code can handle
    // synchronization or access the UI element in a more elegant and reliable way, i.e.
    // GREYSlideAction.
    GREYRunLoopSpinner *runLoopSpinner = [[GREYRunLoopSpinner alloc] init];
    runLoopSpinner.timeout = timeout;
    runLoopSpinner.minRunLoopDrains = 0;
    runLoopSpinner.maxSleepInterval = DBL_MAX;
    [runLoopSpinner spinWithStopConditionBlock:^BOOL {
      return dispatch_semaphore_wait(waitTouches, DISPATCH_TIME_NOW) == 0;
    }];
  }
}

#pragma mark - Private Injecting touches API's

/**
 * Takes a GREYTouchInfo object and converts it into a UITouch. Also adds the newly created
 * touch object and adds it to an array of ongoing touches.
 *
 * @param touchInfo The info that is used to create the UITouch.
 * @param event     The UIEvent for the touches injected.
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
      if (@available(iOS 14.0, *)) {
#if defined(__IPHONE_14_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_14_0
        [touch _setIsTapToClick:YES];
#endif
      } else {
        [touch setIsTap:YES];
      }
      [touch setTapCount:touchInfo.tapCount];
      [touch setIsDelayed:NO];
      [touch _setPathIndex:1];
      [touch _setPathIdentity:2];
      if ([touch respondsToSelector:@selector(_setSenderID:)]) {
        [touch _setSenderID:0x0acefade00000002 /* value sourced from trial run on simulator */];
      }
      UIView *touchView = [_window hitTest:touchPoint withEvent:event];
      [touch setView:touchView];
      SetTouchFlagPropertyInUITouch(touch);
      [ongoingTouches addObject:touch];
    } else {
      touch = ongoingTouches[i];
      if (!touch.view) {
        [touch setView:[_window hitTest:touchPoint withEvent:event]];
      }
    }

#if defined(__IPHONE_18_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_18_0
    if (touchInfo.responder) {
      [touch _setResponder:touchInfo.responder];
    }
#endif

    // Set phase appropriate values.
    [touch setPhase:touchInfo.phase];
    [touch _setLocationInWindow:touchPoint resetPrevious:(touchInfo.phase == UITouchPhaseBegan)];
  }
}

/**
 * Inject touches to the application.
 *
 * @param touchInfo      The info that is used to create the UITouch.
 * @param ongoingTouches The array of UITouches that are being injected.
 * @param exception      The exception if it fails to inject.
 *
 * @return @c YES if injection succeeds, @c NO otherwise.
 */
- (BOOL)grey_injectTouches:(GREYTouchInfo *)touchInfo
            ongoingTouches:(NSMutableArray<UITouch *> *)ongoingTouches
                 exception:(NSException **)exception {
  GREYFatalAssertMainThread();
  id injectionException;
  UITouchesEvent *event = [UIApplication.sharedApplication _touchesEvent];
  [self grey_updateUITouchObjectsFromTouchInfo:touchInfo
                                ongoingTouches:ongoingTouches
                                     withEvent:event];

  [event _clearTouches];

  CFTimeInterval touchDeliveryTime = CACurrentMediaTime();
  uint64_t deliveryTime = GetMachOTimeFromSeconds(touchDeliveryTime);

  IOHIDDigitizerEventMask fingerEventMask = FingerDigitizerEventMaskFromPhase(touchInfo.phase);
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
      [UIApplication.sharedApplication sendEvent:event];
    }
  } @catch (id exception) {
    injectionException = exception;
  } @finally {
    [event _setHIDEvent:NULL];
  }
  return !injectionException;
}

/**
 * @return event mask for the provided touch phase.
 */
static inline IOHIDDigitizerEventMask FingerDigitizerEventMaskFromPhase(UITouchPhase phase) {
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
 * @return Converts @c seconds to mach-o time type.
 */
static inline uint64_t GetMachOTimeFromSeconds(CFTimeInterval seconds) {
  mach_timebase_info_data_t info;
  kern_return_t retVal = mach_timebase_info(&info);
  if (retVal != KERN_SUCCESS) {
    NSCAssert(NO, @"mach_timebase_info failed with kern return val: %d", retVal);
  }
  uint64_t nanosecs = (uint64_t)(seconds * NSEC_PER_SEC);
  uint64_t time = (nanosecs / info.numer) * info.denom;
  return time;
}

/**
 * For iOS 14+, sets on the first _firstTouchForView property on the touchFlags struct of a UITouch.
 *
 * @note We are trying to modify a value in the UITouchFlags struct over here. If we try to obtain
 *       the entire struct and get / set it, then we run the chance of setting over the size of the
 *       struct, leading to corruption in the memory beyond the after the struct's memory. If this
 *       happens, then we get a crash on dealloc when the memory is deallocated with the
 *       objc.cxx_descruct call. Hence, only the minimum amount required, a 1 byte char is set in
 *       the UITouchFlags struct denoting the _firstTouchForView property which we need.
 *
 * @param touch The UITouch being updated.
 */
static inline void SetTouchFlagPropertyInUITouch(UITouch *touch) {
  typedef UITouchFlags (*UITouchFlagsGetVariableFunction)(id object, Ivar ivar);
  UITouchFlagsGetVariableFunction getTouchFlagsFunction =
      (UITouchFlagsGetVariableFunction)object_getIvar;
  Ivar touchflags = class_getInstanceVariable([UITouch class], "_touchFlags");

  UITouchFlags flags = getTouchFlagsFunction(touch, touchflags);
  flags._firstTouchForView = 1;

  typedef void (*UITouchSetVariableFunction)(id object, Ivar ivar, UITouchFlags flags);
  UITouchSetVariableFunction setTouchFlagsFunction = (UITouchSetVariableFunction)object_setIvar;
  setTouchFlagsFunction(touch, touchflags, flags);
}

@end
