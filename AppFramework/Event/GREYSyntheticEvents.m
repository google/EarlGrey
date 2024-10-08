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
                        timeout:timeout];
}

+ (void)touchAlongMultiplePaths:(NSArray *)touchPaths
               relativeToWindow:(UIWindow *)window
                    forDuration:(NSTimeInterval)duration
                        timeout:(NSTimeInterval)timeout {
  GREYThrowOnFailedCondition(touchPaths.count >= 1);
  GREYThrowOnFailedCondition(duration >= 0);

  NSUInteger firstTouchPathSize = [touchPaths[0] count];
  GREYSyntheticEvents *eventGenerator = [[GREYSyntheticEvents alloc] init];

  // Inject "begin" event for the first points of each path.
  [eventGenerator grey_beginTouchesAtPoints:[self grey_objectsAtIndex:0 ofArrays:touchPaths]
                           relativeToWindow:window
                          immediateDelivery:NO
                                    timeout:timeout];

  // If the paths have a single point, then just inject an "end" event with the delay being the
  // provided duration. Otherwise, insert multiple "continue" events with delays being a fraction
  // of the duration, then inject an "end" event with no delay.
  if (firstTouchPathSize == 1) {
    [eventGenerator grey_endTouchesAtPoints:[self grey_objectsAtIndex:firstTouchPathSize - 1
                                                             ofArrays:touchPaths]
          timeElapsedSinceLastTouchDelivery:duration
                                    timeout:timeout];
  } else {
    // Start injecting "continue touch" events, starting from the second position on the touch
    // path as it was already injected as a "begin touch" event.
    CFTimeInterval delayBetweenEachEvent = duration / (double)(firstTouchPathSize - 1);

    for (NSUInteger i = 1; i < firstTouchPathSize; i++) {
      [eventGenerator grey_continueTouchAtPoints:[self grey_objectsAtIndex:i ofArrays:touchPaths]
          afterTimeElapsedSinceLastTouchDelivery:delayBetweenEachEvent
                               immediateDelivery:NO
                                         timeout:timeout];
    }

    [eventGenerator grey_endTouchesAtPoints:[self grey_objectsAtIndex:firstTouchPathSize - 1
                                                             ofArrays:touchPaths]
          timeElapsedSinceLastTouchDelivery:0
                                    timeout:timeout];
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
  _lastInjectedTouchPoint = [NSValue valueWithCGPoint:point];
  [self grey_beginTouchesAtPoints:@[ _lastInjectedTouchPoint ]
                 relativeToWindow:window
                immediateDelivery:immediate
                          timeout:timeout];
}

- (void)continueTouchAtPoint:(CGPoint)point
           immediateDelivery:(BOOL)immediate
                     timeout:(NSTimeInterval)timeout {
  _lastInjectedTouchPoint = [NSValue valueWithCGPoint:point];
  [self grey_continueTouchAtPoints:@[ _lastInjectedTouchPoint ]
      afterTimeElapsedSinceLastTouchDelivery:kMinimumDelayBetweenTouchPathEvents
                           immediateDelivery:immediate
                                     timeout:timeout];
}

- (void)endTouchWithTimeout:(NSTimeInterval)timeout {
  [self grey_endTouchesAtPoints:@[ _lastInjectedTouchPoint ]
      timeElapsedSinceLastTouchDelivery:kMinimumDelayBetweenTouchPathEvents
                                timeout:timeout];
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
                          timeout:(NSTimeInterval)timeout {
  GREYFatalAssertWithMessage(!_touchInjector,
                             @"Cannot call this method more than once until endTouch is called.");

  _touchInjector = [[GREYTouchInjector alloc] initWithWindow:window];
  GREYTouchInfo *touchInfo = [[GREYTouchInfo alloc] initWithPoints:points
                                                             phase:UITouchPhaseBegan
                                   deliveryTimeDeltaSinceLastTouch:0];
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
                                   timeout:(NSTimeInterval)timeout {
  GREYTouchInfo *touchInfo = [[GREYTouchInfo alloc] initWithPoints:points
                                                             phase:UITouchPhaseMoved
                                   deliveryTimeDeltaSinceLastTouch:seconds];
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
                              timeout:(NSTimeInterval)timeout {
  GREYTouchInfo *touchInfo = [[GREYTouchInfo alloc] initWithPoints:points
                                                             phase:UITouchPhaseEnded
                                   deliveryTimeDeltaSinceLastTouch:seconds];
  [_touchInjector enqueueTouchInfoForDelivery:touchInfo];
  [_touchInjector waitUntilAllTouchesAreDeliveredWithTimeout:timeout];

  _touchInjector = nil;
}

@end

void GREYPerformMultipleTap(CGPoint location, UIWindow *window, NSUInteger tapCount,
                            NSTimeInterval timeout, UIResponder *responder) {
  GREYTouchInjector *touchInjector = [[GREYTouchInjector alloc] initWithWindow:window];
  NSArray<NSValue *> *touchPath = @[ [NSValue valueWithCGPoint:location] ];

  GREYTouchInfo *beginTouchInfo = [[GREYTouchInfo alloc] initWithPoints:touchPath
                                                           withTapCount:tapCount
                                                                  phase:UITouchPhaseBegan
                                        deliveryTimeDeltaSinceLastTouch:0
                                                              responder:responder];
  [touchInjector enqueueTouchInfoForDelivery:beginTouchInfo];

  GREYTouchInfo *endTouchInfo = [[GREYTouchInfo alloc] initWithPoints:touchPath
                                                         withTapCount:tapCount
                                                                phase:UITouchPhaseEnded
                                      deliveryTimeDeltaSinceLastTouch:0
                                                            responder:responder];
  [touchInjector enqueueTouchInfoForDelivery:endTouchInfo];
  [touchInjector waitUntilAllTouchesAreDeliveredWithTimeout:timeout];
}
