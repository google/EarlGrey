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
#import "GREYMatcher.h"

#if !defined(GREY_DISABLE_SHORTHAND) || !(GREY_DISABLE_SHORTHAND)

id<GREYMatcher> grey_keyWindow(void) { return [GREYMatchers matcherForKeyWindow]; }

id<GREYMatcher> grey_accessibilityLabel(NSString *label) {
  return [GREYMatchers matcherForAccessibilityLabel:label];
}

id<GREYMatcher> grey_accessibilityID(NSString *accessibilityID) {
  return [GREYMatchers matcherForAccessibilityID:accessibilityID];
}

id<GREYMatcher> grey_accessibilityValue(NSString *value) {
  return [GREYMatchers matcherForAccessibilityValue:value];
}

id<GREYMatcher> grey_accessibilityTrait(UIAccessibilityTraits traits) {
  return [GREYMatchers matcherForAccessibilityTraits:traits];
}

id<GREYMatcher> grey_accessibilityHint(NSString *hint) {
  return [GREYMatchers matcherForAccessibilityHint:hint];
}

id<GREYMatcher> grey_accessibilityFocused(void) {
  return [GREYMatchers matcherForAccessibilityElementIsFocused];
}

id<GREYMatcher> grey_text(NSString *text) { return [GREYMatchers matcherForText:text]; }

id<GREYMatcher> grey_firstResponder(void) { return [GREYMatchers matcherForFirstResponder]; }

id<GREYMatcher> grey_minimumVisiblePercent(CGFloat percent) {
  return [GREYMatchers matcherForMinimumVisiblePercent:percent];
}

id<GREYMatcher> grey_sufficientlyVisible(void) {
  return [GREYMatchers matcherForSufficientlyVisible];
}

id<GREYMatcher> grey_notVisible(void) { return [GREYMatchers matcherForNotVisible]; }

id<GREYMatcher> grey_interactable(void) { return [GREYMatchers matcherForInteractable]; }

id<GREYMatcher> grey_accessibilityElement(void) {
  return [GREYMatchers matcherForAccessibilityElement];
}

id<GREYMatcher> grey_kindOfClass(Class klass) { return [GREYMatchers matcherForKindOfClass:klass]; }

id<GREYMatcher> grey_kindOfClassName(NSString *className) {
  return [GREYMatchers matcherForKindOfClassName:className];
}

id<GREYMatcher> grey_progress(id<GREYMatcher> comparisonMatcher) {
  return [GREYMatchers matcherForProgress:comparisonMatcher];
}

id<GREYMatcher> grey_respondsToSelector(SEL sel) {
  return [GREYMatchers matcherForRespondsToSelector:sel];
}

id<GREYMatcher> grey_conformsToProtocol(Protocol *protocol) {
  return [GREYMatchers matcherForConformsToProtocol:protocol];
}

id<GREYMatcher> grey_ancestor(id<GREYMatcher> matcher) {
  return [GREYMatchers matcherForAncestor:matcher];
}

id<GREYMatcher> grey_descendant(id<GREYMatcher> matcher) {
  return [GREYMatchers matcherForDescendant:matcher];
}

id<GREYMatcher> grey_buttonTitle(NSString *text) {
  return [GREYMatchers matcherForButtonTitle:text];
}

id<GREYMatcher> grey_scrollViewContentOffset(CGPoint offset) {
  return [GREYMatchers matcherForScrollViewContentOffset:offset];
}

id<GREYMatcher> grey_sliderValueMatcher(id<GREYMatcher> valueMatcher) {
  return [GREYMatchers matcherForSliderValueMatcher:valueMatcher];
}

id<GREYMatcher> grey_stepperValue(double value) {
  return [GREYMatchers matcherForStepperValue:value];
}

id<GREYMatcher> grey_pickerColumnSetToValue(NSInteger column, NSString *value) {
  return [GREYMatchers matcherForPickerColumn:column setToValue:value];
}

id<GREYMatcher> grey_systemAlertViewShown(void) {
  return [GREYMatchers matcherForSystemAlertViewShown];
}

id<GREYMatcher> grey_datePickerValue(NSDate *value) {
  return [GREYMatchers matcherForDatePickerValue:value];
}

id<GREYMatcher> grey_enabled(void) { return [GREYMatchers matcherForEnabledElement]; }

id<GREYMatcher> grey_selected(void) { return [GREYMatchers matcherForSelectedElement]; }

id<GREYMatcher> grey_userInteractionEnabled(void) {
  return [GREYMatchers matcherForUserInteractionEnabled];
}

id<GREYMatcher> grey_layout(NSArray *constraints, id<GREYMatcher> referenceElementMatcher) {
  return [GREYMatchers matcherForLayoutConstraints:constraints
                        toReferenceElementMatching:referenceElementMatcher];
}

id<GREYMatcher> grey_nil(void) { return [GREYMatchers matcherForNil]; }

id<GREYMatcher> grey_notNil(void) { return [GREYMatchers matcherForNotNil]; }

id<GREYMatcher> grey_switchWithOnState(BOOL on) {
  return [GREYMatchers matcherForSwitchWithOnState:on];
}

id<GREYMatcher> grey_closeTo(double value, double delta) {
  return [GREYMatchers matcherForCloseTo:value delta:delta];
}

id<GREYMatcher> grey_anything(void) { return [GREYMatchers matcherForAnything]; }

id<GREYMatcher> grey_equalTo(id value) { return [GREYMatchers matcherForEqualTo:value]; }

id<GREYMatcher> grey_lessThan(id value) { return [GREYMatchers matcherForLessThan:value]; }

id<GREYMatcher> grey_greaterThan(id value) { return [GREYMatchers matcherForGreaterThan:value]; }

id<GREYMatcher> grey_scrolledToContentEdge(GREYContentEdge edge) {
  return [GREYMatchers matcherForScrolledToContentEdge:edge];
}

id<GREYMatcher> grey_textFieldValue(NSString *value) {
  return [GREYMatchers matcherForTextFieldValue:value];
}

id<GREYMatcher> grey_anyOf(id<GREYMatcher> matcher, ...) {
  va_list args;
  va_start(args, matcher);

  NSMutableArray *matcherList = [[NSMutableArray alloc] init];
  id<GREYMatcher> nextMatcher = matcher;
  do {
    [matcherList addObject:nextMatcher];
  } while ((nextMatcher = va_arg(args, id<GREYMatcher>)) != nil);

  va_end(args);
  return [[GREYAnyOf alloc] initWithMatchers:matcherList];
}

id<GREYMatcher> grey_anyOfMatchers(NSArray<GREYMatcher> *matchers) {
  return [[GREYAnyOf alloc] initWithMatchers:matchers];
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
  return [[GREYAllOf alloc] initWithMatchers:matcherList];
}

id<GREYMatcher> grey_allOfMatchers(NSArray<GREYMatcher> *matchers) {
  return [[GREYAllOf alloc] initWithMatchers:matchers];
}

id<GREYMatcher> grey_not(id<GREYMatcher> matcher) {
  return [GREYMatchers matcherForNegation:matcher];
}

#endif  // GREY_DISABLE_SHORTHAND
