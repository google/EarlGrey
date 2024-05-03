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

static CGRect CGRectPixelAligned(CGRect rectInPixels) {
  rectInPixels.origin.x = round(rectInPixels.origin.x);
  rectInPixels.origin.y = round(rectInPixels.origin.y);
  rectInPixels.size.width = ceil(rectInPixels.size.width);
  rectInPixels.size.height = ceil(rectInPixels.size.height);

  return rectInPixels;
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
  NSEnumerator *visibleWindowsInReverse =
      [[self visibleWindowsWithStatusBar:includeStatusBar] reverseObjectEnumerator];
  for (UIWindow *window in visibleWindowsInReverse) {
    [self drawViewInContext:context view:window bounds:screenRect afterScreenUpdates:afterUpdates];
  }
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
  // We want to capture the most up-to-date version of the screen here, including the updates that
  // have been made in the current runloop iteration. Therefore we use
  UIImage *orientedScreenshot = [self imageOfViews:@[ viewToSnapshot ].objectEnumerator
                                      inScreenRect:elementAXFrame
                                        withFormat:format
                                afterScreenUpdates:YES];

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
  UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat preferredFormat];
  format.opaque = !iOS17_OR_ABOVE();
  NSArray<UIView *> *visibleWindows = [self visibleWindowsWithStatusBar:includeStatusBar];
  UIImage *orientedScreenshot = [self imageOfViews:visibleWindows.reverseObjectEnumerator
                                      inScreenRect:screenRect
                                        withFormat:format
                                afterScreenUpdates:afterScreenUpdates];


  return orientedScreenshot;
}

#pragma mark - Private

+ (UIImage *)imageOfViews:(NSEnumerator<UIView *> *)views
             inScreenRect:(CGRect)screenRect
               withFormat:(UIGraphicsImageRendererFormat *)format
       afterScreenUpdates:(BOOL)afterUpdates {
  CGRect snapshotRect = screenRect;
  // When possible, only draws the portion where the target rect is located instead of drawing the
  // entire screen and cropping it to the size of the target rect. This optimization works when
  // using @c UIGraphicsBeginImageContextWithOptions (deprecated in iOS 17), but results in a
  // partial render with @c UIGraphicsImageRendererFormat in some cases. It is not completely clear
  // what triggers this, but some necessary conditions are:
  // 1. screenshot is taken on a physical device with iOS 16 or below
  // 2. @c screenRect is contained by the entire screen bounds
#if !TARGET_OS_SIMULATOR
  if (!iOS17_OR_ABOVE()) {
    UIScreen *mainScreen = MainScreen();
    if (!mainScreen) return nil;
    if (CGRectContainsRect(mainScreen.bounds, snapshotRect)) {
      snapshotRect = mainScreen.bounds;
    }
  }
#endif

  UIGraphicsImageRenderer *renderer =
      [[UIGraphicsImageRenderer alloc] initWithSize:snapshotRect.size format:format];
  UIImage *image = [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
    for (UIView *view in views) {
      [self drawViewInContext:context
                         view:view
                       bounds:snapshotRect
           afterScreenUpdates:afterUpdates];
    }
  }];

  if (!CGRectEqualToRect(snapshotRect, screenRect)) {
    CGRect rectInPixels = CGRectPixelAligned(CGRectPointToPixel(screenRect));
    CGImageRef croppedImage = CGImageCreateWithImageInRect(image.CGImage, rectInPixels);
    image = [UIImage imageWithCGImage:croppedImage
                                scale:image.scale
                          orientation:image.imageOrientation];
    CGImageRelease(croppedImage);
  }

  return image;
}

+ (NSArray<UIWindow *> *)visibleWindowsWithStatusBar:(BOOL)includeStatusBar {
  NSPredicate *visiblePredicate = [NSPredicate
      predicateWithBlock:^BOOL(UIWindow *window, NSDictionary<NSString *, id> *bindings) {
        return !window.hidden && window.alpha != 0;
      }];
  return [[GREYUIWindowProvider allWindowsWithStatusBar:includeStatusBar]
      filteredArrayUsingPredicate:visiblePredicate];
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
