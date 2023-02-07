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
  }
}

- (BOOL)greyswizzled_setCaretBlinkAnimationEnabled:(BOOL)enabled {
  // The continuous caret blink animation is disabled by default in order to prevent it from causing
  // a delay after any typing action. The cursor is also hidden as it generally has little use in UI
  // tests.
  INVOKE_ORIGINAL_IMP1(BOOL, @selector(greyswizzled_setCaretBlinkAnimationEnabled:), NO);
  [self setHidden:YES];
  return NO;
}

@end
