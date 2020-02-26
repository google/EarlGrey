//
// Copyright 2019 Google Inc.
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

#import "GREYQuickVisibilityChecker.h"

#import <UIKit/UIKit.h>

#import "NSObject+GREYCommon.h"
#import "CGGeometry+GREYUI.h"
#import "GREYUIWindowProvider.h"
#import "GREYTraversalDFS.h"
#import "GREYTraversalFunctions.h"
#import "GREYVisibilityCheckerTarget.h"

@implementation GREYQuickVisibilityChecker

// TODO(b/135684391): Traverse each sublayers of the view (if it exists), and check if
// it obscures the target. Note: There might be cases where a view's layer has sublayer(s) that
// extends out from the view's boundary and obscure other views. Since the quick visibility checker
// does not check each sublayers for that case, there could be false positive result.
+ (CGFloat)percentVisibleAreaOfElement:(id)element performFallback:(BOOL *)performFallback {
  GREYVisibilityCheckerTarget *target = ResultingTarget(element, performFallback, NO);
  return *performFallback ? nanf(NULL) : [target percentageVisible];
}

+ (CGPoint)visibleInteractionPointForElement:(id)element performFallback:(BOOL *)performFallback {
  GREYVisibilityCheckerTarget *target = ResultingTarget(element, performFallback, YES);
  return target ? [target interactionPoint] : GREYCGPointNull;
}

#pragma mark - Private

/**
 *  Determines whether or not the current target is eligible for quick visibility check by checking
 *  certain criteria. If the following criteria is met, a fallback needs to be performed as the
 *  quick visibility checker can no longer provide an accurate answer. Invoke this method for each
 *  element that's drawn after the target element in the view hierarchy. Perform fallback if the @c
 *  element is transformed. Because quick visibility checker performs a frame by frame comparison,
 *  it cannot accurately determine the visibility of the target under a transformed view.
 *
 *  @param element Element that is drawn on top of target in the view hierarchy.
 *
 *  @return Whether or not a fallback is required.
 */
static BOOL ShouldPerformThoroughVisibilityCheckForElement(id element) {
  if ([element isKindOfClass:[UIView class]]) {
    UIView *view = (UIView *)element;
    if (!CGAffineTransformEqualToTransform(CGAffineTransformIdentity, [view transform])) {
      return YES;
    } else if (GREYIsInvalidView(view)) {
      return YES;
    }
  }
  return NO;
}

/**
 *  @return UIWindow that contains @c element.
 */
static UIWindow *WindowContainingElement(id element) {
  UIWindow *containerWindow;
  // Get window that contains element.
  if ([element isKindOfClass:[UIWindow class]]) {
    containerWindow = (UIWindow *)element;
  } else {
    UIView *container = [element grey_viewContainingSelf];
    if (!container) {
      return nil;
    } else if ([container isKindOfClass:[UIWindow class]]) {
      containerWindow = (UIWindow *)container;
    } else {
      containerWindow = container.window;
    }
  }
  return containerWindow;
}

/**
 *  Traverses the view hierarchy to determine the visibility of the target element. It traverses the
 *  view hierarchy from back to front until it finds the target element whose visible percentage is
 *  being calculated. Once the target element is found, each subsequent elements' frames are
 *  compared and intersected with the target element's frame to see how much they obscure the target
 *  by. At the end of the iteration, we will have the the information to check the visibility status
 *  of the target element populated in GREYVisibilityCheckerTarget. Note that we are only interested
 *  in the elements that are drawn after target element because any elements behind the target
 *  element would not affect its visibility.
 *
 *  @param      element         Target element to check the visibility status of.
 *  @param[out] performFallback An out parameter that indicates whether or not a more accurate
 *                              visibility checking is required. Use GREYThoroughVisibilityChecker
 *                              instead.
 *  @param      interactability Whether or not the resulting target should take interactability into
 *                              consideration when obscuring the target.
 *
 *  @return GREYVisibilityCheckerTarget instance populated with the view hierarchy. @c nil if
 *          element is not visible.
 */
static GREYVisibilityCheckerTarget *ResultingTarget(id element, BOOL *performFallback,
                                                    BOOL interactability) {
  __block GREYVisibilityCheckerTarget *target;
  __block BOOL stopWindowTraversal = NO;
  *performFallback = NO;
  UIWindow *containerWindow = WindowContainingElement(element);
  // Element is not visible because it does not have a parent view.
  if (!containerWindow) {
    return nil;
  }
  NSEnumerator<UIWindow *> *windowsBackToFrontEnumerator =
      [GREYUIWindowProvider windowsFromLevelOfWindow:containerWindow withStatusBar:NO]
          .reverseObjectEnumerator;
  for (UIWindow *window in windowsBackToFrontEnumerator) {
    if (stopWindowTraversal) {
      break;
    }
    // If you are looking for the visibility of a UIWindow, skip all its subviews.
    if (window == element) {
      GREYTraversalProperties *properties = GREYTraversalPropertiesForElement(window);
      GREYTraversalObject *object = [[GREYTraversalObject alloc] initWithElement:element
                                                                           level:0
                                                                      properties:properties];
      target = [[GREYVisibilityCheckerTarget alloc] initWithObject:object
                                                   interactability:interactability];
      continue;
    }
    GREYTraversalDFS *traversal =
        [GREYTraversalDFS backToFrontHierarchyForElementWithDFSTraversal:window zOrdering:YES];
    __block NSUInteger targetLevel = 0;
    __block BOOL isTargetChild = YES;
    // Traverse the hierarchy until the target element is found.
    [traversal enumerateUsingBlock:^(GREYTraversalObject *object, BOOL *stopElementTraversal) {
      id currentElement = object.element;
      // If the target is seen and the current level is smaller or equal to target's level, this
      // implies that target's children have been traversed already.
      if (target && object.level <= targetLevel) {
        isTargetChild = NO;
      }
      if (target && !isTargetChild) {
        GREYVisibilityCheckerTargetObscureResult result =
            [target obscureResultByOverlappingObject:object];
        switch (result) {
          case GREYVisibilityCheckerTargetObscureResultFull: {
            // If the target is fully obscured, stop traversing.
            *stopElementTraversal = YES;
            stopWindowTraversal = YES;

            if (ShouldPerformThoroughVisibilityCheckForElement(currentElement)) {
              *performFallback = YES;
            }
            break;
          }
          case GREYVisibilityCheckerTargetObscureResultPartial: {
            // If the target was partially obscured by the element, check if the traversing element
            // requires thorough check.
            if (ShouldPerformThoroughVisibilityCheckForElement(currentElement)) {
              *stopElementTraversal = YES;
              stopWindowTraversal = YES;
              *performFallback = YES;
            }
            break;
          }
          default:
            break;
        }
      } else if (currentElement == element) {
        target = [[GREYVisibilityCheckerTarget alloc] initWithObject:object
                                                     interactability:interactability];
        targetLevel = object.level;
        // Target is not visible on screen. No need to traverse further.
        if (!target) {
          *stopElementTraversal = YES;
          stopWindowTraversal = YES;
        }
      }
    }];
  }
  return target;
}

@end
