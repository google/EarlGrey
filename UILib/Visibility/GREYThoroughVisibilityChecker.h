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

#import "GREYConstants.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - GREYVisibilityDiffBuffer

/**
 * Data structure that holds a buffer representing the visible pixels of a visibility check diff.
 */
typedef struct GREYVisibilityDiffBuffer {
  BOOL *data;
  size_t width;
  size_t height;
} GREYVisibilityDiffBuffer;

/** Data structure to hold information about visible pixels. */
typedef struct GREYVisiblePixelData {
  /** The number of visible pixels. */
  NSUInteger visiblePixelCount;

  /**
   * A default pixel that's visible.
   * If no pixel is visible -- i.e. the visiblePixelCount = 0, then this is set to CGPointNull.
   */
  CGPoint visiblePixel;
} GREYVisiblePixelData;

/**
 * Creates a diff buffer with the specified width and height. This method allocates a buffer of
 * size: width * height, which must be released with GREYVisibilityDiffBufferRelease after being
 * used.
 *
 * @param width  The width of the diff buffer.
 * @param height The height of the diff buffer.
 */
GREYVisibilityDiffBuffer GREYVisibilityDiffBufferCreate(size_t width, size_t height);

/**
 * Releases the underlying storage for the diff buffer.
 *
 * @param buffer The buffer whose storage is to be released.
 */
void GREYVisibilityDiffBufferRelease(GREYVisibilityDiffBuffer buffer);

/**
 * Returns the visibility status for the point at the given x and y coordinates. Returns @c YES if
 * the point is visible, or @c NO if the point isn't visible or lies outside the buffer's bounds.
 *
 * @param buffer The buffer that is to be queried.
 * @param x      The x coordinate of the search point.
 * @param y      The y coordinate of the search point.
 */
BOOL GREYVisibilityDiffBufferIsVisible(GREYVisibilityDiffBuffer buffer, size_t x, size_t y);

/**
 * Changes the visibility value for the {@c x, @c y} position. If @c isVisible is @c YES the point
 * is marked as visible else it is marked as not visible.
 *
 * @param buffer    The buffer whose visibility is to be updated.
 * @param x         The x coordinate of the target point.
 * @param y         The y coordinate of the target point.
 * @param isVisible A boolean that indicates the new visibility status (@c YES for visible,
                     @c NO otherwise) for the target point.
 */
void GREYVisibilityDiffBufferSetVisibility(GREYVisibilityDiffBuffer buffer, size_t x, size_t y,
                                           BOOL isVisible);

#pragma mark - GREYVisibilityChecker

/**
 * Performs a pixel-by-pixel comparison to determine the visibility of an element. As
 * the name implies, this check yields better result than GREYQuickVisibilityChecker
 * because it covers complicated views (i.e. views with corner). However, because it
 * it is doing a pixel-by-pixel comparison, it is substantially slower (2x <) than the
 * GREYQuickVisibilityChecker, which is why we are using this checker as a fallback
 * from GREYQuickVisibilityChecker.
 */
@interface GREYThoroughVisibilityChecker : NSObject

/**
 * Calculates the percentage visible of the element in the screen.
 *
 * @param element The UI element whose visibility is to be checked.
 *
 * @return The percentage ([0,1] inclusive) of the area visible on the screen compared to @c
 *         element's accessibility frame.
 */
+ (CGFloat)percentVisibleAreaOfElement:(id)element;

/**
 * Calculates the visible point where a user can tap to interact with.
 *
 * @param element The UI element whose visibility is to be checked.
 *
 * @return A visible point where a user can tap to interact with specified @c element, or
 *         @c GREYCGPointNull if there's no such point.
 * @remark The returned point is relative to @c element's bound.
 */
+ (CGPoint)visibleInteractionPointForElement:(id)element;

/**
 * Calculates the smallest rectangle enclosing the entire visible area of the element.
 *
 * @param element The UI element whose visibility is to be checked.
 *
 * @return The smallest rectangle enclosing the entire visible area of @c element in screen
 *         coordinates. If no part of the element is visible, @c CGRectZero will be returned. The
 *         returned rect is always in points.
 */
+ (CGRect)rectEnclosingVisibleAreaOfElement:(id)element;

/**
 * @brief Exposes GREYThoroughVisibilityChecker interfaces and methods that are otherwise private
 * for testing purposes.
 */

/**
 * Clears last stored visibility images
 */
+ (void)resetVisibilityImages;

/**
 * @return The last known original image used by the thorough visibility checker.
 *
 * @remark This is available only for internal testing purposes.
 */
+ (UIImage *)lastActualBeforeImage;

/**
 * @return The last known actual color shifted image used by the thorough visibility checker.
 *
 * @remark This is available only for internal testing purposes.
 */
+ (UIImage *)lastActualAfterImage;

/**
 * @return The last known actual color shifted image used by thorough visibility checker.
 *
 * @remark This is available only for internal testing purposes.
 */
+ (UIImage *)lastExpectedAfterImage;

@end

NS_ASSUME_NONNULL_END
