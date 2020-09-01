//
//  UITextSelectionView.m
//  EarlGrey
//
//  Created by Xavier Jurado on 01/09/2020.
//  Copyright © 2020 Google Inc. All rights reserved.
//

#import "UITextSelectionView+GREYAdditions.h"

#include <objc/runtime.h>

#import "Common/GREYDefines.h"
#import "Common/GREYFatalAsserts.h"
#import "Common/GREYAppleInternals.h"
#import "Common/GREYSwizzler.h"

@implementation UITextSelectionView_GREYAdditions

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
  // a delay after any typing action.
  INVOKE_ORIGINAL_IMP1(BOOL, @selector(greyswizzled_setCaretBlinkAnimationEnabled:), NO);
  return NO;
}

@end
