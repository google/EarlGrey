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
#import <UIKit/UIKit.h>

#import "NSFileManager+GREYCommon.h"
#import "NSObject+GREYCommon.h"
#import "GREYFatalAsserts.h"
#import "GREYLogger.h"
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

+ (void)drawScreenInContext:(CGContextRef)bitmapContextRef
         afterScreenUpdates:(BOOL)afterUpdates
              withStatusBar:(BOOL)includeStatusBar {
  GREYFatalAssertWithMessage(CGBitmapContextGetBitmapInfo(bitmapContextRef) != 0,
                             @"The context ref must point to a CGBitmapContext.");
  UIScreen *mainScreen = MainScreen();
  if (!mainScreen) return;
  CGRect screenRect = mainScreen.bounds;
  [self drawScreenInContext:bitmapContextRef
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
  UIGraphicsBeginImageContextWithOptions(elementAXFrame.size, NO, mainScreen.scale);
  [self drawViewInContext:UIGraphicsGetCurrentContext()
                     view:viewToSnapshot
                   bounds:elementAXFrame
       afterScreenUpdates:NO];
  UIImage *orientedScreenshot = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  // Add information for screendiff tests.
  AddAccessibilityHintForKeyboardToScreenshot(orientedScreenshot, elementAXFrame);
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
  UIGraphicsBeginImageContextWithOptions(screenRect.size, YES, 0);
  [self drawScreenInContext:UIGraphicsGetCurrentContext()
         afterScreenUpdates:afterScreenUpdates
               inScreenRect:screenRect
              withStatusBar:includeStatusBar];
  UIImage *orientedScreenshot = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  // Add information for screendiff tests.
  if (!forDebugging) {
    AddAccessibilityHintForKeyboardToScreenshot(orientedScreenshot, CGRectNull);
  }
  return orientedScreenshot;
}

#pragma mark - Private

+ (void)drawScreenInContext:(CGContextRef)bitmapContextRef
         afterScreenUpdates:(BOOL)afterUpdates
               inScreenRect:(CGRect)screenRect
              withStatusBar:(BOOL)includeStatusBar {
  GREYFatalAssertWithMessage(CGBitmapContextGetBitmapInfo(bitmapContextRef) != 0,
                             @"The context ref must point to a CGBitmapContext.");
  // The bitmap context width and height are scaled, so we need to undo the scale adjustment.
  NSEnumerator *allWindowsInReverse =
      [[GREYUIWindowProvider allWindowsWithStatusBar:includeStatusBar] reverseObjectEnumerator];
  for (UIWindow *window in allWindowsInReverse) {
    if (window.hidden || window.alpha == 0) {
      continue;
    }
    [self drawViewInContext:bitmapContextRef
                       view:window
                     bounds:screenRect
         afterScreenUpdates:afterUpdates];
  }
}

/**
 * Draws the @c view and its subviews within the specified @c bounds to the provided @c
 * bitmapContextRef. This centers the view to the context if the context size and view size are
 * different.
 *
 * @param bitmapContextRef   Target bitmap context for rendering.
 * @param view               The view to draw to the context.
 * @param boundsInScreenRect The bounds of the view to draw to the context in window coordinate.
 * @param afterScreenUpdates BOOL indicating whether to render before (@c NO) or after (@c YES)
 *                           screen updates.
 */
+ (void)drawViewInContext:(CGContextRef)bitmapContextRef
                     view:(UIView *)view
                   bounds:(CGRect)boundsInScreenRect
       afterScreenUpdates:(BOOL)afterScreenUpdates {
  UIScreen *mainScreen = MainScreen();
  if (!mainScreen) return;
  // The bitmap context width and height are scaled, so we need to undo the scale adjustment.
  CGFloat scale = mainScreen.scale;
  CGFloat contextWidth = CGBitmapContextGetWidth(bitmapContextRef) / scale;
  CGFloat contextHeight = CGBitmapContextGetHeight(bitmapContextRef) / scale;
  CGSize boundsSize = boundsInScreenRect.size;
  CGFloat xOffset = (contextWidth - boundsSize.width) / 2;
  CGFloat yOffset = (contextHeight - boundsSize.height) / 2;

  // This special case is for Alert-Views that for some reason do not render correctly.
  if ([view isKindOfClass:gUIAlertControllerShimPresenterWindowClass] ||
      [view isKindOfClass:gUIModalItemHostingWindowClass]) {
    CGContextSaveGState(bitmapContextRef);
    if (xOffset == 0 && yOffset == 0) {
      // If the screenRect and context size is the same, capture the screenRect of the
      // current window.
      CGAffineTransform searchTranslate = CGAffineTransformMakeTranslation(
          -boundsInScreenRect.origin.x, -boundsInScreenRect.origin.y);
      CGContextConcatCTM(bitmapContextRef, searchTranslate);
    } else {
      // Center the screenshot of the current window if the screenRect and the context size
      // is different.
      CGRect viewRect = view.bounds;
      CGPoint viewCenter = view.center;
      CGPoint viewAnchor = view.layer.anchorPoint;
      CGContextTranslateCTM(bitmapContextRef, viewCenter.x + xOffset, viewCenter.y + yOffset);
      CGContextConcatCTM(bitmapContextRef, view.transform);
      CGContextTranslateCTM(bitmapContextRef, -CGRectGetWidth(viewRect) * viewAnchor.x,
                            -CGRectGetHeight(viewRect) * viewAnchor.y);
    }
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    CGContextRestoreGState(bitmapContextRef);
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

  UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
  CGRect imageRect = CGRectMake(0, 0, image.size.width, image.size.height);
  [image drawInRect:imageRect];
  UIImage *rotatedImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return rotatedImage;
}

/**
 * Sets the accessibility hint of the specified @c screenshot to be the keyboardFrame's string
 * representation.
 *
 * @param screenshot     The UIImage for the taken screenshot.
 * @param elementAXFrame A CGRect with the accessibility frame of the view being scrapped. If not
 *                       @c nil, a screenshot will only be taken if this is as big as the whole
 *                       screen.
 *
 */
static void AddAccessibilityHintForKeyboardToScreenshot(UIImage *screenshot,
                                                        CGRect elementAXFrame) {
  if (!screenshot) {
    return;
  } else if (!CGRectIsNull(elementAXFrame) &&
             !CGRectEqualToRect(MainScreen().bounds, elementAXFrame)) {
    // We only want to add masking for a keyboard when the screenshot is for the entire app.
    return;
  } else {
    NSMutableDictionary<NSString *, NSString *> *maskingData = [[NSMutableDictionary alloc] init];
    CGRect keyboardFrame = [GREYUILibUtils scaledKeyboardFrame];
    if (!CGRectIsEmpty(keyboardFrame)) {
      maskingData[@"KeyboardFrame"] = NSStringFromCGRect(keyboardFrame);
    }
    if ([maskingData count]) {
      NSError *error;
      NSData *maskingJSON = [NSJSONSerialization dataWithJSONObject:maskingData
                                                            options:0
                                                              error:&error];
      if (error) {
        GREYLog(@"Screenshot's debug info could not be applied NSJSONSerialization error: %@\n%@",
                error, [NSThread callStackSymbols]);
      }
      NSString *maskingJSONString = [[NSString alloc] initWithData:maskingJSON
                                                          encoding:NSUTF8StringEncoding];
      [screenshot setAccessibilityHint:maskingJSONString];
    }
  }
}

@end
