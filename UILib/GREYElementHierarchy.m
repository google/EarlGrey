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
#import "GREYUIWindowProvider.h"
#import "GREYTraversalDFS.h"
#import "GREYTraversalObject.h"

@implementation GREYElementHierarchy

+ (NSString *)hierarchyString {
  __block NSMutableString *log = [[NSMutableString alloc] init];
  void (^hierarchyBlock)(void) = ^(void) {
    long unsigned index = 0;
    NSArray<UIWindow *> *windows = [GREYUIWindowProvider allWindowsWithStatusBar:NO];
    for (UIWindow *window in windows.reverseObjectEnumerator) {
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
 * Creates an NSString similar to GREYElementHierarchy::hierarchyStringForElement:.
 *
 * @param element              The UI element to be printed.
 * @param annotationDictionary The annotations to be applied.
 *
 * @return A string containing the full view hierarchy from the given @c element.
 */
+ (NSString *)hierarchyStringForElement:(id)element
               withAnnotationDictionary:
                   (NSDictionary<NSValue *, NSString *> *)annotationDictionary {
  GREYFatalAssert(element);
  NSMutableString *outputString = [[NSMutableString alloc] init];

  NSMutableDictionary<NSString *, NSString *> *animationInfoDict =
      [[NSMutableDictionary alloc] init];

  // Traverse the hierarchy associated with the element from back to front as per the
  // UIView::subviews order.
  GREYTraversalDFS *traversal =
      [GREYTraversalDFS backToFrontHierarchyForElementWithDFSTraversal:element zOrdering:NO];

  // Enumerate the hierarchy using block enumeration.
  [traversal enumerateUsingBlock:^(GREYTraversalObject *object, BOOL *stop) {
    // Obtain hierarchy Info.
    id hierarchyElement = object.element;
    if ([outputString length] != 0) {
      [outputString appendString:@"\n"];
    }
    NSString *description = [GREYElementHierarchy grey_printDescriptionForElement:hierarchyElement
                                                                          atLevel:object.level];
    [outputString appendString:description];
    NSValue *hierarchyElementAsValue = [NSValue valueWithNonretainedObject:hierarchyElement];
    NSString *annotation = annotationDictionary[hierarchyElementAsValue];
    if (annotation) {
      [outputString appendString:@" "];  // Space before annotation.
      [outputString appendString:annotation];
    }
    // Obtain animation info.
    DedupeAndAppendAnimationInfoForView(hierarchyElement, animationInfoDict);
  }];

  if ([animationInfoDict count] != 0) {
    NSMutableString *animations = [[NSMutableString alloc] init];
    for (NSString *animation in [animationInfoDict allKeys]) {
      [animations appendString:animationInfoDict[animation]];
    }
    NSString *animationInfoWithTitle =
        [@"\n\n**** Currently Animating Elements: ****\n" stringByAppendingString:animations];
    [outputString appendString:animationInfoWithTitle];
  } else {
    [outputString appendString:@"\n\n**** No Animating Views Found. ****"];
  }
  [outputString appendString:@"\n"];

  return outputString;
}

/**
 * Adds any info about any animation attached to the layer and sublayers of the @c
 * element.
 *
 * @remark To ensure no duplicate animation are seen, a dictionary is passed in which ensures that
 *         animations are deduped to the last view whose sublayer they were added to.
 *
 * @param element             An object for an accessibility element or a UIView present in the UI
 *                            hierarchy.
 * @param animationDictionary The NSMutableDictionary to add the animation and its info to. This
 *                            ensures no duplicate information is added.
 */
static void DedupeAndAppendAnimationInfoForView(
    id element, NSMutableDictionary<NSString *, NSString *> *animationDictionary) {
  if ([element isKindOfClass:[UIView class]]) {
    UIView *view = (UIView *)element;
    // MDCActivityIndicators which don't add animations to layers.
    NSString *axValue = view.accessibilityValue;
    if ([view isKindOfClass:NSClassFromString(@"MDCActivityIndicator")] &&
        ([axValue isEqualToString:@"In Progress"] ||
         [axValue containsString:@"Percent Complete"])) {
      NSString *activityIndicatorInfo = [NSString
          stringWithFormat:@"\nAnimating MDCActivityIndicator: %@", [view grey_objectDescription]];
      [animationDictionary setValue:activityIndicatorInfo forKey:@"In-progress Activity Indicator"];
    } else {
      NSMutableArray<CALayer *> *layers = [[NSMutableArray alloc] initWithObjects:view.layer, nil];
      while ([layers count] > 0) {
        CALayer *firstLayer = [layers firstObject];
        DedupeAndAppendAnimationInfoForLayerOfView(firstLayer, view, animationDictionary);
        [layers addObjectsFromArray:[firstLayer sublayers]];
        [layers removeObjectAtIndex:0];
      }
    }
  }
}

/**
 * Adds any info about any animation attached to the specified @c layer obtained from the @c view to
 * the @c animationDictionary.
 *
 * @param layer               The CALayer being checked for animations.
 * @param view                The UIView for which the animation information is to be obtained.
 *                            Passed for adding a key for the animation.
 * @param animationDictionary The NSMutableDictionary to add the animation and its info to. This
 *                            ensures no duplicate information is added.
 */
static void DedupeAndAppendAnimationInfoForLayerOfView(
    CALayer *layer, UIView *view,
    NSMutableDictionary<NSString *, NSString *> *animationDictionary) {
  for (NSString *animationKey in layer.animationKeys) {
    CAAnimation *animation = [layer animationForKey:animationKey];
    NSString *animationInfo =
        [NSString stringWithFormat:@"\nUIView: %@\n    AnimationKey: %@ withAnimation: %@",
                                   [view grey_objectDescription], animationKey, animation];
    [animationDictionary setObject:animationInfo forKey:animation.description];
  }
}

/**
 * Creates the description in the correct format for the @c element at a particular @c
 * level (depth of the element in the view hierarchy).
 *
 * @param element The element whose description is to be printed.
 * @param level   The depth of the element in the view hierarchy.
 *
 * @return A string with the description of the given @c element.
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
