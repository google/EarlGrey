//
// Copyright 2016 Google Inc.
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

#import "Action/GREYActions.h"

#import "Action/GREYAction.h"
#import "Action/GREYActionBlock.h"
#import "Action/GREYChangeStepperAction.h"
#import "Action/GREYPickerAction.h"
#import "Action/GREYScrollAction.h"
#import "Action/GREYScrollToContentEdgeAction.h"
#import "Action/GREYSlideAction.h"
#import "Action/GREYSwipeAction.h"
#import "Action/GREYTapAction.h"
#import "Additions/NSError+GREYAdditions.h"
#import "Additions/NSObject+GREYAdditions.h"
#import "Additions/NSString+GREYAdditions.h"
#import "Additions/UISwitch+GREYAdditions.h"
#import "Assertion/GREYAssertionDefines.h"
#import "Common/GREYExposed.h"
#import "Common/GREYScreenshotUtil.h"
#import "Core/GREYInteraction.h"
#import "Core/GREYKeyboard.h"
#import "Matcher/GREYAllOf.h"
#import "Matcher/GREYAnyOf.h"
#import "Matcher/GREYMatcher.h"
#import "Matcher/GREYMatchers.h"
#import "Matcher/GREYNot.h"
#import "Synchronization/GREYUIThreadExecutor.h"
#import "Synchronization/GREYUIWebViewIdlingResource.h"

@implementation GREYActions

+ (id<GREYAction>)actionForSwipeFastInDirection:(GREYDirection)direction {
  return [[GREYSwipeAction alloc] initWithDirection:direction duration:kGREYSwipeFastDuration];
}

+ (id<GREYAction>)actionForSwipeSlowInDirection:(GREYDirection)direction {
  return [[GREYSwipeAction alloc] initWithDirection:direction duration:kGREYSwipeSlowDuration];
}

+ (id<GREYAction>)actionForSwipeFastInDirection:(GREYDirection)direction
                         xOriginStartPercentage:(CGFloat)xOriginStartPercentage
                         yOriginStartPercentage:(CGFloat)yOriginStartPercentage {
  return [[GREYSwipeAction alloc] initWithDirection:direction
                                           duration:kGREYSwipeFastDuration
                                      startPercents:CGPointMake(xOriginStartPercentage,
                                                                yOriginStartPercentage)];
}

+ (id<GREYAction>)actionForSwipeSlowInDirection:(GREYDirection)direction
                         xOriginStartPercentage:(CGFloat)xOriginStartPercentage
                         yOriginStartPercentage:(CGFloat)yOriginStartPercentage {
  return [[GREYSwipeAction alloc] initWithDirection:direction
                                           duration:kGREYSwipeSlowDuration
                                      startPercents:CGPointMake(xOriginStartPercentage,
                                                                yOriginStartPercentage)];
}

+ (id<GREYAction>)actionForMoveSliderToValue:(float)value {
  return [[GREYSlideAction alloc] initWithSliderValue:value];
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

// The |amount| is in points
+ (id<GREYAction>)actionForScrollInDirection:(GREYDirection)direction amount:(CGFloat)amount {
  return [[GREYScrollAction alloc] initWithDirection:direction amount:amount];
}

+ (id<GREYAction>)actionForScrollToContentEdge:(GREYContentEdge)edge {
  return [[GREYScrollToContentEdgeAction alloc] initWithEdge:edge];
}

+ (id<GREYAction>)actionForTurnSwitchOn:(BOOL)on {
  id<GREYMatcher> constraints = grey_allOf(grey_not(grey_systemAlertViewShown()),
                                           grey_respondsToSelector(@selector(isOn)), nil);
  NSString *actionName = [NSString stringWithFormat:@"Turn switch to %@ state",
                             [UISwitch grey_stringFromOnState:on]];
  return [GREYActionBlock actionWithName:actionName
                             constraints:constraints
                            performBlock:^BOOL (id switchView, __strong NSError **errorOrNil) {
    if (([switchView isOn] && !on) || (![switchView isOn] && on)) {
      id<GREYAction> longPressAction =
          [GREYActions actionForLongPressWithDuration:kGREYLongPressDefaultDuration];
      return [longPressAction perform:switchView error:errorOrNil];
    }
    return YES;
  }];
}

+ (id<GREYAction>)actionForTypeText:(NSString *)text {
  return [GREYActions actionForTypeText:text atUITextPosition:nil];
}

// Use the iOS keyboard to type a string starting from the provided UITextPosition. If position is
// nil, then will type text from the text input's current position. Should only be called with a
// position if element conforms to the UITextInput protocol - which it should if you derived the
// UITextPosition from the element.
+ (id<GREYAction>)actionForTypeText:(NSString *)text atUITextPosition:(UITextPosition *)position {
  return [GREYActionBlock actionWithName:[NSString stringWithFormat:@"Type \"%@\"", text]
                             constraints:grey_not(grey_systemAlertViewShown())
                            performBlock:^BOOL (id element, __strong NSError **errorOrNil) {
    UIView *expectedFirstResponderView;
    if (![element isKindOfClass:[UIView class]]) {
      expectedFirstResponderView = [element grey_viewContainingSelf];
    } else {
      expectedFirstResponderView = element;
    }

    // If expectedFirstResponderView or one of its ancestors isn't the first responder, tap on
    // it so it becomes the first responder.
    if (![expectedFirstResponderView isFirstResponder] &&
        ![grey_ancestor(grey_firstResponder()) matches:expectedFirstResponderView]) {
      // Tap on the element to make expectedFirstResponderView a first responder.
      if (![[GREYActions actionForTap] perform:element error:errorOrNil]) {
        return NO;
      }
      // Wait for keyboard to show up and any other UI changes to take effect.
      if (![GREYKeyboard waitForKeyboardToAppear]) {
        NSString *description = @"Keyboard did not appear after tapping on %@. Are you sure that "
                                @"tapping on this element will bring up the keyboard?";
        [NSError grey_logOrSetOutReferenceIfNonNil:errorOrNil
                                        withDomain:kGREYInteractionErrorDomain
                                              code:kGREYInteractionActionFailedErrorCode
                              andDescriptionFormat:description, element];
        return NO;
      }
    }

    // Autocorrection might change the results of the type action in unexpected ways. In order to
    // avoid that, we must disable autocorrection for the first responder before executing the
    // action.
    UITextAutocorrectionType originalAutocorrectionType = UITextAutocorrectionTypeNo;
    id firstResponder = [expectedFirstResponderView.window firstResponder];
    if ([firstResponder respondsToSelector:@selector(autocorrectionType)] &&
        [firstResponder respondsToSelector:@selector(setAutocorrectionType:)]) {
      originalAutocorrectionType = [firstResponder autocorrectionType];
      [firstResponder setAutocorrectionType:UITextAutocorrectionTypeNo];

      // If the view already is the first responder and had autocorrect enabled, it must
      // resign and become first responder for the autocorrect type change to take effect.
      [firstResponder resignFirstResponder];
      if (![GREYKeyboard waitForKeyboardToDisappear]) {
        NSString *description = @"Keyboard did not disappear after resigning first responder "
                                @"status of %@";
        [NSError grey_logOrSetOutReferenceIfNonNil:errorOrNil
                                        withDomain:kGREYInteractionErrorDomain
                                              code:kGREYInteractionActionFailedErrorCode
                              andDescriptionFormat:description, firstResponder];
        return NO;
      }
      [firstResponder becomeFirstResponder];
      if (![GREYKeyboard waitForKeyboardToAppear]) {
        NSString *description = @"Keyboard did not appear after %@ became the first responder.";
        [NSError grey_logOrSetOutReferenceIfNonNil:errorOrNil
                                        withDomain:kGREYInteractionErrorDomain
                                              code:kGREYInteractionActionFailedErrorCode
                              andDescriptionFormat:description, firstResponder];
        return NO;
      }
    }

    // If a position is given, move the text cursor to that position.
    if (position) {
      UITextRange *newRange = [element textRangeFromPosition:position toPosition:position];
      [element setSelectedTextRange:newRange];
    }

    // After autocorrect is disabled, we can perform the actual typing.
    BOOL retVal = [GREYKeyboard typeString:text error:errorOrNil];

    // If the element's UITextAutocorrection type was changed, it has to be restored before
    // continuing.
    if (originalAutocorrectionType != UITextAutocorrectionTypeNo) {
      [firstResponder setAutocorrectionType:originalAutocorrectionType];
    }

    return retVal;
  }];
}

+ (id<GREYAction>)actionForClearText {
  Class webElement = NSClassFromString(@"WebAccessibilityObjectWrapper");
  id<GREYMatcher> constraints = grey_anyOf(grey_respondsToSelector(@selector(text)),
                                           grey_kindOfClass(webElement),
                                           nil);
  NSString *actionName = [NSString stringWithFormat:@"Clear text"];
  return [GREYActionBlock actionWithName:actionName
                             constraints:constraints
                            performBlock:^BOOL (id element, __strong NSError **errorOrNil) {
    NSString *textStr;
    // If we're dealing with a text field in a web view, we need to use JS to get the text value.
    if ([element isKindOfClass:webElement]) {
      // Input tags can be identified by having the 'title' attribute set, or current value.
      // Associating a <label> tag to the input tag does NOT result in an iOS accessibility element.
      NSString *xPathResultType = @"XPathResult.FIRST_ORDERED_NODE_TYPE";
      NSString *xPathForTitle =
          [NSString stringWithFormat:@"//input[@title=\"%@\" or @value=\"%@\"]",
              [element accessibilityLabel], [element accessibilityLabel]];
      NSString *jsForTitle = [[NSString alloc] initWithFormat:
          @"document.evaluate('%@', document, null, %@, null).singleNodeValue.value = '';",
          xPathForTitle,
          xPathResultType];
      UIWebView *parentWebView = (UIWebView *)[element grey_viewContainingSelf];
      textStr = [parentWebView stringByEvaluatingJavaScriptFromString:jsForTitle];
    } else {
      textStr = [element text];
    }

    NSMutableString *deleteStr = [[NSMutableString alloc] init];
    for (NSUInteger i = 0; i < textStr.length; i++) {
      [deleteStr appendString:@"\b"];
    }

    if (deleteStr.length == 0) {
      return YES;
    } else if ([element conformsToProtocol:@protocol(UITextInput)]) {
      id<GREYAction> typeAtEnd = [GREYActions actionForTypeText:deleteStr
                                               atUITextPosition:[element endOfDocument]];
      return [typeAtEnd perform:element error:errorOrNil];
    } else {
      return [[GREYActions actionForTypeText:deleteStr] perform:element error:errorOrNil];
    }
  }];
}

+ (id<GREYAction>)actionForSetDate:(NSDate *)date {
  id<GREYMatcher> constraints = grey_allOf(grey_interactable(),
                                           grey_not(grey_systemAlertViewShown()),
                                           grey_kindOfClass([UIDatePicker class]),
                                           nil);
  return [[GREYActionBlock alloc] initWithName:[NSString stringWithFormat:@"Set date to %@", date]
                                   constraints:constraints
                                  performBlock:^BOOL (UIDatePicker *datePicker,
                                                      __strong NSError **errorOrNil) {
    NSDate *previousDate = [datePicker date];
    [datePicker setDate:date animated:YES];
    // Changing the data programmatically does not fire the "value changed" events,
    // So we have to trigger the events manually if the value changes.
    if (![date isEqualToDate:previousDate]) {
      [datePicker sendActionsForControlEvents:UIControlEventValueChanged];
    }
    return YES;
  }];
}

+ (id<GREYAction>)actionForSetPickerColumn:(NSInteger)column toValue:(NSString *)value {
  return [[GREYPickerAction alloc] initWithColumn:column value:value];
}

+ (id<GREYAction>)actionForJavaScriptExecution:(NSString *)js
                                        output:(out __strong NSString **)outResult {
  // TODO: JS Errors should be propagated up.
  id<GREYMatcher> constraints = grey_allOf(grey_not(grey_systemAlertViewShown()),
                                           grey_kindOfClass([UIWebView class]),
                                           nil);
  return [[GREYActionBlock alloc] initWithName:@"Execute JavaScript"
                                   constraints:constraints
                                  performBlock:^BOOL (UIWebView *webView,
                                                      __strong NSError **errorOrNil) {
    if (outResult) {
      *outResult = [webView stringByEvaluatingJavaScriptFromString:js];
    } else {
      [webView stringByEvaluatingJavaScriptFromString:js];
    }
    // TODO: Delay should be removed once webview sync is stable.
    [[GREYUIThreadExecutor sharedInstance] drainForTime:0.5];  // Wait for actions to register.
    return YES;
  }];
}

+ (id<GREYAction>)actionForSnapshot:(out __strong UIImage **)outImage {
  NSParameterAssert(outImage);

  return [[GREYActionBlock alloc] initWithName:@"Element Snapshot"
                                   constraints:nil
                                  performBlock:^BOOL (id element, __strong NSError **errorOrNil) {
    UIImage *snapshot = [GREYScreenshotUtil snapshotElement:element];
    if (snapshot == nil) {
      [NSError grey_logOrSetOutReferenceIfNonNil:errorOrNil
                                      withDomain:kGREYInteractionErrorDomain
                                            code:kGREYInteractionActionFailedErrorCode
                            andDescriptionFormat:@"Failed to take snapshot. Snapshot is nil."];
      return NO;
    } else {
      *outImage = snapshot;
      return YES;
    }
  }];
}

@end

#if !(GREY_DISABLE_SHORTHAND)

id<GREYAction> grey_doubleTap(void) {
  return [GREYActions actionForMultipleTapsWithCount:2];
}

id<GREYAction> grey_multipleTapsWithCount(NSUInteger count) {
  return [GREYActions actionForMultipleTapsWithCount:count];
}

id<GREYAction> grey_longPress(void) {
  return [GREYActions actionForLongPress];
}

id<GREYAction> grey_longPressWithDuration(CFTimeInterval duration) {
  return [GREYActions actionForLongPressWithDuration:duration];
}

id<GREYAction> grey_longPressAtPointWithDuration(CGPoint point, CFTimeInterval duration) {
  return [GREYActions actionForLongPressAtPoint:point duration:duration];
}

id<GREYAction> grey_scrollInDirection(GREYDirection direction, CGFloat amount) {
  return [GREYActions actionForScrollInDirection:direction amount:amount];
}

id<GREYAction> grey_scrollToContentEdge(GREYContentEdge edge) {
  return [GREYActions actionForScrollToContentEdge:edge];
}

id<GREYAction> grey_swipeFastInDirection(GREYDirection direction) {
  return [GREYActions actionForSwipeFastInDirection:direction];
}

id<GREYAction> grey_swipeSlowInDirection(GREYDirection direction) {
  return [GREYActions actionForSwipeSlowInDirection:direction];
}

id<GREYAction> grey_swipeFastInDirectionWithStartPoint(GREYDirection direction,
                                                       CGFloat xOriginStartPercentage,
                                                       CGFloat yOriginStartPercentage) {
  return [GREYActions actionForSwipeFastInDirection:direction
                             xOriginStartPercentage:xOriginStartPercentage
                             yOriginStartPercentage:yOriginStartPercentage];
}

id<GREYAction> grey_swipeSlowInDirectionWithStartPoint(GREYDirection direction,
                                                       CGFloat xOriginStartPercentage,
                                                       CGFloat yOriginStartPercentage) {
  return [GREYActions actionForSwipeSlowInDirection:direction
                             xOriginStartPercentage:xOriginStartPercentage
                             yOriginStartPercentage:yOriginStartPercentage];
}

id<GREYAction> grey_moveSliderToValue(float value) {
  return [GREYActions actionForMoveSliderToValue:value];
}

id<GREYAction> grey_setStepperValue(double value) {
  return [GREYActions actionForSetStepperValue:value];
}

id<GREYAction> grey_tap(void) {
  return [GREYActions actionForTap];
}

id<GREYAction> grey_tapAtPoint(CGPoint point) {
  return [GREYActions actionForTapAtPoint:point];
}

id<GREYAction> grey_typeText(NSString *text) {
  return [GREYActions actionForTypeText:text];
}

id<GREYAction> grey_clearText(void) {
  return [GREYActions actionForClearText];
}

id<GREYAction> grey_turnSwitchOn(BOOL on) {
  return [GREYActions actionForTurnSwitchOn:on];
}

id<GREYAction> grey_setDate(NSDate *date) {
  return [GREYActions actionForSetDate:date];
}

id<GREYAction> grey_setPickerColumnToValue(NSInteger column, NSString *value) {
  return [GREYActions actionForSetPickerColumn:column toValue:value];
}

id<GREYAction> grey_javaScriptExecution(NSString *js, __strong NSString **outResult) {
  return [GREYActions actionForJavaScriptExecution:js output:outResult];
}

id<GREYAction> grey_snapshot(__strong UIImage **outImage) {
  return [GREYActions actionForSnapshot:outImage];
}

#endif // GREY_DISABLE_SHORTHAND
