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


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Interface

/**
 * Utility to deliver user actions such as touches, taps, gestures and device rotation to the
 * application under test
 */
@interface GREYSyntheticEvents : NSObject

/**
 * Touch along a specified path in a @c CGPoint array.
 * This method blocks until all touches are delivered.
 *
 * @param touchPath An array of @c CGPoints. The first point in @c touchPath is the point where
                    touch begins, and the last point in @c touchPath is the final touch point
                    where touch ends. Points in @c touchPath must be in @c window coordinates.
 * @param window    The UIWindow that contains the points in the @c touchPath where
 *                  the touches are performed. Interaction will begin on the view inside
 *                  @c window which passes the hit-test for the first point in @c touchPath.
 * @param duration  The time interval over which to space the touches evenly. If 0, all
 *                  touches will be sent one after the other without any delay in-between them.
 * @param timeout   The length of time that the method should wait for the interaction to complete.
 */
+ (void)touchAlongPath:(NSArray *)touchPath
      relativeToWindow:(UIWindow *)window
           forDuration:(NSTimeInterval)duration
               timeout:(NSTimeInterval)timeout;

/**
 * Touch along a specified path in a @c CGPoint array.
 * This method blocks until all touches are delivered.
 *
 * @param touchPath An array of @c CGPoints. The first point in @c touchPath is the point where
                    touch begins, and the last point in @c touchPath is the final touch point
                    where touch ends. Points in @c touchPath must be in @c window coordinates.
 * @param window    The UIWindow that contains the points in the @c touchPath where
 *                  the touches are performed. Interaction will begin on the view inside
 *                  @c window which passes the hit-test for the first point in @c touchPath.
 * @param duration  The time interval over which to space the touches evenly. If 0, all
 *                  touches will be sent one after the other without any delay in-between them.
 * @param timeout   The length of time that the method should wait for the interaction to complete.
 * @param element   The touched element used to find the overriding UIResponder that will receive
 *                  the touch event if any for swiftUI iOS 18+. Optional.
 */
+ (void)touchAlongPath:(NSArray *)touchPath
      relativeToWindow:(UIWindow *)window
           forDuration:(NSTimeInterval)duration
               timeout:(NSTimeInterval)timeout
               element:(id _Nullable)element;

/**
 * Touch along a specified path in a @c CGPoint array, invoking optional handlers while the touch
 * is down. This method blocks until all touches are delivered.
 *
 * Each handler is invoked synchronously on the calling thread, and touch delivery pauses until it
 * returns. If a handler is a block created in the test process, EarlGrey invokes it in the test
 * process over eDistantObject. Handlers should return quickly and must not perform EarlGrey
 * interactions, because the interaction that invoked them is still in progress. If a handler
 * raises an exception, the rest of the gesture still runs, including the other handler, and the
 * exception propagates after the touch is lifted. If both handlers raise, the first exception
 * propagates and the second is logged.
 *
 * @param touchPath             An array of @c CGPoints. The first point in @c touchPath is the
 *                              point where touch begins, and the last point in @c touchPath is the
 *                              final touch point where touch ends. Points in @c touchPath must be
 *                              in @c window coordinates.
 * @param window                The UIWindow that contains the points in the @c touchPath where
 *                              the touches are performed. Interaction will begin on the view
 *                              inside @c window which passes the hit-test for the first point in
 *                              @c touchPath.
 * @param duration              The time interval over which to space the touches evenly. If 0,
 *                              all touches will be sent one after the other without any delay
 *                              in-between them.
 * @param timeout               The length of time that the method should wait for each batch of
 *                              touches to be delivered.
 * @param element               The touched element used to find the overriding UIResponder that
 *                              will receive the touch event if any for swiftUI iOS 18+. Optional.
 * @param touchesBeganHandler   If non-nil, called after the touch-began event is delivered and
 *                              before any touch-moved events are delivered.
 * @param touchesWillEndHandler If non-nil, called after the last touch-moved event (if any) is
 *                              delivered and before the touch-ended event is delivered.
 */
+ (void)touchAlongPath:(NSArray *)touchPath
         relativeToWindow:(UIWindow *)window
              forDuration:(NSTimeInterval)duration
                  timeout:(NSTimeInterval)timeout
                  element:(id _Nullable)element
      touchesBeganHandler:(dispatch_block_t _Nullable)touchesBeganHandler
    touchesWillEndHandler:(dispatch_block_t _Nullable)touchesWillEndHandler;

/**
 * Injects a multi touch sequence specified by the array of @c touchPaths in the specified @c
 * duration.
 * Note that a single touch path is an array of CGPoint structs identifying the path taken by it
 * relative to the specified @c window.
 *
 * @param touchPaths An array of @c touchpaths each of which are array of @c CGPoints.
 *                   The first point in @c touchPath is the point where touch begins, and the last
 *                   point in @c touchPath is the final touch point where touch ends. Points in @c
 *                   touchPath Points in @c touchPath must be in @c window coordinates.
 * @param window     The UIWindow that contains the points in the @c touchPath where
 *                   the touches are performed. Interaction will begin on the view inside
 *                   @c window which passes the hit-test for the first point in @c touchPath.
 * @param duration   The time interval over which to space the touches evenly. If 0, all
 *                   touches will be sent one after the other without any delay in-between them.
 * @param timeout    The length of time that the method should wait for the interaction to complete.
 */
+ (void)touchAlongMultiplePaths:(NSArray *)touchPaths
               relativeToWindow:(UIWindow *)window
                    forDuration:(NSTimeInterval)duration
                        timeout:(NSTimeInterval)timeout;

/**
 * Injects a multi touch sequence specified by the array of @c touchPaths in the specified @c
 * duration.
 * Note that a single touch path is an array of CGPoint structs identifying the path taken by it
 * relative to the specified @c window.
 *
 * @param touchPaths An array of @c touchpaths each of which are array of @c CGPoints.
 *                   The first point in @c touchPath is the point where touch begins, and the last
 *                   point in @c touchPath is the final touch point where touch ends. Points in @c
 *                   touchPath Points in @c touchPath must be in @c window coordinates.
 * @param window     The UIWindow that contains the points in the @c touchPath where
 *                   the touches are performed. Interaction will begin on the view inside
 *                   @c window which passes the hit-test for the first point in @c touchPath.
 * @param duration   The time interval over which to space the touches evenly. If 0, all
 *                   touches will be sent one after the other without any delay in-between them.
 * @param timeout    The length of time that the method should wait for the interaction to complete.
 * @param element    The touched element used to find the overriding UIResponder that will
 *                   receive the touch event if any for swiftUI iOS 18+. Optional.
 */
+ (void)touchAlongMultiplePaths:(NSArray *)touchPaths
               relativeToWindow:(UIWindow *)window
                    forDuration:(NSTimeInterval)duration
                        timeout:(NSTimeInterval)timeout
                        element:(id _Nullable)element;

/**
 * Shakes the device.
 */
+ (void)shakeDevice;

/**
 * Begins interaction with a new touch starting at a specified point within a specified
 * window's coordinates.
 *
 * @param point     The point where the touch is to start.
 * @param window    The window that contains the coordinates of the touch points.
 * @param immediate If @c YES, this method blocks until touch is delivered, otherwise the touch is
 *                  enqueued for delivery the next time runloop drains.
 * @param timeout   The length of time that the method should wait for the interaction to complete.
 */
- (void)beginTouchAtPoint:(CGPoint)point
         relativeToWindow:(UIWindow *)window
        immediateDelivery:(BOOL)immediate
                  timeout:(NSTimeInterval)timeout;

/**
 * Begins interaction with a new touch starting at a specified point within a specified
 * window's coordinates.
 *
 * @param point     The point where the touch is to start.
 * @param window    The window that contains the coordinates of the touch points.
 * @param immediate If @c YES, this method blocks until touch is delivered, otherwise the touch is
 *                  enqueued for delivery the next time runloop drains.
 * @param timeout   The length of time that the method should wait for the interaction to complete.
 * @param element   The touched element used to find the overriding UIResponder that will receive
 *                  the touch event if any for swiftUI iOS 18+. Optional.
 */
- (void)beginTouchAtPoint:(CGPoint)point
         relativeToWindow:(UIWindow *)window
        immediateDelivery:(BOOL)immediate
                  timeout:(NSTimeInterval)timeout
                  element:(id _Nullable)element;

/**
 * Continues the current interaction by moving touch to a new point. Providing the same point
 * in consecutive calls is interpreted as stationary touches. While delivering these touch points,
 * they may be buffered and during delivery if there are multiple stale touch points that
 * are time sensitive some of them may be dropped.
 *
 * @param point     The point to move the touch to.
 * @param immediate If @c YES, this method blocks until touch is delivered, otherwise the touch is
 *                  enqueued for delivery the next time runloop drains.
 * @param timeout   The length of time that the method should wait for the interaction to complete.
 */
- (void)continueTouchAtPoint:(CGPoint)point
           immediateDelivery:(BOOL)immediate
                     timeout:(NSTimeInterval)timeout;

/**
 * Continues the current interaction by moving touch to a new point. Providing the same point
 * in consecutive calls is interpreted as stationary touches. While delivering these touch points,
 * they may be buffered and during delivery if there are multiple stale touch points that
 * are time sensitive some of them may be dropped.
 *
 * @param point     The point to move the touch to.
 * @param immediate If @c YES, this method blocks until touch is delivered, otherwise the touch is
 *                  enqueued for delivery the next time runloop drains.
 * @param timeout   The length of time that the method should wait for the interaction to complete.
 * @param element   The touched element used to find the overriding UIResponder that will receive
 *                  the touch event if any for swiftUI iOS 18+. Optional.
 */
- (void)continueTouchAtPoint:(CGPoint)point
           immediateDelivery:(BOOL)immediate
                     timeout:(NSTimeInterval)timeout
                     element:(id _Nullable)element;

/**
 * Ends interaction started by GREYSyntheticEvents::beginTouchAtPoint:relativeToWindow.
 * This method will block until all the touches since the beginning of the interaction have been
 * delivered.
 *
 * @param timeout The length of time that the method should wait for the interaction to complete.
 */
- (void)endTouchWithTimeout:(NSTimeInterval)timeout;

/**
 * Ends interaction started by GREYSyntheticEvents::beginTouchAtPoint:relativeToWindow.
 * This method will block until all the touches since the beginning of the interaction have been
 * delivered.
 *
 * @param timeout The length of time that the method should wait for the interaction to complete.
 * @param element The touched element used to find the overriding UIResponder that will receive
 *                the touch event if any for swiftUI iOS 18+. Optional.
 */
- (void)endTouchWithTimeout:(NSTimeInterval)timeout element:(id _Nullable)element;

@end

/**
 * Perform a tap interaction with tap count being indexed.
 *
 * @param location The location to be tapped, relative to the window being tapped.
 * @param window   The UIWindow that contains the points in the @c location where
 *                 the tap is performed. Interaction will begin on the view inside
 *                 @c window which passes the hit-test.
 * @param tapCount The number of taps that occurred for this touch within a predefined period of
 *                 time. It corresponding to the UITouch's tapCount and gesture recognizers use
 *                 it to detect single-tapped, double-tapped, and multi-tapped.
 * @param timeout  The length of time that the method should wait for the interaction to complete.
 * @param element  The touched element used to find the overriding UIResponder that will receive
 *                 the touch event if any for swiftUI iOS 18+. Optional.
 */
void GREYPerformMultipleTap(CGPoint location, UIWindow *window, NSUInteger tapCount,
                            NSTimeInterval timeout, id element);

NS_ASSUME_NONNULL_END
