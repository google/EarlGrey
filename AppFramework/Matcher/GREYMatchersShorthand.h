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

#import <UIKit/UIKit.h>

#import "GREYConstants.h"
#import "GREYDefines.h"

NS_ASSUME_NONNULL_BEGIN

@protocol GREYMatcher;

#if !defined(GREY_DISABLE_SHORTHAND) || !(GREY_DISABLE_SHORTHAND)

/** Shorthand for GREYMatchers::matcherForKeyWindow. */
GREY_EXPORT id<GREYMatcher> grey_keyWindow(void);

/** Shorthand for GREYMatchers::matcherForAccessibilityLabel:. */
GREY_EXPORT id<GREYMatcher> grey_accessibilityLabel(NSString *label);

/** Shorthand for GREYMatchers::matcherForAccessibilityID:. */
GREY_EXPORT id<GREYMatcher> grey_accessibilityID(NSString *accessibilityID);

/** Shorthand for GREYMatchers::matcherForAccessibilityValue:. */
GREY_EXPORT id<GREYMatcher> grey_accessibilityValue(NSString *grey_accessibilityValue);

/** Shorthand for GREYMatchers::matcherForAccessibilityTraits:. */
GREY_EXPORT id<GREYMatcher> grey_accessibilityTrait(UIAccessibilityTraits traits);

/** Shorthand for GREYMatchers::matcherForAccessibilityElementIsFocused. */
GREY_EXPORT id<GREYMatcher> grey_accessibilityFocused(void);

/** Shorthand for GREYMatchers::matcherForAccessibilityHint:. */
GREY_EXPORT id<GREYMatcher> grey_accessibilityHint(NSString *hint);

/** Shorthand for GREYMatchers::matcherForText:. */
GREY_EXPORT id<GREYMatcher> grey_text(NSString *inputText);

/** Shorthand for GREYMatchers::matcherForFirstResponder. */
GREY_EXPORT id<GREYMatcher> grey_firstResponder(void);

/** Shorthand for GREYMatchers::matcherForSystemAlertViewShown. */
GREY_EXPORT id<GREYMatcher> grey_systemAlertViewShown(void);

/** Shorthand for GREYMatchers::matcherForMinimumVisiblePercent:. */
GREY_EXPORT id<GREYMatcher> grey_minimumVisiblePercent(CGFloat percent);

/** Shorthand for GREYMatchers::matcherForSufficientlyVisible. */
GREY_EXPORT id<GREYMatcher> grey_sufficientlyVisible(void);

/** Shorthand for GREYMatchers::matcherForInteractable. */
GREY_EXPORT id<GREYMatcher> grey_interactable(void);

/** Shorthand for GREYMatchers::matcherForNotVisible. */
GREY_EXPORT id<GREYMatcher> grey_notVisible(void);

/** Shorthand for GREYMatchers::matcherForAccessibilityElement. */
GREY_EXPORT id<GREYMatcher> grey_accessibilityElement(void);

/** Shorthand for GREYMatchers::matcherForKindOfClass:. */
GREY_EXPORT id<GREYMatcher> grey_kindOfClass(Class klass);

/** Shorthand for GREYMatchers::matcherForKindOfClassName:. */
GREY_EXPORT id<GREYMatcher> grey_kindOfClassName(NSString *className);

/** Shorthand for GREYMatchers::matcherForProgress:. */
GREY_EXPORT id<GREYMatcher> grey_progress(id<GREYMatcher> comparisonMatcher);

/** Shorthand for GREYMatchers::matcherForRespondsToSelector:. */
GREY_EXPORT id<GREYMatcher> grey_respondsToSelector(SEL sel);

/** Shorthand for GREYMatchers::matcherForConformsToProtocol:. */
GREY_EXPORT id<GREYMatcher> grey_conformsToProtocol(Protocol *protocol);

/** Shorthand for GREYMatchers::matcherForAncestor:. */
GREY_EXPORT id<GREYMatcher> grey_ancestor(id<GREYMatcher> ancestorMatcher);

/** Shorthand for GREYMatchers::matcherForDescendant:. */
GREY_EXPORT id<GREYMatcher> grey_descendant(id<GREYMatcher> descendantMatcher);

/** Shorthand for GREYMatchers::matcherForButtonTitle:. */
GREY_EXPORT id<GREYMatcher> grey_buttonTitle(NSString *text);

/** Shorthand for GREYMatchers::matcherForScrollViewContentOffset:. */
GREY_EXPORT id<GREYMatcher> grey_scrollViewContentOffset(CGPoint offset);

/** Shorthand for GREYMatchers::matcherForStepperValue:. */
GREY_EXPORT id<GREYMatcher> grey_stepperValue(double value);

/** Shorthand for GREYMatchers::matcherForSliderValueMatcher:. */
GREY_EXPORT id<GREYMatcher> grey_sliderValueMatcher(id<GREYMatcher> valueMatcher);

/** Shorthand for GREYMatchers::matcherForDatePickerValue:. */
GREY_EXPORT id<GREYMatcher> grey_datePickerValue(NSDate *date);

/** Shorthand for GREYMatchers::matcherForPickerColumn:setToValue:. */
GREY_EXPORT id<GREYMatcher> grey_pickerColumnSetToValue(NSInteger column,
                                                        NSString *_Nullable value);

/** Shorthand for GREYMatchers::matcherForEnabledElement. */
GREY_EXPORT id<GREYMatcher> grey_enabled(void);

/** Shorthand for GREYMatchers::matcherForSelectedElement. */
GREY_EXPORT id<GREYMatcher> grey_selected(void);

/** Shorthand for GREYMatchers::matcherForUserInteractionEnabled. */
GREY_EXPORT id<GREYMatcher> grey_userInteractionEnabled(void);

/** Shorthand for GREYMatchers::matcherForLayoutConstraints:toReferenceElementMatching:. */
GREY_EXPORT id<GREYMatcher> grey_layout(NSArray *constraints,
                                        id<GREYMatcher> referenceElementMatcher);

/** Shorthand for GREYMatchers::matcherForNil. */
GREY_EXPORT id<GREYMatcher> grey_nil(void);

/** Shorthand for GREYMatchers::matcherForNotNil. */
GREY_EXPORT id<GREYMatcher> grey_notNil(void);

/** Shorthand for GREYMatchers::matcherForSwitchWithOnState:. */
GREY_EXPORT id<GREYMatcher> grey_switchWithOnState(BOOL on);

/** Shorthand for GREYMatchers::matcherForCloseTo:. */
GREY_EXPORT id<GREYMatcher> grey_closeTo(double value, double delta);

/** Shorthand for GREYMatchers::matcherForAnything. */
GREY_EXPORT id<GREYMatcher> grey_anything(void);

/** Shorthand for GREYMatchers::matcherForEqualTo:. */
GREY_EXPORT id<GREYMatcher> grey_equalTo(id value);

/** Shorthand for GREYMatchers::matcherForLessThan:. */
GREY_EXPORT id<GREYMatcher> grey_lessThan(id value);

/** Shorthand for GREYMatchers::matcherForGreaterThan:. */
GREY_EXPORT id<GREYMatcher> grey_greaterThan(id value);

/** Shorthand for GREYMatchers::matcherForScrolledToContentEdge:. */
GREY_EXPORT id<GREYMatcher> grey_scrolledToContentEdge(GREYContentEdge edge);

/** Shorthand for GREYMatchers::matcherForNegation:. */
GREY_EXPORT id<GREYMatcher> grey_not(id<GREYMatcher> matcher);

/** Shorthand for GREYMatchers::matcherForTextFieldValue:. */
GREY_EXPORT id<GREYMatcher> grey_textFieldValue(NSString *value);

/**
 *  A shorthand matcher that is a logical AND of all the matchers passed in as variable arguments.
 *
 *  @param matcher The first matcher in the list of matchers.
 *  @param ...     Any more matchers to be added. Matchers are invoked in the order they are
 *                 specified and only if the preceding matcher passes. This va-arg must be
 *                 terminated with a @c nil value.
 *
 *  @return An object conforming to GREYMatcher, initialized with the required matchers.
 */
GREY_EXPORT id<GREYMatcher> grey_allOf(id<GREYMatcher> _Nullable matcher, ...)
    NS_SWIFT_UNAVAILABLE("Use grey_allOf(_:) instead") NS_REQUIRES_NIL_TERMINATION;

/**
 *  A shorthand matcher that is a logical AND of all the matchers passed in within an NSArray.
 *
 *  @param matchers An NSArray of one or more matchers to be added. Matchers are invoked in the
 *                  order they are specified and only if the preceding matcher passes.
 *
 *  @return An object conforming to GREYMatcher, initialized with the required matchers.
 */
GREY_EXPORT id<GREYMatcher> grey_allOfMatchers(NSArray<__kindof id<GREYMatcher>> *matchers)
    NS_SWIFT_NAME(grey_allOf(_:));

/**
 *  A matcher that is a logical OR of all the matchers passed in as variable arguments.
 *
 *  @param match The first matcher in the list of matchers.
 *  @param ...   Any more matchers to be added. Matchers are invoked in the order they are
 *               specified and only if the preceding matcher fails.
 *               This va-arg must be terminated with a @c nil value.
 *
 *  @return An object conforming to GREYMatcher, initialized with the required matchers.
 */
GREY_EXPORT id<GREYMatcher> grey_anyOf(id<GREYMatcher> match, ...)
    NS_SWIFT_UNAVAILABLE("Use grey_anyOf(_:) instead") NS_REQUIRES_NIL_TERMINATION;

/**
 *  A matcher that is a logical OR of all the matchers passed in within an NSArray.
 *
 *  @param matchers An array of one more matchers to be added. Matchers are invoked in the order
 *                  they are specified and only if the preceding matcher fails.
 *
 *  @return An object conforming to GREYMatcher, initialized with the required matchers.
 */
GREY_EXPORT id<GREYMatcher> grey_anyOfMatchers(NSArray<__kindof id<GREYMatcher>> *matchers)
    NS_SWIFT_NAME(grey_anyOf(_:));

#endif  // GREY_DISABLE_SHORTHAND

NS_ASSUME_NONNULL_END
