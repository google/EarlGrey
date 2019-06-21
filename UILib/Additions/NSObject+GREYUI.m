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

#import "NSObject+GREYUI.h"

#import "NSObject+GREYCommon.h"
#import "GREYElementHierarchy.h"

@implementation NSObject (GREYUI)

- (NSString *)grey_recursiveDescription {
  if ([self grey_isWebAccessibilityElement]) {
    return [GREYElementHierarchy hierarchyStringForElement:[self grey_viewContainingSelf]];
  } else if ([self isKindOfClass:[UIView class]] ||
             [self respondsToSelector:@selector(accessibilityContainer)]) {
    return [GREYElementHierarchy hierarchyStringForElement:self];
  } else {
    NSAssert(NO,
             @"The element hierarchy call is being made on an element that is not a valid "
             @"UI element.");
    return nil;
  }
}

@end
