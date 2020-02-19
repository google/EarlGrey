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

#import "GREYTraversalObject.h"

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
 *  Initiates an instance with the specified target object and @c boundingRect.
 *
 *  @param object          The target object the visible percentage is being calculated of.
 *                         The wrapped element could be either an NSObject that conforms to
 *                         UIAccessibility informal protocol or a UIView instance.
 *  @param interactability The boolean to specify if the target is checked for its interactability.
 *
 *  @return An instance of GREYVisibilityCheckerTarget, initialized with the specified information.
 *          Returns @c nil if the target is not visible.
 */
- (instancetype)initWithObject:(GREYTraversalObject *)object interactability:(BOOL)interactability;

/**
 *  Compares and intersects the object's frame to the target's frame and calculates how much of
 *  target is intersected with the object. The intersected area is where the target is obscured by
 *  the element. The intersection rects are later subtracted from the target's frame to calculate
 *  how much of the target's frame has been obscured.
 *
 *  @param object The traversing object whose frame is being compared with target element.
 *
 *  @return A @c GREYVisibilityCheckerTargetObscureResult that indicates how much of the target
 *          element obscured.
 */
- (GREYVisibilityCheckerTargetObscureResult)obscureResultByOverlappingObject:
    (GREYTraversalObject *)object;

/**
 *  @return A double value indicating the percentage visible of the target that is visible on
 *          screen. This lazily calculates the remaining visible area using the intersecting rects,
 *          so invoke this with caution.
 */
- (CGFloat)percentageVisible;

/**
 *  @return The point in element that is interactable where a user can tap to interact with. This
 *          lazily calculates the remaining visible area using the intersecting rects, so invoke
 *          this with caution.
 */
- (CGPoint)interactionPoint;

/**
 *  TODO(b/146083877): Add support for custom drawn views.
 *  @return A @c BOOL if the traversing view has a CAShapeLayer. Since quick visibility checker
 *          doesn't support custom drawn views yet, it cannot accurately obtain the visibility of an
 *          element obscured by a custom drawn view with CAShapeLayer. This check should be removed
 *          once quick visibility checker supports custom drawn views.
 */
BOOL GREYViewContainsCAShapeLayer(UIView *view);

@end

NS_ASSUME_NONNULL_END
