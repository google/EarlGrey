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

#import "GREYScrollToContentEdgeAction.h"

#import "GREYScrollAction.h"
#import "NSObject+GREYApp.h"
#import "UIScrollView+GREYApp.h"
#import "GREYAllOf.h"
#import "GREYAnyOf.h"
#import "GREYMatchers.h"
#import "GREYNot.h"
#import "NSString+GREYCommon.h"
#import "GREYFatalAsserts.h"
#import "GREYScrollActionError.h"
#import "NSError+GREYCommon.h"
#import "CGGeometry+GREYUI.h"
#import "GREYVisibilityChecker.h"

@implementation GREYScrollToContentEdgeAction {
  /**
   *  The specified edge of the content to be scrolled to.
   */
  GREYContentEdge _edge;
  /**
   *  The point specified as percentage referencing visible scrollable area to be used for fixing
   *  scroll start point. If any of the coordinates are set to NAN the corresponding coordinates of
   *  the scroll start point will be set to achieve maximum scroll.
   */
  CGPoint _startPointPercents;
  /**
   *  Identifier used for diagnostics.
   */
  NSString *_diagnosticsID;
}

- (instancetype)initWithEdge:(GREYContentEdge)edge startPointPercents:(CGPoint)startPointPercents {
  GREYFatalAssertWithMessage(
      isnan(startPointPercents.x) || (startPointPercents.x > 0 && startPointPercents.x < 1),
      @"startPointPercents must be NAN or in the range (0, 1) exclusive");
  GREYFatalAssertWithMessage(
      isnan(startPointPercents.y) || (startPointPercents.y > 0 && startPointPercents.y < 1),
      @"startPointPercents must be NAN or in the range (0, 1) exclusive");

  NSString *name =
      [NSString stringWithFormat:@"Scroll To %@ content edge", NSStringFromGREYContentEdge(edge)];

  NSArray *classMatchers = @[
    [GREYMatchers matcherForKindOfClass:[UIScrollView class]],
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    // TODO: Perform a scan of UIWebView usage and deprecate if possible. // NOLINT
    [GREYMatchers matcherForKindOfClass:[UIWebView class]],
#pragma clang diagnostic pop
  ];
  id<GREYMatcher> systemAlertShownMatcher = [GREYMatchers matcherForSystemAlertViewShown];
  NSArray *constraintMatchers = @[
    [[GREYAnyOf alloc] initWithMatchers:classMatchers],
    [[GREYNot alloc] initWithMatcher:systemAlertShownMatcher]
  ];
  self = [super initWithName:name
                 constraints:[[GREYAllOf alloc] initWithMatchers:constraintMatchers]];
  if (self) {
    _diagnosticsID = name;
    _edge = edge;
    _startPointPercents = startPointPercents;
  }
  return self;
}

- (instancetype)initWithEdge:(GREYContentEdge)edge {
  return [self initWithEdge:edge startPointPercents:GREYCGPointNull];
}

#pragma mark - GREYAction

- (BOOL)perform:(UIScrollView *)element error:(__strong NSError **)error {
  if (![self satisfiesConstraintsForElement:element error:error]) {
    return NO;
  }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  // TODO: Perform a scan of UIWebView usage and deprecate if possible. // NOLINT
  // To scroll UIWebView we must use the UIScrollView in its error and scroll it.
  if ([element isKindOfClass:[UIWebView class]]) {
    element = [(UIWebView *)element scrollView];
  }
#pragma clang diagnostic pop

  // Get the maximum scrollable amount in any direction and keep applying it until the edge
  // is reached.
  const CGFloat maxScrollInAnyDirection =
      MAX([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
  // TODO: This means that we keep scrolling until we reach the top and can take
  // forever if we are operating on a circular scroll view, implement a way to timeout long
  // running actions and make this process timeout.
  GREYScrollAction *scrollAction =
      [[GREYScrollAction alloc] initWithDirection:[GREYConstants directionFromCenterForEdge:_edge]
                                           amount:maxScrollInAnyDirection
                               startPointPercents:_startPointPercents];
  NSError *scrollError;
  while (YES) {
    @autoreleasepool {
      if (![scrollAction perform:element error:&scrollError]) {
        break;
      }
    }
  }

  if (scrollError.code == kGREYScrollReachedContentEdge &&
      [scrollError.domain isEqualToString:kGREYScrollErrorDomain]) {
    // We have reached the content edge.
    return YES;
  } else {
    // Some other error has occurred.
    *error = scrollError;
    return NO;
  }
}

#pragma mark - GREYDiagnosable

- (NSString *)diagnosticsID {
  return _diagnosticsID;
}

@end
