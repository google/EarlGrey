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

#import "GREYElementHierarchy.h"

#import "NSObject+GREYCommon.h"
#import "GREYFatalAsserts.h"
#import "GREYThrowDefines.h"
#import "GREYConstants.h"
#import "GREYUIWindowProvider.h"
#import "GREYTraversalDFS.h"

@implementation GREYElementHierarchy

+ (NSString *)hierarchyString {
  __block NSMutableString *log = [[NSMutableString alloc] init];
  void (^hierarchyBlock)(void) = ^(void) {
    long unsigned index = 0;
    for (UIWindow *window in [GREYUIWindowProvider allWindowsWithStatusBar:NO]) {
      if (index != 0) {
        [log appendString:@"\n"];
      }
      index++;
      [log appendFormat:@"========== Window %lu ==========\n\n%@", index,
                        [GREYElementHierarchy hierarchyStringForElement:window]];
    }
  };
  if (![NSThread isMainThread]) {
    dispatch_sync(dispatch_get_main_queue(), ^{
      hierarchyBlock();
    });
  } else {
    hierarchyBlock();
  }
  return log;
}

+ (NSString *)hierarchyStringForElement:(id)element {
  GREYThrowOnNilParameter(element);
  return [self hierarchyStringForElement:element withAnnotationDictionary:@{}];
}

#pragma mark - Private

/**
 *  Creates an NSString similar to GREYElementHierarchy::hierarchyStringForElement:.
 *
 *  @param element              The UI element to be printed.
 *  @param annotationDictionary The annotations to be applied.
 *
 *  @return A string containing the full view hierarchy from the given @c element.
 */
+ (NSString *)hierarchyStringForElement:(id)element
               withAnnotationDictionary:(NSDictionary *)annotationDictionary {
  GREYFatalAssert(element);
  NSMutableString *outputString = [[NSMutableString alloc] init];

  NSMutableString *animationInfoString = [[NSMutableString alloc] init];

  // Traverse the hierarchy associated with the element.
  GREYTraversalDFS *traversal =
      [GREYTraversalDFS frontToBackHierarchyForElementWithDFSTraversal:element];

  // Enumerate the hierarchy using block enumeration.
  [traversal enumerateUsingBlock:^(id _Nonnull element, NSUInteger level, CGRect boundingRect,
                                   BOOL *stop) {
    // Obtain hierarchy Info.
    if ([outputString length] != 0) {
      [outputString appendString:@"\n"];
    }
    [outputString appendString:[self grey_printDescriptionForElement:element atLevel:level]];
    NSString *annotation = annotationDictionary[[NSValue valueWithNonretainedObject:element]];
    if (annotation) {
      [outputString appendString:@" "];  // Space before annotation.
      [outputString appendString:annotation];
    }
    // Obtain animation info.
    [animationInfoString appendString:[self grey_animationInfoForView:element]];
  }];

  if ([animationInfoString length] != 0) {
    NSString *animationInfoWithTitle = [@"\n\n**** Currently Animating Elements: ****\n"
        stringByAppendingString:animationInfoString];
    [outputString appendString:animationInfoWithTitle];
  } else {
    [outputString appendString:@"\n\n**** No Animating Views Found. ****"];
  }
  [outputString appendString:@"\n"];

  return outputString;
}

/**
 *  @return An NSString with info about any animation attached to the specified element's layer.
 *
 *  @param element An object for an accessibility element or a UIView present in the UI hierarchy.
 */
+ (NSString *)grey_animationInfoForView:(id)element {
  NSMutableString *animationInfoForView = [[NSMutableString alloc] init];
  if ([element isKindOfClass:[UIView class]]) {
    UIView *view = (UIView *)element;
    // MDCActivityIndicators which don't add animations to layers.
    if ([view isKindOfClass:NSClassFromString(@"MDCActivityIndicator")] &&
        [view.accessibilityValue isEqualToString:@"In Progress"]) {
      [animationInfoForView
          appendFormat:@"\nAnimating MDCActivityIndicator: %@", [view grey_objectDescription]];
    } else {
      NSArray *animationKeys = [view.layer animationKeys];
      if ([animationKeys count] > 0) {
        [animationInfoForView appendFormat:@"\nUIView: %@", [view grey_objectDescription]];
        // Obtain the animation from the animation keys and check if it is being tracked.
        for (NSString *animationKey in animationKeys) {
          [animationInfoForView appendFormat:@"\n    AnimationKey: %@ withAnimation: %@",
                                             animationKey,
                                             [view.layer animationForKey:animationKey]];
        }
      }
    }
  }
  return animationInfoForView;
}

/**
 *  Creates and outputs the description in the correct format for the @c element at a particular @c
 *  level (depth of the element in the view hierarchy).
 *
 *  @param element The element whose description is to be printed.
 *  @param level   The depth of the element in the view hierarchy.
 *
 *  @return A string with the description of the given @c element.
 */
+ (NSString *)grey_printDescriptionForElement:(id)element atLevel:(NSUInteger)level {
  GREYFatalAssert(element);
  NSMutableString *printOutput = [NSMutableString stringWithString:@""];

  if (level > 0) {
    [printOutput appendString:@"  "];
    for (NSUInteger space = 0; space < level; space++) {
      if (space != level - 1) {
        [printOutput appendString:@"|  "];
      } else {
        [printOutput appendString:@"|--"];
      }
    }
  }
  [printOutput appendString:[element grey_description]];
  return printOutput;
}

@end
