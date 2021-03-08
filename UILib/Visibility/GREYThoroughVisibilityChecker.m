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

#import "GREYThoroughVisibilityChecker.h"

#include <CoreGraphics/CoreGraphics.h>

#import "NSObject+GREYCommon.h"
#import "UIView+GREYCommon.h"
#import "GREYFatalAsserts.h"
#import "GREYLogger.h"
#import "CGGeometry+GREYUI.h"
#import "GREYScreenshotter+Private.h"
#import "GREYScreenshotter.h"
#import "GREYVisibilityChecker.h"

static const NSUInteger kColorChannelsPerPixel = 4;

/**
 * Last known original image used by the visibility checker is saved in this global for debugging
 * purposes.
 */
static UIImage *gLastActualBeforeImage;

/**
 * Last known color shifted image created by the visibility checker is saved in this global for
 * debugging purposes.
 */
static UIImage *gLastExceptedAfterImage;

/**
 * Last known actual color shifted image used by visibility checker is saved in this global for
 * debugging purposes.
 */
static UIImage *gLastActualAfterImage;

#pragma mark - GREYVisibilityDiffBuffer

GREYVisibilityDiffBuffer GREYVisibilityDiffBufferCreate(size_t width, size_t height) {
  GREYVisibilityDiffBuffer diffBuffer;
  diffBuffer.width = width;
  diffBuffer.height = height;
  diffBuffer.data = (BOOL *)malloc(sizeof(BOOL) * width * height);
  if (diffBuffer.data == NULL) {
    NSLog(@"diffBuffer.data is NULL.");
    abort();
  }
  return diffBuffer;
}

void GREYVisibilityDiffBufferRelease(GREYVisibilityDiffBuffer buffer) {
  if (buffer.data == NULL) {
    NSLog(@"buffer.data is NULL.");
    abort();
  }
  free(buffer.data);
}

BOOL GREYVisibilityDiffBufferIsVisible(GREYVisibilityDiffBuffer buffer, size_t x, size_t y) {
  if (x >= buffer.width || y >= buffer.height) {
    return NO;
  }

  return buffer.data[y * buffer.width + x];
}

inline void GREYVisibilityDiffBufferSetVisibility(GREYVisibilityDiffBuffer buffer, size_t x,
                                                  size_t y, BOOL isVisible) {
  if (x >= buffer.width || y >= buffer.height) {
    NSLog(@"Warning: trying to access a point outside the diff buffer: {%zu, %zu}", x, y);
    return;
  }

  buffer.data[y * buffer.width + x] = isVisible;
}

#pragma mark - GREYThoroughVisibilityChecker

@implementation GREYThoroughVisibilityChecker

+ (CGFloat)percentVisibleAreaOfElement:(id)element {
  CGFloat percentVisible = (CGFloat)[self grey_percentElementVisibleOnScreen:element];
  GREYFatalAssertWithMessage(percentVisible >= 0.0f && percentVisible <= 1.0f,
                             @"percentVisible(%f) must be in the range [0,1]", percentVisible);
  GREYLogVerbose(@"Visibility percent: %f for element: %@", percentVisible,
                 [element grey_description]);
  return percentVisible;
}

+ (CGRect)rectEnclosingVisibleAreaOfElement:(id)element {
  GREYFatalAssertWithMessage([element isKindOfClass:[UIView class]],
                             @"Only elements of kind UIView are supported by this method.");
  UIView *view = element;
  CGImageRef beforeImage = NULL;
  CGImageRef afterImage = NULL;
  CGPoint origin = CGPointZero;
  BOOL viewIntersectsScreen =
      [GREYThoroughVisibilityChecker grey_captureBeforeImage:&beforeImage
                                               andAfterImage:&afterImage
                                    andGetIntersectionOrigin:&origin
                                                     forView:view
                                                  withinRect:[view accessibilityFrame]];
  CGRect visibleAreaRect = CGRectZero;
  if (viewIntersectsScreen) {
    [GREYThoroughVisibilityChecker grey_countPixelsInImage:afterImage
                               thatAreShiftedPixelsOfImage:beforeImage
                               storeVisiblePixelRectInRect:&visibleAreaRect
                          andStoreComparisonResultInBuffer:NULL];
  }

  CGImageRelease(beforeImage);
  CGImageRelease(afterImage);

  if (!CGRectIsEmpty(visibleAreaRect)) {
    // |visibleAreaRectInPoints| must be offset by its origin within the screenshot before we can
    // convert it to points coordinates.
    visibleAreaRect = CGRectOffset(visibleAreaRect, origin.x, origin.y);
    visibleAreaRect = CGRectPixelToPoint(visibleAreaRect);
  }
  return visibleAreaRect;
}

+ (CGPoint)visibleInteractionPointForElement:(id)element {
  UIView *view = [self grey_containingViewIfNonView:element];
  if (!view) {
    // Non-UIView elements without a container are considered NOT visible for interaction.
    return GREYCGPointNull;
  }

  // Interaction point to be calculated after peforming visibility checks.
  CGPoint interactionPointInFixedPoints = GREYCGPointNull;

  CGRect elementFrame = [element accessibilityFrame];
  CGImageRef beforeImage = NULL;
  CGImageRef afterImage = NULL;
  CGPoint intersectionPointInVariablePixels;

  BOOL viewIntersectsScreen =
      [GREYThoroughVisibilityChecker grey_captureBeforeImage:&beforeImage
                                               andAfterImage:&afterImage
                                    andGetIntersectionOrigin:&intersectionPointInVariablePixels
                                                     forView:view
                                                  withinRect:elementFrame];
  if (viewIntersectsScreen) {
    const CGFloat scale = [[UIScreen mainScreen] scale];
    const size_t widthInPixels = CGImageGetWidth(beforeImage);
    const size_t heightInPixels = CGImageGetHeight(beforeImage);
    const size_t minimumPixelsVisibleForInteraction =
        (size_t)(kMinimumPointsVisibleForInteraction * scale);

    // If the element hasn't a minimum area in pixels, stop immediately.
    const size_t elementAreaInPixels = widthInPixels * heightInPixels;
    if (elementAreaInPixels < minimumPixelsVisibleForInteraction) {
      CGImageRelease(beforeImage);
      CGImageRelease(afterImage);
      return GREYCGPointNull;
    }

    GREYVisibilityDiffBuffer diffBuffer =
        GREYVisibilityDiffBufferCreate(widthInPixels, heightInPixels);

    // visibleRectInVariablePixels will contain the minimum rect containing all visible pixels
    // and a sub-area of the diffBuffer rectangle, which is the intersection of the view and the
    // screen.
    CGRect visibleRectInVariablePixels;
    GREYVisiblePixelData visiblePixels = [self grey_countPixelsInImage:afterImage
                                           thatAreShiftedPixelsOfImage:beforeImage
                                           storeVisiblePixelRectInRect:&visibleRectInVariablePixels
                                      andStoreComparisonResultInBuffer:&diffBuffer];
    size_t visiblePixelCount = visiblePixels.visiblePixelCount;
    CGPoint interactionPointInVariablePixels = GREYCGPointNull;

    if (visiblePixelCount >= minimumPixelsVisibleForInteraction) {
      // If the activation point lies inside the screen, use it if it is visible.
      CGPoint activationPoint = [element accessibilityActivationPoint];

      if (CGRectContainsPoint([[UIScreen mainScreen] bounds], activationPoint)) {
        CGPoint activationPointInVariablePixels = activationPoint;
        activationPointInVariablePixels = CGPointToPixel(activationPointInVariablePixels);

        CGPoint relativeActivationPointInVariablePixels =
            CGPointMake(activationPointInVariablePixels.x - intersectionPointInVariablePixels.x,
                        activationPointInVariablePixels.y - intersectionPointInVariablePixels.y);

        BOOL isVisible = relativeActivationPointInVariablePixels.x >= 0 &&
                         relativeActivationPointInVariablePixels.y >= 0 &&
                         GREYVisibilityDiffBufferIsVisible(
                             diffBuffer, (size_t)relativeActivationPointInVariablePixels.x,
                             (size_t)relativeActivationPointInVariablePixels.y);
        if (isVisible) {
          // So that it's relative to screen coordinates.
          interactionPointInVariablePixels = activationPointInVariablePixels;
        }
      }
      // If the activation point is not visible, try the center of visible rect.
      if (CGPointIsNull(interactionPointInVariablePixels)) {
        CGPoint centerOfVisibleAreaInVariablePixels = CGRectCenter(visibleRectInVariablePixels);
        if (GREYVisibilityDiffBufferIsVisible(diffBuffer,
                                              (size_t)centerOfVisibleAreaInVariablePixels.x,
                                              (size_t)centerOfVisibleAreaInVariablePixels.y)) {
          interactionPointInVariablePixels = centerOfVisibleAreaInVariablePixels;
          // Adjust offsets so it's relative to screen coordinates.
          interactionPointInVariablePixels.x += intersectionPointInVariablePixels.x;
          interactionPointInVariablePixels.y += intersectionPointInVariablePixels.y;
        }
      }
      // If the center of the visible rect isn't visible, get a default visible pixel.
      if (CGPointIsNull(interactionPointInVariablePixels)) {
        interactionPointInVariablePixels = visiblePixels.visiblePixel;
        // Adjust offsets so it's relative to screen coordinates.
        interactionPointInVariablePixels.x += intersectionPointInVariablePixels.x;
        interactionPointInVariablePixels.y += intersectionPointInVariablePixels.y;
      }

      if (!CGPointIsNull(interactionPointInVariablePixels)) {
        // At this point the interaction point is in variable screen coordinates, but the expected
        // output is in fixed view coordinates so it needs to be converted.
        interactionPointInFixedPoints = CGPixelToPoint(interactionPointInVariablePixels);
        interactionPointInFixedPoints = [view.window convertPoint:interactionPointInFixedPoints
                                                       fromWindow:nil];
        interactionPointInFixedPoints = [view convertPoint:interactionPointInFixedPoints
                                                  fromView:nil];
        // If the element is an accessibility view, the interaction point has to be further
        // converted into its coordinate system.
        if (element != view) {
          CGRect axFrameRelativeToView = [view.window convertRect:elementFrame fromWindow:nil];
          axFrameRelativeToView = [view convertRect:axFrameRelativeToView fromView:nil];

          interactionPointInFixedPoints.x -= axFrameRelativeToView.origin.x;
          interactionPointInFixedPoints.y -= axFrameRelativeToView.origin.y;
        }
      }
    }
    GREYVisibilityDiffBufferRelease(diffBuffer);
  }

  CGImageRelease(beforeImage);
  CGImageRelease(afterImage);
  return interactionPointInFixedPoints;
}

#pragma mark - Private

/**
 * Returns fraction of the total area of @c element that is visible to the user. Any part of the
 * element that is obscured or off-screen is considered not visible. Return value of 0 means that
 * no part of the element is visible on screen. That might mean that element is off-screen, or it
 * could be on-screen, but covered by another element. Return value of 1 means that the entire
 * element is visible on screen, which means that the entire frame of the element is on-screen, and
 * no part of the element is obscured by another element. If any part of the element is off-screen,
 * the return value will be less than 1, even if this element is covering the entire screen and no
 * part of it is obscured by another element.
 *
 * @param element The element whose percent area is being queried.
 *
 * @return The percent area in range [0,1], of the @c element that is visible on the screen.
 */
+ (double)grey_percentElementVisibleOnScreen:(id)element {
  UIView *view = [self grey_containingViewIfNonView:element];
  return [self grey_percentViewVisibleOnScreen:view withinRect:[element accessibilityFrame]];
}

/**
 * Returns fraction of the total area of @c element that is visible to the user. Any part of the
 * element that is obscured or off-screen is considered not visible. Return value of 0 means that
 * no part of the element is visible on screen. That might mean that element is off-screen, or it
 * could be on-screen, but covered by another element. Return value of 1 means that the entire
 * element is visible on screen, which means that the entire frame of the element is on-screen, and
 * no part of the element is obscured by another element. If any part of the element is off-screen,
 * the return value will be less than 1, even if this element is covering the entire screen and no
 * part of it is obscured by another element.
 *
 * @param element The non-view element whose percent area is being queried.
 *
 * @return The percent area in range [0,1], of the @c element that is visible on the screen.
 */
+ (double)grey_percentNonViewVisibleOnScreen:(id)element {
  GREYFatalAssert(![element isKindOfClass:[UIView class]]);
  if (![element isKindOfClass:[NSObject class]] ||
      ![element respondsToSelector:@selector(accessibilityFrame)] ||
      CGRectIsEmpty([element accessibilityFrame])) {
    return 0;
  }

  return [self grey_percentViewVisibleOnScreen:[self grey_containingViewIfNonView:element]
                                    withinRect:[element accessibilityFrame]];
}

/**
 * The logic behind the implementation is that it takes 2 screenshots, one before any modification
 * and one after. The latter contains modification to UIView by adding an inverted image to it that
 * is visible on top all subviews. The actual visibility check calculates how many pixels changed
 * before and after the modification, and returns fraction of area of the element that changed out
 * of the entire area of the element. This check is restricted to only consider a certain rectangle
 * inside a view, in screen coordinates. This may naturally be set to the entire view.
 *
 * @param view                          The view whose percent visible area is being queried.
 * @param searchRectInScreenCoordinates A rect in screen coordinates within which the visibility
 *                                      check is to be performed.
 *
 * @return The percent area in range [0,1], of the @c element that is visible within the search
 *         rect.
 */
+ (double)grey_percentViewVisibleOnScreen:(UIView *)view
                               withinRect:(CGRect)searchRectInScreenCoordinates {
  CGImageRef beforeImage = NULL;
  CGImageRef afterImage = NULL;
  BOOL viewIntersectsScreen =
      [GREYThoroughVisibilityChecker grey_captureBeforeImage:&beforeImage
                                               andAfterImage:&afterImage
                                    andGetIntersectionOrigin:NULL
                                                     forView:view
                                                  withinRect:searchRectInScreenCoordinates];
  double percentVisible = 0;
  if (viewIntersectsScreen) {
    // Count number of whole pixels in entire search area, including areas off screen or outside
    // view.
    CGRect searchRect_pixels = CGRectPointToPixelAligned(searchRectInScreenCoordinates);
    double countTotalSearchRectPixels = CGRectArea(searchRect_pixels);
    GREYFatalAssertWithMessage(countTotalSearchRectPixels >= 1,
                               @"countTotalSearchRectPixels should be at least 1");
    GREYVisiblePixelData visiblePixelData = [self grey_countPixelsInImage:afterImage
                                              thatAreShiftedPixelsOfImage:beforeImage
                                              storeVisiblePixelRectInRect:NULL
                                         andStoreComparisonResultInBuffer:NULL];
    percentVisible = visiblePixelData.visiblePixelCount / countTotalSearchRectPixels;
  }

  CGImageRelease(beforeImage);
  CGImageRelease(afterImage);

  GREYFatalAssertWithMessage(0 <= percentVisible,
                             @"percentVisible should not be negative. Current Percent: %0.1f%%",
                             (double)(percentVisible * 100.0));
  return percentVisible;
}

+ (UIView *)grey_containingViewIfNonView:(id)element {
  return ([element isKindOfClass:[UIView class]] ? element : [element grey_viewContainingSelf]);
}

/**
 * Captures the visibility check's before and after image for the given @c view and loads the pixel
 * data into the given @c beforeImage and @c afterImage and returns @c YES if at least one pixel
 * from the view intersects with the given @c searchRectInScreenCoordinates, @c NO otherwise.
 * Optionally the method also stores the intersection point of the screen, view and search rect (in
 * pixels) at @c outIntersectionOriginOrNull. The caller must release @c beforeImage and @c
 * afterImage using CGImageRelease once done using them.
 *
 * @param[out] outBeforeImage              A reference to receive the before-check image.
 * @param[out] outAfterImage               A reference to receive the after-check image.
 * @param[out] outIntersectionOriginOrNull A reference to receive the origin of the view in the
 *                                         given search rect.
 * @param view                             The view whose visibility check is being performed.
 * @param searchRectInScreenCoordinates    A rect in screen coordinates within which the visibility
 *                                         check is to be performed.
 *
 * @return @c YES if at least one pixel from the view intersects with the given @c
 *         searchRectInScreenCoordinates, @c NO otherwise.
 */
+ (BOOL)grey_captureBeforeImage:(CGImageRef *)outBeforeImage
                  andAfterImage:(CGImageRef *)outAfterImage
       andGetIntersectionOrigin:(CGPoint *)outIntersectionOriginOrNull
                        forView:(UIView *)view
                     withinRect:(CGRect)searchRectInScreenCoordinates {
  GREYFatalAssert(outBeforeImage);
  GREYFatalAssert(outAfterImage);

  // A quick visibility check is done here to rule out any definitely hidden views.
  if (![view grey_isVisible] || CGRectIsEmpty(searchRectInScreenCoordinates)) {
    return NO;
  }

  // Find portion of search rect that is on screen and in view.
  CGRect screenBounds = [[UIScreen mainScreen] bounds];
  CGRect axFrame = [view accessibilityFrame];
  CGRect searchRectOnScreenInViewInScreenCoordinates = CGRectIntersectionStrict(
      searchRectInScreenCoordinates, CGRectIntersectionStrict(axFrame, screenBounds));
  if (CGRectIsEmpty(searchRectOnScreenInViewInScreenCoordinates)) {
    return NO;
  }

  // Calculate the search rectangle for screenshot.
  CGRect screenshotSearchRect_pixel = searchRectOnScreenInViewInScreenCoordinates;
  screenshotSearchRect_pixel = CGRectPointToPixelAligned(screenshotSearchRect_pixel);

  // Set screenshot origin point.
  if (outIntersectionOriginOrNull) {
    *outIntersectionOriginOrNull = screenshotSearchRect_pixel.origin;
  }

  if (screenshotSearchRect_pixel.size.width == 0 || screenshotSearchRect_pixel.size.height == 0) {
    return NO;
  }

  // Take an image of what the view looks like before shifting pixel intensity.
  // Ensures that any implicit animations that might have taken place since the last runloop
  // run are committed to the presentation layer.
  // @see
  // http://optshiftk.com/2013/11/better-documentation-for-catransaction-flush/
  [CATransaction begin];
  [CATransaction flush];
  [CATransaction commit];
  // For the searchRect used in screenshotting, use screenshotSearchRect_point instead of
  // searchRectOnScreenInViewInScreenCoordinates as the former is pixel aligned points.
  CGRect screenshotSearchRect_point = CGRectPixelToPoint(screenshotSearchRect_pixel);
  UIImage *beforeScreenshot =
      [GREYScreenshotter grey_takeScreenshotAfterScreenUpdates:YES
                                                  inScreenRect:screenshotSearchRect_point
                                                 withStatusBar:YES];
  CGImageRef beforeImage = CGImageCreateCopy(beforeScreenshot.CGImage);
  if (!beforeImage) {
    return NO;
  }

  // View with shifted colors will be added on top of all the subviews of view. We offset the view
  // to make it appear in the correct location. If we are checking for visibility of a scroll view,
  // visibility checker will take a picture of the entire UIScrollView, and adjust the frame of
  // shiftedBeforeImageView to position it correctly within the UIScrollView.
  // In iOS 7, UIScrollViews are often full-screen, and a part of them is hidden behind the
  // navigation bar. ContentInsets are set automatically to make this happen seamlessly. In this
  // case, EarlGrey will take a picture of the entire UIScrollView, including the navigation bar,
  // to check visibility, but because navigation bar covers only a small portion of the scroll view,
  // it will still be above the visibility threshold.

  // Calculate the search rectangle in view coordinates.
  CGRect searchRectOnScreenInViewInWindowCoordinates =
      [view.window convertRect:searchRectOnScreenInViewInScreenCoordinates fromWindow:nil];
  CGRect searchRectOnScreenInViewInViewCoordinates =
      [view convertRect:searchRectOnScreenInViewInWindowCoordinates fromView:nil];

  CGRect rectAfterPixelAlignment = CGRectPixelToPoint(screenshotSearchRect_pixel);
  // Offset must be in variable screen coordinates.
  CGRect searchRectOnScreenInViewInVariableScreenCoordinates =
      searchRectOnScreenInViewInScreenCoordinates;
  CGFloat xPixelAlignmentDiff = CGRectGetMinX(rectAfterPixelAlignment) -
                                CGRectGetMinX(searchRectOnScreenInViewInVariableScreenCoordinates);
  CGFloat yPixelAlignmentDiff = CGRectGetMinY(rectAfterPixelAlignment) -
                                CGRectGetMinY(searchRectOnScreenInViewInVariableScreenCoordinates);

  CGFloat searchRectOffsetX =
      CGRectGetMinX(searchRectOnScreenInViewInViewCoordinates) + xPixelAlignmentDiff;
  CGFloat searchRectOffsetY =
      CGRectGetMinY(searchRectOnScreenInViewInViewCoordinates) + yPixelAlignmentDiff;

  CGPoint searchRectOffset = CGPointMake(searchRectOffsetX, searchRectOffsetY);
  UIView *shiftedView =
      [self grey_imageViewWithShiftedColorOfImage:beforeImage
                                      frameOffset:searchRectOffset
                                      orientation:beforeScreenshot.imageOrientation];
  UIImage *afterScreenshot = [self grey_imageAfterAddingSubview:shiftedView
                                                         toView:view
                                                     searchRect:screenshotSearchRect_point];
  CGImageRef afterImage = CGImageCreateCopy(afterScreenshot.CGImage);
  if (!afterImage) {
    GREYFatalAssertWithMessage(NO, @"afterImage should not be null");
    CGImageRelease(beforeImage);
    return NO;
  }
  *outBeforeImage = beforeImage;
  *outAfterImage = afterImage;

  gLastActualBeforeImage = [UIImage imageWithCGImage:beforeImage];
  gLastActualAfterImage = [UIImage imageWithCGImage:afterImage];

  return YES;
}

+ (UIImage *)grey_imageAfterAddingSubview:(UIView *)shiftedView
                                   toView:(UIView *)view
                               searchRect:(CGRect)searchRect {
  GREYFatalAssert(shiftedView);
  GREYFatalAssert(view);

  UIImage *screenshot = [self grey_prepareView:view
             forVisibilityCheckAndPerformBlock:^id {
               [CATransaction begin];
               [CATransaction setDisableActions:YES];
               // Add a check for the UIVisualEffectView which requires subviews to be added only
               // to the contentView.
               if ([view isKindOfClass:[UIVisualEffectView class]]) {
                 UIVisualEffectView *visualEffectView = (UIVisualEffectView *)view;
                 [[visualEffectView contentView] addSubview:shiftedView];
               } else {
                 [view addSubview:shiftedView];
               }
               [view grey_keepSubviewOnTopAndFrameFixed:shiftedView];
               [CATransaction flush];
               [CATransaction commit];
#ifdef EARLGREY_EXPERIMENT
               // For some special cases (b/138174761), the visibility checker would not commit @c
               // shiftedView to the view hierarchy before it starts drawing to the graphics
               // context. As a result, the visibility checker would give a false positive
               // visibility status. This is a temporary fix that would make sure that the shifted
               // view is added to the screenshot. This will have flickering effect on the view
               // that is being checked for visibility.
               CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, NO);
#endif
               UIImage *shiftedImage =
                   [GREYScreenshotter grey_takeScreenshotAfterScreenUpdates:YES
                                                               inScreenRect:searchRect
                                                              withStatusBar:YES];
               [shiftedView removeFromSuperview];
               return shiftedImage;
             }];
  return screenshot;
}

/**
 * Prepares @c view for visibility check by modifying visual aspects that interfere with
 * pixel intensities. Then, executes block, restores view's properties and returns the result of
 * executing the block to the caller.
 */
+ (UIImage *)grey_prepareView:(UIView *)view forVisibilityCheckAndPerformBlock:(id (^)(void))block {
  BOOL disablingActions = [CATransaction disableActions];
  BOOL isRasterizingLayer = view.layer.shouldRasterize;

  [CATransaction begin];
  [CATransaction setDisableActions:YES];
  // Set the corner radius to zero. This is added to counter cases such as avatar screens where
  // the background in the rectangle adds noise since it's not actually being checked for
  // visibility.
  CGFloat originalCornerRadius = view.layer.cornerRadius;
  view.layer.cornerRadius = 0;
  // Rasterizing causes flakiness by re-drawing the view frame by frame for any layout change and
  // caching it for further use. This brings a delay in refreshing the layout for the shiftedView.
  view.layer.shouldRasterize = NO;

  // Views may be translucent and there have their alpha adjusted to 1.0 when taking the screenshot
  // because the shifted view, being a child of the view, will inherit its opacity. The problem
  // with that is that shifted view is created from a screenshot of the view with its original
  // opacity, so if we just add the shifted view as a subview of view the opacity change will be
  // applied once more. This may result on false negatives, specially on anti-aliased text. To make
  // sure the opacity won't affect the screenshot, we need to apply the change to the view and all
  // of its parents, then reset the changes when done.
  [view grey_recursivelyMakeOpaque];
  [CATransaction flush];
  [CATransaction commit];

  id retVal = block();

  [CATransaction begin];
  [CATransaction setDisableActions:YES];
  // Restore opacity back to what it was before.
  [view grey_restoreOpacity];
  view.layer.cornerRadius = originalCornerRadius;
  view.layer.shouldRasterize = isRasterizingLayer;
  [CATransaction setDisableActions:disablingActions];
  [CATransaction flush];
  [CATransaction commit];
  return retVal;
}

/**
 * Calculates the number of pixel in @c afterImage that have different pixel intensity in
 * @c beforeImage.
 * If @c visiblePixelRect is not NULL, stores the smallest rectangle enclosing all shifted pixels
 * in @c visiblePixelRect. If no shifted pixels are found, @c visiblePixelRect will be CGRectZero.
 * @todo Use a better image comparison library/tool for this stuff. For now, pixel-by-pixel
 *       comparison it is.
 *
 * @param afterImage               The image containing view with shifted colors.
 * @param beforeImage              The original image of the view.
 * @param[out] outVisiblePixelRect A reference for getting the largest
 *                                 rectangle enclosing only visible points in the view.
 * @param[out] outDiffBufferOrNULL A reference for getting the GREYVisibilityDiffBuffer that was
 *                                 created to detect image diff.
 *
 * @return The number of pixels and a default pixel in @c afterImage that are shifted
 *         intensity of @c beforeImage.
 */
+ (GREYVisiblePixelData)grey_countPixelsInImage:(CGImageRef)afterImage
                    thatAreShiftedPixelsOfImage:(CGImageRef)beforeImage
                    storeVisiblePixelRectInRect:(CGRect *)outVisiblePixelRect
               andStoreComparisonResultInBuffer:(GREYVisibilityDiffBuffer *)outDiffBufferOrNULL {
  GREYFatalAssert(beforeImage);
  GREYFatalAssert(afterImage);
  GREYFatalAssertWithMessage(CGImageGetWidth(beforeImage) == CGImageGetWidth(afterImage),
                             @"width must be the same");
  GREYFatalAssertWithMessage(CGImageGetHeight(beforeImage) == CGImageGetHeight(afterImage),
                             @"height must be the same");
  unsigned char *pixelBuffer = grey_createImagePixelDataFromCGImageRef(beforeImage, NULL);
  GREYFatalAssertWithMessage(pixelBuffer, @"pixelBuffer must not be null");
  unsigned char *shiftedPixelBuffer = grey_createImagePixelDataFromCGImageRef(afterImage, NULL);
  GREYFatalAssertWithMessage(shiftedPixelBuffer, @"shiftedPixelBuffer must not be null");
  NSUInteger width = CGImageGetWidth(beforeImage);
  NSUInteger height = CGImageGetHeight(beforeImage);
  uint16_t *histograms = NULL;
  // We only want to perform the relatively expensive rect computation if we've actually
  // been asked for it.
  if (outVisiblePixelRect) {
    histograms = calloc((size_t)(width * height), sizeof(uint16_t));
  }
  GREYVisiblePixelData visiblePixelData = {0, GREYCGPointNull};
  // Make sure we go row-order to take advantage of data locality (cuts runtime in half).
  for (NSUInteger y = 0; y < height; y++) {
    for (NSUInteger x = 0; x < width; x++) {
      NSUInteger currentPixelIndex = (y * width + x) * kColorChannelsPerPixel;
      // We don't care about the first byte because we are dealing with XRGB format.
      BOOL pixelHasDiff = IsPixelDifferent(&pixelBuffer[currentPixelIndex + 1],
                                           &shiftedPixelBuffer[currentPixelIndex + 1]);
      if (pixelHasDiff) {
        visiblePixelData.visiblePixelCount++;
        // Always pick the bottom and right-most pixel. We may want to consider using tax-cab
        // formula to find a pixel that's closest to the center if we encounter problems with this
        // approach.
        visiblePixelData.visiblePixel.x = x;
        visiblePixelData.visiblePixel.y = y;
      }
      if (outVisiblePixelRect) {
        if (y == 0) {
          histograms[x] = pixelHasDiff ? 1 : 0;
        } else {
          histograms[y * width + x] = pixelHasDiff ? (histograms[(y - 1) * width + x] + 1) : 0;
        }
      }
      if (outDiffBufferOrNULL) {
        GREYVisibilityDiffBufferSetVisibility(*outDiffBufferOrNULL, x, y, pixelHasDiff);
      }
    }
  }
  if (outVisiblePixelRect) {
    CGRect largestRect = CGRectZero;
    for (NSUInteger idx = 0; idx < height; idx++) {
      CGRect thisLargest = CGRectLargestRectInHistogram(&histograms[idx * width], (uint16_t)width);
      if (CGRectArea(thisLargest) > CGRectArea(largestRect)) {
        // Because our histograms point up, not down.
        thisLargest.origin.y = idx - thisLargest.size.height + 1;
        largestRect = thisLargest;
      }
    }
    *outVisiblePixelRect = largestRect;
    free(histograms);
    histograms = NULL;
  }
  free(pixelBuffer);
  pixelBuffer = NULL;
  free(shiftedPixelBuffer);
  shiftedPixelBuffer = NULL;
  return visiblePixelData;
}

/**
 * Creates a UIImageView and adds a shifted color image of @c imageRef to it, in addition
 * view.frame is offset by @c offset and image orientation set to @c orientation. There are 256
 * possible values for a color component, from 0 to 255. Each color component will be shifted by
 * exactly 128, examples: 0 => 128, 64 => 192, 128 => 0, 255 => 127.
 *
 * @param imageRef The image whose colors are to be shifted.
 * @param offset The frame offset to be applied to resulting view.
 * @param orientation The target orientation of the image added to the resulting view.
 *
 * @return A view containing shifted color image of @c imageRef with view.frame offset by
 *         @c offset and orientation set to @c orientation.
 */
+ (UIView *)grey_imageViewWithShiftedColorOfImage:(CGImageRef)imageRef
                                      frameOffset:(CGPoint)offset
                                      orientation:(UIImageOrientation)orientation {
  GREYFatalAssert(imageRef);

  size_t width = CGImageGetWidth(imageRef);
  size_t height = CGImageGetHeight(imageRef);
  // TODO(b/143889177): Find a good way to compute imagePixelData of before image only once without
  // negatively impacting the readability of code in visibility checker.
  unsigned char *shiftedImagePixels = grey_createImagePixelDataFromCGImageRef(imageRef, NULL);

  for (NSUInteger i = 0; i < height * width; i++) {
    NSUInteger currentPixelIndex = kColorChannelsPerPixel * i;
    // We don't care about the [first] byte of the [X]RGB format.
    for (unsigned char j = 1; j <= 2; j++) {
      static const unsigned char kShiftIntensityAmount[] = {0, 10, 10, 10};  // Shift for X, R, G, B
      unsigned char pixelIntensity = shiftedImagePixels[currentPixelIndex + j];
      if (pixelIntensity >= kShiftIntensityAmount[j]) {
        pixelIntensity = pixelIntensity - kShiftIntensityAmount[j];
      } else {
        pixelIntensity = pixelIntensity + kShiftIntensityAmount[j];
      }
      shiftedImagePixels[currentPixelIndex + j] = pixelIntensity;
    }
  }

  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGContextRef bitmapContext =
      CGBitmapContextCreate(shiftedImagePixels, width, height, 8, kColorChannelsPerPixel * width,
                            colorSpace, kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Big);

  CGColorSpaceRelease(colorSpace);

  CGImageRef bitmapImageRef = CGBitmapContextCreateImage(bitmapContext);
  UIImage *shiftedImage = [UIImage imageWithCGImage:bitmapImageRef
                                              scale:[[UIScreen mainScreen] scale]
                                        orientation:orientation];

  CGImageRelease(bitmapImageRef);
  CGContextRelease(bitmapContext);
  free(shiftedImagePixels);

  gLastExceptedAfterImage = shiftedImage;

  UIImageView *shiftedImageView = [[UIImageView alloc] initWithImage:shiftedImage];
  shiftedImageView.frame = CGRectOffset(shiftedImageView.frame, offset.x, offset.y);
  shiftedImageView.opaque = YES;
  return shiftedImageView;
}

/**
 * @return @c true if the encoded rgb1[R, G, B] color values are different from rbg2[R, G, B]
 *         values, @c false otherwise.
 * @todo Ideally, we should be testing that pixel colors are shifted by a certain amount instead of
 *       checking if they are simply different. However, the naive check for shifted colors doesn't
 *       work if pixels are overlapped by a translucent mask or have special layer effects applied
 *       to it. Because they are still visible to user and we want to avoid false-negatives that
 *       would cause the test to fail, we resort to a naive check that rbg1 and rgb2 are not the
 *       same without specifying the exact delta between them.
 */
static inline bool IsPixelDifferent(unsigned char rgb1[], unsigned char rgb2[]) {
  return abs(rgb1[0] - rgb2[0]) > 2 || abs(rgb1[1] - rgb2[1]) > 2 || abs(rgb1[2] - rgb2[2]) > 2;
}

#pragma mark - Package Internal

+ (void)resetVisibilityImages {
  gLastActualAfterImage = nil;
  gLastActualBeforeImage = nil;
  gLastExceptedAfterImage = nil;
}

+ (UIImage *)lastActualBeforeImage {
  return gLastActualBeforeImage;
}

+ (UIImage *)lastActualAfterImage {
  return gLastActualAfterImage;
}

+ (UIImage *)lastExpectedAfterImage {
  return gLastExceptedAfterImage;
}

@end
