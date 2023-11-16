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

#import "GREYMatchersShorthand.h"

#import "GREYAllOf.h"
#import "GREYAnyOf.h"
#import "GREYMatchers.h"
#import "GREYDistantObjectUtils.h"
#import "GREYMatcher.h"
#import "NSObject+EDOValueObject.h"

#if !defined(GREY_DISABLE_SHORTHAND) || !(GREY_DISABLE_SHORTHAND)

id<GREYMatcher> GREYKeyWindow(void) { return [GREYMatchers matcherForKeyWindow]; }
id<GREYMatcher> grey_keyWindow(void) { return GREYKeyWindow(); }

id<GREYMatcher> GREYAccessibilityLabel(NSString *label) {
  return [GREYMatchers matcherForAccessibilityLabel:label];
}
id<GREYMatcher> grey_accessibilityLabel(NSString *label) { return GREYAccessibilityLabel(label); }

id<GREYMatcher> GREYAccessibilityID(NSString *accessibilityID) {
  return [GREYMatchers matcherForAccessibilityID:accessibilityID];
}
id<GREYMatcher> grey_accessibilityID(NSString *accessibilityID) {
  return GREYAccessibilityID(accessibilityID);
}

id<GREYMatcher> GREYAccessibilityValue(NSString *value) {
  return [GREYMatchers matcherForAccessibilityValue:value];
}
id<GREYMatcher> grey_accessibilityValue(NSString *value) { return GREYAccessibilityValue(value); }

id<GREYMatcher> GREYAccessibilityTrait(UIAccessibilityTraits traits) {
  return [GREYMatchers matcherForAccessibilityTraits:traits];
}

id<GREYMatcher> grey_accessibilityTrait(UIAccessibilityTraits traits) {
  return GREYAccessibilityTrait(traits);
}

id<GREYMatcher> GREYAccessibilityHint(NSString *hint) {
  return [GREYMatchers matcherForAccessibilityHint:hint];
}
id<GREYMatcher> grey_accessibilityHint(NSString *hint) { return GREYAccessibilityHint(hint); }

id<GREYMatcher> GREYAccessibilityFocused(void) {
  return [GREYMatchers matcherForAccessibilityElementIsFocused];
}
id<GREYMatcher> grey_accessibilityFocused(void) { return GREYAccessibilityFocused(); }

id<GREYMatcher> GREYText(NSString *text) { return [GREYMatchers matcherForText:text]; }
id<GREYMatcher> grey_text(NSString *text) { return GREYText(text); }

id<GREYMatcher> GREYFirstResponder(void) { return [GREYMatchers matcherForFirstResponder]; }
id<GREYMatcher> grey_firstResponder(void) { return GREYFirstResponder(); }

id<GREYMatcher> GREYMinimumVisiblePercent(CGFloat percent) {
  return [GREYMatchers matcherForMinimumVisiblePercent:percent];
}
id<GREYMatcher> grey_minimumVisiblePercent(CGFloat percent) {
  return GREYMinimumVisiblePercent(percent);
}

id<GREYMatcher> GREYSufficientlyVisible(void) {
  return [GREYMatchers matcherForSufficientlyVisible];
}
id<GREYMatcher> grey_sufficientlyVisible(void) { return GREYSufficientlyVisible(); }

id<GREYMatcher> GREYNotVisible(void) { return [GREYMatchers matcherForNotVisible]; }
id<GREYMatcher> grey_notVisible(void) { return GREYNotVisible(); }

id<GREYMatcher> GREYInteractable(void) { return [GREYMatchers matcherForInteractable]; }
id<GREYMatcher> grey_interactable(void) { return GREYInteractable(); }

id<GREYMatcher> GREYAccessibilityElement(void) {
  return [GREYMatchers matcherForAccessibilityElement];
}
id<GREYMatcher> grey_accessibilityElement(void) { return GREYAccessibilityElement(); }

id<GREYMatcher> GREYKindOfClass(Class klass) { return [GREYMatchers matcherForKindOfClass:klass]; }
id<GREYMatcher> grey_kindOfClass(Class klass) { return GREYKindOfClass(klass); }

id<GREYMatcher> GREYKindOfClassName(NSString *className) {
  return [GREYMatchers matcherForKindOfClassName:className];
}
id<GREYMatcher> grey_kindOfClassName(NSString *className) { return GREYKindOfClassName(className); }

id<GREYMatcher> GREYProgress(id<GREYMatcher> comparisonMatcher) {
  return [GREYMatchers matcherForProgress:comparisonMatcher];
}
id<GREYMatcher> grey_progress(id<GREYMatcher> comparisonMatcher) {
  return GREYProgress(comparisonMatcher);
}

id<GREYMatcher> GREYRespondsToSelector(SEL sel) {
  return [GREYMatchers matcherForRespondsToSelector:sel];
}
id<GREYMatcher> grey_respondsToSelector(SEL sel) { return GREYRespondsToSelector(sel); }

id<GREYMatcher> GREYConformsToProtocol(Protocol *protocol) {
  return [GREYMatchers matcherForConformsToProtocol:protocol];
}
id<GREYMatcher> grey_conformsToProtocol(Protocol *protocol) {
  return GREYConformsToProtocol(protocol);
}

id<GREYMatcher> GREYAncestor(id<GREYMatcher> matcher) {
  return [GREYMatchers matcherForAncestor:matcher];
}
id<GREYMatcher> grey_ancestor(id<GREYMatcher> matcher) { return GREYAncestor(matcher); }

id<GREYMatcher> GREYDescendant(id<GREYMatcher> matcher) {
  return [GREYMatchers matcherForDescendant:matcher];
}
id<GREYMatcher> grey_descendant(id<GREYMatcher> matcher) { return GREYDescendant(matcher); }

id<GREYMatcher> GREYButtonTitle(NSString *text) {
  return [GREYMatchers matcherForButtonTitle:text];
}
id<GREYMatcher> grey_buttonTitle(NSString *text) { return GREYButtonTitle(text); }

id<GREYMatcher> GREYScrollViewContentOffset(CGPoint offset) {
  return [GREYMatchers matcherForScrollViewContentOffset:offset];
}
id<GREYMatcher> grey_scrollViewContentOffset(CGPoint offset) {
  return GREYScrollViewContentOffset(offset);
}

id<GREYMatcher> GREYSliderValueMatcher(id<GREYMatcher> valueMatcher) {
  return [GREYMatchers matcherForSliderValueMatcher:valueMatcher];
}
id<GREYMatcher> grey_sliderValueMatcher(id<GREYMatcher> valueMatcher) {
  return GREYSliderValueMatcher(valueMatcher);
}

id<GREYMatcher> GREYStepperValue(double value) {
  return [GREYMatchers matcherForStepperValue:value];
}
id<GREYMatcher> grey_stepperValue(double value) { return GREYStepperValue(value); }

id<GREYMatcher> GREYPickerColumnSetToValue(NSInteger column, NSString *value) {
  return [GREYMatchers matcherForPickerColumn:column setToValue:value];
}
id<GREYMatcher> grey_pickerColumnSetToValue(NSInteger column, NSString *value) {
  return GREYPickerColumnSetToValue(column, value);
}

id<GREYMatcher> GREYSystemAlertViewShown(void) {
  return [GREYMatchers matcherForSystemAlertViewShown];
}
id<GREYMatcher> grey_systemAlertViewShown(void) { return GREYSystemAlertViewShown(); }

id<GREYMatcher> GREYDatePickerValue(NSDate *value) {
  return [GREYMatchers matcherForDatePickerValue:value];
}
id<GREYMatcher> grey_datePickerValue(NSDate *value) { return GREYDatePickerValue(value); }

id<GREYMatcher> GREYEnabled(void) { return [GREYMatchers matcherForEnabledElement]; }
id<GREYMatcher> grey_enabled(void) { return GREYEnabled(); }

id<GREYMatcher> GREYSelected(void) { return [GREYMatchers matcherForSelectedElement]; }
id<GREYMatcher> grey_selected(void) { return GREYSelected(); }

id<GREYMatcher> GREYUserInteractionEnabled(void) {
  return [GREYMatchers matcherForUserInteractionEnabled];
}
id<GREYMatcher> grey_userInteractionEnabled(void) { return GREYUserInteractionEnabled(); }

id<GREYMatcher> GREYLayout(NSArray *constraints, id<GREYMatcher> referenceElementMatcher) {
  NSArray<GREYLayoutConstraint *> *appConstraints =
      GREYIsTestProcess() ? [constraints passByValue] : constraints;
  return [GREYMatchers matcherForLayoutConstraints:appConstraints
                        toReferenceElementMatching:referenceElementMatcher];
}
id<GREYMatcher> grey_layout(NSArray *constraints, id<GREYMatcher> referenceElementMatcher) {
  return GREYLayout(constraints, referenceElementMatcher);
}

id<GREYMatcher> GREYNil(void) { return [GREYMatchers matcherForNil]; }
id<GREYMatcher> grey_nil(void) { return GREYNil(); }

id<GREYMatcher> GREYNotNil(void) { return [GREYMatchers matcherForNotNil]; }
id<GREYMatcher> grey_notNil(void) { return GREYNotNil(); }

id<GREYMatcher> GREYSwitchWithOnState(BOOL on) {
  return [GREYMatchers matcherForSwitchWithOnState:on];
}
id<GREYMatcher> grey_switchWithOnState(BOOL on) { return GREYSwitchWithOnState(on); }

id<GREYMatcher> GREYCloseTo(double value, double delta) {
  return [GREYMatchers matcherForCloseTo:value delta:delta];
}
id<GREYMatcher> grey_closeTo(double value, double delta) { return GREYCloseTo(value, delta); }

id<GREYMatcher> GREYAnything(void) { return [GREYMatchers matcherForAnything]; }
id<GREYMatcher> grey_anything(void) { return GREYAnything(); }

id<GREYMatcher> GREYEqualTo(id value) { return [GREYMatchers matcherForEqualTo:value]; }
id<GREYMatcher> grey_equalTo(id value) { return GREYEqualTo(value); }

id<GREYMatcher> GREYLessThan(id value) { return [GREYMatchers matcherForLessThan:value]; }
id<GREYMatcher> grey_lessThan(id value) { return GREYLessThan(value); }

id<GREYMatcher> GREYGreaterThan(id value) { return [GREYMatchers matcherForGreaterThan:value]; }
id<GREYMatcher> grey_greaterThan(id value) { return GREYGreaterThan(value); }

id<GREYMatcher> GREYScrolledToContentEdge(GREYContentEdge edge) {
  return [GREYMatchers matcherForScrolledToContentEdge:edge];
}
id<GREYMatcher> grey_scrolledToContentEdge(GREYContentEdge edge) {
  return GREYScrolledToContentEdge(edge);
}

id<GREYMatcher> GREYTextFieldValue(NSString *value) {
  return [GREYMatchers matcherForTextFieldValue:value];
}
id<GREYMatcher> grey_textFieldValue(NSString *value) { return GREYTextFieldValue(value); }

#pragma mark - Compound Matchers.

id<GREYMatcher> grey_anyOf(id<GREYMatcher> matcher, ...) {
  va_list args;
  va_start(args, matcher);

  NSMutableArray *matcherList = [[NSMutableArray alloc] init];
  id<GREYMatcher> nextMatcher = matcher;
  do {
    [matcherList addObject:nextMatcher];
  } while ((nextMatcher = va_arg(args, id<GREYMatcher>)) != nil);

  va_end(args);
  return GREYAnyOfMatchers(matcherList);
}

id<GREYMatcher> GREYAnyOfMatchers(NSArray<GREYMatcher> *matchers) {
  NSArray<id<GREYMatcher>> *appMatchers =
      GREYIsTestProcess() ? GREYGetRemoteArrayShallowCopy(matchers) : matchers;
  return [[GREYAnyOf alloc] initWithMatchers:appMatchers];
}
id<GREYMatcher> grey_anyOfMatchers(NSArray<GREYMatcher> *matchers) {
  return GREYAnyOfMatchers(matchers);
}

id<GREYMatcher> grey_allOf(id<GREYMatcher> matcher, ...) {
  va_list args;
  va_start(args, matcher);

  NSMutableArray *matcherList = [[NSMutableArray alloc] init];
  id<GREYMatcher> nextMatcher = matcher;
  do {
    [matcherList addObject:nextMatcher];
  } while ((nextMatcher = va_arg(args, id<GREYMatcher>)) != nil);

  va_end(args);
  return GREYAllOfMatchers(matcherList);
}

id<GREYMatcher> GREYAllOfMatchers(NSArray<GREYMatcher> *matchers) {
  NSArray<id<GREYMatcher>> *appMatchers =
      GREYIsTestProcess() ? GREYGetRemoteArrayShallowCopy(matchers) : matchers;
  return [[GREYAllOf alloc] initWithMatchers:appMatchers];
}
id<GREYMatcher> grey_allOfMatchers(NSArray<GREYMatcher> *matchers) {
  return GREYAllOfMatchers(matchers);
}

id<GREYMatcher> GREYNot(id<GREYMatcher> matcher) {
  return [GREYMatchers matcherForNegation:matcher];
}
id<GREYMatcher> grey_not(id<GREYMatcher> matcher) { return GREYNot(matcher); }

id<GREYMatcher> GREYHidden(BOOL hidden) { return [GREYMatchers matcherForHidden:hidden]; }
id<GREYMatcher> grey_hidden(BOOL hidden) { return GREYHidden(hidden); }

id<GREYMatcher> GREYSubview(id<GREYMatcher> matcher) {
  return [GREYMatchers matcherForSubview:matcher];
}
id<GREYMatcher> grey_subview(id<GREYMatcher> matcher) { return GREYSubview(matcher); }

id<GREYMatcher> GREYSibling(id<GREYMatcher> matcher) {
  return [GREYMatchers matcherForSibling:matcher];
}
id<GREYMatcher> grey_sibling(id<GREYMatcher> matcher) { return GREYSibling(matcher); }
#endif  // GREY_DISABLE_SHORTHAND
