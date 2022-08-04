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
#import "GREYLogger.h"

@implementation NSObject (GREYCommon)

- (UIView *)grey_viewContainingSelf {
  if ([self isKindOfClass:[UIView class]]) {
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

- (NSString *)grey_description {
  NSMutableString *description = [[NSMutableString alloc] init];

  // Class information.
  [description appendFormat:@"<%@", NSStringFromClass([self class])];
  [description appendFormat:@":%p", self];

  // IsAccessibilityElement.
  if ([self respondsToSelector:@selector(isAccessibilityElement)]) {
    [description appendFormat:@"; isAccessible=%@", self.isAccessibilityElement ? @"Y" : @"N"];
  }

  // IsAccessibilityElement.
  if ([self respondsToSelector:@selector(accessibilityViewIsModal)]) {
    [description
        appendFormat:@"; accessibilityViewIsModal=%@", self.accessibilityViewIsModal ? @"Y" : @"N"];
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

  // Is Accessibility View Modal.
  if ([self respondsToSelector:@selector(accessibilityViewIsModal)]) {
    [description appendFormat:@"; AX.isModal=%@", self.accessibilityViewIsModal ? @"Y" : @"N"];
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
      [description appendString:@"; User Interaction Disabled"];
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
      GREYLog(@"Caught exception when calling text method on %@", self);
    }
  }

  // Logically it would make more sense to use -conformsToProtocol: here, but it has known
  // performance issues, see "Performance Considerations" at:
  // https://developer.apple.com/documentation/objectivec/nsobject/1418893-conformstoprotocol.
  if ([self respondsToSelector:@selector(grey_extendedDescriptionAttributes)]) {
    id<GREYExtendedDescriptionAttributes> extendedSelf =
        (id<GREYExtendedDescriptionAttributes>)self;
    NSDictionary<NSString *, id> *_Nullable extendedAttributes =
        extendedSelf.grey_extendedDescriptionAttributes;
    // Since we didn't use -conformsToProtocol:, in theory the object could be implementing this
    // method with a different signature, so be paranoid about the type of the returned object.
    // This also checks for the nil-return case.
    if ([extendedAttributes isKindOfClass:[NSDictionary class]]) {
      for (NSString *attribute in extendedAttributes) {
        [description appendFormat:@"; %@=\'%@\'", attribute, extendedAttributes[attribute]];
      }
    }
  }

  [description appendString:@">"];
  return description;
}

- (id)viewCoveringByViewIsModal {
  if (![self respondsToSelector:@selector(superview)]) {
    return nil;
  }
  id superview = [(id)self superview];
  if (![superview respondsToSelector:@selector(subviews)]) {
    return nil;
  }
  NSArray<id> *subviews = (NSArray<id> *)[(id)superview subviews];
  for (id subview in subviews) {
    if (subview == self || ![subview respondsToSelector:@selector(accessibilityViewIsModal)]) {
      continue;
    }
    BOOL isModal = [(id)subview accessibilityViewIsModal];
    if (isModal) {
      return subview;
    }
  }
  return [(id)superview viewCoveringByViewIsModal];
}

- (NSString *)grey_shortDescription {
  NSMutableString *description = [[NSMutableString alloc] init];

  [description appendString:[[NSString alloc] initWithFormat:@"%@:%p", [self class], self]];

  if ([self respondsToSelector:@selector(accessibilityIdentifier)]) {
    NSString *accessibilityIdentifier = [self performSelector:@selector(accessibilityIdentifier)];
    NSString *axIdentifierDescription =
        [self grey_formattedDescriptionOrEmptyStringForValue:accessibilityIdentifier
                                                  withPrefix:@"; AX.id="];
    [description appendString:axIdentifierDescription];
  }

  if ([self respondsToSelector:@selector(accessibilityViewIsModal)]) {
    NSString *accessibilityViewIsModal =
        (BOOL)[self performSelector:@selector(accessibilityViewIsModal)] ? @"Y" : @"N";
    NSString *axViewIsModalDescription =
        [self grey_formattedDescriptionOrEmptyStringForValue:accessibilityViewIsModal
                                                  withPrefix:@"; AX.viewIsModal="];
    [description appendString:axViewIsModalDescription];
  }

  id coveringView = [self viewCoveringByViewIsModal];
  NSString *coveringViewDesc =
      (coveringView == nil)
          ? @"nil"
          : [NSString
                stringWithFormat:@"%@ %p", NSStringFromClass([coveringView class]), coveringView];
  NSString *coveringViewDescription =
      [self grey_formattedDescriptionOrEmptyStringForValue:coveringViewDesc
                                                withPrefix:@"; AX.coveredBy="];
  [description appendString:coveringViewDescription];

  if ([self respondsToSelector:@selector(accessibilityLabel)]) {
    NSString *axLabelDescription =
        [self grey_formattedDescriptionOrEmptyStringForValue:self.accessibilityLabel
                                                  withPrefix:@"; AX.label="];
    [description appendString:axLabelDescription];
  }

  return description;
}

- (NSString *)grey_objectDescription {
  return [[NSString alloc] initWithFormat:@"<%@:%p>", [self class], self];
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
