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
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "GREYDefines.h"

#import "NSFileManager+GREYCommon.h"
#import "NSObject+GREYCommon.h"
#import "GREYLogger.h"
#import "CGGeometry+GREYUI.h"
#import "GREYUIWindowProvider.h"
#import "GREYUILibUtils.h"


// Private class for AlertController window that doesn't work with drawViewHierarchyInRect.
static Class gUIAlertControllerShimPresenterWindowClass;
// Private class for ModalHostingWindow window that doesn't work with drawViewHierarchyInRect.
static Class gUIModalItemHostingWindowClass;

/**
 * @return A current screen if the window exists and @c nil if it does not.
 */
static UIScreen *MainScreen(void) {
  UIScreen *mainScreen = [GREYUILibUtils screen];
  if (!mainScreen || CGRectEqualToRect(mainScreen.bounds, CGRectNull)) {
    return nil;
  } else {
    return mainScreen;
  }
}

@implementation GREYScreenshotter

+ (void)initialize {
  if (self == [GREYScreenshotter self]) {
    gUIAlertControllerShimPresenterWindowClass =
        NSClassFromString(@"_UIAlertControllerShimPresenterWindow");
    gUIModalItemHostingWindowClass = NSClassFromString(@"_UIModalItemHostingWindow");
  }
}

+ (void)drawScreenInContext:(UIGraphicsImageRendererContext *)context
         afterScreenUpdates:(BOOL)afterUpdates
              withStatusBar:(BOOL)includeStatusBar {
  UIScreen *mainScreen = MainScreen();
  if (!mainScreen) return;
  CGRect screenRect = mainScreen.bounds;
  [self drawScreenInContext:context
         afterScreenUpdates:afterUpdates
               inScreenRect:screenRect
              withStatusBar:includeStatusBar];
}

+ (UIImage *)takeScreenshot {
  return [self grey_takeScreenshotAfterScreenUpdates:YES withStatusBar:NO forDebugging:NO];
  ;
}

+ (UIImage *)screenshotIncludingStatusBar:(BOOL)includeStatusBar {
  return [self grey_takeScreenshotAfterScreenUpdates:YES
                                       withStatusBar:includeStatusBar
                                        forDebugging:NO];
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

  UIScreen *mainScreen = MainScreen();
  if (!mainScreen) return nil;
  UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat preferredFormat];
  format.scale = mainScreen.scale;
  UIGraphicsImageRenderer *renderer =
      [[UIGraphicsImageRenderer alloc] initWithSize:elementAXFrame.size format:format];
  UIImage *orientedScreenshot =
      [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
        // We want to capture the most up-to-date version of the screen here, including the updates
        // that have been made in the current runloop iteration. Therefore we use
        // `afterScreenUpdates:YES`.
        [self drawViewInContext:context
                           view:viewToSnapshot
                         bounds:elementAXFrame
             afterScreenUpdates:YES];
      }];

  return orientedScreenshot;
}

+ (NSString *)saveImageAsPNG:(UIImage *)image
                      toFile:(NSString *)filename
                 inDirectory:(NSString *)directoryPath {
  return [NSFileManager grey_saveImageAsPNG:image toFile:filename inDirectory:directoryPath];
}

#pragma mark - Package Internal

+ (UIImage *)grey_takeScreenshotAfterScreenUpdates:(BOOL)afterScreenUpdates
                                     withStatusBar:(BOOL)includeStatusBar
                                      forDebugging:(BOOL)forDebugging {
  UIScreen *mainScreen = MainScreen();
  if (!mainScreen) return nil;
  CGRect screenRect = mainScreen.bounds;
  return [self grey_takeScreenshotAfterScreenUpdates:afterScreenUpdates
                                        inScreenRect:screenRect
                                       withStatusBar:includeStatusBar
                                        forDebugging:forDebugging];
}

+ (UIImage *)grey_takeScreenshotAfterScreenUpdates:(BOOL)afterScreenUpdates
                                      inScreenRect:(CGRect)screenRect
                                     withStatusBar:(BOOL)includeStatusBar
                                      forDebugging:(BOOL)forDebugging {
  CGRect snapshotRect = screenRect;
  // When possible, only draws the portion where the target rect is located instead of drawing the
  // entire screen and cropping it to the size of the target rect. This optimization works when
  // using @c UIGraphicsBeginImageContextWithOptions (deprecated in iOS 17), but results in a
  // partial render with @c UIGraphicsImageRendererFormat in some cases when performed on a physical
  // device with iOS 16 or below.
#if !TARGET_OS_SIMULATOR
  if (!iOS17_OR_ABOVE()) {
    UIScreen *mainScreen = MainScreen();
    if (!mainScreen) return nil;
    snapshotRect = mainScreen.bounds;
  }
#endif

  UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat preferredFormat];
  format.opaque = !iOS17_OR_ABOVE();
  UIGraphicsImageRenderer *renderer =
      [[UIGraphicsImageRenderer alloc] initWithSize:snapshotRect.size format:format];
  UIImage *orientedScreenshot =
      [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
        [self drawScreenInContext:context
               afterScreenUpdates:afterScreenUpdates
                     inScreenRect:snapshotRect
                    withStatusBar:includeStatusBar];
      }];

  if (!CGRectEqualToRect(snapshotRect, screenRect)) {
    CGImageRef croppedImage = CGImageCreateWithImageInRect(orientedScreenshot.CGImage,
                                                           CGRectPointToPixelAligned(screenRect));
    orientedScreenshot = [UIImage imageWithCGImage:croppedImage
                                             scale:orientedScreenshot.scale
                                       orientation:orientedScreenshot.imageOrientation];
    CGImageRelease(croppedImage);
  }


  return orientedScreenshot;
}

#pragma mark - Private

+ (void)drawScreenInContext:(UIGraphicsImageRendererContext *)context
         afterScreenUpdates:(BOOL)afterUpdates
               inScreenRect:(CGRect)screenRect
              withStatusBar:(BOOL)includeStatusBar {
  // The bitmap context width and height are scaled, so we need to undo the scale adjustment.
  NSEnumerator *allWindowsInReverse =
      [[GREYUIWindowProvider allWindowsWithStatusBar:includeStatusBar] reverseObjectEnumerator];
  for (UIWindow *window in allWindowsInReverse) {
    if (window.hidden || window.alpha == 0) {
      continue;
    }
    [self drawViewInContext:context view:window bounds:screenRect afterScreenUpdates:afterUpdates];
  }
}

/**
 * Draws the @c view and its subviews within the specified @c bounds to the provided @c
 * context. This centers the view to the context if the context size and view size are different.
 *
 * @param context            UIGraphicsImageRenderer context for rendering.
 * @param view               The view to draw to the context.
 * @param boundsInScreenRect The bounds of the view to draw to the context in window coordinate.
 * @param afterScreenUpdates BOOL indicating whether to render before (@c NO) or after (@c YES)
 *                           screen updates.
 */
+ (void)drawViewInContext:(UIGraphicsImageRendererContext *)context
                     view:(UIView *)view
                   bounds:(CGRect)boundsInScreenRect
       afterScreenUpdates:(BOOL)afterScreenUpdates {
  UIScreen *mainScreen = MainScreen();
  if (!mainScreen) return;
  // The bitmap context width and height are scaled, so we need to undo the scale adjustment.
  CGFloat scale = mainScreen.scale;
  CGSize size = context.format.bounds.size;
  CGFloat contextWidth = size.width / scale;
  CGFloat contextHeight = size.height / scale;
  CGSize boundsSize = boundsInScreenRect.size;
  CGFloat xOffset = (contextWidth - boundsSize.width) / 2;
  CGFloat yOffset = (contextHeight - boundsSize.height) / 2;

  // This special case is for Alert-Views that for some reason do not render correctly.
  if ([view isKindOfClass:gUIAlertControllerShimPresenterWindowClass] ||
      [view isKindOfClass:gUIModalItemHostingWindowClass]) {
    CGContextRef ctxRef = context.CGContext;
    CGContextSaveGState(ctxRef);
    if (xOffset == 0 && yOffset == 0) {
      // If the screenRect and context size is the same, capture the screenRect of the
      // current window.
      CGAffineTransform searchTranslate = CGAffineTransformMakeTranslation(
          -boundsInScreenRect.origin.x, -boundsInScreenRect.origin.y);
      CGContextConcatCTM(ctxRef, searchTranslate);
    } else {
      // Center the screenshot of the current window if the screenRect and the context size
      // is different.
      CGRect viewRect = view.bounds;
      CGPoint viewCenter = view.center;
      CGPoint viewAnchor = view.layer.anchorPoint;
      CGContextTranslateCTM(ctxRef, viewCenter.x + xOffset, viewCenter.y + yOffset);
      CGContextConcatCTM(ctxRef, view.transform);
      CGContextTranslateCTM(ctxRef, -CGRectGetWidth(viewRect) * viewAnchor.x,
                            -CGRectGetHeight(viewRect) * viewAnchor.y);
    }
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    CGContextRestoreGState(ctxRef);
  } else {
    // Convert to local coordinate.
    CGRect localFrame = [view convertRect:boundsInScreenRect fromView:nil];
    // Convert to core graphics coordinate system.
    CGRect frame = CGRectMake(-localFrame.origin.x, -localFrame.origin.y, view.bounds.size.width,
                              view.bounds.size.height);
    BOOL success = [view drawViewHierarchyInRect:frame afterScreenUpdates:afterScreenUpdates];
    if (!success) {
      GREYLog(@"Failed to drawViewHierarchyInRect for view: %@", view);
    }
  }
}

/**
 * @return An image with the given @c image redrawn in the orientation defined by its
 *         imageOrientation property.
 */
+ (UIImage *)grey_imageAfterApplyingOrientation:(UIImage *)image {
  if (image.imageOrientation == UIImageOrientationUp) {
    return image;
  }

  UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat preferredFormat];
  format.scale = image.scale;
  UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:image.size
                                                                             format:format];
  UIImage *rotatedImage = [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
    [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
  }];

  return rotatedImage;
}

@end
