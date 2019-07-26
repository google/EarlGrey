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

/**
 *  @file GREYAppleInternals.h
 *  @brief Exposes interfaces, structs and methods that are otherwise private.
 */

#import <UIKit/UIKit.h>

@interface UIWindow (GREYExposed)
- (id)firstResponder;
@end

@interface UIViewController (GREYExposed)
- (void)viewWillMoveToWindow:(id)window;
- (void)viewDidMoveToWindow:(id)window shouldAppearOrDisappear:(BOOL)arg;
@end

/**
 *  A private class that represents backboard services accelerometer.
 */
@interface BKSAccelerometer : NSObject
/**
 *  Enable or disable accelerometer events.
 */
@property(nonatomic) BOOL accelerometerEventsEnabled;
@end

/**
 *  A private class that represents motion related events. This is sent to UIApplication whenever a
 *  motion occurs.
 */
@interface UIMotionEvent : NSObject {
  // The motion accelerometer of the event.
  BKSAccelerometer *_motionAccelerometer;
}
@end

#if defined(__IPHONE_13_0)

@interface UIStatusBarManager (GREYExposed)
/**
 *  A private method to create a single status bar for the window.
 */
- (id)createLocalStatusBar;
@end

#endif

@interface UIApplication (GREYExposed)
/**
 *  @return @c YES if a system alert is being shown, @c NO otherwise.
 */
- (BOOL)_isSpringBoardShowingAnAlert;
/**
 *  @return The UIWindow for the status bar.
 */
- (UIWindow *)statusBarWindow;
/**
 *  Changes the main runloop to run in the specified mode, pushing it to the top of the stack of
 *  current modes.
 */
- (void)pushRunLoopMode:(NSString *)mode;
/**
 *  Changes the main runloop to run in the specified mode, pushing it to the top of the stack of
 *  current modes.
 */
- (void)pushRunLoopMode:(NSString *)mode requester:(id)requester;
/**
 *  Pops topmost mode from the runloop mode stack.
 */
- (void)popRunLoopMode:(NSString *)mode;
/**
 *  Pops topmost mode from the runloop mode stack.
 */
- (void)popRunLoopMode:(NSString *)mode requester:(id)requester;
/**
 *  @return The shared UIMotionEvent object of the application, used to force enable motion
 *          accelerometer events.
 */
- (UIMotionEvent *)_motionEvent;

/**
 *  Sends a motion began event for the specified subtype.
 */
- (void)_sendMotionBegan:(UIEventSubtype)subtype;

/**
 *  Sends a motion ended event for the specified subtype.
 */
- (void)_sendMotionEnded:(UIEventSubtype)subtype;
@end

@interface UIScrollView (GREYExposed)
/**
 *  Called when user finishes scrolling the content. @c deceleration is @c YES if scrolling movement
 *  will continue, but decelerate, after user stopped dragging the content. If @c deceleration is
 *  @c NO, scrolling stops immediately.
 *
 *  @param deceleration Indicating if scrollview was experiencing deceleration.
 */
- (void)_scrollViewDidEndDraggingWithDeceleration:(BOOL)deceleration;

/**
 *  Called when user is about to begin scrolling the content.
 */
- (void)_scrollViewWillBeginDragging;

/**
 *  Called when scrolling of content has finished, if content continued scrolling with deceleration
 *  after user stopped dragging it. @c notify determines whether UIScrollViewDelegate will be
 *  notified that scrolling has finished.
 *
 *  @param notify An indicator specifying if scrolling has finished.
 */
- (void)_stopScrollDecelerationNotify:(BOOL)notify;
@end

@interface UIDevice (GREYExposed)
- (void)setOrientation:(UIDeviceOrientation)orientation animated:(BOOL)animated;
@end

@interface UIKeyboardTaskQueue
/**
 *  Completes all pending or ongoing tasks in the task queue before returning. Must be called from
 *  the main thread.
 */
- (void)waitUntilAllTasksAreFinished;
@end

@interface UIKeyboardImpl
/**
 *  @return Shared instance of UIKeyboardImpl. It may be different from the active instance.
 */
+ (instancetype)sharedInstance;

/**
 *  @return The Active instance of UIKeyboardImpl, if one exists; otherwise returns @c nil. Active
 *          instance could exist even if the keyboard is not shown on the screen.
 */
+ (instancetype)activeInstance;

/**
 *  @return The current keyboard layout view, which contains accessibility elements for keyboard
 *          keys that are shown on the keyboard.
 */
- (UIView *)_layout;

/**
 *  @return The string shown on the return key on the keyboard.
 */
- (NSString *)returnKeyDisplayName;

/**
 *  @return The task queue keyboard is using to manage asynchronous tasks.
 */
- (UIKeyboardTaskQueue *)taskQueue;

/**
 *  Automatically hides the software keyboard if @c enabled is set to @c YES and hardware keyboard
 *  is available. Setting @c enabled to @c NO will always show software keyboard. This setting is
 *  global and applies to all instances of UIKeyboardImpl.
 *
 *  @param enabled A boolean that indicates automatic minimization (hiding) of the keyboard.
 */
- (void)setAutomaticMinimizationEnabled:(BOOL)enabled;

/**
 *  @return The delegate that the UIKeyboard is typing on.
 */
- (id)delegate;

/**
 *  Sets the current UIKeyboard's delegate.
 *
 *  @param delegate The element to set the UIKeyboard's delegate to.
 */
- (void)setDelegate:(id)delegate;
/**
 *  A method to hide the keyboard without resigning the first responder. This is used only
 *  in iOS 8.1 where we found that turning off the autocorrection type on the first responder
 *  using setAutomaticMinimizationEnabled: without toggling the keyboard caused keyboard touches
 *  to be ignored.
 */
- (void)hideKeyboard;

/**
 *  A method to show the keyboard without resigning the first responder. This is used only
 *  in iOS 8.1 where we found that turning off the autocorrection type on the first responder
 *  using setAutomaticMinimizationEnabled: without toggling the keyboard caused keyboard touches
 *  to be ignored.
 */
- (void)showKeyboard;
@end

/**
 * Text Input preferences controller to modify the keyboard preferences for iOS 8+.
 */
@interface TIPreferencesController : NSObject

/** Whether the autocorrection is enabled. */
@property BOOL autocorrectionEnabled;

/** Whether the predication is enabled. */
@property BOOL predictionEnabled;

/** The shared singleton instance. */
+ (instancetype)sharedPreferencesController;

/** Synchronize the change to save it on disk. */
- (void)synchronizePreferences;

/** Modify the preference @c value by @c key. */
- (void)setValue:(NSValue *)value forPreferenceKey:(NSString *)key;
@end

/**
 *  Used for enabling accessibility on simulator and device.
 */
@interface AXBackBoardServer

/**
 *  Returns backboard server instance.
 */
+ (id)server;

/**
 *  Sets preference with @c key to @c value and raises @c notification.
 */
- (void)setAccessibilityPreferenceAsMobile:(CFStringRef)key
                                     value:(CFBooleanRef)value
                              notification:(CFStringRef)notification;

@end

@interface UIAccessibilityTextFieldElement

/**
 *  @return The UITextField that contains the accessibility text field element.
 */
- (UITextField *)textField;

@end
