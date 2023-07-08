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
 * @file GREYAppleInternals.h
 * @brief Exposes interfaces, structs and methods that are otherwise private.
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
 * A private class that represents motion related events. This is sent to UIApplication whenever a
 * motion occurs.
 */
@interface UIMotionEvent : UIEvent

/**
 * Modify the _shakeState ivar inside motion event.
 *
 * shakeState Set as true for 1 being passed. All other values set to false.
 */
- (void)setShakeState:(int)shakeState;

/**
 * Sets the subtype for the motion event.
 *
 * eventSubType The UIEventSubtype for the motion event.
 */
- (void)_setSubtype:(int)eventSubType;
@end

#if defined(__IPHONE_13_0)

@interface UIStatusBarManager (GREYExposed)
/**
 * A private method to create a single status bar for the window.
 */
- (id)createLocalStatusBar;
@end

#endif

@interface UIApplication (GREYExposed)
/**
 * @return @c YES if a system alert is being shown, @c NO otherwise.
 */
- (BOOL)_isSpringBoardShowingAnAlert;
/**
 * @return The UIWindow for the status bar.
 */
- (UIWindow *)statusBarWindow;
/**
 * Changes the main runloop to run in the specified mode, pushing it to the top of the stack of
 * current modes.
 */
- (void)pushRunLoopMode:(NSString *)mode requester:(id)requester;
/**
 * Pops topmost mode from the runloop mode stack.
 */
- (void)popRunLoopMode:(NSString *)mode requester:(id)requester;
/**
 * Pushes the specified runloop mode for the particular @c requester and @c reason onto the runloop
 * stack.
 *
 * @param mode      The CFRunloopMode being added to the top of the runloop stack.
 * @param requester The object that is pushing the runloop mode.
 * @param reason    An NSString specifying the reason for the mode change.
 */
- (void)_pushRunLoopMode:(NSString *)mode requester:(id)requester reason:(NSString *)reason;
/**
 * Pops the topmost runloop mode from the top of the runloop stack.
 *
 * @param mode      The CFRunloopMode being added to the top of the runloop stack.
 * @param requester The object that is pushing the runloop mode.
 * @param reason    An NSString specifying the reason for the mode change.
 */
- (void)_popRunLoopMode:(NSString *)mode requester:(id)requester reason:(NSString *)reason;
/**
 * @return The shared UIMotionEvent object of the application, used to force enable motion
 *         accelerometer events.
 */
- (UIMotionEvent *)_motionEvent;
@end

@interface UIScrollView (GREYExposed)
/**
 * Called when user finishes scrolling the content. @c deceleration is @c YES if scrolling movement
 * will continue, but decelerate, after user stopped dragging the content. If @c deceleration is
 * @c NO, scrolling stops immediately.
 *
 * @param deceleration Indicating if scrollview was experiencing deceleration.
 */
- (void)_scrollViewDidEndDraggingWithDeceleration:(BOOL)deceleration;

/**
 * Called when user is about to begin scrolling the content.
 */
- (void)_scrollViewWillBeginDragging;

/**
 * Called when scrolling of content has finished, if content continued scrolling with deceleration
 * after user stopped dragging it. @c notify determines whether UIScrollViewDelegate will be
 * notified that scrolling has finished.
 *
 * @param notify An indicator specifying if scrolling has finished.
 */
- (void)_stopScrollDecelerationNotify:(BOOL)notify;
@end

@interface UIDevice (GREYExposed)
#if TARGET_OS_IOS
- (void)setOrientation:(UIDeviceOrientation)orientation animated:(BOOL)animated;
#endif  // TARGET_OS_IOS
@end

@interface UIKeyboardTaskQueue
/**
 * Completes all pending or ongoing tasks in the task queue before returning. Must be called from
 * the main thread.
 */
- (void)waitUntilAllTasksAreFinished;
@end

@interface UIKeyboardImpl
/**
 * @return Shared instance of UIKeyboardImpl. It may be different from the active instance.
 */
+ (instancetype)sharedInstance;

/**
 * @return The Active instance of UIKeyboardImpl, if one exists; otherwise returns @c nil. Active
 *         instance could exist even if the keyboard is not shown on the screen.
 */
+ (instancetype)activeInstance;

/**
 * @return The current keyboard layout view, which contains accessibility elements for keyboard
 *         keys that are shown on the keyboard.
 */
- (UIView *)_layout;

/**
 * @return The string shown on the return key on the keyboard.
 */
- (NSString *)returnKeyDisplayName;

/**
 * @return The task queue keyboard is using to manage asynchronous tasks.
 */
- (UIKeyboardTaskQueue *)taskQueue;

/**
 * Automatically hides the software keyboard if @c enabled is set to @c YES and hardware keyboard
 * is available. Setting @c enabled to @c NO will always show software keyboard. This setting is
 * global and applies to all instances of UIKeyboardImpl.
 *
 * @param enabled A BOOL that indicates automatic minimization (hiding) of the keyboard.
 */
- (void)setAutomaticMinimizationEnabled:(BOOL)enabled;

/**
 * @return The delegate that the UIKeyboard is typing on.
 */
- (id)delegate;

/**
 * Sets the current UIKeyboard's delegate.
 *
 * @param delegate The element to set the UIKeyboard's delegate to.
 */
- (void)setDelegate:(id)delegate;
/**
 * A method to hide the keyboard without resigning the first responder. This is used only
 * in iOS 8.1 where we found that turning off the autocorrection type on the first responder
 * using setAutomaticMinimizationEnabled: without toggling the keyboard caused keyboard touches
 * to be ignored.
 */
- (void)hideKeyboard;

/**
 * A method to show the keyboard without resigning the first responder. This is used only
 * in iOS 8.1 where we found that turning off the autocorrection type on the first responder
 * using setAutomaticMinimizationEnabled: without toggling the keyboard caused keyboard touches
 * to be ignored.
 */
- (void)showKeyboard;
@end

@interface UIAccessibilityTextFieldElement

/**
 * @return The UITextField that contains the accessibility text field element.
 */
- (UITextField *)textField;

@end

/**
 * The selection view for a view for text input - textfields, textviews, keyboard-related objects,
 * webview text input etc.
 */
@interface UITextSelectionView

/**
 * Enable or disable the animation for the caret blinking started after the text is input.
 *
 * @param enabled A BOOL specifying the behavior of the caret's blinking animation.
 *
 * @return Was the animation enabled or disabled.
 */
- (BOOL)_setCaretBlinkAnimationEnabled:(BOOL)enabled;

/**
 * Pre-iOS 14 version of UITextSelectionView::_setCaretBlinkAnimationEnabled:.
 */
- (void)setCaretBlinks:(BOOL)enabled;

@end

/** An internal class similar to UITextSelectionView that is iOS 17+ */
@interface UITextInteractionAssistant

/**
 * A method that is called once a UITextInput conforming view is tapped. This only sets the
 * animation's behavior.
 *
 * @param enabled A BOOL specifying the behavior of the cursor's blinking animation.
 */
- (void)setCursorBlinks:(BOOL)enabled;

/**
 * A method that is called only when a UITextInput disappears. Is used to turn it off.
 *
 * @param enabled A BOOL specifying if the cursor should be visible or not.
 */
- (void)setCursorVisible:(BOOL)enabled;

@end

/**
 * iOS 17+ Utils needed for getting the keyboard.
 */
@interface _UIRemoteKeyboards
/**
 * @return a UIScene that points to the keyboard screen. Will be nil if no keyboard is present.
 *
 * @param screen The UIScreen for which we get the keyboard window. Use the main application screen
 *               here.
 * @param create This will create a new keyboard screen if needed. In general, pass @c NO.
 */
+ (id)keyboardWindowSceneForScreen:(id)screen create:(BOOL)create;
@end

/**
 * UIScene category for getting keyboard information.
 */
@interface UIScene (GREYExposed)
/**
 * @return An NSArray that points to all windows in a scene. When -[UIScene::windows] is nil, this
 *         can be used. There is also _visibleWindows that seems to have an implicit visibility
 *         check.
 */
- (NSArray *)_allWindows;
@end

/**
 * Simplified block ABI for obtaining the description of a block.
 * Source: https://clang.llvm.org/docs/Block-ABI-Apple.html#id2
 */
typedef struct BlockHeader {
  void *isa;
  int flags;
  int reserved;
  void (*invoke)(void);  // NO_LINT
} BlockHeader;

#if !(TARGET_IPHONE_SIMULATOR)
/**
 * Text Input preferences controller to modify the keyboard preferences on device for iOS 8+.
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
#endif
