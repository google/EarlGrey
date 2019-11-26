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

#import <UIKit/UIKit.h>

#import "GREYTraversalProperties.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Explores the immediate children of @c element, including accessibility elements.
 *
 *  @param element         The UI element whose children are to be explored.
 *  @param sortByZPosition Whether or not to sort immediate children by @c zPosition of the
 *                         respective views. This is used mainly in visibility checker to
 *                         iterate the view hierarchy back to front just as it is rendered on
 *                         screen.
 *
 *  @return Creates a new NSArray* that contains the immediate children of @c element. The children
 *  are ordered from front to back, meaning subviews that were added first are present later in the
 *  array. If no children exist, then an empty array is returned.
 */
NSArray<id> *GREYTraversalExploreImmediateChildren(id element, BOOL sortByZPosition);

/**
 *  UIView properties that an element inherited from its ancestors in the view hierarchy.
 *
 *  @param element The element to get the properties of.
 *
 *  @return View properties that the @c element mimics. @c nil if @c element is a non-UIView.
 */
GREYTraversalProperties *GREYTraversalPropertiesForElement(id element);

/**
 *  Pass down the values of the parent's UIView properties to its child to help determining the
 *  behavior of each element.
 *
 *  UIView property values are not inherited to its children in the view hierarchy, although they
 *  mimic the behavior of their parent views. So it's not possible to determine how a view
 *  might behave just alone with its own property values. You would have to investigate all of its
 *  ancestors to do so. For instance, a view is not visible by the user if any of its ancestors
 *  are either hidden or has an alpha equal to zero, regardless of what its own properties are set
 *  to. To keep track of these absolute properties of each views, the values are inherited to its
 *  children appropriately during the traversal.
 *
 *  @param parentProperties Properties that are being passed down.
 *  @param parentView       UI element whose properties are being passed down. This should always be
 *                          a UIView.
 *  @param childElement     UI element to pass down the properties to. This can be either a UIView
 *                          or an accessibility element.
 *
 *  @return Child's traversal properties that are inherited by @c parentObject's properties.
 */
GREYTraversalProperties *GREYTraversalPassDownProperties(GREYTraversalProperties *parentProperties,
                                                         UIView *parentView, id childElement);

NS_ASSUME_NONNULL_END
