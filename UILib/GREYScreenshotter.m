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

#import "UILib/GREYScreenshotter.h"

#import "CommonLib/Additions/NSFileManager+GREYCommon.h"
#import "CommonLib/Additions/NSObject+GREYCommon.h"
#import "CommonLib/Assertion/GREYFatalAsserts.h"
#import "CommonLib/Assertion/GREYThrowDefines.h"
#import "UILib/Provider/GREYUIWindowProvider.h"

/**
 *  Bytes allocated per pixel for an XRGB image.
 */
static const NSUInteger kBytesPerPixel = 4;

// Private class for AlertController window that doesn't work with drawViewHierarchyInRect.
static Class gUIAlertControllerShimPresenterWindowClass;
// Private class for ModalHostingWindow window that doesn't work with drawViewHierarchyInRect.
static Class gUIModalItemHostingWindowClass;

@implementation GREYScreenshotter

+ (void)initialize {
  if (self == [GREYScreenshotter class]) {
    gUIAlertControllerShimPresenterWindowClass =
        NSClassFromString(@"_UIAlertControllerShimPresenterWindow");
    gUIModalItemHostingWindowClass = NSClassFromString(@"_UIModalItemHostingWindow");
  }
}

+ (void)drawScreenInContext:(CGContextRef)bitmapContextRef
         afterScreenUpdates:(BOOL)afterUpdates
              withStatusBar:(BOOL)included {
  GREYFatalAssertWithMessage(CGBitmapContextGetBitmapInfo(bitmapContextRef) != 0,
                             @"The context ref must point to a CGBitmapContext.");
  UIScreen *mainScreen = [UIScreen mainScreen];
  CGRect screenRect = [self grey_rectRotatedToStatusBarOrientation:mainScreen.bounds];

  UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;

  // The bitmap context width and height are scaled, so we need to undo the scale adjustment.
  CGFloat contextWidth = CGBitmapContextGetWidth(bitmapContextRef) / mainScreen.scale;
  CGFloat contextHeight = CGBitmapContextGetHeight(bitmapContextRef) / mainScreen.scale;
  CGFloat xOffset = (contextWidth - screenRect.size.width) / 2;
  CGFloat yOffset = (contextHeight - screenRect.size.height) / 2;
  NSEnumerator *allWindowsInReverse =
      [[GREYUIWindowProvider allWindowsWithStatusBar:included] reverseObjectEnumerator];
  for (UIWindow *window in allWindowsInReverse) {
    if (window.hidden || window.alpha == 0) {
      continue;
    }

    CGContextSaveGState(bitmapContextRef);

    CGRect windowRect = window.bounds;
    CGPoint windowCenter = window.center;
    CGPoint windowAnchor = window.layer.anchorPoint;

    CGContextTranslateCTM(bitmapContextRef, windowCenter.x + xOffset, windowCenter.y + yOffset);
    CGContextConcatCTM(bitmapContextRef, window.transform);
    CGContextTranslateCTM(bitmapContextRef, -CGRectGetWidth(windowRect) * windowAnchor.x,
                          -CGRectGetHeight(windowRect) * windowAnchor.y);
    if (!iOS8_0_OR_ABOVE()) {
      if (orientation == UIInterfaceOrientationLandscapeLeft) {
        // Rotate pi/2
        CGContextConcatCTM(bitmapContextRef, CGAffineTransformMake(0, 1, -1, 0, 0, 0));
        CGContextTranslateCTM(bitmapContextRef, 0, -CGRectGetWidth(screenRect));
      } else if (orientation == UIInterfaceOrientationLandscapeRight) {
        // Rotate -pi/2
        CGContextConcatCTM(bitmapContextRef, CGAffineTransformMake(0, -1, 1, 0, 0, 0));
        CGContextTranslateCTM(bitmapContextRef, -CGRectGetHeight(screenRect), 0);
      } else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
        // Rotate pi
        CGContextConcatCTM(bitmapContextRef, CGAffineTransformMake(-1, 0, 0, -1, 0, 0));
        CGContextTranslateCTM(bitmapContextRef, -CGRectGetWidth(screenRect),
                              -CGRectGetHeight(screenRect));
      }
    }

    // This special case is for Alert-Views that for some reason do not render correctly.
    if ([window isKindOfClass:gUIAlertControllerShimPresenterWindowClass] ||
        [window isKindOfClass:gUIModalItemHostingWindowClass]) {
      [window.layer renderInContext:UIGraphicsGetCurrentContext()];
    } else {
      BOOL success = [window drawViewHierarchyInRect:windowRect afterScreenUpdates:afterUpdates];
      if (!success) {
        NSLog(@"Failed to drawViewHierarchyInRect for window: %@", window);
      }
    }

    CGContextRestoreGState(bitmapContextRef);
  }
}

+ (UIImage *)takeScreenshot {
  return [self grey_takeScreenshotAfterScreenUpdates:YES withStatusBar:NO];
}

+ (UIImage *)screenshotIncludingStatusBar:(BOOL)includeStatusBar {
  return [self grey_takeScreenshotAfterScreenUpdates:YES withStatusBar:includeStatusBar];
}

+ (UIImage *)snapshotElement:(id)element {
  if (![element respondsToSelector:@selector(accessibilityFrame)]) {
    return nil;
  }
  CGRect elementAXFrame = [element accessibilityFrame];
  if (CGRectIsEmpty(elementAXFrame)) {
    return nil;
  }
  UIView *viewToSnapshot = [element isKindOfClass:[UIView class]]
                               ? (UIView *)element
                               : [element grey_viewContainingSelf];
  CGRect viewAXFrame = [viewToSnapshot accessibilityFrame];

  UIGraphicsBeginImageContextWithOptions(elementAXFrame.size, NO, [UIScreen mainScreen].scale);
  CGContextRef currentContext = UIGraphicsGetCurrentContext();
  CGContextSaveGState(currentContext);
  // Translate the canvas to capture the exact element's AX frame.
  CGPoint translationPoint = CGPointMake(-(elementAXFrame.origin.x - (viewAXFrame.origin.x)),
                                         -(elementAXFrame.origin.y - (viewAXFrame.origin.y)));
  CGContextTranslateCTM(currentContext, translationPoint.x, translationPoint.y);

  [viewToSnapshot drawViewHierarchyInRect:viewToSnapshot.bounds afterScreenUpdates:NO];
  UIImage *orientedScreenshot = UIGraphicsGetImageFromCurrentImageContext();

  CGContextRestoreGState(currentContext);
  UIGraphicsEndImageContext();

  return orientedScreenshot;
}

+ (NSString *)saveImageAsPNG:(UIImage *)image
                      toFile:(NSString *)filename
                 inDirectory:(NSString *)directoryPath {
  return [NSFileManager grey_saveImageAsPNG:image toFile:filename inDirectory:directoryPath];
}

#pragma mark - Package Internal

+ (UIImage *)grey_takeScreenshotAfterScreenUpdates:(BOOL)afterScreenUpdates
                                     withStatusBar:(BOOL)included {
  UIScreen *mainScreen = [UIScreen mainScreen];
  CGRect screenRect = [self grey_rectRotatedToStatusBarOrientation:mainScreen.bounds];
  UIGraphicsBeginImageContextWithOptions(screenRect.size, YES, mainScreen.scale);
  [self drawScreenInContext:UIGraphicsGetCurrentContext()
         afterScreenUpdates:afterScreenUpdates
              withStatusBar:included];
  UIImage *orientedScreenshot = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return orientedScreenshot;
}

#pragma mark - Private

+ (CGRect)grey_rectRotatedToStatusBarOrientation:(CGRect)rect {
  UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
  if (!iOS8_0_OR_ABOVE() && UIInterfaceOrientationIsLandscape(orientation)) {
    CGAffineTransform rotationTransform = CGAffineTransformMake(0, 1, 1, 0, 0, 0);
    return CGRectApplyAffineTransform(rect, rotationTransform);
  }

  return rect;
}

/**
 *  @return An image with the given @c image redrawn in the orientation defined by its
 *          imageOrientation property.
 */
+ (UIImage *)grey_imageAfterApplyingOrientation:(UIImage *)image {
  if (image.imageOrientation == UIImageOrientationUp) {
    return image;
  }

  UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
  CGRect imageRect = CGRectMake(0, 0, image.size.width, image.size.height);
  [image drawInRect:imageRect];
  UIImage *rotatedImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return rotatedImage;
}

@end

/**
 * Get a raw image pixel buffer from a CGImageRef pointing to an image.
 */
unsigned char *grey_createImagePixelDataFromCGImageRef(CGImageRef imageRef,
                                                       CGContextRef *outBmpCtx) {
  size_t width = CGImageGetWidth(imageRef);
  size_t height = CGImageGetHeight(imageRef);
  unsigned char *imagePixelBuffer = malloc(height * width * kBytesPerPixel);

  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

  // Create the bitmap context. We want XRGB.
  CGContextRef bitmapContextRef =
      CGBitmapContextCreate(imagePixelBuffer, width, height,
                            8,                       // bits per component
                            width * kBytesPerPixel,  // bytes per row
                            colorSpace, kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Big);
  CGColorSpaceRelease(colorSpace);
  if (!bitmapContextRef) {
    free(imagePixelBuffer);
    return NULL;
  }

  // Once we draw, the memory allocated for the context for rendering will then contain the raw
  // image pixel data in the specified color space.
  CGContextDrawImage(bitmapContextRef, CGRectMake(0, 0, width, height), imageRef);
  if (outBmpCtx != NULL) {
    // Caller must call CGContextRelease.
    *outBmpCtx = bitmapContextRef;
  } else {
    CGContextRelease(bitmapContextRef);
  }

  // Must be freed by the caller.
  return imagePixelBuffer;
}
