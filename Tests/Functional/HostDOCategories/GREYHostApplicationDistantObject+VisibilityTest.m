//
// Copyright 2018 Google Inc.
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

#import "GREYHostApplicationDistantObject+VisibilityTest.h"

#include <objc/runtime.h>

#import "GREYMatchers.h"
#import "GREYAssertionBlock.h"
#import "GREYFatalAsserts.h"
#import "GREYThrowDefines.h"
#import "GREYErrorConstants.h"
#import "GREYMatcher.h"
#import "CGGeometry+GREYUI.h"
#import "GREYVisibilityChecker+Private.h"
#import "GREYVisibilityChecker.h"

@implementation GREYHostApplicationDistantObject (VisibilityTest)

- (id<GREYAssertion>)coverContentOffsetChangedAssertion {
  BOOL (^assertionBlock)(id element, NSError *__strong *errorOrNil) =
      ^BOOL(id element, NSError *__strong *errorOrNil) {
        CGPoint offset = ((UIScrollView *)element).contentOffset;
        CGPoint expectedOffset = CGPointMake(100, 100);
        if (CGPointEqualToPoint(offset, expectedOffset)) {
          return YES;
        } else {
          NSError *error =
              [[NSError alloc] initWithDomain:kGREYInteractionErrorDomain
                                         code:kGREYInteractionAssertionFailedErrorCode
                                     userInfo:@{NSLocalizedDescriptionKey : @"Cover view moved."}];
          *errorOrNil = error;
          return NO;
        }
      };
  return [GREYAssertionBlock assertionWithName:@"coverContentOffsetUnchanged"
                       assertionBlockWithError:assertionBlock];
}

- (id<GREYAssertion>)translucentOverlappingViewVisibleAreaAssertion {
  return [GREYAssertionBlock
            assertionWithName:@"translucentOverlappingViewVisibleArea"
      assertionBlockWithError:^BOOL(id element, NSError *__strong *errorOrNil) {
        CGRect visibleRect = [GREYVisibilityChecker rectEnclosingVisibleAreaOfElement:element];
        CGRect expectedRect = CGRectMake(0, 0, 50, 50);
        GREYFatalAssertWithMessage(CGSizeEqualToSize(visibleRect.size, expectedRect.size),
                                   @"rects must be equal");
        return YES;
      }];
}

- (GREYAssertionBlock *)ftr_assertOnIDSet:(NSMutableSet<NSString *> *)idSet {
  GREYAssertionBlock *assertAxId = [GREYAssertionBlock
            assertionWithName:@"Check Accessibility Id"
      assertionBlockWithError:^BOOL(id element, NSError *__strong *errorOrNil) {
        GREYThrowOnNilParameter(element);

        GREYFatalAssert([[GREYMatchers matcherForSufficientlyVisible] matches:element]);
        UIView *view = element;
        [idSet addObject:view.accessibilityIdentifier];
        return YES;
      }];
  return assertAxId;
}

- (id<GREYAssertion>)visibleRectangleAssertion {
  return [GREYAssertionBlock
            assertionWithName:@"TestVisibleRectangle"
      assertionBlockWithError:^BOOL(id element, NSError *__strong *errorOrNil) {
        GREYThrowOnNilParameterWithMessage(element, @"element must not be nil");
        GREYFatalAssertWithMessage([element isKindOfClass:[UIView class]],
                                   @"element must be UIView");
        UIView *view = element;
        CGRect visibleRect = [GREYVisibilityChecker rectEnclosingVisibleAreaOfElement:view];
        GREYFatalAssertWithMessage(CGRectIsEmpty(visibleRect), @"rect must be CGRectIsZero");
        return YES;
      }];
}

- (id<GREYAssertion>)entireRectangleVisibleAssertion {
  return [GREYAssertionBlock
            assertionWithName:@"TestVisibleRectangle"
      assertionBlockWithError:^BOOL(id element, NSError *__strong *errorOrNil) {
        GREYThrowOnNilParameterWithMessage(element, @"element must not be nil");
        GREYFatalAssertWithMessage([element isKindOfClass:[UIView class]],
                                   @"element must be UIView");
        UIView *view = element;
        CGRect expectedRect = view.accessibilityFrame;
        // Visiblity checker should first convert to pixel, then get integral inside,
        // then back to points.
        expectedRect = CGRectPointToPixel(expectedRect);
        expectedRect = CGRectIntegralInside(expectedRect);
        expectedRect = CGRectPixelToPoint(expectedRect);
        CGRect actualRect = [GREYVisibilityChecker rectEnclosingVisibleAreaOfElement:view];
        GREYFatalAssertWithMessage(CGRectEqualToRect(actualRect, expectedRect),
                                   @"expected: %@, actual: %@", NSStringFromCGRect(expectedRect),
                                   NSStringFromCGRect(actualRect));
        return YES;
      }];
}

- (void)setupOuterView {
  UIWindow *currentWindow = UIApplication.sharedApplication.delegate.window;
  UIView *_outerview = [[UIView alloc] initWithFrame:currentWindow.frame];
  _outerview.isAccessibilityElement = YES;
  _outerview.layer.shouldRasterize = YES;
  _outerview.layer.rasterizationScale = 0.001f;
  _outerview.accessibilityLabel = @"RasterizedLayer";
  _outerview.backgroundColor = [UIColor blueColor];
  [currentWindow.rootViewController.view addSubview:_outerview];
  objc_setAssociatedObject(self, @selector(coverContentOffsetChangedAssertion), _outerview,
                           OBJC_ASSOCIATION_RETAIN);
}

- (void)removeOuterView {
  UIView *outerview = objc_getAssociatedObject(self, @selector(coverContentOffsetChangedAssertion));
  [outerview removeFromSuperview];
}

- (id<GREYAssertion>)visibleRectangleSizeAssertion {
  return [GREYAssertionBlock
            assertionWithName:@"TestVisibleRectangle"
      assertionBlockWithError:^BOOL(id element, NSError *__strong *errorOrNil) {
        CGRect visibleRect = [GREYVisibilityChecker rectEnclosingVisibleAreaOfElement:element];
        GREYThrowOnNilParameterWithMessage(CGSizeEqualToSize(visibleRect.size, CGSizeMake(50, 50)),
                                           @"Visible rect must be 50X50. It is currently %@",
                                           NSStringFromCGSize(visibleRect.size));
        return YES;
      }];
}

- (BOOL)visibilityImagesArePresent {
  return [GREYVisibilityChecker grey_lastActualAfterImage] != nil &&
         [GREYVisibilityChecker grey_lastActualBeforeImage] != nil &&
         [GREYVisibilityChecker grey_lastExpectedAfterImage] != nil;
}

- (BOOL)visibilityImagesAreAbsent {
  return [GREYVisibilityChecker grey_lastExpectedAfterImage] == nil &&
         [GREYVisibilityChecker grey_lastActualBeforeImage] == nil &&
         [GREYVisibilityChecker grey_lastActualAfterImage] == nil;
}

@end
