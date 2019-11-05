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

#import "GREYVisibilityCheckerTarget.h"

#import "NSObject+GREYCommon.h"
#import "UIView+GREYCommon.h"
#import "CGGeometry+GREYUI.h"
#import "GREYScreenshotter.h"

/**
 *  Intersects with the screen bounds and element's bounding area to cut off any portion of the
 *  element that is not visible on screen.
 *
 *  @param element Element to check for the visible rect in screen.
 *  @param boundingRect Area that the view is confined to. Any portion of the view that is outside
 *                      this @c boundingRect would be cropped. It is represented in same coordinate
 *                      space as @c element. @c CGRectNull if it doesn't exist.
 *  @return Frame of the element that is visible on screen in screen coordinate. @c CGRectNull if it
 * is not visible at all.
 */
static CGRect VisibleRectOnScreen(id element, CGRect boundingRect);

/**
 *  Converts @c element's frame to screen coordinate. Before the views are intersected with the @c
 *  _target, they should be converted to the screen coordinate.
 *
 *  @param element The element whose frame will be converted.
 *
 *  @return @c element's frame converted to screen coordinate.
 */
static CGRect ConvertToScreenCoordinate(id element);

/**
 *  Converts rect in points to pixels as per the screen scale and align the pixels. All rects must
 *  be converted as such before interacting with @c _bitVector.
 *
 *  @param rect A rect in point coordinates.
 *
 *  @return A rect that is pixel-aligned in pixel coordinate.
 */
static CGRect ConvertToBitVectorRect(CGRect rect);

@implementation GREYVisibilityCheckerTarget {
  /**
   *  Internal target element.
   */
  id _target;
  /**
   *  View that contains @c _target.
   */
  UIView *_targetContainerView;
  /**
   *  Boolean whether or not @c _target is a UIView.
   */
  BOOL _isView;
  /**
   *  Visible frame of the @c _target in screen coordinate.
   */
  CGRect _targetRect;
  /**
   *  Visible surface area of the @c _target element.
   */
  CGFloat _visibleSurfaceArea;
  /**
   *  CGRect representation of @c _bitVector.
   */
  CGRect _bitVectorRect;
  /**
   *  Binary bitmap representing the visible portion of @c _target in pixel coordinate. Each pixel
   *  contains either 0 or 1. 0 indicating the pixel is visible, 1 if not.
   */
  CFMutableBitVectorRef _bitVector;
  /**
   *  Intersections between the views and the @c _target in pixel coordinate. These intersections
   *  will be subtracted from the @c _bitVector when the traversal is finished.
   */
  NSMutableArray<NSValue *> *_intersections;
}

- (instancetype)initWithTarget:(id)target boundingRect:(CGRect)boundingRect {
  UIView *containerView = [target grey_viewContainingSelf];
  BOOL isView = [target isKindOfClass:[UIView class]];
  CGRect targetRect = VisibleRectOnScreen(target, boundingRect);
  CGRect bitVectorRect = ConvertToBitVectorRect(targetRect);
  if (isView && ![target grey_isVisible]) {
    // Check if target is visible.
    return nil;
  } else if (!isView && containerView && ![containerView grey_isVisible]) {
    // Check if target's container is visible in case target is an AXE.
    return nil;
  } else if (CGRectIsNull(targetRect)) {
    // Check if target is visible on screen.
    return nil;
  } else if (CGRectGetWidth(bitVectorRect) < 1 || CGRectGetHeight(bitVectorRect) < 1) {
    // Check for views that are smaller than a point in the screen.
    return nil;
  }
  self = [super init];
  if (self) {
    _target = target;
    _targetContainerView = containerView;
    _isView = isView;
    _intersections = [[NSMutableArray alloc] init];
    _targetRect = targetRect;
    _bitVectorRect = bitVectorRect;
    CGFloat bitVectorSize = CGRectArea(_bitVectorRect);
    // bit vector is initialized with 0 by default.
    _bitVector = CFBitVectorCreateMutable(kCFAllocatorDefault, 0);
    CFBitVectorSetCount(_bitVector, (CFIndex)bitVectorSize);
    _visibleSurfaceArea = bitVectorSize;
  }
  return self;
}

/**
 *  To calculate the percentage visible from the target view, we maintain a bit matrix that keeps
 *  track of the pixels that are obscured by other views, represented as 1. Once we gather all
 *  intersections between the target and other views, we go through each intersections and set the
 *  bits from the bit matrix that falls into that intersection rect. After we are done setting all
 *  bits, we could calculate the visible percentage of the target as we can count how many pixels
 *  are visible in the bit matrix (by counting 0's).
 *
 *  @return percentage visible from the target element.
 */
- (CGFloat)percentageVisible {
  [self calculateBitsForIntersectionsInParallel];
  CGFloat bitVectorSize = CGRectArea(_bitVectorRect);
  NSInteger numberOfVisiblePixels =
      (NSInteger)CFBitVectorGetCountOfBit(_bitVector, CFRangeMake(0, (CFIndex)bitVectorSize), 0);
  CGRect frame = _isView ? [_target frame] : [_target accessibilityFrame];
  CGRect targetOriginalPixelRect = ConvertToBitVectorRect(frame);
  return numberOfVisiblePixels / CGRectArea(targetOriginalPixelRect);
}

- (GREYVisibilityCheckerTargetObscureResult)obscureResultByOverlappingElement:(id)element
                                                                 boundingRect:(CGRect)boundingRect {
  if (![self couldBeObscuredByElement:element]) {
    return GREYVisibilityCheckerTargetObscureResultNone;
  }
  CGRect viewRect = VisibleRectOnScreen(element, boundingRect);
  if (CGRectIsNull(viewRect)) {
    return GREYVisibilityCheckerTargetObscureResultNone;
  }
  CGRect intersection = CGRectIntersectionStrict(_targetRect, viewRect);
  if (CGRectIsNull(intersection)) {
    return GREYVisibilityCheckerTargetObscureResultNone;
  }
  NSValue *rectValue = [NSValue valueWithCGRect:intersection];
  [_intersections addObject:rectValue];
  // If intersection and _targetRect is the same, it means _targetRect is completely obscured, and
  // the traversal can be stopped prematurely.
  return CGRectEqualToRect(intersection, _targetRect)
             ? GREYVisibilityCheckerTargetObscureResultFull
             : GREYVisibilityCheckerTargetObscureResultPartial;
}

#pragma mark - Private

/**
 *  Dispatches each intersections to set bits in each intersection rect from @c _bitVector. Only
 *  call this method when there's no more intersection that is obscuring @c _targetRect.
 */
- (void)calculateBitsForIntersectionsInParallel {
  dispatch_apply(_intersections.count, DISPATCH_APPLY_AUTO, ^(size_t idx) {
    CGRect intersection = [_intersections[idx] CGRectValue];
    [self setBitsInRect:intersection];
  });
}

/**
 *  Sets all bits inside @c rect from @c _bitVector. The @c rect is converted to pixels as per
 *  screen scale before setting the bits. This is performed in parallel across multiple threads.
 *
 *  @param rect The frame of the pixels to set the bits in @c _bitVector. Must be in points.
 */
- (void)setBitsInRect:(CGRect)rect {
  rect = ConvertToBitVectorRect(rect);
  // _targetRect is indirectly translated to (0,0) since bitVector starts from (0, 0). Therefore,
  // the rect needs to be translated as much as _bitVectorRect did towards the origin.
  CGRect translatedRect = CGRectMake(CGRectGetMinX(rect) - CGRectGetMinX(_bitVectorRect),
                                     CGRectGetMinY(rect) - CGRectGetMinY(_bitVectorRect),
                                     CGRectGetWidth(rect), CGRectGetHeight(rect));
  NSInteger bitVectorRectWidth = (NSInteger)CGRectGetWidth(_bitVectorRect);
  NSInteger bitVectorRectHeight = (NSInteger)CGRectGetHeight(_bitVectorRect);
  NSInteger lowerX = (NSInteger)CGRectGetMinX(translatedRect);
  NSInteger lowerY = (NSInteger)CGRectGetMinY(translatedRect);
  NSInteger upperY = (NSInteger)CGRectGetMaxY(translatedRect);
  NSInteger width = (NSInteger)CGRectGetWidth(translatedRect);
  for (NSInteger y = lowerY; y < upperY; y++) {
    // Pixel aligned rect
    if (y < bitVectorRectHeight) {
      CFIndex start = y * bitVectorRectWidth + lowerX;
      CFRange range = CFRangeMake(start, MIN(width, bitVectorRectWidth - lowerX));
      CFBitVectorSetBits(_bitVector, range, 1);
    }
  }
}

/**
 *  Evaluates whether or not an element could potentially obscure the target element. Elements with
 *  the following conditions should be opted out from the calculation.
 *
 *  (1) Transparent views: View that is hidden, or has no background color.
 *  (2) Any subviews of the target element: Subviews of the target element are considered part of
 *      the view, so they are not obscuring the target element even though they are drawn on top of
 *      it.
 *  (3) Any Accessibility Element that is not a UIView instance: An accessibility element that is
 *      not a UIView cannot obscure a view since it's not a visual element.
 *  (4) Any view whose @c zPosition is lower than that of @c _target: A view with a lower @c
 *      zPosition is always rendered behind of views with higher @c zPosition if they are in the
 *      same level in the view hierarchy.
 */
- (BOOL)couldBeObscuredByElement:(id)element {
  BOOL elementIsView = [element isKindOfClass:[UIView class]];
  if (!_isView && [_target isAccessibilityElement]) {
    // If the target element is an accessibility element, it cannot be obscured by
    // any of its accessibility container's subviews.
    UIView *view = elementIsView ? element : [element grey_viewContainingSelf];
    if ([_targetContainerView grey_isAncestorOfView:view]) {
      return NO;
    }
  }
  if (!elementIsView) {
    // If element is not a UIView, it should not obscure the target.
    return NO;
  }
  return [self couldBeObscuredByView:(UIView *)element];
}

// Evaluates whether or not a view can obscure the target.
- (BOOL)couldBeObscuredByView:(UIView *)view {
  CGFloat white;
  CGFloat alpha;
  UIColor *viewBackgroundColor = view.backgroundColor;
  BOOL success = [viewBackgroundColor getWhite:&white alpha:&alpha];
  if ([NSStringFromClass([view class]) isEqualToString:@"UIKBInputBackdropView"]) {
    // UIKBInputBackdropView is a view that contains iOS input views including both system and
    // custom keyboard. Since this view is translucent, it needs to be checked manually. Otherwise,
    // it will consider as a non-obscuring view. This condition should be checked before checking
    // the translucency of the view.
    return YES;
  }

  if ([viewBackgroundColor isEqual:UIColor.clearColor] || !viewBackgroundColor) {
    return NO;
  } else if ((success && alpha < 1) || (view.alpha < 1)) {
    return NO;
  } else if (_isView && [_target superview] == [view superview] &&
             ((UIView *)_target).layer.zPosition > view.layer.zPosition) {
    // A view with a lower @c zPosition is always rendered behind of views with higher @c zPosition
    // if they are in the same level in the view hierarchy.
    return NO;
  } else if (![view grey_isVisible]) {
    return NO;
  } else {
    return YES;
  }
}

static CGRect VisibleRectOnScreen(id element, CGRect boundingRect) {
  UIView *container = [element grey_viewContainingSelf];
  CGRect containerRect = ConvertToScreenCoordinate(container);
  // If element has a mask view, use that mask view instead.
  if ([element isKindOfClass:[UIView class]]) {
    UIView *maskView = [element maskView];
    if (maskView) {
      element = maskView;
    }
  }

  CGRect elementRect = ConvertToScreenCoordinate(element);
  elementRect = CGRectIntersectionStrict(elementRect, [UIScreen mainScreen].bounds);
  if (!CGRectIsNull(boundingRect)) {
    CGRect boundingRectScreenCoord = [container convertRect:boundingRect toView:nil];
    elementRect = CGRectIntersectionStrict(elementRect, boundingRectScreenCoord);
  }
  // If the element is a subview of a UIScrollView, it should be bounded by the UIScrollView's
  // bound.
  if ([container isKindOfClass:[UIScrollView class]] && [container clipsToBounds]) {
    elementRect = CGRectIntersectionStrict(elementRect, containerRect);
  }
  return elementRect;
}

static CGRect ConvertToScreenCoordinate(id element) {
  if ([element isKindOfClass:[UIView class]]) {
    UIView *container = [element grey_viewContainingSelf];
    if (container) {
      return [container convertRect:[element frame] toView:nil];
    } else {
      // For top-level UIWindows
      return [element bounds];
    }
  } else {
    return [element accessibilityFrame];
  }
}

static CGRect ConvertToBitVectorRect(CGRect rect) {
  rect = CGRectPointToPixel(rect);
  rect = CGRectIntegralInside(rect);
  return rect;
}

- (void)dealloc {
  if (_bitVector) {
    CFRelease(_bitVector);
    _bitVector = NULL;
  }
}

@end
