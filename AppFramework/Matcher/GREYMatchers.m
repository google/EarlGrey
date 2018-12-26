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

#import "AppFramework/Matcher/GREYMatchers.h"

#import <UIKit/UIKit.h>

#include <objc/runtime.h>
#include <tgmath.h>

#import "AppFramework/Additions/UISwitch+GREYApp.h"
#import "AppFramework/Core/GREYElementInteraction+Internal.h"
#import "AppFramework/Core/GREYElementInteraction.h"
#import "AppFramework/Matcher/GREYAllOf.h"
#import "AppFramework/Matcher/GREYAnyOf.h"
#import "AppFramework/Matcher/GREYElementMatcherBlock.h"
#import "AppFramework/Matcher/GREYNot.h"
#import "CommonLib/Additions/NSString+GREYCommon.h"
#import "CommonLib/Assertion/GREYFatalAsserts.h"
#import "CommonLib/Assertion/GREYThrowDefines.h"
#import "CommonLib/Error/GREYError.h"
#import "CommonLib/GREYAppleInternals.h"
#import "CommonLib/Matcher/GREYLayoutConstraint.h"
#import "CommonLib/Matcher/GREYMatcher.h"
#import "UILib/GREYVisibilityChecker.h"
#import "UILib/Provider/GREYElementProvider.h"
#import "UILib/Provider/GREYUIWindowProvider.h"

// The minimum percentage of an element's accessibility frame that must be visible before EarlGrey
// considers the element to be sufficiently visible.
static const double kElementSufficientlyVisiblePercentage = 0.75;

// Expose method for EDOObject as it's not a public class.
@interface NSObject (GREYExposed)
@property(readonly) NSString *className;
@end

// EDOObject class as it's private.
static Class gEDOObjectClass;

@implementation GREYMatchers

+ (void)initialize {
  if (self == [GREYMatchers class]) {
    gEDOObjectClass = NSClassFromString(@"EDOObject");
  }
}

+ (id<GREYMatcher>)matcherForKeyWindow {
  GREYMatchesBlock matches = ^BOOL(UIWindow *element) {
    if (element == [UIApplication sharedApplication].keyWindow) {
      return YES;
    }
    return [element isEqual:[UIApplication sharedApplication].keyWindow];
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:@"keyWindow"];
  };
  NSArray *matchersArray = @[
    [GREYMatchers matcherForKindOfClass:[UIWindow class]],
    [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe],
  ];
  return [[GREYAllOf alloc] initWithMatchers:matchersArray];
}

+ (id<GREYMatcher>)matcherForCloseTo:(double)value delta:(double)delta {
  GREYMatchesBlock matches = ^BOOL(id element) {
    return fabs([element doubleValue] - value) <= delta;
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    NSString *string =
        [NSString stringWithFormat:@"a numeric value close to delta(%lf) from (%lf)", delta, value];
    [description appendText:string];
  };
  return [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe];
}

+ (id<GREYMatcher>)matcherForAnything {
  GREYMatchesBlock matches = ^BOOL(id element) {
    return YES;
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:@"anything"];
  };
  return [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe];
}
+ (id<GREYMatcher>)matcherForEqualTo:(id)value {
  GREYMatchesBlock matches = ^BOOL(id element) {
    if (element) {
      return [element isEqual:value];
    } else {
      return element == value;
    }
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:[NSString stringWithFormat:@"equalTo(%@)", value]];
  };
  return [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe];
}

+ (id<GREYMatcher>)matcherForLessThan:(id)value {
  GREYMatchesBlock matches = ^BOOL(id element) {
    return [value compare:element] == NSOrderedDescending;
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:[NSString stringWithFormat:@"a value less than %@", value]];
  };
  return [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe];
}

+ (id<GREYMatcher>)matcherForGreaterThan:(id)value {
  GREYMatchesBlock matches = ^BOOL(id element) {
    return [value compare:element] == NSOrderedAscending;
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:[NSString stringWithFormat:@"a value greater than %@", value]];
  };
  return [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe];
}

+ (id<GREYMatcher>)matcherForAccessibilityLabel:(NSString *)label {
  GREYMatchesBlock matches = ^BOOL(NSObject *element) {
    return [self grey_accessibilityString:element.accessibilityLabel
             isEqualToAccessibilityString:label];
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:[NSString stringWithFormat:@"accessibilityLabel('%@')", label]];
  };
  NSArray *matchersArray = @[
    [GREYMatchers matcherForAccessibilityElement],
    [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe],
  ];
  return [[GREYAllOf alloc] initWithMatchers:matchersArray];
}

+ (id<GREYMatcher>)matcherForAccessibilityID:(NSString *)accessibilityID {
  GREYMatchesBlock matches = ^BOOL(id<UIAccessibilityIdentification> element) {
    if (element.accessibilityIdentifier == accessibilityID) {
      return YES;
    }

    if( [element.accessibilityIdentifier respondsToSelector:@selector(isEqualToString:)]){
      return [element.accessibilityIdentifier isEqualToString:accessibilityID];
    }
    return NO;
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:[NSString stringWithFormat:@"accessibilityID('%@')", accessibilityID]];
  };
  NSArray *matchersArray = @[
    [GREYMatchers matcherForRespondsToSelector:@selector(accessibilityIdentifier)],
    [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe],
  ];
  return [[GREYAllOf alloc] initWithMatchers:matchersArray];
}

+ (id<GREYMatcher>)matcherForAccessibilityValue:(NSString *)value {
  GREYMatchesBlock matches = ^BOOL(NSObject *element) {
    if (element.accessibilityValue == value) {
      return YES;
    }
    return [self grey_accessibilityString:element.accessibilityValue
             isEqualToAccessibilityString:value];
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:[NSString stringWithFormat:@"accessibilityValue('%@')", value]];
  };
  NSArray *matchersArray = @[
    [GREYMatchers matcherForAccessibilityElement],
    [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe],
  ];
  return [[GREYAllOf alloc] initWithMatchers:matchersArray];
}

+ (id<GREYMatcher>)matcherForAccessibilityTraits:(UIAccessibilityTraits)traits {
  GREYMatchesBlock matches = ^BOOL(NSObject *element) {
    return ([element accessibilityTraits] & traits) != 0;
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    NSString *traitsString = NSStringFromUIAccessibilityTraits(traits);
    [description appendText:[NSString stringWithFormat:@"accessibilityTraits: %@", traitsString]];
  };
  NSArray *matchersArray = @[
    [GREYMatchers matcherForAccessibilityElement],
    [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe],
  ];
  return [[GREYAllOf alloc] initWithMatchers:matchersArray];
}

+ (id<GREYMatcher>)matcherForAccessibilityHint:(id)hint {
  GREYMatchesBlock matches = ^BOOL(NSObject *element) {
    id accessibilityHint = element.accessibilityHint;
    if (accessibilityHint == hint) {
      return YES;
    }
    return [self grey_accessibilityString:accessibilityHint isEqualToAccessibilityString:hint];
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:[NSString stringWithFormat:@"accessibilityHint('%@')", hint]];
  };
  NSArray *matchersArray = @[
    [GREYMatchers matcherForAccessibilityElement],
    [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe],
  ];
  return [[GREYAllOf alloc] initWithMatchers:matchersArray];
}

+ (id<GREYMatcher>)matcherForAccessibilityElementIsFocused {
  GREYMatchesBlock matches = ^BOOL(NSObject *element) {
    return [element accessibilityElementIsFocused];
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:@"accessibilityFocused"];
  };
  id<GREYMatcher> matcher =
      [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe];
  NSArray *matchersArray = @[
    [GREYMatchers matcherForRespondsToSelector:@selector(accessibilityElementIsFocused)],
    matcher,
  ];
  return [[GREYAllOf alloc] initWithMatchers:matchersArray];
}

+ (id<GREYMatcher>)matcherForText:(NSString *)text {
  GREYMatchesBlock matches = ^BOOL(id element) {
    return [[element text] isEqualToString:text];
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:[NSString stringWithFormat:@"hasText('%@')", text]];
  };
  id<GREYMatcher> matcher =
      [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe];
  NSArray *anyOfmatchersArray = @[
    [GREYMatchers matcherForKindOfClass:[UILabel class]],
    [GREYMatchers matcherForKindOfClass:[UITextField class]],
    [GREYMatchers matcherForKindOfClass:[UITextView class]],
  ];
  NSArray *matchersArray = @[
    [[GREYAnyOf alloc] initWithMatchers:anyOfmatchersArray],
    matcher,
  ];
  return [[GREYAllOf alloc] initWithMatchers:matchersArray];
}

+ (id<GREYMatcher>)matcherForFirstResponder {
  GREYMatchesBlock matches = ^BOOL(UIResponder *element) {
    return [element isFirstResponder];
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:@"firstResponder"];
  };
  NSArray *matchersArray = @[
    [GREYMatchers matcherForKindOfClass:[UIResponder class]],
    [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe],
  ];
  return [[GREYAllOf alloc] initWithMatchers:matchersArray];
}

+ (id<GREYMatcher>)matcherForSystemAlertViewShown {
  GREYMatchesBlock matches = ^BOOL(id element) {
    return ([[UIApplication sharedApplication] _isSpringBoardShowingAnAlert] &&
            ![[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.springboard"]);
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:@"isSystemAlertViewShown"];
  };
  return [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe];
}

+ (id<GREYMatcher>)matcherForMinimumVisiblePercent:(CGFloat)percent {
  GREYFatalAssertWithMessage(percent >= 0.0f && percent <= 1.0f,
                             @"Percent %f must be in the range [0,1]", percent);
  GREYMatchesBlock matches = ^BOOL(UIView *element) {
    return [GREYVisibilityChecker percentVisibleAreaOfElement:element] > percent;
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description
        appendText:[NSString stringWithFormat:@"matcherForMinimumVisiblePercent(>=%f)", percent]];
  };
  return [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe];
}

+ (id<GREYMatcher>)matcherForSufficientlyVisible {
  GREYMatchesBlock matches = ^BOOL(UIView *element) {
    CGFloat percent = [GREYVisibilityChecker percentVisibleAreaOfElement:element];
    return (percent >= kElementSufficientlyVisiblePercentage);
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:[NSString stringWithFormat:@"matcherForSufficientlyVisible(>=%f)",
                                                       kElementSufficientlyVisiblePercentage]];
  };
  return [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe];
}

+ (id<GREYMatcher>)matcherForInteractable {
  GREYMatchesBlock matches = ^BOOL(UIView *element) {
    return [GREYVisibilityChecker isVisibleForInteraction:element];
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:@"interactable"];
  };
  return [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe];
}

+ (id<GREYMatcher>)matcherForNotVisible {
  GREYMatchesBlock matches = ^BOOL(UIView *element) {
    return [GREYVisibilityChecker isNotVisible:element];
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:@"notVisible"];
  };
  return [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe];
}

+ (id<GREYMatcher>)matcherForAccessibilityElement {
  GREYMatchesBlock matches = ^BOOL(id element) {
    return [element isAccessibilityElement];
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:@"isAccessibilityElement"];
  };
  NSArray *matchersArray = @[
    [GREYMatchers matcherForRespondsToSelector:@selector(isAccessibilityElement)],
    [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe],
  ];
  return [[GREYAllOf alloc] initWithMatchers:matchersArray];
}

+ (id<GREYMatcher>)matcherForKindOfClass:(Class)klass {
  GREYMatchesBlock matches;
  NSString *className;
  Class localClass;
  if (object_getClass(klass) == gEDOObjectClass) {
    className = [klass className];
    localClass = NSClassFromString(className);
    GREYThrowOnFailedConditionWithMessage(localClass, @"The class from remote cannot be nil");
  } else {
    className = NSStringFromClass(klass);
    localClass = klass;
  }
  matches = ^BOOL(id element) {
    return [element isKindOfClass:localClass];
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:[NSString stringWithFormat:@"kindOfClass('%@')", className]];
  };
  return [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe];
}

+ (id<GREYMatcher>)matcherForKindOfClassName:(NSString *)className {
  GREYThrowOnFailedConditionWithMessage(NSClassFromString(className),
                                        @"The class obtained from the class name cannot be nil");
  return [self matcherForKindOfClass:NSClassFromString(className)];
}

+ (id<GREYMatcher>)matcherForProgress:(id<GREYMatcher>)comparisonMatcher {
  GREYMatchesBlock matches = ^BOOL(UIProgressView *element) {
    return [comparisonMatcher matches:@(element.progress)];
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:[NSString stringWithFormat:@"progressValueThatMatches('%@')",
                                                       comparisonMatcher]];
  };
  NSArray *matchersArray = @[
    [GREYMatchers matcherForKindOfClass:[UIProgressView class]],
    [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe],
  ];
  return [[GREYAllOf alloc] initWithMatchers:matchersArray];
}

+ (id<GREYMatcher>)matcherForRespondsToSelector:(SEL)sel {
  GREYMatchesBlock matches = ^BOOL(id element) {
    return [element respondsToSelector:sel];
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:[NSString stringWithFormat:@"respondsToSelector(%@)",
                                                       NSStringFromSelector(sel)]];
  };
  return [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe];
}

+ (id<GREYMatcher>)matcherForConformsToProtocol:(Protocol *)protocol {
  GREYMatchesBlock matches = ^BOOL(id element) {
    return [element conformsToProtocol:protocol];
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:[NSString stringWithFormat:@"conformsToProtocol(%@)",
                                                       NSStringFromProtocol(protocol)]];
  };
  return [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe];
}

+ (id<GREYMatcher>)matcherForAncestor:(id<GREYMatcher>)ancestorMatcher {
  GREYMatchesBlock matches = ^BOOL(id element) {
    id parent = element;
    while (parent) {
      if ([parent isKindOfClass:[UIView class]]) {
        parent = [parent superview];
      } else {
        parent = [parent accessibilityContainer];
      }
      if (parent && [ancestorMatcher matches:parent]) {
        return YES;
      }
    }
    return NO;
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description
        appendText:[NSString stringWithFormat:@"ancestorThatMatches(%@)", ancestorMatcher]];
  };
  NSArray *anyOfMatchers = @[
    [GREYMatchers matcherForKindOfClass:[UIView class]],
    [GREYMatchers matcherForRespondsToSelector:@selector(accessibilityContainer)],
  ];
  NSArray *matchersArray = @[
    [[GREYAnyOf alloc] initWithMatchers:anyOfMatchers],
    [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe]
  ];
  return [[GREYAllOf alloc] initWithMatchers:matchersArray];
}

+ (id<GREYMatcher>)matcherForDescendant:(id<GREYMatcher>)descendantMatcher {
  GREYMatchesBlock matches = ^BOOL(id element) {
    if (element == nil) {
      return NO;
    }

    GREYElementProvider *elementProvider =
        [[GREYElementProvider alloc] initWithRootElements:@[ element ]];
    NSEnumerator *elementEnumerator = [elementProvider dataEnumerator];
    id child;
    while (child = [elementEnumerator nextObject]) {
      if ([descendantMatcher matches:child] && child != element) {
        return YES;
      }
    }
    return NO;
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description
        appendText:[NSString stringWithFormat:@"descendantThatMatches(%@)", descendantMatcher]];
  };
  return [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe];
}

+ (id<GREYMatcher>)matcherForButtonTitle:(NSString *)title {
  GREYMatchesBlock matches = ^BOOL(UIButton *element) {
    if (element.titleLabel.text == title) {
      return YES;
    }
    return [element.titleLabel.text isEqualToString:title];
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:[NSString stringWithFormat:@"buttonTitle('%@')", title]];
  };
  NSArray *matchersArray = @[
    [GREYMatchers matcherForKindOfClass:[UIButton class]],
    [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe],
  ];
  return [[GREYAllOf alloc] initWithMatchers:matchersArray];
}

+ (id<GREYMatcher>)matcherForScrollViewContentOffset:(CGPoint)offset {
  GREYMatchesBlock matches = ^BOOL(UIScrollView *element) {
    return CGPointEqualToPoint([element contentOffset], offset);
  };
  GREYDescribeToBlock describe = ^(id<GREYDescription> description) {
    NSString *desc = [NSString stringWithFormat:@"contentOffset(%@)", NSStringFromCGPoint(offset)];
    [description appendText:desc];
  };
  NSArray *matchersArray = @[
    [GREYMatchers matcherForKindOfClass:[UIScrollView class]],
    [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe],
  ];
  return [[GREYAllOf alloc] initWithMatchers:matchersArray];
}

+ (id<GREYMatcher>)matcherForSliderValueMatcher:(id<GREYMatcher>)valueMatcher {
  GREYMatchesBlock matches = ^BOOL(UISlider *element) {
    return [valueMatcher matches:@(element.value)];
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:[NSString stringWithFormat:@"sliderValueMatcher:(%@)", valueMatcher]];
  };
  NSArray *matchersArray = @[
    [GREYMatchers matcherForKindOfClass:[UISlider class]],
    [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe],
  ];
  return [[GREYAllOf alloc] initWithMatchers:matchersArray];
}

+ (id<GREYMatcher>)matcherForStepperValue:(double)value {
  GREYMatchesBlock matches = ^BOOL(UIStepper *element) {
    return element.value == value;
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:[NSString stringWithFormat:@"stepperValue(%lf)", value]];
  };
  NSArray *matchersArray = @[
    [GREYMatchers matcherForKindOfClass:[UIStepper class]],
    [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe],
  ];
  return [[GREYAllOf alloc] initWithMatchers:matchersArray];
}

+ (id<GREYMatcher>)matcherForPickerColumn:(NSInteger)column setToValue:(NSString *)value {
  GREYMatchesBlock matches = ^BOOL(UIPickerView *element) {
    if ([element numberOfComponents] < column) {
      return NO;
    }
    NSInteger row = [element selectedRowInComponent:column];
    NSAttributedString *attributedRowLabel;
    NSString *rowLabel;
    id<UIPickerViewDelegate> delegate = element.delegate;
    SEL attributedTitleSelector = @selector(pickerView:attributedTitleForRow:forComponent:);
    SEL nonAttributedTitleSelector = @selector(pickerView:titleForRow:forComponent:);
    if ([delegate respondsToSelector:attributedTitleSelector]) {
      attributedRowLabel =
          [delegate pickerView:element attributedTitleForRow:row forComponent:column];
      if (attributedRowLabel == nil) {
        rowLabel = [delegate pickerView:element titleForRow:row forComponent:column];
      }
    } else if ([delegate respondsToSelector:nonAttributedTitleSelector]) {
      rowLabel = [delegate pickerView:element titleForRow:row forComponent:column];
    }
    return rowLabel == value || [rowLabel isEqualToString:value] ||
           [attributedRowLabel.string isEqualToString:value];
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:[NSString stringWithFormat:@"pickerColumnAtIndex(%ld) value('%@')",
                                                       (long)column, value]];
  };
  NSArray<id<GREYMatcher>> *matchers = @[
    [GREYMatchers matcherForKindOfClass:[UIPickerView class]],
    [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe],
  ];
  return [[GREYAllOf alloc] initWithMatchers:matchers];
}

+ (id<GREYMatcher>)matcherForDatePickerValue:(NSDate *)value {
  GREYMatchesBlock matches = ^BOOL(UIDatePicker *element) {
    if (element.date == value) {
      return YES;
    }
    return [element.date isEqualToDate:value];
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:[NSString stringWithFormat:@"datePickerWithValue('%@')", value]];
  };
  NSArray *matchersArray = @[
    [GREYMatchers matcherForKindOfClass:[UIDatePicker class]],
    [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe],
  ];
  return [[GREYAllOf alloc] initWithMatchers:matchersArray];
}

+ (id<GREYMatcher>)matcherForEnabledElement {
  GREYMatchesBlock matches = ^BOOL(id element) {
    BOOL matched = YES;
    if ([element isKindOfClass:[UIControl class]]) {
      UIControl *control = (UIControl *)element;
      matched = control.enabled;
    }
    return matched;
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:@"enabled"];
  };
  id<GREYMatcher> isEnabledMatcher =
      [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe];
  // We also check that we don't have any disabled ancestors because checking for enabled ancestor
  // will return the first enabled ancestor even through there might be disabled ancestors.
  id<GREYMatcher> notEnabledElementMatcher = [[GREYNot alloc] initWithMatcher:isEnabledMatcher];
  id<GREYMatcher> ancestorMatcher = [GREYMatchers matcherForAncestor:notEnabledElementMatcher];
  id<GREYMatcher> notAncestorOfEnabledElementMatcher =
      [[GREYNot alloc] initWithMatcher:ancestorMatcher];
  return [[GREYAllOf alloc]
      initWithMatchers:@[ isEnabledMatcher, notAncestorOfEnabledElementMatcher ]];
}

+ (id<GREYMatcher>)matcherForSelectedElement {
  GREYMatchesBlock matches = ^BOOL(UIControl *control) {
    return [control isSelected];
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:@"selected"];
  };
  NSArray *matchersArray = @[
    [GREYMatchers matcherForKindOfClass:[[UIControl class] class]],
    [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe],
  ];
  return [[GREYAllOf alloc] initWithMatchers:matchersArray];
}

+ (id<GREYMatcher>)matcherForUserInteractionEnabled {
  GREYMatchesBlock matches = ^BOOL(UIView *view) {
    return [view isUserInteractionEnabled];
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:@"userInteractionEnabled"];
  };
  NSArray *matchersArray = @[
    [GREYMatchers matcherForKindOfClass:[[UIView class] class]],
    [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe],
  ];
  return [[GREYAllOf alloc] initWithMatchers:matchersArray];
}

+ (id<GREYMatcher>)matcherForConstraints:(NSArray *)constraints
              toReferenceElementMatching:(id<GREYMatcher>)referenceElementMatcher {
  NSMutableArray *localConstraints = [[NSMutableArray alloc] init];
  NSEnumerator<GREYLayoutConstraint *> *constraintEnumerator = [constraints objectEnumerator];
  GREYLayoutConstraint *constraint;
  while ((constraint = constraintEnumerator.nextObject)) {
    [localConstraints addObject:constraint];
  }

  GREYMatchesBlock matches = ^BOOL(id element) {
    // TODO: This causes searching the UI hierarchy multiple times for each element, refactor the
    // design to avoid this.
    GREYElementInteraction *interaction =
        [[GREYElementInteraction alloc] initWithElementMatcher:referenceElementMatcher];
    NSError *matcherError;
    NSArray *referenceElements = [interaction matchedElementsWithTimeout:0 error:&matcherError];
    if (matcherError) {
      NSLog(@"Error finding element: %@", [GREYError grey_nestedDescriptionForError:matcherError]);
      return NO;
    } else if (referenceElements.count > 1) {
      NSLog(
          @"More than one element matches the reference matcher.\n"
          @"The following elements were matched: %@\n"
          @"Provided reference matcher: %@\n",
          referenceElements, referenceElementMatcher);
      return NO;
    }

    id referenceElement = [referenceElements firstObject];
    if (!referenceElement) {
      NSLog(@"Could not find reference element.");
      return NO;
    }

    for (GREYLayoutConstraint *constraint in localConstraints) {
      if (![constraint satisfiedByElement:element andReferenceElement:referenceElement]) {
        return NO;
      }
    }
    return YES;
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    NSString *name = [NSString
        stringWithFormat:@"layoutWithConstraints(%@) referenceElementMatcher:(%@)",
                         referenceElementMatcher, [constraints componentsJoinedByString:@","]];
    [description appendText:name];
  };
  // Nil elements do not have layout for matching layout constraints.
  NSArray *matchersArray = @[
    [GREYMatchers matcherForNotNil],
    [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe],
  ];
  return [[GREYAllOf alloc] initWithMatchers:matchersArray];
}

+ (id<GREYMatcher>)matcherForNil {
  GREYMatchesBlock matches = ^BOOL(id element) {
    return element == nil;
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:@"isNil"];
  };
  return [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe];
}

+ (id<GREYMatcher>)matcherForNotNil {
  GREYMatchesBlock matches = ^BOOL(id element) {
    return element != nil;
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:@"isNotNil"];
  };
  return [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe];
}

+ (id<GREYMatcher>)matcherForSwitchWithOnState:(BOOL)on {
  GREYMatchesBlock matches = ^BOOL(id element) {
    return ([element isOn] && on) || (![element isOn] && !on);
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    NSString *name =
        [NSString stringWithFormat:@"switchInState(%@)", [UISwitch grey_stringFromOnState:on]];
    [description appendText:name];
  };
  NSArray *matchersArray = @[
    [GREYMatchers matcherForRespondsToSelector:@selector(isOn)],
    [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe],
  ];
  return [[GREYAllOf alloc] initWithMatchers:matchersArray];
}

+ (id<GREYMatcher>)matcherForScrolledToContentEdge:(GREYContentEdge)edge {
  GREYMatchesBlock matches = ^BOOL(UIScrollView *scrollView) {
    CGPoint contentOffset = [scrollView contentOffset];
    UIEdgeInsets contentInset = [scrollView contentInset];
    CGSize contentSize = [scrollView contentSize];
    CGRect frame = [scrollView frame];
    switch (edge) {
      case kGREYContentEdgeTop:
        return contentOffset.y + contentInset.top == 0;
      case kGREYContentEdgeBottom:
        return contentInset.bottom + contentSize.height - frame.size.height - contentOffset.y == 0;
      case kGREYContentEdgeLeft:
        return contentOffset.x + contentInset.left == 0;
      case kGREYContentEdgeRight:
        return contentInset.right + contentSize.width - frame.size.width - contentOffset.x == 0;
    }
  };
  GREYDescribeToBlock describe = ^(id description) {
    [description appendText:[NSString stringWithFormat:@"scrolledToContentEdge(%@)",
                                                       NSStringFromGREYContentEdge(edge)]];
  };
  NSArray *matchersArray = @[
    [GREYMatchers matcherForKindOfClass:[UIScrollView class]],
    [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe],
  ];
  return [[GREYAllOf alloc] initWithMatchers:matchersArray];
}

+ (id<GREYMatcher>)matcherForTextFieldValue:(NSString *)value {
  GREYMatchesBlock matches = ^BOOL(UITextField *textField) {
    return [textField.text isEqualToString:value];
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:[NSString stringWithFormat:@"textFieldValue('%@')", value]];
  };
  NSArray *matchersArray = @[
    [GREYMatchers matcherForKindOfClass:[UITextField class]],
    [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe],
  ];
  return [[GREYAllOf alloc] initWithMatchers:matchersArray];
}

#pragma mark - Private

/**
 * @return @c YES if the strings have the same string values, @c NO otherwise.
 */
+ (BOOL)grey_accessibilityString:(id)firstString isEqualToAccessibilityString:(id)secondString {
  if (firstString == secondString) {
    return YES;
  }

  // Beginning in iOS 7, accessibility strings, including accessibilityLabel, accessibilityHint,
  // and accessibilityValue, may be instances of NSAttributedString.  This allows the application
  // developer to control aspects of the spoken output such as pitch and language.
  // NSAttributedString, however, does not inherit from NSString, so a check needs to be performed
  // so the underlying NSString value can be extracted for comparison.
  NSString *firstStringValue;
  if ([firstString isKindOfClass:[NSString class]]) {
    firstStringValue = firstString;
  } else if ([firstString isKindOfClass:[NSAttributedString class]]) {
    firstStringValue = [firstString string];
  } else {
    return NO;
  }

  NSString *secondStringValue;
  if ([secondString isKindOfClass:[NSString class]]) {
    secondStringValue = secondString;
  } else if ([secondString isKindOfClass:[NSAttributedString class]]) {
    secondStringValue = [secondString string];
  } else {
    return NO;
  }

  return [firstStringValue isEqualToString:secondStringValue];
}

@end
