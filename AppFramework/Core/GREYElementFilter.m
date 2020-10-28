//
// Copyright 2020 Google Inc.
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

#import "GREYElementFilter.h"

#import <UIKit/UIKit.h>

#import "GREYAppleInternals.h"
#import "GREYConstants.h"

/** Internal class for checking textfield ax elements. */
static Class gAccessibilityTextFieldElementClass;

@implementation GREYElementFilter

+ (void)initialize {
  if (self == [GREYElementFilter self]) {
    gAccessibilityTextFieldElementClass = NSClassFromString(kTextFieldAXElementClassName);
  }
}

+ (NSArray<id> *)filterElements:(NSArray<id> *)elements {
  NSArray<id> *dedupedTextFieldElements = [GREYElementFilter dedupedTextFieldFromElements:elements];
  return [GREYElementFilter parentViewFromRelatedAccessibleViews:dedupedTextFieldElements];
}

#pragma mark - Private

/**
 * De-dupes the list of elements by removing any accessibility element that has its parent
 * UITextField present. If no such combination exists, or if elements array does not contain
 * exactly two elements, it is returned as is.
 *
 * @param elements An NSArray of elements found from an element matcher.
 *
 * @return A UITextField if the matched elements were a UITextfield and its accessibility element,
 *         else the matched element(s).
 */
+ (NSArray<id> *)dedupedTextFieldFromElements:(NSArray<id> *)elements {
  // In iOS 13, a UITextField contained an accessibility element inside it with the same
  // accessibility id, label etc. leading to multiple elements being matched. This was removed in
  // iOS 14 so we return all the elements.
  if (@available(iOS 14.0, *)) {
    return elements;
  }
  // Pre-iOS 14, if two element are matched and one of them is the text field element, then return
  // the text field, else return both the elements.
  if (elements.count != 2) {
    return elements;
  } else {
    id possibleTextField;
    UIAccessibilityTextFieldElement *textFieldAxElement;
    for (id element in elements) {
      if ([element isKindOfClass:gAccessibilityTextFieldElementClass]) {
        textFieldAxElement = element;
      } else {
        possibleTextField = element;
      }
    }
    if ([textFieldAxElement textField] == possibleTextField) {
      return @[ possibleTextField ];
    } else {
      return elements;
    }
  }
}

/**
 * De-dupes elements if they are a superview/subview pair both have been matched via a matcher.
 * This is similar to the real world scenario where a container and its own subview can be set with
 * the same accessibility label and not have issues with the accessibility tree.
 *
 * @param elements An NSArray of elements found from an element matcher.
 *
 * @return An NSArray containing the superview if a superview / subview pair is found, else the
 * provided @c elements..
 */
+ (NSArray<id> *)parentViewFromRelatedAccessibleViews:(NSArray<id> *)elements {
  if (elements.count == 2) {
    if ([elements[0] isKindOfClass:[UIView class]] && [elements[1] isKindOfClass:[UIView class]]) {
      UIView *firstView = elements[0];
      UIView *secondView = elements[1];
      // We check here only for accessibility labels as this is congruent with a real-life scenario
      // of a container/view having the same label. Do not add more properties here without
      // confirming that it's not just a programming error.
      if (firstView.accessibilityLabel == secondView.accessibilityLabel) {
        if ([secondView isDescendantOfView:firstView]) {
          return @[ firstView ];
        } else if ([firstView isDescendantOfView:secondView]) {
          return @[ secondView ];
        }
      }
    }
  }
  return elements;
}

@end
