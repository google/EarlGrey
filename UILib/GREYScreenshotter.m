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

#import "GREYScreenshotter.h"

#import "NSFileManager+GREYCommon.h"
#import "NSObject+GREYCommon.h"
#import "GREYFatalAsserts.h"
#import "GREYThrowDefines.h"
#import "GREYUIWindowProvider.h"

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
  if (self == [GREYScreenshotter self]) {
    gUIAlertControllerShimPresenterWindowClass =
        NSClassFromString(@"_UIAlertControllerShimPresenterWindow");
    gUIModalItemHostingWindowClass = NSClassFromString(@"_UIModalItemHostingWindow");
  }
}

+ (void)drawScreenInContext:(CGContextRef)bitmapContextRef
         afterScreenUpdates:(BOOL)afterUpdates
              withStatusBar:(BOOL)includeStatusBar {
  GREYFatalAssertWithMessage(CGBitmapContextGetBitmapInfo(bitmapContextRef) != 0,
                             @"The context ref must point to a CGBitmapContext.");
  UIScreen *mainScreen = [UIScreen mainScreen];
  CGRect screenRect = mainScreen.bounds;
  [self drawScreenInContext:bitmapContextRef
         afterScreenUpdates:afterUpdates
               inScreenRect:screenRect
              withStatusBar:includeStatusBar];
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
                                     withStatusBar:(BOOL)includeStatusBar {
  CGRect screenRect = [UIScreen mainScreen].bounds;
  return [self grey_takeScreenshotAfterScreenUpdates:afterScreenUpdates
                                        inScreenRect:screenRect
                                       withStatusBar:includeStatusBar];
}

+ (UIImage *)grey_takeScreenshotAfterScreenUpdates:(BOOL)afterScreenUpdates
                                      inScreenRect:(CGRect)screenRect
                                     withStatusBar:(BOOL)includeStatusBar {
  UIGraphicsBeginImageContextWithOptions(screenRect.size, YES, 0);
  [self drawScreenInContext:UIGraphicsGetCurrentContext()
         afterScreenUpdates:afterScreenUpdates
               inScreenRect:screenRect
              withStatusBar:includeStatusBar];
  UIImage *orientedScreenshot = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return orientedScreenshot;
}

#pragma mark - Private

+ (void)drawScreenInContext:(CGContextRef)bitmapContextRef
         afterScreenUpdates:(BOOL)afterUpdates
               inScreenRect:(CGRect)screenRect
              withStatusBar:(BOOL)includeStatusBar {
  GREYFatalAssertWithMessage(CGBitmapContextGetBitmapInfo(bitmapContextRef) != 0,
                             @"The context ref must point to a CGBitmapContext.");
  UIScreen *mainScreen = [UIScreen mainScreen];

  // The bitmap context width and height are scaled, so we need to undo the scale adjustment.
  CGFloat scale = mainScreen.scale;
  CGFloat contextWidth = CGBitmapContextGetWidth(bitmapContextRef) / scale;
  CGFloat contextHeight = CGBitmapContextGetHeight(bitmapContextRef) / scale;
  CGSize screenSize = screenRect.size;
  CGFloat xOffset = (contextWidth - screenSize.width) / 2;
  CGFloat yOffset = (contextHeight - screenSize.height) / 2;

  // The bitmap context width and height are scaled, so we need to undo the scale adjustment.
  NSEnumerator *allWindows =
      [[GREYUIWindowProvider allWindowsWithStatusBar:includeStatusBar] objectEnumerator];
  for (UIWindow *window in allWindows) {
    if (window.hidden || window.alpha == 0) {
      continue;
    }

    // This special case is for Alert-Views that for some reason do not render correctly.
    if ([window isKindOfClass:gUIAlertControllerShimPresenterWindowClass] ||
        [window isKindOfClass:gUIModalItemHostingWindowClass]) {
      CGContextSaveGState(bitmapContextRef);
      if (xOffset == 0 && yOffset == 0) {
        // If the screenRect and context size is the same, capture the screenRect of the
        // current window.
        CGAffineTransform searchTranslate =
            CGAffineTransformMakeTranslation(-screenRect.origin.x, -screenRect.origin.y);
        CGContextConcatCTM(bitmapContextRef, searchTranslate);
      } else {
        // Center the screenshot of the current window if the screenRect and the context size
        // is different.
        CGRect windowRect = window.bounds;
        CGPoint windowCenter = window.center;
        CGPoint windowAnchor = window.layer.anchorPoint;
        CGContextTranslateCTM(bitmapContextRef, windowCenter.x + xOffset, windowCenter.y + yOffset);
        CGContextConcatCTM(bitmapContextRef, window.transform);
        CGContextTranslateCTM(bitmapContextRef, -CGRectGetWidth(windowRect) * windowAnchor.x,
                              -CGRectGetHeight(windowRect) * windowAnchor.y);
      }
      [window.layer renderInContext:UIGraphicsGetCurrentContext()];
      CGContextRestoreGState(bitmapContextRef);
    } else {
      CGRect localFrame = [window convertRect:screenRect fromWindow:nil];
      // Convert to core graphics coordinate system.
      CGRect frame = CGRectMake(-localFrame.origin.x, -localFrame.origin.y,
                                window.bounds.size.width, window.bounds.size.height);
      BOOL success = [window drawViewHierarchyInRect:frame afterScreenUpdates:afterUpdates];
      if (!success) {
        NSLog(@"Failed to drawViewHierarchyInRect for window: %@", window);
      }
    }
  }
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
