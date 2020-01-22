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

+ (NSArray<id> *)dedupedTextFieldFromElements:(NSArray<id> *)elements {
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

@end
