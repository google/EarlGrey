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

#import "GREYSyntheticEvents.h"

#import "GREYTouchInjector.h"
#import "GREYFatalAsserts.h"
#import "GREYThrowDefines.h"
#import "GREYTouchInfo.h"
#import "GREYAppleInternals.h"
#import "GREYUIWindowProvider.h"

#pragma mark - Implementation

/**
 * The minimum gap between two events in a touch path.
 */
static const NSTimeInterval kMinimumDelayBetweenTouchPathEvents = 1.0 / 120.0;

@implementation GREYSyntheticEvents {
  /**
   * The touch injector that completes the touch sequence for an event.
   */
  GREYTouchInjector *_touchInjector;

  /**
   * The last injected touch point.
   */
  NSValue *_lastInjectedTouchPoint;
}

+ (void)touchAlongPath:(NSArray *)touchPath
      relativeToWindow:(UIWindow *)window
           forDuration:(NSTimeInterval)duration
               timeout:(NSTimeInterval)timeout {
  [self touchAlongMultiplePaths:@[ touchPath ]
               relativeToWindow:window
                    forDuration:duration
                        timeout:timeout
                        element:nil];
}

+ (void)touchAlongPath:(NSArray *)touchPath
      relativeToWindow:(UIWindow *)window
           forDuration:(NSTimeInterval)duration
               timeout:(NSTimeInterval)timeout
               element:(id _Nullable)element {
  [self touchAlongMultiplePaths:@[ touchPath ]
               relativeToWindow:window
                    forDuration:duration
                        timeout:timeout
                        element:element];
}

+ (void)touchAlongPath:(NSArray<NSValue *> *)touchPath
         relativeToWindow:(UIWindow *)window
              forDuration:(NSTimeInterval)duration
                  timeout:(NSTimeInterval)timeout
                  element:(id _Nullable)element
      touchesBeganHandler:(dispatch_block_t _Nullable)touchesBeganHandler
    touchesWillEndHandler:(dispatch_block_t _Nullable)touchesWillEndHandler {
  [self grey_touchAlongMultiplePaths:@[ touchPath ]
                    relativeToWindow:window
                         forDuration:duration
                             timeout:timeout
                             element:element
                 touchesBeganHandler:touchesBeganHandler
               touchesWillEndHandler:touchesWillEndHandler];
}

+ (void)touchAlongMultiplePaths:(NSArray *)touchPaths
               relativeToWindow:(UIWindow *)window
                    forDuration:(NSTimeInterval)duration
                        timeout:(NSTimeInterval)timeout {
  [self touchAlongMultiplePaths:touchPaths
               relativeToWindow:window
                    forDuration:duration
                        timeout:timeout
                        element:nil];
}

+ (void)touchAlongMultiplePaths:(NSArray *)touchPaths
               relativeToWindow:(UIWindow *)window
                    forDuration:(NSTimeInterval)duration
                        timeout:(NSTimeInterval)timeout
                        element:(id _Nullable)element {
  [self grey_touchAlongMultiplePaths:touchPaths
                    relativeToWindow:window
                         forDuration:duration
                             timeout:timeout
                             element:element
                 touchesBeganHandler:nil
               touchesWillEndHandler:nil];
}

/**
 * Injects a multi touch sequence along @c touchPaths, optionally invoking handlers while the
 * touches are down. See the public touchAlongPath:...touchesBeganHandler:touchesWillEndHandler:
 * method for parameter details.
 *
 * If @c touchesBeganHandler is non-nil, the "begin" event is delivered before calling it. If
 * @c touchesWillEndHandler is non-nil, it is called immediately before the "end" event is
 * delivered. If @c touchesBeganHandler raises an exception, @c touchesWillEndHandler is skipped,
 * because it may depend on state that @c touchesBeganHandler failed to set up. Either way, the rest
 * of the gesture still runs and the exception is rethrown after the "end" event is delivered, so
 * that no touch is left down in the app.
 */
+ (void)grey_touchAlongMultiplePaths:(NSArray<NSArray<NSValue *> *> *)touchPaths
                    relativeToWindow:(UIWindow *)window
                         forDuration:(NSTimeInterval)duration
                             timeout:(NSTimeInterval)timeout
                             element:(id _Nullable)element
                 touchesBeganHandler:(dispatch_block_t _Nullable)touchesBeganHandler
               touchesWillEndHandler:(dispatch_block_t _Nullable)touchesWillEndHandler {
  GREYThrowOnFailedCondition(touchPaths.count >= 1);
  GREYThrowOnFailedCondition(duration >= 0);

  NSUInteger firstTouchPathSize = [touchPaths[0] count];
  NSArray<NSValue *> *lastPoints = [self grey_objectsAtIndex:firstTouchPathSize - 1
                                                    ofArrays:touchPaths];
  GREYSyntheticEvents *eventGenerator = [[GREYSyntheticEvents alloc] init];

  // Inject "begin" event for the first points of each path. If there is a handler to call once the
  // touches have begun, deliver the event immediately so the handler runs while the touch is down.
  [eventGenerator grey_beginTouchesAtPoints:[self grey_objectsAtIndex:0 ofArrays:touchPaths]
                           relativeToWindow:window
                          immediateDelivery:(touchesBeganHandler != nil)
                                    timeout:timeout
                                    element:element];
  NSException *touchesBeganException = nil;
  if (touchesBeganHandler) {
    @try {
      touchesBeganHandler();
    } @catch (NSException *exception) {
      touchesBeganException = exception;
    }
  }

  // Inject "continue" events for the rest of each path (if any), with delays being a fraction of
  // the duration, starting from the second position on the touch path as it was already injected
  // as a "begin touch" event.
  if (firstTouchPathSize > 1) {
    CFTimeInterval delayBetweenEachEvent = duration / (double)(firstTouchPathSize - 1);
    for (NSUInteger i = 1; i < firstTouchPathSize; i++) {
      [eventGenerator grey_continueTouchAtPoints:[self grey_objectsAtIndex:i ofArrays:touchPaths]
          afterTimeElapsedSinceLastTouchDelivery:delayBetweenEachEvent
                               immediateDelivery:NO
                                         timeout:timeout
                                         element:element];
    }
  }

  // Inject the "end" event. If the paths have a single point, the "end" event is delayed by the
  // provided duration. Otherwise, the "continue" events already took up the duration, so it is
  // injected with no delay. Skip touchesWillEndHandler if touchesBeganHandler raised, because it
  // may depend on state that touchesBeganHandler failed to set up.
  NSException *touchesWillEndException = [eventGenerator
                grey_endTouchesAtPoints:lastPoints
      timeElapsedSinceLastTouchDelivery:(firstTouchPathSize == 1 ? duration : 0)
                                timeout:timeout
                                element:element
                  touchesWillEndHandler:(touchesBeganException ? nil : touchesWillEndHandler)];

  // Now that no touch is left down, rethrow any exception raised by a handler.
  NSException *handlerException = touchesBeganException ?: touchesWillEndException;
  if (handlerException) {
    @throw handlerException;
  }
}

+ (void)shakeDevice {
  UIApplication *application = UIApplication.sharedApplication;
  UIWindow *keyWindow = [GREYUIWindowProvider keyWindowForSharedApplication];
  UIMotionEvent *motionEvent = [application _motionEvent];

  [motionEvent setShakeState:1];
  [motionEvent _setSubtype:UIEventSubtypeMotionShake];
  [application sendEvent:motionEvent];
  [keyWindow motionBegan:UIEventSubtypeMotionShake withEvent:motionEvent];
  [keyWindow motionEnded:UIEventSubtypeMotionShake withEvent:motionEvent];
}

- (void)beginTouchAtPoint:(CGPoint)point
         relativeToWindow:(UIWindow *)window
        immediateDelivery:(BOOL)immediate
                  timeout:(NSTimeInterval)timeout {
  [self beginTouchAtPoint:point
         relativeToWindow:window
        immediateDelivery:immediate
                  timeout:timeout
                  element:nil];
}

- (void)beginTouchAtPoint:(CGPoint)point
         relativeToWindow:(UIWindow *)window
        immediateDelivery:(BOOL)immediate
                  timeout:(NSTimeInterval)timeout
                  element:(id _Nullable)element {
  _lastInjectedTouchPoint = [NSValue valueWithCGPoint:point];
  [self grey_beginTouchesAtPoints:@[ _lastInjectedTouchPoint ]
                 relativeToWindow:window
                immediateDelivery:immediate
                          timeout:timeout
                          element:element];
}

- (void)continueTouchAtPoint:(CGPoint)point
           immediateDelivery:(BOOL)immediate
                     timeout:(NSTimeInterval)timeout {
  [self continueTouchAtPoint:point immediateDelivery:immediate timeout:timeout element:nil];
}

- (void)continueTouchAtPoint:(CGPoint)point
           immediateDelivery:(BOOL)immediate
                     timeout:(NSTimeInterval)timeout
                     element:(id _Nullable)element {
  _lastInjectedTouchPoint = [NSValue valueWithCGPoint:point];
  [self grey_continueTouchAtPoints:@[ _lastInjectedTouchPoint ]
      afterTimeElapsedSinceLastTouchDelivery:kMinimumDelayBetweenTouchPathEvents
                           immediateDelivery:immediate
                                     timeout:timeout
                                     element:element];
}

- (void)endTouchWithTimeout:(NSTimeInterval)timeout {
  [self grey_endTouchesAtPoints:@[ _lastInjectedTouchPoint ]
      timeElapsedSinceLastTouchDelivery:kMinimumDelayBetweenTouchPathEvents
                                timeout:timeout
                                element:nil];
}

- (void)endTouchWithTimeout:(NSTimeInterval)timeout element:(id _Nullable)element {
  [self grey_endTouchesAtPoints:@[ _lastInjectedTouchPoint ]
      timeElapsedSinceLastTouchDelivery:kMinimumDelayBetweenTouchPathEvents
                                timeout:timeout
                                element:element];
}

#pragma mark - Private

// Given an array containing multiple arrays, returns an array with the index'th element of each
// array.
+ (NSArray *)grey_objectsAtIndex:(NSUInteger)index ofArrays:(NSArray *)arrayOfArrays {
  GREYFatalAssertWithMessage([arrayOfArrays count] > 0,
                             @"arrayOfArrays must contain at least one element.");
  NSUInteger firstArraySize = [arrayOfArrays[0] count];
  GREYFatalAssertWithMessage(index < firstArraySize,
                             @"index must be smaller than the size of the arrays.");

  NSMutableArray *output = [[NSMutableArray alloc] initWithCapacity:[arrayOfArrays count]];
  for (NSArray *array in arrayOfArrays) {
    GREYFatalAssertWithMessage([array count] == firstArraySize,
                               @"All arrays must be of the same size.");
    [output addObject:array[index]];
  }

  return output;
}

/**
 * Begins interaction with new touches starting at multiple @c points. Touch will be delivered to
 * the hit test view in @c window under point and will not end until @c endTouch is called.
 *
 * @param points    Multiple points where touches should start.
 * @param window    The window that contains the coordinates of the touch points.
 * @param immediate If @c YES, this method blocks until touch is delivered, otherwise the touch is
 *                  enqueued for delivery the next time runloop drains.
 * @param timeout   If @c immediate is YES, it specifies the length of time that the method will
 *                  wait.
 */
- (void)grey_beginTouchesAtPoints:(NSArray<NSValue *> *)points
                 relativeToWindow:(UIWindow *)window
                immediateDelivery:(BOOL)immediate
                          timeout:(NSTimeInterval)timeout
                          element:(id _Nullable)element {
  GREYFatalAssertWithMessage(!_touchInjector,
                             @"Cannot call this method more than once until endTouch is called.");

  _touchInjector = [[GREYTouchInjector alloc] initWithWindow:window];

  GREYTouchInfo *touchInfo = [[GREYTouchInfo alloc] initWithPoints:points
                                                             phase:UITouchPhaseBegan
                                   deliveryTimeDeltaSinceLastTouch:0
                                                           element:element];
  [_touchInjector enqueueTouchInfoForDelivery:touchInfo];

  if (immediate) {
    [_touchInjector waitUntilAllTouchesAreDeliveredWithTimeout:timeout];
  }
}

/**
 * Enqueues the next touch to be delivered.
 *
 * @param points    Multiple points at which the touches are to be made.
 * @param seconds   An interval to wait after the every last touch event.
 * @param immediate If @c YES, this method blocks until touches are delivered, otherwise it is
 *                  enqueued for delivery the next time runloop drains.
 * @param timeout   If @c immediate is YES, it specifies the length of time that the method will
 *                  wait.
 */
- (void)grey_continueTouchAtPoints:(NSArray<NSValue *> *)points
    afterTimeElapsedSinceLastTouchDelivery:(NSTimeInterval)seconds
                         immediateDelivery:(BOOL)immediate
                                   timeout:(NSTimeInterval)timeout
                                   element:(id _Nullable)element {
  GREYTouchInfo *touchInfo = [[GREYTouchInfo alloc] initWithPoints:points
                                                             phase:UITouchPhaseMoved
                                   deliveryTimeDeltaSinceLastTouch:seconds
                                                           element:element];
  [_touchInjector enqueueTouchInfoForDelivery:touchInfo];
  if (immediate) {
    [_touchInjector waitUntilAllTouchesAreDeliveredWithTimeout:timeout];
  }
}

/**
 * Enqueues the final touch in a touch sequence to be delivered.
 *
 * @param points  Multiple points at which the touches are to be made.
 * @param seconds An interval to wait after the every last touch event.
 * @param timeout The length of time that the method will wait.
 */
- (void)grey_endTouchesAtPoints:(NSArray<NSValue *> *)points
    timeElapsedSinceLastTouchDelivery:(NSTimeInterval)seconds
                              timeout:(NSTimeInterval)timeout
                              element:(id _Nullable)element {
  [self grey_endTouchesAtPoints:points
      timeElapsedSinceLastTouchDelivery:seconds
                                timeout:timeout
                                element:element
                  touchesWillEndHandler:nil];
}

/**
 * Enqueues the final touch in a touch sequence to be delivered, calling @c touchesWillEndHandler
 * (if non-nil) on the main thread immediately before it is delivered, after the @c seconds delay.
 * If the handler raises an exception, the final touch is still delivered.
 *
 * @param points                Multiple points at which the touches are to be made.
 * @param seconds               An interval to wait after the every last touch event.
 * @param timeout               The length of time that the method will wait.
 * @param touchesWillEndHandler If non-nil, called immediately before the final touch is delivered.
 *
 * @return The exception raised by @c touchesWillEndHandler, or @c nil if it did not raise one.
 */
- (NSException *)grey_endTouchesAtPoints:(NSArray<NSValue *> *)points
       timeElapsedSinceLastTouchDelivery:(NSTimeInterval)seconds
                                 timeout:(NSTimeInterval)timeout
                                 element:(id _Nullable)element
                   touchesWillEndHandler:(dispatch_block_t _Nullable)touchesWillEndHandler {
  GREYTouchInfo *touchInfo = [[GREYTouchInfo alloc] initWithPoints:points
                                                             phase:UITouchPhaseEnded
                                   deliveryTimeDeltaSinceLastTouch:seconds
                                                           element:element];
  [_touchInjector enqueueTouchInfoForDelivery:touchInfo];
  NSException *touchesWillEndException =
      [_touchInjector waitUntilAllTouchesAreDeliveredWithTimeout:timeout
                                               finalTouchHandler:touchesWillEndHandler];

  _touchInjector = nil;
  return touchesWillEndException;
}

@end

void GREYPerformMultipleTap(CGPoint location, UIWindow *window, NSUInteger tapCount,
                            NSTimeInterval timeout, id element) {
  GREYTouchInjector *touchInjector = [[GREYTouchInjector alloc] initWithWindow:window];
  NSArray<NSValue *> *touchPath = @[ [NSValue valueWithCGPoint:location] ];

  GREYTouchInfo *beginTouchInfo = [[GREYTouchInfo alloc] initWithPoints:touchPath
                                                           withTapCount:tapCount
                                                                  phase:UITouchPhaseBegan
                                        deliveryTimeDeltaSinceLastTouch:0
                                                                element:element];
  [touchInjector enqueueTouchInfoForDelivery:beginTouchInfo];

  GREYTouchInfo *endTouchInfo = [[GREYTouchInfo alloc] initWithPoints:touchPath
                                                         withTapCount:tapCount
                                                                phase:UITouchPhaseEnded
                                      deliveryTimeDeltaSinceLastTouch:0
                                                              element:element];
  [touchInjector enqueueTouchInfoForDelivery:endTouchInfo];
  [touchInjector waitUntilAllTouchesAreDeliveredWithTimeout:timeout];
}
