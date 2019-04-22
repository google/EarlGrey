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

#import "GREYHostApplicationDistantObject+UITableViewTest.h"

#import "AppFramework/Matcher/GREYAllOf.h"
#import "AppFramework/Matcher/GREYMatchers.h"

@implementation GREYHostApplicationDistantObject (UITableViewTest)

- (id<GREYMatcher>)matcherForNotScrolling {
  GREYMatchesBlock matchesNotScrolling = ^BOOL(UIScrollView *element) {
    return !element.dragging && !element.decelerating;
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:@"scrollViewNotScrolling"];
  };
  return [[GREYAllOf alloc] initWithMatchers:@[
    [GREYMatchers matcherForKindOfClass:[UIScrollView class]],
    [[GREYElementMatcherBlock alloc] initWithMatchesBlock:matchesNotScrolling
                                         descriptionBlock:describe]
  ]];
}

- (GREYActionBlock *)actionForTableViewBoundOff {
  id<GREYMatcher> scrollViewMatcher = [GREYMatchers matcherForKindOfClass:[UIScrollView class]];
  return [[GREYActionBlock alloc]
      initWithName:@"toggleBounces"
       constraints:scrollViewMatcher
      performBlock:^BOOL(UIScrollView *scrollView, NSError *__strong *error) {
        grey_dispatch_sync_on_main_thread(^{
          scrollView.bounces = NO;
        });
        return YES;
      }];
}

@end
