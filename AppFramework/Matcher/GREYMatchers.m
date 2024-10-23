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

#import "GREYMatchers.h"

#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>

#include <objc/runtime.h>
#include <tgmath.h>

#import "UISwitch+GREYApp.h"
#import "UIView+GREYApp.h"
#import "GREYElementFinder.h"
#import "GREYAllOf+Private.h"
#import "GREYAllOf.h"
#import "GREYAnyOf.h"
#import "GREYVisibilityMatcher.h"
#import "GREYSyncAPI.h"
#import "GREYThrowDefines.h"
#import "GREYConfigKey.h"
#import "GREYConfiguration.h"
#import "GREYAppleInternals.h"
#import "GREYConstants.h"
#import "GREYDiagnosable.h"
#import "GREYLogger.h"
#import "GREYDescription.h"
#import "GREYElementMatcherBlock+Private.h"
#import "GREYElementMatcherBlock.h"
#import "GREYLayoutConstraint.h"
#import "GREYMatcher.h"
#import "GREYElementProvider.h"
#import "GREYUIWindowProvider.h"
#import "GREYTraversalFunctions.h"

/**
 * @param customMatcher The custom matcher to match accessibility property such as label, hint
 *                      or value.
 *
 * @return An NSArray containing the passed in custom matcher along with isAccessibilityElement
 *         matcher if @c ignoreIsAccessibility in GREYConfiguration is @c NO, otherwise, return
 *         an array with just the custom matcher.
 */
static NSArray<id<GREYMatcher>> *MatcherWithAccessibilityElement(id<GREYMatcher> customMatcher) {
  BOOL ignoreIsAccessible = GREY_CONFIG_BOOL(kGREYConfigKeyIgnoreIsAccessible);
  if (ignoreIsAccessible) {
    return @[ customMatcher ];
  } else {
    NSArray<id<GREYMatcher>> *matchersArray = @[
      [GREYMatchers matcherForAccessibilityElement],
      customMatcher,
    ];
    return matchersArray;
  }
}

// Expose method for EDOObject as it's not a public class.
@interface NSObject (GREYExposed)
@property(readonly) NSString *className;
@end

// EDOObject class as it's private.
static Class gEDOObjectClass;

/**
 * The internal class that lets us know if the activity sheet is present.
 */
static NSString *const kActivitySheetContainerClass = @"_UISceneLayerHostContainerView";

@implementation GREYMatchers

+ (void)initialize {
  if (self == [GREYMatchers self]) {
    gEDOObjectClass = NSClassFromString(@"EDOObject");
  }
}

+ (id<GREYMatcher>)matcherForKeyWindow {
  NSString *prefix = @"keyWindow";
  GREYMatchesBlock matches = ^BOOL(UIWindow *element) {
    UIWindow *keyWindow = [GREYUIWindowProvider keyWindowForSharedApplication];
    if (element == keyWindow) {
      return YES;
    }
    return [element isEqual:keyWindow];
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:prefix];
  };
  NSArray<id<GREYMatcher>> *matchersArray = @[
    [GREYMatchers matcherForKindOfClass:[UIWindow class]],
    [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe],
  ];
  return [[GREYAllOf alloc] initWithName:GREYCorePrefixedDiagnosticsID(prefix)
                                matchers:matchersArray];
}

+ (id<GREYMatcher>)matcherForCloseTo:(double)value delta:(double)delta {
  NSString *prefix = @"closeTo";
  GREYMatchesBlock matches = ^BOOL(id element) {
    return fabs([element doubleValue] - value) <= delta;
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:[NSString stringWithFormat:@"%@(%lf) by (%lf)", prefix, value, delta]];
  };
  return [[GREYElementMatcherBlock alloc] initWithName:GREYCorePrefixedDiagnosticsID(prefix)
                                          matchesBlock:matches
                                      descriptionBlock:describe];
}

+ (id<GREYMatcher>)matcherForAnything {
  NSString *prefix = @"anything";
  GREYMatchesBlock matches = ^BOOL(id element) {
    return YES;
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:prefix];
  };
  return [[GREYElementMatcherBlock alloc] initWithName:GREYCorePrefixedDiagnosticsID(prefix)
                                          matchesBlock:matches
                                      descriptionBlock:describe];
}

+ (id<GREYMatcher>)matcherForEqualTo:(id)value {
  NSString *prefix = @"equalTo";
  GREYMatchesBlock matches = ^BOOL(id element) {
    if (element) {
      return [element isEqual:value];
    } else {
      return element == value;
    }
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:[NSString stringWithFormat:@"%@(%@)", prefix, value]];
  };
  return [[GREYElementMatcherBlock alloc] initWithName:GREYCorePrefixedDiagnosticsID(prefix)
                                          matchesBlock:matches
                                      descriptionBlock:describe];
}

+ (id<GREYMatcher>)matcherForLessThan:(id)value {
  NSString *prefix = @"lessThan";
  GREYMatchesBlock matches = ^BOOL(id element) {
    return [value compare:element] == NSOrderedDescending;
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:[NSString stringWithFormat:@"%@(%@)", prefix, value]];
  };
  return [[GREYElementMatcherBlock alloc] initWithName:GREYCorePrefixedDiagnosticsID(prefix)
                                          matchesBlock:matches
                                      descriptionBlock:describe];
}

+ (id<GREYMatcher>)matcherForGreaterThan:(id)value {
  NSString *prefix = @"greaterThan";
  GREYMatchesBlock matches = ^BOOL(id element) {
    return [value compare:element] == NSOrderedAscending;
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:[NSString stringWithFormat:@"%@(%@)", prefix, value]];
  };
  return [[GREYElementMatcherBlock alloc] initWithName:GREYCorePrefixedDiagnosticsID(prefix)
                                          matchesBlock:matches
                                      descriptionBlock:describe];
}

+ (id<GREYMatcher>)matcherForAccessibilityLabel:(NSString *)label {
  NSString *prefix = @"accessibilityLabel";
  GREYMatchesBlock matches = ^BOOL(NSObject *element) {
    return [self accessibilityString:element.accessibilityLabel isEqualToAccessibilityString:label];
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:[NSString stringWithFormat:@"%@('%@')", prefix, label]];
  };
  id<GREYMatcher> customMatcher = [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches
                                                                       descriptionBlock:describe];
  NSString *name = GREYCorePrefixedDiagnosticsID(prefix);
  return [[GREYAllOf alloc] initWithName:name
                                matchers:MatcherWithAccessibilityElement(customMatcher)];
}

+ (id<GREYMatcher>)matcherForAccessibilityID:(NSString *)accessibilityID {
  NSString *prefix = @"accessibilityID";
  GREYMatchesBlock matches = ^BOOL(id<UIAccessibilityIdentification> element) {
    if (element.accessibilityIdentifier == accessibilityID) {
      return YES;
    }
    return [element.accessibilityIdentifier isEqualToString:accessibilityID];
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:[NSString stringWithFormat:@"%@('%@')", prefix, accessibilityID]];
  };
  NSArray<id<GREYMatcher>> *matchersArray = @[
    [GREYMatchers matcherForRespondsToSelector:@selector(accessibilityIdentifier)],
    [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe],
  ];
  return [[GREYAllOf alloc] initWithName:GREYCorePrefixedDiagnosticsID(prefix)
                                matchers:matchersArray];
}

+ (id<GREYMatcher>)matcherForAccessibilityValue:(NSString *)value {
  NSString *prefix = @"accessibilityValue";
  GREYMatchesBlock matches = ^BOOL(NSObject *element) {
    NSString *accessibilityValue = element.accessibilityValue ?: @"";
    if ([accessibilityValue isEqualToString:value]) {
      return YES;
    }
    return [self accessibilityString:element.accessibilityValue isEqualToAccessibilityString:value];
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:[NSString stringWithFormat:@"%@('%@')", prefix, value]];
  };
  id<GREYMatcher> customMatcher = [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches
                                                                       descriptionBlock:describe];
  NSString *name = GREYCorePrefixedDiagnosticsID(prefix);
  return [[GREYAllOf alloc] initWithName:name
                                matchers:MatcherWithAccessibilityElement(customMatcher)];
}

+ (id<GREYMatcher>)matcherForAccessibilityTraits:(UIAccessibilityTraits)traits {
  NSString *prefix = @"accessibilityTraits";
  GREYMatchesBlock matches = ^BOOL(NSObject *element) {
    return ([element accessibilityTraits] & traits) != 0;
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    NSString *traitsString = NSStringFromUIAccessibilityTraits(traits);
    [description appendText:[NSString stringWithFormat:@"%@: %@", prefix, traitsString]];
  };
  id<GREYMatcher> customMatcher = [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches
                                                                       descriptionBlock:describe];
  NSString *name = GREYCorePrefixedDiagnosticsID(prefix);
  return [[GREYAllOf alloc] initWithName:name
                                matchers:MatcherWithAccessibilityElement(customMatcher)];
}

+ (id<GREYMatcher>)matcherForAccessibilityHint:(id)hint {
  NSString *prefix = @"accessibilityHint";
  GREYMatchesBlock matches = ^BOOL(NSObject *element) {
    id accessibilityHint = element.accessibilityHint;
    if (accessibilityHint == hint) {
      return YES;
    }
    return [self accessibilityString:accessibilityHint isEqualToAccessibilityString:hint];
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:[NSString stringWithFormat:@"%@('%@')", prefix, hint]];
  };
  id<GREYMatcher> customMatcher = [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches
                                                                       descriptionBlock:describe];
  NSString *name = GREYCorePrefixedDiagnosticsID(prefix);
  return [[GREYAllOf alloc] initWithName:name
                                matchers:MatcherWithAccessibilityElement(customMatcher)];
}

+ (id<GREYMatcher>)matcherForAccessibilityElementIsFocused {
  NSString *prefix = @"accessibilityFocused";
  GREYMatchesBlock matches = ^BOOL(NSObject *element) {
    return [element accessibilityElementIsFocused];
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:prefix];
  };
  id<GREYMatcher> matcher = [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches
                                                                 descriptionBlock:describe];
  NSArray<id<GREYMatcher>> *matchersArray = @[
    [GREYMatchers matcherForRespondsToSelector:@selector(accessibilityElementIsFocused)],
    matcher,
  ];
  return [[GREYAllOf alloc] initWithName:GREYCorePrefixedDiagnosticsID(prefix)
                                matchers:matchersArray];
}

+ (id<GREYMatcher>)matcherForText:(NSString *)text {
  NSString *prefix = @"hasText";
  NSString *swiftPrefix = @"hasTextSwiftUI";
  GREYMatchesBlock matchesSwiftUI = ^BOOL(id element) {
    return [self accessibilityString:((NSObject *)element).accessibilityLabel
        isEqualToAccessibilityString:text];
  };
  GREYMatchesBlock matchesNonSwiftUI = ^BOOL(id element) {
    return [[element text] isEqualToString:text];
  };

  GREYDescribeToBlock describeSwiftUI = ^void(id<GREYDescription> description) {
    [description appendText:[NSString stringWithFormat:@"%@('%@')", swiftPrefix, text]];
  };
  GREYDescribeToBlock describeNonSwiftUI = ^void(id<GREYDescription> description) {
    [description appendText:[NSString stringWithFormat:@"%@('%@')", prefix, text]];
  };
  // A matcher for SwiftUI elements - compares 'ax.label' instead of 'text'
  id<GREYMatcher> swiftUIMatcher =
      [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matchesSwiftUI
                                           descriptionBlock:describeSwiftUI];
  // A matcher for non-SwiftUI elements
  id<GREYMatcher> nonSwiftUIMatcher =
      [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matchesNonSwiftUI
                                           descriptionBlock:describeNonSwiftUI];

  NSArray<id<GREYMatcher>> *nonSwiftUIMatchersArray = @[
    [GREYMatchers matcherForKindOfClass:[UILabel class]],
    [GREYMatchers matcherForKindOfClass:[UITextField class]],
    [GREYMatchers matcherForKindOfClass:[UITextView class]],
  ];
  NSArray<id<GREYMatcher>> *swiftUIMatchersArray = @[
    [GREYMatchers matcherForSwiftUI],
    [GREYMatchers matcherForAccessibilityElement],
    swiftUIMatcher,
  ];

  NSArray<id<GREYMatcher>> *matchersArray = @[ [[GREYAnyOf alloc] initWithMatchers:@[
    [[GREYAllOf alloc] initWithMatchers:@[
      [[GREYAnyOf alloc] initWithMatchers:nonSwiftUIMatchersArray],
      nonSwiftUIMatcher,
    ]],
    [[GREYAllOf alloc] initWithMatchers:swiftUIMatchersArray],
  ]] ];

  return [[GREYAllOf alloc] initWithName:GREYCorePrefixedDiagnosticsID(prefix)
                                matchers:matchersArray];
}

+ (id<GREYMatcher>)matcherForFirstResponder {
  NSString *prefix = @"firstResponder";
  GREYMatchesBlock matches = ^BOOL(UIResponder *element) {
    return [element isFirstResponder];
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:prefix];
  };
  NSArray<id<GREYMatcher>> *matchersArray = @[
    [GREYMatchers matcherForKindOfClass:[UIResponder class]],
    [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe],
  ];
  return [[GREYAllOf alloc] initWithName:GREYCorePrefixedDiagnosticsID(prefix)
                                matchers:matchersArray];
}

+ (id<GREYMatcher>)matcherForSystemAlertViewShown {
  NSString *prefix = @"isSystemAlertViewShown";
  GREYMatchesBlock matches = ^BOOL(id element) {
    return [UIApplication.sharedApplication _isSpringBoardShowingAnAlert];
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:prefix];
  };
  return [[GREYElementMatcherBlock alloc] initWithName:GREYCorePrefixedDiagnosticsID(prefix)
                                          matchesBlock:matches
                                      descriptionBlock:describe];
}

+ (id<GREYMatcher>)matcherForMinimumVisiblePercent:(CGFloat)percent {
  return [[GREYVisibilityMatcher alloc] initForMinimumVisiblePercent:percent];
}

+ (id<GREYMatcher>)matcherForSufficientlyVisible {
  return [[GREYVisibilityMatcher alloc] initForSufficientlyVisible];
}

+ (id<GREYMatcher>)matcherForInteractable {
  return [[GREYVisibilityMatcher alloc] initForInteractable];
}

+ (id<GREYMatcher>)matcherForNotVisible {
  return [[GREYVisibilityMatcher alloc] initForNotVisible];
}

+ (id<GREYMatcher>)matcherForAccessibilityElement {
  NSString *prefix = @"isAccessibilityElement";
  GREYMatchesBlock matches = ^BOOL(id element) {
    return [element isAccessibilityElement];
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:prefix];
  };
  NSArray<id<GREYMatcher>> *matchersArray = @[
    [GREYMatchers matcherForRespondsToSelector:@selector(isAccessibilityElement)],
    [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe],
  ];
  return [[GREYAllOf alloc] initWithName:GREYCorePrefixedDiagnosticsID(prefix)
                                matchers:matchersArray];
}

+ (id<GREYMatcher>)matcherForKindOfClass:(nullable Class)klass {
  GREYMatchesBlock matches;
  NSString *prefix = @"kindOfClass";
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
    [description appendText:[NSString stringWithFormat:@"%@('%@')", prefix, className]];
  };
  return [[GREYElementMatcherBlock alloc] initWithName:GREYCorePrefixedDiagnosticsID(prefix)
                                          matchesBlock:matches
                                      descriptionBlock:describe];
}

+ (id<GREYMatcher>)matcherForKindOfClassName:(NSString *)className {
  GREYThrowOnFailedConditionWithMessage(NSClassFromString(className),
                                        @"The class obtained from the class name cannot be nil");
  return [self matcherForKindOfClass:NSClassFromString(className)];
}

+ (id<GREYMatcher>)matcherForProgress:(id<GREYMatcher>)comparisonMatcher {
  NSString *prefix = @"progressValueThatMatches";
  GREYMatchesBlock matches = ^BOOL(UIProgressView *element) {
    return [comparisonMatcher matches:@(element.progress)];
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:[NSString stringWithFormat:@"%@('%@')", prefix, comparisonMatcher]];
  };
  NSArray<id<GREYMatcher>> *matchersArray = @[
    [GREYMatchers matcherForKindOfClass:[UIProgressView class]],
    [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe],
  ];
  return [[GREYAllOf alloc] initWithName:GREYCorePrefixedDiagnosticsID(prefix)
                                matchers:matchersArray];
}

+ (id<GREYMatcher>)matcherForRespondsToSelector:(SEL)sel {
  NSString *prefix = @"respondsToSelector";
  GREYMatchesBlock matches = ^BOOL(id element) {
    return [element respondsToSelector:sel];
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description
        appendText:[NSString stringWithFormat:@"%@(%@)", prefix, NSStringFromSelector(sel)]];
  };
  return [[GREYElementMatcherBlock alloc] initWithName:GREYCorePrefixedDiagnosticsID(prefix)
                                          matchesBlock:matches
                                      descriptionBlock:describe];
}

+ (id<GREYMatcher>)matcherForConformsToProtocol:(Protocol *)protocol {
  NSString *prefix = @"conformsToProtocol";
  GREYMatchesBlock matches = ^BOOL(id element) {
    return [element conformsToProtocol:protocol];
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description
        appendText:[NSString stringWithFormat:@"%@(%@)", prefix, NSStringFromProtocol(protocol)]];
  };
  return [[GREYElementMatcherBlock alloc] initWithName:GREYCorePrefixedDiagnosticsID(prefix)
                                          matchesBlock:matches
                                      descriptionBlock:describe];
}

+ (id<GREYMatcher>)matcherForAncestor:(id<GREYMatcher>)ancestorMatcher {
  NSString *prefix = @"ancestorThatMatches";
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
    [description appendText:[NSString stringWithFormat:@"%@(%@)", prefix, ancestorMatcher]];
  };
  NSArray<id<GREYMatcher>> *anyOfMatchers = @[
    [GREYMatchers matcherForKindOfClass:[UIView class]],
    [GREYMatchers matcherForRespondsToSelector:@selector(accessibilityContainer)],
  ];
  NSArray<id<GREYMatcher>> *matchersArray = @[
    [[GREYAnyOf alloc] initWithMatchers:anyOfMatchers],
    [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe]
  ];
  return [[GREYAllOf alloc] initWithName:GREYCorePrefixedDiagnosticsID(prefix)
                                matchers:matchersArray];
}

+ (id<GREYMatcher>)matcherForDescendant:(id<GREYMatcher>)descendantMatcher {
  NSString *prefix = @"descendantThatMatches";
  GREYMatchesBlock matches = ^BOOL(id element) {
    if (element == nil) {
      return NO;
    }

    GREYElementProvider *elementProvider =
        [[GREYElementProvider alloc] initWithRootElements:@[ element ]];
    NSEnumerator *elementEnumerator = [elementProvider dataEnumerator];
    id child = [elementEnumerator nextObject];
    while (child) {
      if ([descendantMatcher matches:child] && child != element) {
        return YES;
      }
      child = [elementEnumerator nextObject];
    }
    return NO;
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:[NSString stringWithFormat:@"%@(%@)", prefix, descendantMatcher]];
  };
  return [[GREYElementMatcherBlock alloc] initWithName:GREYCorePrefixedDiagnosticsID(prefix)
                                          matchesBlock:matches
                                      descriptionBlock:describe];
}

+ (id<GREYMatcher>)matcherForButtonTitle:(NSString *)title {
  NSString *prefix = @"buttonTitle";
  NSString *swiftPrefix = @"buttonTitleSwiftUI";

  GREYMatchesBlock matchesSwiftUI = ^BOOL(NSObject *element) {
    if (([element accessibilityTraits] & UIAccessibilityTraitButton) != 0 &&
        [self accessibilityString:element.accessibilityLabel isEqualToAccessibilityString:title]) {
      return YES;
    }
    return NO;
  };
  GREYMatchesBlock matchesNonSwiftUI = ^BOOL(UIButton *element) {
    if (element.titleLabel.text == title) {
      return YES;
    }
    return [element.titleLabel.text isEqualToString:title];
  };
  GREYDescribeToBlock describeSwiftUI = ^void(id<GREYDescription> description) {
    [description appendText:[NSString stringWithFormat:@"%@('%@')", swiftPrefix, title]];
  };
  GREYDescribeToBlock describeNonSwiftUI = ^void(id<GREYDescription> description) {
    [description appendText:[NSString stringWithFormat:@"%@('%@')", prefix, title]];
  };

  // A matcher for SwiftUI elements - makes sure the element has a button trait and compares
  // 'ax.label' instead of 'text'
  id<GREYMatcher> swiftUIMatcher =
      [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matchesSwiftUI
                                           descriptionBlock:describeSwiftUI];
  // A matcher for non-SwiftUI elements
  id<GREYMatcher> nonSwiftUIMatcher =
      [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matchesNonSwiftUI
                                           descriptionBlock:describeNonSwiftUI];

  NSArray<id<GREYMatcher>> *swiftUIMatchersArray = @[
    [GREYMatchers matcherForSwiftUI],
    [GREYMatchers matcherForAccessibilityElement],
    swiftUIMatcher,
  ];
  NSArray<id<GREYMatcher>> *nonSwiftUIMatchersArray = @[
    [GREYMatchers matcherForKindOfClass:[UIButton class]],
    nonSwiftUIMatcher,
  ];
  NSArray<id<GREYMatcher>> *matchersArray = @[ [[GREYAnyOf alloc] initWithMatchers:@[
    [[GREYAllOf alloc] initWithMatchers:nonSwiftUIMatchersArray],
    [[GREYAllOf alloc] initWithMatchers:swiftUIMatchersArray],
  ]] ];

  return [[GREYAllOf alloc] initWithName:GREYCorePrefixedDiagnosticsID(prefix)
                                matchers:matchersArray];
}

+ (id<GREYMatcher>)matcherForScrollViewContentOffset:(CGPoint)offset {
  NSString *prefix = @"contentOffset";
  GREYMatchesBlock matches = ^BOOL(UIScrollView *element) {
    return CGPointEqualToPoint([element contentOffset], offset);
  };
  GREYDescribeToBlock describe = ^(id<GREYDescription> description) {
    NSString *desc = [NSString stringWithFormat:@"%@(%@)", prefix, NSStringFromCGPoint(offset)];
    [description appendText:desc];
  };
  NSArray<id<GREYMatcher>> *matchersArray = @[
    [GREYMatchers matcherForKindOfClass:[UIScrollView class]],
    [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe],
  ];
  return [[GREYAllOf alloc] initWithName:GREYCorePrefixedDiagnosticsID(prefix)
                                matchers:matchersArray];
}

+ (id<GREYMatcher>)matcherForSliderValueMatcher:(id<GREYMatcher>)valueMatcher {
#if TARGET_OS_IOS
  NSString *prefix = @"sliderValueMatches";
  GREYMatchesBlock matches = ^BOOL(UISlider *element) {
    return [valueMatcher matches:@(element.value)];
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:[NSString stringWithFormat:@"%@(%@)", prefix, valueMatcher]];
  };
  NSArray<id<GREYMatcher>> *matchersArray = @[
    [GREYMatchers matcherForKindOfClass:[UISlider class]],
    [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe],
  ];
  return [[GREYAllOf alloc] initWithName:GREYCorePrefixedDiagnosticsID(prefix)
                                matchers:matchersArray];
#else
  return nil;
#endif  // TARGET_OS_IOS
}

+ (id<GREYMatcher>)matcherForStepperValue:(double)value {
#if TARGET_OS_IOS
  NSString *prefix = @"stepperValue";
  GREYMatchesBlock matches = ^BOOL(UIStepper *element) {
    return element.value == value;
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:[NSString stringWithFormat:@"%@(%lf)", prefix, value]];
  };
  NSArray<id<GREYMatcher>> *matchersArray = @[
    [GREYMatchers matcherForKindOfClass:[UIStepper class]],
    [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe],
  ];
  return [[GREYAllOf alloc] initWithName:GREYCorePrefixedDiagnosticsID(prefix)
                                matchers:matchersArray];
#else
  return nil;
#endif  // TARGET_OS_IOS
}

+ (id<GREYMatcher>)matcherForPickerColumn:(NSInteger)column setToValue:(NSString *)value {
#if TARGET_OS_IOS
  NSString *prefix = @"pickerColumnAtIndex";
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
    SEL viewForRowSelector = @selector(pickerView:viewForRow:forComponent:reusingView:);
    if ([delegate respondsToSelector:attributedTitleSelector]) {
      attributedRowLabel = [delegate pickerView:element
                          attributedTitleForRow:row
                                   forComponent:column];
      if (attributedRowLabel == nil) {
        rowLabel = [delegate pickerView:element titleForRow:row forComponent:column];
      }
    } else if ([delegate respondsToSelector:nonAttributedTitleSelector]) {
      rowLabel = [delegate pickerView:element titleForRow:row forComponent:column];
    } else if ([delegate respondsToSelector:viewForRowSelector]) {
      UIView *rowView = [delegate pickerView:element
                                  viewForRow:row
                                  forComponent:column
                                  reusingView:nil];
      if (![rowView isKindOfClass:[UILabel class]]) {
        NSArray<UILabel *> *labels = [rowView grey_childrenAssignableFromClass:[UILabel class]];
        UILabel *label = (labels.count > 0 ? labels[0] : nil);
        rowLabel = label.text;
      } else {
        rowLabel = [((UILabel *)rowView) text];
      }
    }
    return rowLabel == value || [rowLabel isEqualToString:value] ||
           [attributedRowLabel.string isEqualToString:value];
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description
        appendText:[NSString stringWithFormat:@"%@(%ld) value('%@')", prefix, (long)column, value]];
  };
  NSArray<id<GREYMatcher>> *matchersArray = @[
    [GREYMatchers matcherForKindOfClass:[UIPickerView class]],
    [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe],
  ];
  return [[GREYAllOf alloc] initWithName:GREYCorePrefixedDiagnosticsID(prefix)
                                matchers:matchersArray];
#else
  return nil;
#endif  // TARGET_OS_IOS
}

+ (id<GREYMatcher>)matcherForDatePickerValue:(NSDate *)value {
#if TARGET_OS_IOS
  NSString *prefix = @"datePickerWithValue";
  GREYMatchesBlock matches = ^BOOL(UIDatePicker *element) {
    if (element.date == value) {
      return YES;
    }
    return [element.date isEqualToDate:value];
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:[NSString stringWithFormat:@"%@('%@')", prefix, value]];
  };
  NSArray<id<GREYMatcher>> *matchersArray = @[
    [GREYMatchers matcherForKindOfClass:[UIDatePicker class]],
    [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe],
  ];
  return [[GREYAllOf alloc] initWithName:GREYCorePrefixedDiagnosticsID(prefix)
                                matchers:matchersArray];
#else
  return nil;
#endif  // TARGET_OS_IOS
}

+ (id<GREYMatcher>)matcherForEnabledElement {
  NSString *prefix = @"enabled";
  GREYMatchesBlock matches = ^BOOL(id element) {
    BOOL matched = YES;
    if ([element isKindOfClass:[UIControl class]]) {
      UIControl *control = (UIControl *)element;
      matched = control.enabled;
    }
    return matched;
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:prefix];
  };
  id<GREYMatcher> isEnabledMatcher =
      [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe];
  // We also check that we don't have any disabled ancestors because checking for enabled ancestor
  // will return the first enabled ancestor even through there might be disabled ancestors.
  id<GREYMatcher> notEnabledElementMatcher = [GREYMatchers matcherForNegation:isEnabledMatcher];
  id<GREYMatcher> ancestorMatcher = [GREYMatchers matcherForAncestor:notEnabledElementMatcher];
  id<GREYMatcher> notAncestorOfEnabledElementMatcher =
      [GREYMatchers matcherForNegation:ancestorMatcher];
  return [[GREYAllOf alloc] initWithName:GREYCorePrefixedDiagnosticsID(prefix)
                                matchers:@[ notAncestorOfEnabledElementMatcher, isEnabledMatcher ]];
}

+ (id<GREYMatcher>)matcherForSelectedElement {
  NSString *prefix = @"selected";
  GREYMatchesBlock matches = ^BOOL(id element) {
    return [element isSelected];
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:prefix];
  };
  NSArray<id<GREYMatcher>> *matchersArray = @[
    [GREYMatchers matcherForRespondsToSelector:@selector(isSelected)],
    [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe],
  ];
  return [[GREYAllOf alloc] initWithName:GREYCorePrefixedDiagnosticsID(prefix)
                                matchers:matchersArray];
}

+ (id<GREYMatcher>)matcherForUserInteractionEnabled {
  NSString *prefix = @"userInteractionEnabled";
  GREYMatchesBlock matches = ^BOOL(UIView *view) {
    return [view isUserInteractionEnabled];
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:prefix];
  };
  NSArray<id<GREYMatcher>> *matchersArray = @[
    [GREYMatchers matcherForKindOfClass:[[UIView class] class]],
    [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe],
  ];
  return [[GREYAllOf alloc] initWithName:GREYCorePrefixedDiagnosticsID(prefix)
                                matchers:matchersArray];
}

+ (id<GREYMatcher>)matcherForLayoutConstraints:(NSArray<GREYLayoutConstraint *> *)constraints
                    toReferenceElementMatching:(id<GREYMatcher>)referenceElementMatcher {
  NSString *prefix = @"layoutWithConstraints";
  NSMutableArray<GREYLayoutConstraint *> *localConstraints = [[NSMutableArray alloc] init];
  NSEnumerator<GREYLayoutConstraint *> *constraintEnumerator = [constraints objectEnumerator];
  GREYLayoutConstraint *constraint;
  while ((constraint = constraintEnumerator.nextObject)) {
    [localConstraints addObject:constraint];
  }

  GREYMatchesBlock matches = ^BOOL(id element) {
    // TODO: This causes searching the UI hierarchy multiple times for each element, refactor the
    // design to avoid this.
    GREYUIWindowProvider *windowProvider =
        [GREYUIWindowProvider providerWithAllWindowsWithStatusBar:YES];
    GREYElementProvider *entireRootHierarchyProvider =
        [GREYElementProvider providerWithRootProvider:windowProvider];
    GREYElementFinder *finder = [[GREYElementFinder alloc] initWithMatcher:referenceElementMatcher];
    __block NSArray<id> *referenceElements;
    grey_dispatch_sync_on_main_thread(^{
      referenceElements = [finder elementsMatchedInProvider:entireRootHierarchyProvider];
    });

    if (referenceElements.count > 1) {
      GREYLog(@"More than one element matches the reference matcher.\n"
              @"The following elements were matched: %@\n"
              @"Provided reference matcher: %@\n",
              referenceElements, referenceElementMatcher);
      return NO;
    }

    id referenceElement = [referenceElements firstObject];
    if (!referenceElement) {
      GREYLog(@"Could not find reference element.");
      return NO;
    }

    for (GREYLayoutConstraint *localConstraint in localConstraints) {
      if (![localConstraint satisfiedByElement:element andReferenceElement:referenceElement]) {
        return NO;
      }
    }
    return YES;
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    NSString *name = [NSString stringWithFormat:@"%@(%@) referenceElementMatcher:(%@)", prefix,
                                                referenceElementMatcher,
                                                [constraints componentsJoinedByString:@","]];
    [description appendText:name];
  };
  // Nil elements do not have layout for matching layout constraints.
  NSArray<id<GREYMatcher>> *matchersArray = @[
    [GREYMatchers matcherForNotNil],
    [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe],
  ];
  return [[GREYAllOf alloc] initWithName:GREYCorePrefixedDiagnosticsID(prefix)
                                matchers:matchersArray];
}

+ (id<GREYMatcher>)matcherForNil {
  NSString *prefix = @"isNil";
  GREYMatchesBlock matches = ^BOOL(id element) {
    return element == nil;
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:prefix];
  };
  return [[GREYElementMatcherBlock alloc] initWithName:GREYCorePrefixedDiagnosticsID(prefix)
                                          matchesBlock:matches
                                      descriptionBlock:describe];
}

+ (id<GREYMatcher>)matcherForNegation:(id<GREYMatcher>)matcher {
  NSString *prefix = nil;
  GREYMatchesBlock matches = ^BOOL(id element) {
    return ![matcher matches:element];
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [[[description appendText:@"!("] appendDescriptionOf:matcher] appendText:@")"];
  };
  if ([matcher respondsToSelector:@selector(diagnosticsID)]) {
    prefix = [matcher diagnosticsID];
  }
  return [[GREYElementMatcherBlock alloc] initWithName:prefix
                                          matchesBlock:matches
                                      descriptionBlock:describe];
}

+ (id<GREYMatcher>)matcherForNotNil {
  NSString *prefix = @"isNotNil";
  GREYMatchesBlock matches = ^BOOL(id element) {
    return element != nil;
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:prefix];
  };
  return [[GREYElementMatcherBlock alloc] initWithName:GREYCorePrefixedDiagnosticsID(prefix)
                                          matchesBlock:matches
                                      descriptionBlock:describe];
}

+ (id<GREYMatcher>)matcherForSwitchWithOnState:(BOOL)on {
#if TARGET_OS_IOS
  NSString *prefix = @"switchInState";
  GREYMatchesBlock matches = ^BOOL(id element) {
    return ([element isOn] && on) || (![element isOn] && !on);
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    NSString *name =
        [NSString stringWithFormat:@"%@(%@)", prefix, [UISwitch grey_stringFromOnState:on]];
    [description appendText:name];
  };
  NSArray<id<GREYMatcher>> *matchersArray = @[
    [GREYMatchers matcherForRespondsToSelector:@selector(isOn)],
    [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe],
  ];
  return [[GREYAllOf alloc] initWithName:GREYCorePrefixedDiagnosticsID(prefix)
                                matchers:matchersArray];
#else
  return nil;
#endif  // TARGET_OS_IOS
}

+ (id<GREYMatcher>)matcherForScrolledToContentEdge:(GREYContentEdge)edge {
  NSString *prefix = @"scrolledToContentEdge";
  GREYMatchesBlock matches = ^BOOL(UIScrollView *scrollView) {
    CGPoint contentOffset = [scrollView contentOffset];
    UIEdgeInsets contentInset = [scrollView adjustedContentInset];
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
    [description appendText:[NSString stringWithFormat:@"%@(%@)", prefix,
                                                       NSStringFromGREYContentEdge(edge)]];
  };
  NSArray<id<GREYMatcher>> *matchersArray = @[
    [GREYMatchers matcherForKindOfClass:[UIScrollView class]],
    [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe],
  ];
  return [[GREYAllOf alloc] initWithName:GREYCorePrefixedDiagnosticsID(prefix)
                                matchers:matchersArray];
}

+ (id<GREYMatcher>)matcherForTextFieldValue:(NSString *)value {
  NSString *prefix = @"textFieldValue";
  GREYMatchesBlock matches = ^BOOL(UITextField *textField) {
    return [textField.text isEqualToString:value];
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:[NSString stringWithFormat:@"%@('%@')", prefix, value]];
  };
  NSArray<id<GREYMatcher>> *matchersArray = @[
    [GREYMatchers matcherForKindOfClass:[UITextField class]],
    [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe],
  ];
  return [[GREYAllOf alloc] initWithName:GREYCorePrefixedDiagnosticsID(prefix)
                                matchers:matchersArray];
}

+ (id<GREYMatcher>)matcherForHidden:(BOOL)hidden {
  NSString *prefix = [NSString stringWithFormat:@"hidden(\"%d\")", hidden];
  NSString *errorDescription =
      @"\n\n 'SwiftUI elements will not respond to isHidden, if you have used .hidden() on your "
      @"element, use grey_nil() instead to check that it is not present in the view."
      @"\n\n";

  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:prefix];
  };
  GREYDescribeToBlock describeSelectorError = ^void(id<GREYDescription> description) {
    [description appendText:errorDescription];
  };

  GREYMatchesBlock matchesNonSwiftUI = ^BOOL(UIView *view) {
    BOOL viewIsHidden = NO;
    UIView *currentView = view;
    // A view is hidden visually if either its hidden flag is YES or any superview's
    // hidden flag is YES.
    while (currentView && !viewIsHidden) {
      viewIsHidden = currentView.hidden;
      currentView = currentView.superview;
    }
    return viewIsHidden == hidden;
  };
  GREYMatchesBlock matchesSwiftUI = ^BOOL(UIView *view) {
    return view.hidden == hidden;
  };
  GREYMatchesBlock matchesSelectorErrorDescription = ^BOOL(UIView *view) {
    return YES;
  };

  id<GREYMatcher> nonSwiftUIMatcher = [[GREYAllOf alloc]
      initWithMatchers:@[ [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matchesNonSwiftUI
                                                               descriptionBlock:describe] ]];
  id<GREYMatcher> swiftUIMatcher = [[GREYAllOf alloc] initWithMatchers:@[
    [GREYMatchers matcherForSwiftUI],
    [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matchesSwiftUI descriptionBlock:describe]
  ]];
  id<GREYMatcher> selectorErrorMatcher =
      [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matchesSelectorErrorDescription
                                           descriptionBlock:describeSelectorError];

  NSArray<id<GREYMatcher>> *matchersArray = @[
    [GREYMatchers matcherForRespondsToSelector:@selector(isHidden)],
    [[GREYAnyOf alloc] initWithMatchers:@[ swiftUIMatcher, nonSwiftUIMatcher ]],
    selectorErrorMatcher,
  ];

  return [[GREYAllOf alloc] initWithName:GREYCorePrefixedDiagnosticsID(prefix)
                                matchers:matchersArray];
}

+ (id<GREYMatcher>)matcherForSubview:(id<GREYMatcher>)matcher {
  NSString *prefix = @"subview";
  GREYMatchesBlock matches = ^BOOL(id element) {
    NSArray<id> *children = GREYTraversalExploreImmediateChildren(element, NO);

    for (id child in children) {
      if ([matcher matches:child] && child != element) {
        return YES;
      }
    }

    return NO;
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:[NSString stringWithFormat:@"%@(%@)", prefix, matcher]];
  };
  return [[GREYElementMatcherBlock alloc] initWithName:GREYCorePrefixedDiagnosticsID(prefix)
                                          matchesBlock:matches
                                      descriptionBlock:describe];
}

+ (id<GREYMatcher>)matcherForSibling:(id<GREYMatcher>)matcher {
  NSString *prefix = @"sibling";
  GREYMatchesBlock matches = ^BOOL(id element) {
    id parent = [element isKindOfClass:[UIView class]] ? [element superview]
                                                       : [element accessibilityContainer];
    if (!parent) {
      return NO;
    }
    NSArray<id> *children = GREYTraversalExploreImmediateChildren(parent, NO);
    for (id child in children) {
      if ([matcher matches:child] && child != element) {
        return YES;
      }
    }
    return NO;
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:[NSString stringWithFormat:@"%@(%@)", prefix, matcher]];
  };
  return [[GREYElementMatcherBlock alloc] initWithName:GREYCorePrefixedDiagnosticsID(prefix)
                                          matchesBlock:matches
                                      descriptionBlock:describe];
}

+ (id<GREYMatcher>)matcherForSwiftUI {
  NSString *prefix = @"isSwiftUI";
  GREYMatchesBlock matches = ^BOOL(id element) {
    NSString *elementClass = NSStringFromClass([element class]);
    return [elementClass hasPrefix:kSwiftUIConstant];
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:prefix];
  };

  return [[GREYElementMatcherBlock alloc] initWithName:GREYCorePrefixedDiagnosticsID(prefix)
                                          matchesBlock:matches
                                      descriptionBlock:describe];
}

#pragma mark - Private

/**
 * @return An iOS 17 only API to match with the now out of process activity sheet.
 */
+ (id<GREYMatcher>)activitySheetPresentMatcher {
  NSString *prefix = @"isActivitySheet";
  GREYMatchesBlock matches = ^BOOL(id element) {
    if ([element respondsToSelector:@selector(scene)]) {
      id scene = [element scene];
      if ([scene respondsToSelector:@selector(identifier)]) {
        return [[scene identifier] hasPrefix:@"scene::SharingUI::"];
      }
    }
    return NO;
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:@"Activity List View Present"];
  };
  NSArray<id<GREYMatcher>> *matchersArray = @[
    [GREYMatchers matcherForKindOfClassName:kActivitySheetContainerClass],
    [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matches descriptionBlock:describe],
  ];
  return [[GREYAllOf alloc] initWithName:GREYCorePrefixedDiagnosticsID(prefix)
                                matchers:matchersArray];
}

/**
 * @return @c YES if the strings have the same string values, @c NO otherwise.
 */
+ (BOOL)accessibilityString:(id)firstString isEqualToAccessibilityString:(id)secondString {
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
