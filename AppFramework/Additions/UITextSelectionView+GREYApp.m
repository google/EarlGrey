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

/** Category for UITextInteractionAssistant to call the -setCursorVisible: method on it. */
@interface UITextInteractionAssistant_GREYApp (Private)
- (void)setCursorVisible:(BOOL)arg1;
@end

@implementation UITextInteractionAssistant_GREYApp

+ (void)load {
  if (iOS17_OR_ABOVE()) {
    GREYSwizzler *swizzler = [[GREYSwizzler alloc] init];
    SEL swizzledCursorBlinkSelector = @selector(greyswizzled_setCursorBlinks:);
    IMP implementation = [self instanceMethodForSelector:swizzledCursorBlinkSelector];
    BOOL swizzled = [swizzler swizzleClass:NSClassFromString(@"UITextInteractionAssistant")
                         addInstanceMethod:swizzledCursorBlinkSelector
                        withImplementation:implementation
              andReplaceWithInstanceMethod:@selector(setCursorBlinks:)];
    GREYFatalAssertWithMessage(swizzled,
                               @"Failed to swizzle UITextInteractionAssistant setCursorBlinks:");
  }
}

- (void)greyswizzled_setCursorBlinks:(BOOL)arg1 {
  [self setCursorVisible:NO];
  INVOKE_ORIGINAL_IMP1(void, @selector(greyswizzled_setCursorBlinks:), NO);
}

@end
