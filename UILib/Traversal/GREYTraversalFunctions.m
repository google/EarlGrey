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

#import "GREYTraversalFunctions.h"

#import <UIKit/UIKit.h>

#import "GREYThrowDefines.h"
#import "GREYConstants.h"
#import "CGGeometry+GREYUI.h"

NS_ASSUME_NONNULL_BEGIN

NSArray<id> *GREYTraversalExploreImmediateChildren(id element, BOOL sortByZPosition) {
  GREYThrowInFunctionOnNilParameter(element);

  NSMutableOrderedSet<id> *immediateChildren = [[NSMutableOrderedSet alloc] init];

  if ([element isKindOfClass:[UIView class]]) {
    // Grab all subviews so that we continue traversing the entire hierarchy.
    // Add the objects in reverse order to make sure that objects on top get matched first.
    NSArray<id> *subviews = [element subviews];
    if ([subviews count] > 0) {
      for (UIView *subview in [subviews reverseObjectEnumerator]) {
        [immediateChildren addObject:subview];
      }
    }
  }

  // Accessibility elements of the current element (if any) need not be sorted due to the following
  // reasons:
  // (1) If any of the accessibility elements were a UIView, it would have been added to the
  // immediateChildren already (thus subject to sorting.)
  // (2) If it were a UIView that is not anyone's subview, zPosition would not matter because it's
  // not visible to the user anyway.
  // (3) If it were an accessibility element (not a UIView), it does not have a zPosition property.
  if (sortByZPosition) {
    // Must be stable sort because the views should maintain order when zPosition is same. Note that
    // the set only contains UIView instances at this point.
    [immediateChildren sortWithOptions:NSSortStable
                       usingComparator:^NSComparisonResult(UIView *view1, UIView *view2) {
                         return [@(view2.layer.zPosition) compare:@(view1.layer.zPosition)];
                       }];
  }

  // If we encounter an accessibility container, grab all the contained accessibility elements.
  // However, we need to skip a few types of containers:
  // 1) UITableViewCells as they do a lot of custom accessibility work underneath
  //    and the accessibility elements they return are 'mocks' that cause access errors.
  // 2) UITableViews as because they report all their cells, even the ones off-screen as
  //    accessibility elements. We should not consider off-screen cells as there could be
  //    hundreds, even thousands of them and we would be iterating over them unnecessarily.
  //    Worse yet, if the cell isn't visible, calling accessibilityElementAtIndex will create
  //    and initialize them each time.
  if ([element respondsToSelector:@selector(accessibilityElementCount)] &&
      ![element isKindOfClass:[UITableView class]] &&
      ![element isKindOfClass:[UITableViewCell class]]) {
    NSInteger elementCount = [element accessibilityElementCount];
    if (elementCount != NSNotFound && elementCount > 0) {
      if ([element isKindOfClass:NSClassFromString(@"UIPickerTableView")]) {
        // If we hit a picker table view then we will limit the number of elements to 500 since
        // we don't want to timeout searching through identical views that are created to make
        // it seem like there is an infinite number of items in the picker.
        elementCount = MIN(elementCount, kUIPickerViewMaxAccessibilityViews);
      }
      // Temp holder created by UIKit. What we really want is the underlying element.
      Class accessibilityMockClass = NSClassFromString(@"UIAccessibilityElementMockView");
      for (NSInteger i = elementCount - 1; i >= 0; i--) {
        id item = [element accessibilityElementAtIndex:i];
        if ([item isKindOfClass:accessibilityMockClass]) {
          // Replace mock views with the views they encapsulate.
          item = [item view];
        }

        if (!item) {
          continue;
        }

        // If item is a UIView subclass, it could be both a subview of another view and an
        // accssibility element of a different accessibility container (which is not necessarily its
        // superview). This could introduce elements being duplicated in the view hierarchy.
        if ([item isKindOfClass:[UIView class]]) {
          // Only add the item as the element's immediate children if it meets these conditions:
          // (1) Item's superview is the element. This ensures that other accessibility containers
          //     don't add it as their immeditate children.
          // (2) Item does not have a superview. If item does not have a superview, you can ensure
          //     it's being added only once as an accessibility element of a container.
          id superview = [item superview];
          if (superview == element || !superview) {
            [immediateChildren addObject:item];
          }
        } else {
          // If the item not a UIView subclass, it's mostly safe to add it as immediate child
          // since no two accessibility containers should add the same accessible element.
          [immediateChildren addObject:item];
        }
      }
    }
  }

  return [immediateChildren array];
}

GREYTraversalViewProperties *GREYTraversalPropertiesForElement(id element) {
  if (![element isKindOfClass:[UIView class]]) {
    return nil;
  }
  UIView *view = (UIView *)element;
  NSMutableArray<UIView *> *viewPath = [[NSMutableArray alloc] init];
  // Traverse to the root, and store ancestors of the element, except the root element.
  while (view.superview) {
    [viewPath insertObject:view atIndex:0];
    view = view.superview;
  }
  // View is at the root.
  GREYTraversalViewProperties *properties =
      [[GREYTraversalViewProperties alloc] initWithBoundingRect:CGRectNull
                                                         hidden:view.hidden
                                         userInteractionEnabled:view.userInteractionEnabled
                                                    lowestAlpha:view.alpha];
  UIView *parentView = view;
  // Pass down the properties to the original element.
  for (NSUInteger i = 0; i < viewPath.count; i++) {
    UIView *childView = viewPath[i];
    properties = GREYTraversalPassDownProperties(properties, parentView, childView);
    parentView = childView;
  }
  return properties;
}

GREYTraversalViewProperties *GREYTraversalPassDownProperties(
    GREYTraversalViewProperties *parentProperties, id parentElement, id childElement) {
  if (![childElement isKindOfClass:[UIView class]] ||
      ![parentElement isKindOfClass:[UIView class]]) {
    return nil;
  }
  UIView *parentView = (UIView *)parentElement;
  UIView *childView = (UIView *)childElement;

  // If parent view hidden, its children are hidden too, regardless of their hidden properties.
  BOOL hidden = parentProperties.hidden || childView.hidden;
  // If parent view disables user interaction, its children are disabled too, regardless of their
  // userInteractionEnabled properties.
  BOOL userInteractionEnabled =
      parentProperties.userInteractionEnabled && childView.userInteractionEnabled;
  // View mimics the behavior of the lowest alpha among its ancestors.
  CGFloat alpha = MIN(parentProperties.lowestAlpha, childView.alpha);
  CGRect boundingRect;
  {
    // This updates the bounding area of each traversal object. If the parent view's clipsToBound is
    // set to YES, update the bounding area applying the parent view's frame. Otherwise, pass down
    // the current view's bounding area. The bounding rect should be converted to the current view's
    // coordinate space.
    CGRect convertedBoundingRect = [[parentView superview] convertRect:parentProperties.boundingRect
                                                                toView:parentView];
    CGRect convertedParentRect = [[parentView superview] convertRect:parentView.frame
                                                              toView:parentView];
    if (![parentView superview]) {
      boundingRect = CGRectNull;
    } else if ([parentView clipsToBounds]) {
      if (CGRectEqualToRect(parentProperties.boundingRect, CGRectNull)) {
        // If there's currently no boundingRect, update it to parent's frame.
        boundingRect = convertedParentRect;
      } else {
        CGRect intersectionRect =
            CGRectIntersectionStrict(convertedBoundingRect, convertedParentRect);
        if (CGRectIsNull(intersectionRect)) {
          // If the boundingRect does not intersect with parent's frame, boundingRect stays the same
          // as parent view would be clipped in the boundingRect.
          boundingRect = convertedBoundingRect;
        } else {
          boundingRect = intersectionRect;
        }
      }
    } else {
      // If parent does not clip, pass down boundingRect.
      boundingRect = convertedBoundingRect;
    }
  }

  GREYTraversalViewProperties *properties =
      [[GREYTraversalViewProperties alloc] initWithBoundingRect:boundingRect
                                                         hidden:hidden
                                         userInteractionEnabled:userInteractionEnabled
                                                    lowestAlpha:alpha];
  return properties;
}

NS_ASSUME_NONNULL_END
