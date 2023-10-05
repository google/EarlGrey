//
// Copyright 2020 Google Inc.
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

#import "UITextSelectionView+GREYApp.h"

#import "GREYFatalAsserts.h"
#import "GREYAppleInternals.h"
#import "GREYDefines.h"
#import "GREYSwizzler.h"

/** Category for UITextSelectionView to call the -setHidden: method on it. */
@interface UITextSelectionView_GREYApp (Private)
- (void)setHidden:(BOOL)hidden;
@end

@implementation UITextSelectionView_GREYApp

+ (void)load {
  GREYSwizzler *swizzler = [[GREYSwizzler alloc] init];
  if (iOS14_OR_ABOVE()) {
    SEL swizzledCaretBlinkSelector = @selector(greyswizzled_setCaretBlinkAnimationEnabled:);
    IMP implementation = [self instanceMethodForSelector:swizzledCaretBlinkSelector];
    BOOL swizzled = [swizzler swizzleClass:NSClassFromString(@"UITextSelectionView")
                         addInstanceMethod:swizzledCaretBlinkSelector
                        withImplementation:implementation
              andReplaceWithInstanceMethod:@selector(_setCaretBlinkAnimationEnabled:)];
    GREYFatalAssertWithMessage(
        swizzled, @"Failed to swizzle UITextSelectionView _setCaretBlinkAnimationEnabled:");
  } else {
    SEL swizzledCaretBlinkSelector = @selector(greyswizzled_setCaretBlinks:);
    IMP implementation = [self instanceMethodForSelector:swizzledCaretBlinkSelector];
    BOOL swizzled = [swizzler swizzleClass:NSClassFromString(@"UITextSelectionView")
                         addInstanceMethod:swizzledCaretBlinkSelector
                        withImplementation:implementation
              andReplaceWithInstanceMethod:@selector(setCaretBlinks:)];
    GREYFatalAssertWithMessage(swizzled, @"Failed to swizzle UITextSelectionView setCaretBlinks:");
  }
}

// The continuous caret blink animation is disabled by default in order to prevent it from causing
// a delay after any typing action. The cursor is also hidden as it generally has little use in UI
// tests. Both methods below do this for all iOS versions.

- (BOOL)greyswizzled_setCaretBlinkAnimationEnabled:(BOOL)enabled {
  INVOKE_ORIGINAL_IMP1(BOOL, @selector(greyswizzled_setCaretBlinkAnimationEnabled:), NO);
  [self setHidden:YES];
  return NO;
}

- (void)greyswizzled_setCaretBlinks:(BOOL)arg1 {
  INVOKE_ORIGINAL_IMP1(void, @selector(greyswizzled_setCaretBlinks:), NO);
  [self setHidden:YES];
}

@end

#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 170000)
// A new public class in Xcode 15.1+ which provides more information about the cursor.
@implementation UITextSelectionDisplayInteraction (Private)

+ (void)load {
  if (@available(iOS 17.0, *)) {
    if (iOS17_OR_ABOVE()) {
      BOOL swizzleSuccess =
          [[[GREYSwizzler alloc] init] swizzleClass:self
                              replaceInstanceMethod:@selector(setCursorBlinks:)
                                         withMethod:@selector(greyswizzled_setCursorBlinks:)];
      GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle UIView setNeedsDisplay");
    }
  }
}

- (void)greyswizzled_setCursorBlinks:(BOOL)act {
  if (@available(iOS 17.0, *)) {
    // Just setting cursorView to hidden does nothing. It was found that setting the subview of
    // the cursorView to hidden hides the entire cursor. The subview is of class _UIShapeView
    // as of Xcode 15.1.
    UIView *shapeView = [[self.cursorView subviews] firstObject];
    [shapeView setHidden:YES];
    INVOKE_ORIGINAL_IMP1(void, @selector(greyswizzled_setCursorBlinks:), 0);
  } else {
    INVOKE_ORIGINAL_IMP1(void, @selector(greyswizzled_setCursorBlinks:), 0);
  }
}
@end
#endif
