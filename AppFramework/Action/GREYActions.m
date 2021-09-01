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

#import "GREYActions.h"

#if TARGET_OS_IOS
#import <WebKit/WebKit.h>
#endif  // TARGET_OS_IOS
#include <mach/mach_time.h>

#import "GREYAction.h"
#import "GREYActionBlock+Private.h"
#import "GREYActionBlock.h"
#import "GREYChangeStepperAction.h"
#import "GREYMultiFingerSwipeAction.h"
#import "GREYPickerAction.h"
#import "GREYPinchAction.h"
#import "GREYScrollAction.h"
#import "GREYScrollToContentEdgeAction.h"
#import "GREYSlideAction.h"
#import "GREYSwipeAction.h"
#import "GREYTapAction.h"
#import "UISwitch+GREYApp.h"
#import "GREYAppError.h"
#import "GREYFailureScreenshotter.h"
#import "GREYKeyboard.h"
#import "GREYAllOf.h"
#import "GREYAnyOf.h"
#import "GREYMatchers.h"
#import "GREYSyncAPI.h"
#import "NSObject+GREYCommon.h"
#import "GREYThrowDefines.h"
#import "GREYConfigKey.h"
#import "GREYConfiguration.h"
#import "GREYError.h"
#import "GREYErrorConstants.h"
#import "GREYAppleInternals.h"
#import "GREYConstants.h"
#import "GREYDefines.h"
#import "GREYDiagnosable.h"
#import "GREYMatcher.h"
#import "GREYElementHierarchy.h"
#import "GREYScreenshotter.h"
#import "EDORemoteVariable.h"

static Class gAccessibilityTextFieldElementClass;
static SEL gTextSelector;
static SEL gBeginningOfDocumentSelector;
static Protocol *gTextInputProtocol;

@implementation GREYActions

+ (void)initialize {
  if (self == [GREYActions self]) {
    gAccessibilityTextFieldElementClass = NSClassFromString(kTextFieldAXElementClassName);
    gTextSelector = @selector(text);
    gBeginningOfDocumentSelector = @selector(beginningOfDocument);
    gTextInputProtocol = @protocol(UITextInput);
  }
}

+ (id<GREYAction>)actionForSwipeFastInDirection:(GREYDirection)direction {
  return [[GREYSwipeAction alloc] initWithDirection:direction duration:kGREYSwipeFastDuration];
}

+ (id<GREYAction>)actionForSwipeSlowInDirection:(GREYDirection)direction {
  return [[GREYSwipeAction alloc] initWithDirection:direction duration:kGREYSwipeSlowDuration];
}

+ (id<GREYAction>)actionForSwipeFastInDirection:(GREYDirection)direction
                         xOriginStartPercentage:(CGFloat)xOriginStartPercentage
                         yOriginStartPercentage:(CGFloat)yOriginStartPercentage {
  return [[GREYSwipeAction alloc]
      initWithDirection:direction
               duration:kGREYSwipeFastDuration
          startPercents:CGPointMake(xOriginStartPercentage, yOriginStartPercentage)];
}

+ (id<GREYAction>)actionForSwipeSlowInDirection:(GREYDirection)direction
                         xOriginStartPercentage:(CGFloat)xOriginStartPercentage
                         yOriginStartPercentage:(CGFloat)yOriginStartPercentage {
  return [[GREYSwipeAction alloc]
      initWithDirection:direction
               duration:kGREYSwipeSlowDuration
          startPercents:CGPointMake(xOriginStartPercentage, yOriginStartPercentage)];
}

+ (id<GREYAction>)actionForMultiFingerSwipeSlowInDirection:(GREYDirection)direction
                                           numberOfFingers:(NSUInteger)numberOfFingers {
  return [[GREYMultiFingerSwipeAction alloc] initWithDirection:direction
                                                      duration:kGREYSwipeSlowDuration
                                               numberOfFingers:numberOfFingers];
}

+ (id<GREYAction>)actionForMultiFingerSwipeFastInDirection:(GREYDirection)direction
                                           numberOfFingers:(NSUInteger)numberOfFingers {
  return [[GREYMultiFingerSwipeAction alloc] initWithDirection:direction
                                                      duration:kGREYSwipeFastDuration
                                               numberOfFingers:numberOfFingers];
}

+ (id<GREYAction>)actionForMultiFingerSwipeSlowInDirection:(GREYDirection)direction
                                           numberOfFingers:(NSUInteger)numberOfFingers
                                    xOriginStartPercentage:(CGFloat)xOriginStartPercentage
                                    yOriginStartPercentage:(CGFloat)yOriginStartPercentage {
  return [[GREYMultiFingerSwipeAction alloc]
      initWithDirection:direction
               duration:kGREYSwipeSlowDuration
        numberOfFingers:numberOfFingers
          startPercents:CGPointMake(xOriginStartPercentage, yOriginStartPercentage)];
}

+ (id<GREYAction>)actionForMultiFingerSwipeFastInDirection:(GREYDirection)direction
                                           numberOfFingers:(NSUInteger)numberOfFingers
                                    xOriginStartPercentage:(CGFloat)xOriginStartPercentage
                                    yOriginStartPercentage:(CGFloat)yOriginStartPercentage {
  return [[GREYMultiFingerSwipeAction alloc]
      initWithDirection:direction
               duration:kGREYSwipeFastDuration
        numberOfFingers:numberOfFingers
          startPercents:CGPointMake(xOriginStartPercentage, yOriginStartPercentage)];
}

+ (id<GREYAction>)actionForPinchFastInDirection:(GREYPinchDirection)pinchDirection
                                      withAngle:(double)angle {
  return [[GREYPinchAction alloc] initWithDirection:pinchDirection
                                           duration:kGREYPinchFastDuration
                                         pinchAngle:angle];
}

+ (id<GREYAction>)actionForPinchSlowInDirection:(GREYPinchDirection)pinchDirection
                                      withAngle:(double)angle {
  return [[GREYPinchAction alloc] initWithDirection:pinchDirection
                                           duration:kGREYPinchSlowDuration
                                         pinchAngle:angle];
}

+ (id<GREYAction>)actionForMoveSliderToValue:(float)value {
#if TARGET_OS_IOS
  id<GREYMatcher> classConstraint = [GREYMatchers matcherForKindOfClass:[UISlider class]];
  return [[GREYSlideAction alloc] initWithSliderValue:value classConstraint:classConstraint];
#else
  return [[GREYSlideAction alloc] initWithSliderValue:value classConstraint:nil];
#endif  // TARGET_OS_IOS
}

+ (id<GREYAction>)actionForSetStepperValue:(double)value {
  return [[GREYChangeStepperAction alloc] initWithValue:value];
}

+ (id<GREYAction>)actionForTap {
  return [[GREYTapAction alloc] initWithType:kGREYTapTypeShort];
}

+ (id<GREYAction>)actionForTapAtPoint:(CGPoint)point {
  return [[GREYTapAction alloc] initWithType:kGREYTapTypeShort numberOfTaps:1 location:point];
}

+ (id<GREYAction>)actionForLongPress {
  return [GREYActions actionForLongPressWithDuration:kGREYLongPressDefaultDuration];
}

+ (id<GREYAction>)actionForLongPressWithDuration:(CFTimeInterval)duration {
  return [[GREYTapAction alloc] initLongPressWithDuration:duration];
}

+ (id<GREYAction>)actionForLongPressAtPoint:(CGPoint)point duration:(CFTimeInterval)duration {
  return [[GREYTapAction alloc] initLongPressWithDuration:duration location:point];
}

+ (id<GREYAction>)actionForMultipleTapsWithCount:(NSUInteger)count {
  return [[GREYTapAction alloc] initWithType:kGREYTapTypeMultiple numberOfTaps:count];
}

+ (id<GREYAction>)actionForMultipleTapsWithCount:(NSUInteger)count atPoint:(CGPoint)point {
  return [[GREYTapAction alloc] initWithType:kGREYTapTypeMultiple
                                numberOfTaps:count
                                    location:point];
}

// The |amount| is in points
+ (id<GREYAction>)actionForScrollInDirection:(GREYDirection)direction amount:(CGFloat)amount {
  return [[GREYScrollAction alloc] initWithDirection:direction amount:amount];
}

+ (id<GREYAction>)actionForScrollInDirection:(GREYDirection)direction
                                      amount:(CGFloat)amount
                      xOriginStartPercentage:(CGFloat)xOriginStartPercentage
                      yOriginStartPercentage:(CGFloat)yOriginStartPercentage {
  return [[GREYScrollAction alloc]
       initWithDirection:direction
                  amount:amount
      startPointPercents:CGPointMake(xOriginStartPercentage, yOriginStartPercentage)];
}

+ (id<GREYAction>)actionForScrollToContentEdge:(GREYContentEdge)edge {
  return [[GREYScrollToContentEdgeAction alloc] initWithEdge:edge];
}

+ (id<GREYAction>)actionForScrollToContentEdge:(GREYContentEdge)edge
                        xOriginStartPercentage:(CGFloat)xOriginStartPercentage
                        yOriginStartPercentage:(CGFloat)yOriginStartPercentage {
  return [[GREYScrollToContentEdgeAction alloc]
            initWithEdge:edge
      startPointPercents:CGPointMake(xOriginStartPercentage, yOriginStartPercentage)];
}

+ (id<GREYAction>)actionForTurnSwitchOn:(BOOL)on {
#if TARGET_OS_IOS
  NSString *diagnosticsID = GREYCorePrefixedDiagnosticsID(@"toggleSwitch");
  id<GREYMatcher> systemAlertShownMatcher = [GREYMatchers matcherForSystemAlertViewShown];
  NSArray<id<GREYMatcher>> *constraintMatchers = @[
    [GREYMatchers matcherForNegation:systemAlertShownMatcher],
    [GREYMatchers matcherForRespondsToSelector:@selector(isOn)]
  ];
  id<GREYMatcher> constraints = [[GREYAllOf alloc] initWithMatchers:constraintMatchers];
  NSString *actionName =
      [NSString stringWithFormat:@"Turn switch to %@ state", [UISwitch grey_stringFromOnState:on]];
  return [GREYActionBlock
      actionWithName:actionName
       diagnosticsID:diagnosticsID
         constraints:constraints
        onMainThread:YES
        performBlock:^BOOL(id switchView, __strong NSError **errorOrNil) {
          __block BOOL toggleSwitch = NO;
          grey_dispatch_sync_on_main_thread(^{
            toggleSwitch = ([switchView isOn] && !on) || (![switchView isOn] && on);
          });
          if (toggleSwitch) {
            id<GREYAction> longPressAction =
                [GREYActions actionForLongPressWithDuration:kGREYLongPressDefaultDuration];
            return [longPressAction perform:switchView error:errorOrNil];
          }
          return YES;
        }];
#else
  return nil;
#endif  // TARGET_OS_IOS
}

+ (id<GREYAction>)actionForTypeText:(NSString *)text {
  return [GREYActions grey_actionForTypeText:text atUITextPosition:nil];
}

+ (id<GREYAction>)actionForTypeText:(NSString *)text atPosition:(NSInteger)position {
  NSString *diagnosticsID = GREYCorePrefixedDiagnosticsID(@"typeText");
  NSString *actionName =
      [NSString stringWithFormat:@"Action to type \"%@\" at position %ld", text, (long)position];
  id<GREYMatcher> protocolMatcher = [GREYMatchers matcherForConformsToProtocol:gTextInputProtocol];
  GREYPerformBlock block = ^BOOL(id element, __strong NSError **errorOrNil) {
    __block UITextPosition *textPosition;
    grey_dispatch_sync_on_main_thread(^{
      if (position >= 0) {
        textPosition = [element positionFromPosition:[element beginningOfDocument] offset:position];
        if (!textPosition) {
          // Text position will be nil if the computed text position is greater than the length
          // of the backing string or less than zero. Since position is positive, the computed
          // value was past the end of the text field.
          textPosition = [element endOfDocument];
        }
      } else {
        // Position is negative. -1 should map to the end of the text field.
        textPosition = [element positionFromPosition:[element endOfDocument] offset:position + 1];
        if (!textPosition) {
          // Since position is positive, the computed value was past beginning of the text
          // field.
          textPosition = [element beginningOfDocument];
        }
      }
    });

    id<GREYAction> action = [GREYActions grey_actionForTypeText:text atUITextPosition:textPosition];
    return [action perform:element error:errorOrNil];
  };
  return [GREYActionBlock actionWithName:actionName
                           diagnosticsID:diagnosticsID
                             constraints:protocolMatcher
                            onMainThread:NO
                            performBlock:block];
}

+ (id<GREYAction>)actionForReplaceText:(NSString *)text {
  return [GREYActions grey_actionForReplaceText:text];
}

+ (id<GREYAction>)actionForClearText {
  NSString *diagnosticsID = GREYCorePrefixedDiagnosticsID(@"clearText");
  NSArray<id<GREYMatcher>> *constraintMatchers = @[
    [GREYMatchers matcherForRespondsToSelector:gTextSelector],
    [GREYMatchers matcherForKindOfClass:gAccessibilityTextFieldElementClass],
    [GREYMatchers matcherForConformsToProtocol:gTextInputProtocol]
  ];
  id<GREYMatcher> constraints = [[GREYAnyOf alloc] initWithMatchers:constraintMatchers];
  NSString *actionName = @"Clear text";
  return [GREYActionBlock
      actionWithName:actionName
       diagnosticsID:diagnosticsID
         constraints:constraints
        onMainThread:NO
        performBlock:^BOOL(id element, __strong NSError **errorOrNil) {
          __block NSString *currentText;
          if ([element isKindOfClass:gAccessibilityTextFieldElementClass] && !iOS13_OR_ABOVE()) {
            element = [element textField];
          } else {
            grey_dispatch_sync_on_main_thread(^{
              if ([element respondsToSelector:gTextSelector]) {
                currentText = [element text];
              } else if ([element respondsToSelector:gBeginningOfDocumentSelector]) {
                UITextRange *range = [element textRangeFromPosition:[element beginningOfDocument]
                                                         toPosition:[element endOfDocument]];
                currentText = [element textInRange:range];
              }
            });
          }

          NSMutableString *deleteStr = [[NSMutableString alloc] init];
          for (NSUInteger i = 0; i < currentText.length; i++) {
            [deleteStr appendString:@"\b"];
          }

          if (deleteStr.length == 0) {
            return YES;
          } else if ([element conformsToProtocol:gTextInputProtocol]) {
            __block UITextPosition *endPosition;
            grey_dispatch_sync_on_main_thread(^{
              endPosition = [element endOfDocument];
            });
            id<GREYAction> typeAtEnd = [GREYActions grey_actionForTypeText:deleteStr
                                                          atUITextPosition:endPosition];
            return [typeAtEnd perform:element error:errorOrNil];
          } else {
            return [[GREYActions actionForTypeText:deleteStr] perform:element error:errorOrNil];
          }
        }];
}

+ (id<GREYAction>)actionForSetDate:(NSDate *)date {
#if TARGET_OS_IOS
  NSString *diagnosticsID = GREYCorePrefixedDiagnosticsID(@"setDate");
  id<GREYMatcher> systemAlertShownMatcher = [GREYMatchers matcherForSystemAlertViewShown];
  NSArray<id<GREYMatcher>> *constraintMatchers = @[
    [GREYMatchers matcherForInteractable],
    [GREYMatchers matcherForNegation:systemAlertShownMatcher],
    [GREYMatchers matcherForKindOfClass:[UIDatePicker class]]
  ];
  id<GREYMatcher> constraints = [[GREYAllOf alloc] initWithMatchers:constraintMatchers];
  NSString *actionName = [NSString stringWithFormat:@"Set date to %@", date];
  return [[GREYActionBlock alloc]
       initWithName:actionName
      diagnosticsID:diagnosticsID
        constraints:constraints
       onMainThread:YES
       performBlock:^BOOL(UIDatePicker *datePicker, __strong NSError **errorOrNil) {
         grey_dispatch_sync_on_main_thread(^{
           NSDate *previousDate = [datePicker date];
           [datePicker setDate:date animated:YES];
           // Changing the data programmatically does not fire the "value changed" events,
           // So we have to trigger the events manually if the value changes.
           if (![date isEqualToDate:previousDate]) {
             [datePicker sendActionsForControlEvents:UIControlEventValueChanged];
           }
         });
         return YES;
       }];
#else
  return nil;
#endif  // TARGET_OS_IOS
}

+ (id<GREYAction>)actionForSetPickerColumn:(NSInteger)column toValue:(NSString *)value {
  return [[GREYPickerAction alloc] initWithColumn:column value:value];
}

+ (id<GREYAction>)actionForJavaScriptExecution:(NSString *)js
                                        output:(EDORemoteVariable<NSString *> *)outResult {
#if TARGET_OS_IOS
  NSString *diagnosticsID = GREYCorePrefixedDiagnosticsID(@"executeJavaScript");
  // TODO: JS Errors should be propagated up.
  id<GREYMatcher> systemAlertShownMatcher = [GREYMatchers matcherForSystemAlertViewShown];
  NSArray<id<GREYMatcher>> *webViewMatchers =
      @[ [GREYMatchers matcherForKindOfClass:[WKWebView class]] ];
  NSArray<id<GREYMatcher>> *constraintMatchers = @[
    [GREYMatchers matcherForNegation:systemAlertShownMatcher],
    [[GREYAnyOf alloc] initWithMatchers:webViewMatchers]
  ];
  NSString *actionName = @"Execute JavaScript";
  id<GREYMatcher> constraints = [[GREYAllOf alloc] initWithMatchers:constraintMatchers];
  return [[GREYActionBlock alloc]
       initWithName:actionName
      diagnosticsID:diagnosticsID
        constraints:constraints
       onMainThread:YES
       performBlock:^BOOL(id webView, __strong NSError **errorOrNil) {
         __block NSError *localError = nil;
         __block BOOL finishedCompletion = NO;
         grey_dispatch_sync_on_main_thread(^{
           [webView evaluateJavaScript:js
                     completionHandler:^(id result, NSError *error) {
                       if (result) {
                         // Populate the javascript result for the user to get back.
                         outResult.object = [NSString stringWithFormat:@"%@", result];
                       }
                       if (error) {
                         localError = error;
                       }
                       finishedCompletion = YES;
                     }];
         });
         // Wait for the interaction timeout for the semaphore to return.
         CFTimeInterval interactionTimeout =
             GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration);

         BOOL success = grey_check_condition_until_timeout(
             ^BOOL(void) {
               return finishedCompletion;
             },
             interactionTimeout);

         if (!success) {
           I_GREYPopulateError(errorOrNil, kGREYInteractionErrorDomain,
                               kGREYWKWebViewInteractionFailedErrorCode,
                               @"Interaction with WKWebView failed because of timeout");
           return NO;
         }
         if (localError) {
           NSString *description = [localError userInfo][@"WKJavaScriptExceptionMessage"];
           if (!description) {
             description = localError.userInfo[kErrorFailureReasonKey]
                               ?: @"Interaction with WKWebView failed for an internal reason";
           }
           I_GREYPopulateError(errorOrNil, kGREYInteractionErrorDomain,
                               kGREYWKWebViewInteractionFailedErrorCode, description);
           return NO;
         } else {
           return YES;
         }
       }];
#else
  return nil;
#endif  // TARGET_OS_IOS
}

+ (id<GREYAction>)actionForSnapshot:(EDORemoteVariable<UIImage *> *)outImage {
  NSString *diagnosticsID = GREYCorePrefixedDiagnosticsID(@"snapshot");
  GREYThrowOnNilParameter(outImage);
  NSString *actionName = @"Element Snapshot";
  return [[GREYActionBlock alloc]
       initWithName:actionName
      diagnosticsID:diagnosticsID
        constraints:nil
       onMainThread:YES
       performBlock:^BOOL(id element, __strong NSError **errorOrNil) {
         UIImage __block *snapshot = nil;
         grey_dispatch_sync_on_main_thread(^{
           snapshot = [GREYScreenshotter snapshotElement:element];
         });
         if (snapshot == nil) {
           I_GREYPopulateError(errorOrNil, kGREYInteractionErrorDomain,
                               kGREYInteractionActionFailedErrorCode,
                               @"Failed to take snapshot. Snapshot is nil.");
           return NO;
         } else {
           outImage.object = snapshot;
           return YES;
         }
       }];
}

#pragma mark - Private

/**
 * Set the UITextField text value directly, bypassing the iOS keyboard.
 *
 * @param text The text to be typed.
 *
 * @return @c YES if the action succeeded, else @c NO. If an action returns @c NO, it does not
 *         mean that the action was not performed at all but somewhere during the action execution
 *         the error occurred and so the UI may be in an unrecoverable state.
 */
+ (id<GREYAction>)grey_actionForReplaceText:(NSString *)text {
  SEL setTextSelector = NSSelectorFromString(@"setText:");
  NSArray<id<GREYMatcher>> *constraintMatchers = @[
    [GREYMatchers matcherForRespondsToSelector:setTextSelector],
    [GREYMatchers matcherForKindOfClass:gAccessibilityTextFieldElementClass],
  ];
  id<GREYMatcher> constraints = [[GREYAnyOf alloc] initWithMatchers:constraintMatchers];
  NSString *actionName = [NSString stringWithFormat:@"Replace with text: \"%@\"", text];
  NSString *diagnosticsID = GREYCorePrefixedDiagnosticsID(@"replaceText");
  return [GREYActionBlock
      actionWithName:actionName
       diagnosticsID:diagnosticsID
         constraints:constraints
        onMainThread:YES
        performBlock:^BOOL(id element, __strong NSError **errorOrNil) {
          if ([element isKindOfClass:gAccessibilityTextFieldElementClass] && !iOS13_OR_ABOVE()) {
            element = [element textField];
          }

          NSNotificationCenter *defaultCenter = NSNotificationCenter.defaultCenter;
          BOOL elementIsUIControl = [element isKindOfClass:[UIControl class]];
          BOOL elementIsUITextField = [element isKindOfClass:[UITextField class]];
          BOOL elementIsUITextView = [element isKindOfClass:[UITextView class]];
          grey_dispatch_sync_on_main_thread(^{
            // Did begin editing notifications.
            if (elementIsUIControl) {
              [element sendActionsForControlEvents:UIControlEventEditingDidBegin];
            }
            if (elementIsUITextField) {
              NSNotification *notification =
                  [NSNotification notificationWithName:UITextFieldTextDidBeginEditingNotification
                                                object:element];
              [defaultCenter postNotification:notification];
            }
            if (elementIsUITextView) {
              NSNotification *notification =
                  [NSNotification notificationWithName:UITextViewTextDidBeginEditingNotification
                                                object:element];
              [defaultCenter postNotification:notification];
            }

            // Actually change the text.
            [element setText:text];

            // Did change editing notifications.
            if (elementIsUIControl) {
              [element sendActionsForControlEvents:UIControlEventEditingChanged];
            }
            if (elementIsUITextField) {
              NSNotification *notification =
                  [NSNotification notificationWithName:UITextFieldTextDidChangeNotification
                                                object:element];
              [defaultCenter postNotification:notification];
            }
            if (elementIsUITextView) {
              NSNotification *notification =
                  [NSNotification notificationWithName:UITextViewTextDidChangeNotification
                                                object:element];
              [defaultCenter postNotification:notification];
            }

            // Did end editing notifications.
            if (elementIsUIControl) {
              [element sendActionsForControlEvents:UIControlEventEditingDidEndOnExit];
              [element sendActionsForControlEvents:UIControlEventEditingDidEnd];
            }
            if (elementIsUITextField) {
              NSNotification *notification =
                  [NSNotification notificationWithName:UITextFieldTextDidEndEditingNotification
                                                object:element];
              [defaultCenter postNotification:notification];
              [element sendActionsForControlEvents:UIControlEventValueChanged];
            }
            if (elementIsUITextView) {
              NSNotification *notification =
                  [NSNotification notificationWithName:UITextViewTextDidEndEditingNotification
                                                object:element];
              [defaultCenter postNotification:notification];
            }

            // For a UITextView, call the textViewDidChange: delegate.
            if ([element isKindOfClass:[UITextView class]]) {
              UITextView *textView = (UITextView *)element;
              id<UITextViewDelegate> textViewDelegate = textView.delegate;
              if ([textViewDelegate respondsToSelector:@selector(textViewDidChange:)]) {
                [textViewDelegate textViewDidChange:textView];
              }
            }
          });
          return YES;
        }];
}

#pragma mark - Package Internal

+ (id<GREYAction>)grey_actionForTypeText:(NSString *)text
                        atUITextPosition:(UITextPosition *)position {
  id<GREYMatcher> systemAlertShownMatcher = [GREYMatchers matcherForSystemAlertViewShown];
  id<GREYMatcher> actionBlockMatcher = [GREYMatchers matcherForNegation:systemAlertShownMatcher];
  NSString *actionName = [NSString stringWithFormat:@"Type '%@'", text];
  NSString *diagnosticsID = GREYCorePrefixedDiagnosticsID(@"typeText");
  return [GREYActionBlock
      actionWithName:actionName
       diagnosticsID:diagnosticsID
         constraints:actionBlockMatcher
        onMainThread:NO
        performBlock:^BOOL(id element, __strong NSError **errorOrNil) {
          __block UIView *expectedFirstResponderView;
          if (![element isKindOfClass:[UIView class]]) {
            grey_dispatch_sync_on_main_thread(^{
              expectedFirstResponderView = [element grey_viewContainingSelf];
            });
          } else {
            expectedFirstResponderView = element;
          }

          // If expectedFirstResponderView or one of its ancestors isn't the first responder,
          // tap on it so it becomes the first responder.
          __block BOOL elementMatched = NO;
          grey_dispatch_sync_on_main_thread(^{
            elementMatched = [expectedFirstResponderView isFirstResponder];
            if (!elementMatched) {
              id<GREYMatcher> firstResponderMatcher = [GREYMatchers matcherForFirstResponder];
              id<GREYMatcher> ancestorMatcher =
                  [GREYMatchers matcherForAncestor:firstResponderMatcher];
              elementMatched = [ancestorMatcher matches:expectedFirstResponderView];
            }
          });
          // A period key for an email UITextField on iOS9 and above types the email domain (.com,
          // .org) by default. That is not the desired behavior so check below disables it.
          __block BOOL keyboardTypeWasChangedFromEmailType = NO;
          grey_dispatch_sync_on_main_thread(^{
            if ([text containsString:@"."] &&
                [element respondsToSelector:@selector(keyboardType)] &&
                [element keyboardType] == UIKeyboardTypeEmailAddress) {
              [element setKeyboardType:UIKeyboardTypeDefault];
              // reloadInputViews must be called so that the keyboardType change becomes effective.
              [element reloadInputViews];
              keyboardTypeWasChangedFromEmailType = YES;
            }
          });

          if (!elementMatched) {
            // Tap on the element to make expectedFirstResponderView a first responder.
            if (![[GREYActions actionForTap] perform:element error:errorOrNil]) {
              return NO;
            }
            // Wait for keyboard to show up and any other UI changes to take effect.
            if (![GREYKeyboard waitForKeyboardToAppear]) {
              __block NSString *elementDescription;
              grey_dispatch_sync_on_main_thread(^{
                elementDescription = [element grey_description];
              });
              NSString *description = [NSString
                  stringWithFormat:
                      @"Keyboard did not appear after tapping on an element. "
                      @"\nAre you sure that tapping on this element will bring up the keyboard?"
                      @"\nElement: \n%@",
                      element];
              I_GREYPopulateError(errorOrNil, kGREYInteractionErrorDomain,
                                  kGREYInteractionActionFailedErrorCode, description);
              return NO;
            }
          }

          // If a position is given, move the text cursor to that position.
          __block id firstResponder = nil;
          __block NSString *description = nil;
          grey_dispatch_sync_on_main_thread(^{
            firstResponder = [[expectedFirstResponderView window] firstResponder];
            if (position) {
              if ([firstResponder conformsToProtocol:gTextInputProtocol]) {
                UITextRange *newRange = [firstResponder textRangeFromPosition:position
                                                                   toPosition:position];
                [firstResponder setSelectedTextRange:newRange];
              } else {
                description = [NSString
                    stringWithFormat:
                        @"First Responder of Element does not conform to UITextInput protocol."
                        @"\nFirst Responder: %@ \nElement: %@",
                        [firstResponder description], [expectedFirstResponderView description]];
              }
            }
          });

          if (description) {
            I_GREYPopulateError(errorOrNil, kGREYInteractionErrorDomain,
                                kGREYInteractionActionFailedErrorCode, description);
            return NO;
          }

          BOOL result = [GREYKeyboard typeString:text
                                inFirstResponder:firstResponder
                                           error:errorOrNil];
          if (keyboardTypeWasChangedFromEmailType) {
            // Set the keyboard type back to the Email Type.
            [firstResponder setKeyboardType:UIKeyboardTypeEmailAddress];
          }
          return result;
        }];
}

@end
