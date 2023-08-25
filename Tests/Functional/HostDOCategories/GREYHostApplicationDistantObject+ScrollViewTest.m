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

#import "ExposedForTesting.h"
#import "GREYSyncAPI.h"
#import "GREYHostApplicationDistantObject+ScrollViewTest.h"
#import "CGGeometry+GREYUI.h"
#import "GREYVisibilityChecker.h"

@implementation GREYHostApplicationDistantObject (ScrollViewTest)

- (id<GREYAction>)actionForSetScrollViewContentOffSet:(CGPoint)offset animated:(BOOL)animated {
  BOOL (^actionBlock)(UIScrollView *, __strong NSError **) =
      ^BOOL(UIScrollView *view, __strong NSError **errorOrNil) {
        grey_dispatch_sync_on_main_thread(^{
          [view setContentOffset:offset animated:animated];
        });
        return YES;
      };

  return [GREYActionBlock actionWithName:@"setContentOffSet"
                             constraints:[GREYMatchers matcherForKindOfClass:[UIScrollView class]]
                            performBlock:actionBlock];
}

- (id<GREYAction>)actionForToggleBounces {
  return [[GREYActionBlock alloc]
      initWithName:@"toggleBounces"
       constraints:[GREYMatchers matcherForKindOfClass:[UIScrollView class]]
      performBlock:^BOOL(UIScrollView *scrollView, NSError *__strong *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
          scrollView.bounces = !scrollView.bounces;
        });
        return YES;
      }];
}

- (id<GREYAssertion>)assertionWithPartiallyVisible {
  return [GREYAssertionBlock
            assertionWithName:@"TestVisibleRectangle"
      assertionBlockWithError:^BOOL(UIScrollView *view, NSError *__strong *errorOrNil) {
        if (![view isKindOfClass:[UIScrollView class]]) {
          return NO;
        }

        CGRect visibleRect = [GREYVisibilityChecker rectEnclosingVisibleAreaOfElement:view];
        visibleRect = [view.window convertRect:visibleRect fromWindow:nil];
        visibleRect = [view convertRect:visibleRect fromView:nil];

        CGPoint contentOffset = view.contentOffset;
        CGRect expectedVisibleRect =
            CGRectMake(contentOffset.x, contentOffset.y, view.superview.bounds.size.width, 82);
        return CGRectEqaulToRectWithFloatingTolerance(visibleRect, expectedVisibleRect);
      }];
}

@end
