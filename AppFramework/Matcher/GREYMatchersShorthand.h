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

#pragma mark - Accessibility Matchers

/** Shorthand for GREYMatchers::matcherForAccessibilityLabel:. */
GREY_EXPORT id<GREYMatcher> grey_accessibilityLabel(NSString *label);
GREY_EXPORT id<GREYMatcher> GREYAccessibilityLabel(NSString *label);

/**
 * Shorthand for GREYMatchers::matcherForAccessibilityID:.
 *
 * @note Even though this mentions "accessibility", the identifier is mainly to be used for UI
 *       testing.
 */
GREY_EXPORT id<GREYMatcher> grey_accessibilityID(NSString *accessibilityID);
GREY_EXPORT id<GREYMatcher> GREYAccessibilityID(NSString *accessibilityID);

/** Shorthand for GREYMatchers::matcherForAccessibilityValue:. */
GREY_EXPORT id<GREYMatcher> grey_accessibilityValue(NSString *grey_accessibilityValue);
GREY_EXPORT id<GREYMatcher> GREYAccessibilityValue(NSString *grey_accessibilityValue);

/** Shorthand for GREYMatchers::matcherForAccessibilityTraits:. */
GREY_EXPORT id<GREYMatcher> grey_accessibilityTrait(UIAccessibilityTraits traits);
GREY_EXPORT id<GREYMatcher> GREYAccessibilityTrait(UIAccessibilityTraits traits);

/** Shorthand for GREYMatchers::matcherForAccessibilityElementIsFocused. */
GREY_EXPORT id<GREYMatcher> grey_accessibilityFocused(void);
GREY_EXPORT id<GREYMatcher> GREYAccessibilityFocused(void);

/** Shorthand for GREYMatchers::matcherForAccessibilityHint:. */
GREY_EXPORT id<GREYMatcher> grey_accessibilityHint(NSString *hint);
GREY_EXPORT id<GREYMatcher> GREYAccessibilityHint(NSString *hint);

/** Shorthand for GREYMatchers::matcherForAccessibilityElement. */
GREY_EXPORT id<GREYMatcher> grey_accessibilityElement(void);
GREY_EXPORT id<GREYMatcher> GREYAccessibilityElement(void);

#pragma mark - UI Property Matchers

/** Shorthand for GREYMatchers::matcherForButtonTitle:. */
GREY_EXPORT id<GREYMatcher> grey_buttonTitle(NSString *text);
GREY_EXPORT id<GREYMatcher> GREYButtonTitle(NSString *text);

/** Shorthand for GREYMatchers::matcherForDatePickerValue:. */
GREY_EXPORT id<GREYMatcher> grey_datePickerValue(NSDate *date);
GREY_EXPORT id<GREYMatcher> GREYDatePickerValue(NSDate *date);

/** Shorthand for GREYMatchers::matcherForEnabledElement. */
GREY_EXPORT id<GREYMatcher> grey_enabled(void);
GREY_EXPORT id<GREYMatcher> GREYEnabled(void);

/** Shorthand for GREYMatchers::matcherForFirstResponder. */
GREY_EXPORT id<GREYMatcher> grey_firstResponder(void);
GREY_EXPORT id<GREYMatcher> GREYFirstResponder(void);

/** Shorthand macro for GREYMatchers::matcherForHidden */
GREY_EXPORT id<GREYMatcher> grey_hidden(BOOL hidden);
GREY_EXPORT id<GREYMatcher> GREYHidden(BOOL hidden);

/** Shorthand for GREYMatchers::matcherForInteractable. */
GREY_EXPORT id<GREYMatcher> grey_interactable(void);
GREY_EXPORT id<GREYMatcher> GREYInteractable(void);

/** Shorthand for GREYMatchers::matcherForLayoutConstraints:toReferenceElementMatching:. */
GREY_EXPORT id<GREYMatcher> grey_layout(NSArray *constraints,
                                        id<GREYMatcher> referenceElementMatcher);
GREY_EXPORT id<GREYMatcher> GREYLayout(NSArray *constraints,
                                       id<GREYMatcher> referenceElementMatcher);

/** Shorthand for GREYMatchers::matcherForMinimumVisiblePercent:. */
GREY_EXPORT id<GREYMatcher> grey_minimumVisiblePercent(CGFloat percent);
GREY_EXPORT id<GREYMatcher> GREYMinimumVisiblePercent(CGFloat percent);

/** Shorthand for GREYMatchers::matcherForNotVisible. */
GREY_EXPORT id<GREYMatcher> grey_notVisible(void);
GREY_EXPORT id<GREYMatcher> GREYNotVisible(void);

/** Shorthand for GREYMatchers::matcherForPickerColumn:setToValue:. */
GREY_EXPORT id<GREYMatcher> grey_pickerColumnSetToValue(NSInteger column,
                                                        NSString *_Nullable value);
GREY_EXPORT id<GREYMatcher> GREYPickerColumnSetToValue(NSInteger column, NSString *_Nullable value);

/** Shorthand for GREYMatchers::matcherForProgress:. */
GREY_EXPORT id<GREYMatcher> grey_progress(id<GREYMatcher> comparisonMatcher);
GREY_EXPORT id<GREYMatcher> GREYProgress(id<GREYMatcher> comparisonMatcher);

/** Shorthand for GREYMatchers::matcherForScrolledToContentEdge:. */
GREY_EXPORT id<GREYMatcher> grey_scrolledToContentEdge(GREYContentEdge edge);
GREY_EXPORT id<GREYMatcher> GREYScrolledToContentEdge(GREYContentEdge edge);

/** Shorthand for GREYMatchers::matcherForScrollViewContentOffset:. */
GREY_EXPORT id<GREYMatcher> grey_scrollViewContentOffset(CGPoint offset);
GREY_EXPORT id<GREYMatcher> GREYScrollViewContentOffset(CGPoint offset);

/** Shorthand for GREYMatchers::matcherForSelectedElement. */
GREY_EXPORT id<GREYMatcher> grey_selected(void);
GREY_EXPORT id<GREYMatcher> GREYSelected(void);

/** Shorthand for GREYMatchers::matcherForSliderValueMatcher:. */
GREY_EXPORT id<GREYMatcher> grey_sliderValueMatcher(id<GREYMatcher> valueMatcher);
GREY_EXPORT id<GREYMatcher> GREYSliderValueMatcher(id<GREYMatcher> valueMatcher);

/** Shorthand for GREYMatchers::matcherForStepperValue:. */
GREY_EXPORT id<GREYMatcher> grey_stepperValue(double value);
GREY_EXPORT id<GREYMatcher> GREYStepperValue(double value);

/** Shorthand for GREYMatchers::matcherForSufficientlyVisible. */
GREY_EXPORT id<GREYMatcher> grey_sufficientlyVisible(void);
GREY_EXPORT id<GREYMatcher> GREYSufficientlyVisible(void);

/** Shorthand for GREYMatchers::matcherForSwitchWithOnState:. */
GREY_EXPORT id<GREYMatcher> grey_switchWithOnState(BOOL on);
GREY_EXPORT id<GREYMatcher> GREYSwitchWithOnState(BOOL on);

/** Shorthand for GREYMatchers::matcherForText:. */
GREY_EXPORT id<GREYMatcher> grey_text(NSString *inputText);
GREY_EXPORT id<GREYMatcher> GREYText(NSString *inputText);

/** Shorthand for GREYMatchers::matcherForTextFieldValue:. */
GREY_EXPORT id<GREYMatcher> grey_textFieldValue(NSString *value);
GREY_EXPORT id<GREYMatcher> GREYTextFieldValue(NSString *value);

/** Shorthand for GREYMatchers::matcherForUserInteractionEnabled. */
GREY_EXPORT id<GREYMatcher> grey_userInteractionEnabled(void);
GREY_EXPORT id<GREYMatcher> GREYUserInteractionEnabled(void);

#pragma mark - Hierarchy Based Matchers

/** Shorthand for GREYMatchers::matcherForAncestor:. */
GREY_EXPORT id<GREYMatcher> grey_ancestor(id<GREYMatcher> ancestorMatcher);
GREY_EXPORT id<GREYMatcher> GREYAncestor(id<GREYMatcher> ancestorMatcher);

/** Shorthand for GREYMatchers::matcherForDescendant:. */
GREY_EXPORT id<GREYMatcher> grey_descendant(id<GREYMatcher> descendantMatcher);
GREY_EXPORT id<GREYMatcher> GREYDescendant(id<GREYMatcher> descendantMatcher);

/** Shorthand for GREYMatchers::matcherForSubview. */
GREY_EXPORT id<GREYMatcher> grey_subview(id<GREYMatcher> subviewMatcher);
GREY_EXPORT id<GREYMatcher> GREYSubview(id<GREYMatcher> subviewMatcher);

/** Shorthand for GREYMatchers::matcherForSibling. */
GREY_EXPORT id<GREYMatcher> grey_sibling(id<GREYMatcher> siblingMatcher);
GREY_EXPORT id<GREYMatcher> GREYSibling(id<GREYMatcher> siblingMatcher);

/** Shorthand for GREYMatchers::matcherForKeyWindow. */
GREY_EXPORT id<GREYMatcher> grey_keyWindow(void);
GREY_EXPORT id<GREYMatcher> GREYKeyWindow(void);

#pragma mark - Class-type Based Matchers

/** Shorthand for GREYMatchers::matcherForConformsToProtocol:. */
GREY_EXPORT id<GREYMatcher> grey_conformsToProtocol(Protocol *protocol);
GREY_EXPORT id<GREYMatcher> GREYConformsToProtocol(Protocol *protocol);

/** Shorthand for GREYMatchers::matcherForKindOfClass:. */
GREY_EXPORT id<GREYMatcher> grey_kindOfClass(Class _Nullable klass);
GREY_EXPORT id<GREYMatcher> GREYKindOfClass(Class _Nullable klass);

/** Shorthand for GREYMatchers::matcherForKindOfClassName:. */
GREY_EXPORT id<GREYMatcher> grey_kindOfClassName(NSString *className);
GREY_EXPORT id<GREYMatcher> GREYKindOfClassName(NSString *className);

/** Shorthand for GREYMatchers::matcherForRespondsToSelector:. */
GREY_EXPORT id<GREYMatcher> grey_respondsToSelector(SEL sel);
GREY_EXPORT id<GREYMatcher> GREYRespondsToSelector(SEL sel);

// Comparison based matchers

/** Shorthand for GREYMatchers::matcherForCloseTo:. */
GREY_EXPORT id<GREYMatcher> grey_closeTo(double value, double delta);
GREY_EXPORT id<GREYMatcher> GREYCloseTo(double value, double delta);

/** Shorthand for GREYMatchers::matcherForEqualTo:. */
GREY_EXPORT id<GREYMatcher> grey_equalTo(id value);
GREY_EXPORT id<GREYMatcher> GREYEqualTo(id value);

/** Shorthand for GREYMatchers::matcherForLessThan:. */
GREY_EXPORT id<GREYMatcher> grey_lessThan(id value);
GREY_EXPORT id<GREYMatcher> GREYLessThan(id value);

/** Shorthand for GREYMatchers::matcherForGreaterThan:. */
GREY_EXPORT id<GREYMatcher> grey_greaterThan(id value);
GREY_EXPORT id<GREYMatcher> GREYGreaterThan(id value);

#pragma mark - Other Matchers

/** Shorthand for GREYMatchers::matcherForAnything. */
GREY_EXPORT id<GREYMatcher> grey_anything(void);
GREY_EXPORT id<GREYMatcher> GREYAnything(void);

/** Shorthand for GREYMatchers::matcherForNil. */
GREY_EXPORT id<GREYMatcher> grey_nil(void);
GREY_EXPORT id<GREYMatcher> GREYNil(void);

/** Shorthand for GREYMatchers::matcherForNotNil. */
GREY_EXPORT id<GREYMatcher> grey_notNil(void);
GREY_EXPORT id<GREYMatcher> GREYNotNil(void);

/** Shorthand for GREYMatchers::matcherForSystemAlertViewShown. */
GREY_EXPORT id<GREYMatcher> grey_systemAlertViewShown(void);
GREY_EXPORT id<GREYMatcher> GREYSystemAlertViewShown(void);

#pragma mark - Clubbing / Logic Matchers

/**
 * A shorthand matcher that is a logical AND of all the matchers passed in as variable arguments.
 *
 * @param matcher The first matcher in the list of matchers.
 * @param ...     Any more matchers to be added. Matchers are invoked in the order they are
 *                specified and only if the preceding matcher passes. This va-arg must be
 *                terminated with a @c nil value.
 *
 * @return An object conforming to GREYMatcher, initialized with the required matchers.
 */
GREY_EXPORT id<GREYMatcher> grey_allOf(id<GREYMatcher> _Nullable matcher, ...)
    NS_SWIFT_UNAVAILABLE("Use grey_allOf(_:) instead") NS_REQUIRES_NIL_TERMINATION;

/**
 * A matcher that is a logical OR of all the matchers passed in as variable arguments.
 *
 * @param match The first matcher in the list of matchers.
 * @param ...   Any more matchers to be added. Matchers are invoked in the order they are
 *              specified and only if the preceding matcher fails.
 *              This va-arg must be terminated with a @c nil value.
 *
 * @return An object conforming to GREYMatcher, initialized with the required matchers.
 */
GREY_EXPORT id<GREYMatcher> grey_anyOf(id<GREYMatcher> match, ...)
    NS_SWIFT_UNAVAILABLE("Use grey_anyOf(_:) instead") NS_REQUIRES_NIL_TERMINATION;

/** Shorthand for GREYMatchers::matcherForNegation:. */
GREY_EXPORT id<GREYMatcher> grey_not(id<GREYMatcher> matcher);
GREY_EXPORT id<GREYMatcher> GREYNot(id<GREYMatcher> matcher);

// Clubbing / Logic Matchers (Swift-Based)

/**
 * A shorthand matcher that is a logical AND of all the matchers passed in within an NSArray.
 *
 * @param matchers An NSArray of one or more matchers to be added. Matchers are invoked in the
 *                 order they are specified and only if the preceding matcher passes.
 *
 * @return An object conforming to GREYMatcher, initialized with the required matchers.
 */
GREY_EXPORT id<GREYMatcher> grey_allOfMatchers(NSArray<__kindof id<GREYMatcher>> *matchers)
    NS_SWIFT_NAME(grey_allOf(_:));
GREY_EXPORT id<GREYMatcher> GREYAllOfMatchers(NSArray<__kindof id<GREYMatcher>> *matchers)
    NS_SWIFT_NAME(GREYAllOf(_:));

/**
 * A matcher that is a logical OR of all the matchers passed in within an NSArray.
 *
 * @param matchers An array of one more matchers to be added. Matchers are invoked in the order
 *                 they are specified and only if the preceding matcher fails.
 *
 * @return An object conforming to GREYMatcher, initialized with the required matchers.
 */
GREY_EXPORT id<GREYMatcher> grey_anyOfMatchers(NSArray<__kindof id<GREYMatcher>> *matchers)
    NS_SWIFT_NAME(grey_anyOf(_:));
GREY_EXPORT id<GREYMatcher> GREYAnyOfMatchers(NSArray<__kindof id<GREYMatcher>> *matchers)
    NS_SWIFT_NAME(GREYAnyOf(_:));

#endif  // GREY_DISABLE_SHORTHAND

NS_ASSUME_NONNULL_END
