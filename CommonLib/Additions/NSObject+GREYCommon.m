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

#import "NSObject+GREYCommon.h"
#import "GREYConstants.h"

/**
 *  Class that all Web Accessibility Elements have to be a kind of.
 */
static Class gWebAccessibilityWrapper;

@implementation NSObject (GREYCommon)

+ (void)load {
  gWebAccessibilityWrapper = NSClassFromString(@"WebAccessibilityObjectWrapper");
}

- (UIView *)grey_viewContainingSelf {
  if ([self grey_isWebAccessibilityElement]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    // TODO: Perform a scan of UIWebView usage and deprecate if possible. // NOLINT
    return [[self grey_containersAssignableFromClass:[UIWebView class]] firstObject];
#pragma clang diagnostic pop
  } else if ([self isKindOfClass:[UIView class]]) {
    return [self grey_container];
  } else if ([self respondsToSelector:@selector(accessibilityContainer)]) {
    id container = [self grey_container];
    if (![container isKindOfClass:[UIView class]]) {
      return [container grey_viewContainingSelf];
    }
    return container;
  }
  return nil;
}

- (id)grey_container {
  if ([self isKindOfClass:[UIView class]]) {
    return [(UIView *)self superview];
  } else if ([self respondsToSelector:@selector(accessibilityContainer)]) {
    return [self performSelector:@selector(accessibilityContainer)];
  } else {
    return nil;
  }
}

- (NSArray *)grey_containersAssignableFromClass:(Class)klass {
  NSMutableArray *containers = [[NSMutableArray alloc] init];

  id container = self;
  do {
    container = [container grey_container];
    if ([container isKindOfClass:klass]) {
      [containers addObject:container];
    }
  } while (container);

  return containers;
}

/**
 *  @return @c YES if @c self is an accessibility element within a UIWebView, @c NO otherwise.
 */
- (BOOL)grey_isWebAccessibilityElement {
  return [self isKindOfClass:gWebAccessibilityWrapper];
}

- (NSString *)grey_description {
  NSMutableString *description = [[NSMutableString alloc] init];

  // Class information.
  [description appendFormat:@"<%@", NSStringFromClass([self class])];
  [description appendFormat:@":%p", self];

  // IsAccessibilityElement.
  if ([self respondsToSelector:@selector(isAccessibilityElement)]) {
    [description appendFormat:@"; isAccessible=%@", self.isAccessibilityElement ? @"Y" : @"N"];
  }

  // AccessibilityIdentifier from UIAccessibilityIdentification.
  if ([self respondsToSelector:@selector(accessibilityIdentifier)]) {
    NSString *value = [self performSelector:@selector(accessibilityIdentifier)];
    [description appendString:[self grey_formattedDescriptionOrEmptyStringForValue:value
                                                                        withPrefix:@"; AX.id="]];
  }

  // Include UIAccessibilityElement properties.

  // Accessibility Label.
  if ([self respondsToSelector:@selector(accessibilityLabel)]) {
    NSString *value = self.accessibilityLabel;
    [description appendString:[self grey_formattedDescriptionOrEmptyStringForValue:value
                                                                        withPrefix:@"; AX.label="]];
  }

  // Accessibility hint.
  if ([self respondsToSelector:@selector(accessibilityHint)]) {
    NSString *value = self.accessibilityHint;
    [description appendString:[self grey_formattedDescriptionOrEmptyStringForValue:value
                                                                        withPrefix:@"; AX.hint="]];
  }

  // Accessibility value.
  if ([self respondsToSelector:@selector(accessibilityValue)]) {
    NSString *value = self.accessibilityValue;
    [description appendString:[self grey_formattedDescriptionOrEmptyStringForValue:value
                                                                        withPrefix:@"; AX.value="]];
  }

  // Accessibility frame.
  if ([self respondsToSelector:@selector(accessibilityFrame)]) {
    [description appendFormat:@"; AX.frame=%@", NSStringFromCGRect(self.accessibilityFrame)];
  }

  // Accessibility activation point.
  if ([self respondsToSelector:@selector(accessibilityActivationPoint)]) {
    [description appendFormat:@"; AX.activationPoint=%@",
                              NSStringFromCGPoint(self.accessibilityActivationPoint)];
  }

  // Accessibility traits.
  if ([self respondsToSelector:@selector(accessibilityTraits)]) {
    [description appendFormat:@"; AX.traits=\'%@\'",
                              NSStringFromUIAccessibilityTraits(self.accessibilityTraits)];
  }

  // Accessibility element is focused from UIAccessibility.
  if ([self respondsToSelector:@selector(accessibilityElementIsFocused)]) {
    [description
        appendFormat:@"; AX.focused=\'%@\'", self.accessibilityElementIsFocused ? @"Y" : @"N"];
  }

  // Values present if view.
  if ([self isKindOfClass:[UIView class]]) {
    UIView *selfAsView = (UIView *)self;

    // View frame.
    [description appendFormat:@"; frame=%@", NSStringFromCGRect(selfAsView.frame)];

    // Visual properties.
    if (selfAsView.isOpaque) {
      [description appendString:@"; opaque"];
    }
    if (selfAsView.isHidden) {
      [description appendString:@"; hidden"];
    }

    [description appendFormat:@"; alpha=%g", selfAsView.alpha];

    if (!selfAsView.isUserInteractionEnabled) {
      [description appendString:@"; UIE=N"];
    }
  }

  // Check if control is enabled.
  if ([self isKindOfClass:[UIControl class]] && !((UIControl *)self).isEnabled) {
    [description appendString:@"; disabled"];
  }

  // Text used for presentation.
  if ([self respondsToSelector:@selector(text)]) {
    // The text method of private class UIWebDocumentView can throw an exception when calling its
    // text method while loading a web page.
    @try {
      NSString *text = [self performSelector:@selector(text)];
      [description appendFormat:@"; text=\'%@\'", !text ? @"" : text];
    } @catch (NSException *exception) {
      NSLog(@"Caught exception when calling text method on %@", self);
    }
  }

  [description appendString:@">"];
  return description;
}

- (NSString *)grey_shortDescription {
  NSMutableString *description = [[NSMutableString alloc] init];

  [description appendString:NSStringFromClass([self class])];

  if ([self respondsToSelector:@selector(accessibilityIdentifier)]) {
    NSString *accessibilityIdentifier = [self performSelector:@selector(accessibilityIdentifier)];
    NSString *axIdentifierDescription =
        [self grey_formattedDescriptionOrEmptyStringForValue:accessibilityIdentifier
                                                  withPrefix:@"; AX.id="];
    [description appendString:axIdentifierDescription];
  }

  if ([self respondsToSelector:@selector(accessibilityLabel)]) {
    NSString *axLabelDescription =
        [self grey_formattedDescriptionOrEmptyStringForValue:self.accessibilityLabel
                                                  withPrefix:@"; AX.label="];
    [description appendString:axLabelDescription];
  }

  return description;
}

- (NSString *)grey_objectDescription {
  return [[NSString alloc] initWithFormat:@"<%@: %p>", [self class], self];
}

#pragma mark - Private

- (NSString *)grey_formattedDescriptionOrEmptyStringForValue:(NSString *)value
                                                  withPrefix:(NSString *)prefix {
  NSMutableString *description = [[NSMutableString alloc] initWithString:@""];
  if (value.length > 0) {
    [description appendString:prefix];
    [description appendFormat:@"\'%@\'", value];
  }
  return description;
}

@end
