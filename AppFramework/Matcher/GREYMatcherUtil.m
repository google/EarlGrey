//
// Copyright 2021 Google Inc.
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

#import "GREYMatcherUtil.h"

#import "GREYVisibilityMatcher.h"
#import "GREYFrameworkException.h"
#import "GREYMatcher.h"

BOOL GREYIsVisibilityMatcher(id<GREYMatcher> matcher) {
  return [matcher isKindOfClass:[GREYVisibilityMatcher class]];
}

void GREYThrowImproperOrderException(NSArray<id<GREYMatcher>> *matcherList) {
  NSString *reason = [NSString
      stringWithFormat:@"Compound matcher: %@ does not have visibility matcher - "
                       @"grey_sufficientlyVisible(), grey_interactable() etc. at the "
                       @"end of the matcher list. Please move it to the end.\nStack Trace: %@",
                       matcherList, [NSThread callStackSymbols]];
  [[GREYFrameworkException exceptionWithName:kGREYImproperMatcherOrderingException
                                      reason:reason] raise];
}

NSArray<id<GREYMatcher>> *GREYMatchersCheckedForImproperOrdering(
    NSArray<id<GREYMatcher>> *matcherList) {
  BOOL isVisibilityMatcher;
  for (id<GREYMatcher> matcher in matcherList) {
    if (isVisibilityMatcher) {
      GREYThrowImproperOrderException(matcherList);
    } else {
      if (GREYIsVisibilityMatcher(matcher)) {
        isVisibilityMatcher = YES;
      }
    }
  }
  return matcherList;
}
