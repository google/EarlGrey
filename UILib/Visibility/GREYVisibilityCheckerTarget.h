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

#import <UIKit/UIKit.h>

#import "GREYTraversalProperties.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Enum for indicating how much of the target element is covered by the element in
 *  GREYVisibilityCheckerTarget::obscureWithElement:boundingRect:
 */
typedef NS_ENUM(NSInteger, GREYVisibilityCheckerTargetObscureResult) {
  /**
   *  Target was not obscured by the element, i. e. element does not intersect
   *  with the target element.
   */
  GREYVisibilityCheckerTargetObscureResultNone,
  /**
   *  Target was obscured partially, i.e., element intersects, but not fully, with the target
   *  element.
   */
  GREYVisibilityCheckerTargetObscureResultPartial,
  /**
   *  Target was completely obscured by the element, i.e., the intersection is the same as the
   *  target's rect.
   */
  GREYVisibilityCheckerTargetObscureResultFull,
};

/**
 *  A representation of the target element used for checking visiblility status.
 */
@interface GREYVisibilityCheckerTarget : NSObject

/**
 *  @remark init is not an available initializer. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 *  Initiates an instance with the specified target element and @c boundingRect.
 *
 *  @param target          The target element interested in calculating the visible percentage of.
 *                         It could be either an object that conforms to UIAccessibility informal
 *                         protocol or a UIView instance.
 *  @param properties      Properties that @c target inherited from its ancestors during traversal.
 *  @param interactability The boolean to specify if the target is checked for its interactability.
 *
 *  @return An instance of GREYVisibilityCheckerTarget, initialized with the specified information.
 *          Returns @c nil if the target is not visible.
 */
- (instancetype)initWithTarget:(id)target
                    properties:(GREYTraversalProperties *)properties
               interactability:(BOOL)interactability;

/**
 *  Compares and intersects the element's frame to the @c _target's frame and calculates how much of
 *  @c _target is intersected with the element. The intersected area is where the @c _target is
 *  obscured by the element. The intersection rects are later subtracted from the @c _target's frame
 *  to calculate how much of the @c _target's frame has been obscured.
 *
 *  @param element    The element whose frame is being compared with target element.
 *  @param properties Properties that @c element inherited from its ancestors during traversal.
 *
 *  @return A @c GREYVisibilityCheckerTargetObscureResult that indicates how much of the @c _target
 *          element obscured.
 */
- (GREYVisibilityCheckerTargetObscureResult)
    obscureResultByOverlappingElement:(id)element
                           properties:(GREYTraversalProperties *)properties;
/**
 *  Percentage of the target element that is visible on the screen. This lazily calculates the
 *  visible percentage using the overlapping elements. Invoke this with caution as this is an
 *  expensive operation.
 *
 *  @return A double value indicating the percentage visible.
 */
- (CGFloat)percentageVisible;

/**
 *  @return The point in element that is interactable where a user can tap to interact with.
 */
- (CGPoint)interactionPoint;

@end

NS_ASSUME_NONNULL_END
