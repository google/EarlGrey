//
// Copyright 2016 Google Inc.
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

#import "Additions/UITouch+GREYAdditions.h"

#import <objc/runtime.h>

#import "Additions/CGGeometry+GREYAdditions.h"
#import "Common/GREYAppleInternals.h"
#import "Common/GREYThrowDefines.h"

@implementation UITouch (GREYAdditions)

- (id)initAtPoint:(CGPoint)point relativeToWindow:(UIWindow *)window {
  GREYThrowOnNilParameter(window);

  point = CGPointAfterRemovingFractionalPixels(point);

  self = [super init];
  if (self) {
    [self setTapCount:1];
    [self setPhase:UITouchPhaseBegan];

    [self setWindow:window];
    [self _setLocationInWindow:point resetPrevious:YES];
    [self setView:[window hitTest:point withEvent:nil]];
    [self setTimestamp:[[NSProcessInfo processInfo] systemUptime]];

    // PSPDFKit: This was changed in iOS 14.
    if ([self respondsToSelector:@selector(_setIsFirstTouchForView:)]) {
        [self setIsTap:YES];
        [self _setIsFirstTouchForView:YES];
    } else {
        [self _setIsTapToClick:YES];

        // We modify the touchFlags ivar struct directly.
        // First entry is _firstTouchForView
        Ivar flagsIvar = class_getInstanceVariable(object_getClass(self), "_touchFlags");
        ptrdiff_t touchFlagsOffset = ivar_getOffset(flagsIvar);
        char *flags = (__bridge void *)self + touchFlagsOffset;
        *flags = *flags | (char)0x01;
    }
  }
  return self;
}

@end
