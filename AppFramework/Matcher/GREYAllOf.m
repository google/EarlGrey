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

#import "GREYAllOf.h"
#import "GREYAllOf+Private.h"


#import "GREYMatcherUtil.h"
#import "GREYThrowDefines.h"
#import "GREYBaseMatcher.h"
#import "GREYDescription.h"
#import "GREYMatcher.h"
#import "GREYStringDescription.h"

@implementation GREYAllOf {
  NSArray<id<GREYMatcher>> *_matchers;
  NSString *_diagnosticsID;
}

- (instancetype)initWithMatchers:(NSArray<id<GREYMatcher>> *)matchers {
  GREYThrowOnFailedCondition(matchers.count > 0);

  self = [super init];
  if (self) {
    NSUInteger numOfMatchers = matchers.count;
    NSMutableArray<id<GREYMatcher>> *matchersCopy =
        [[NSMutableArray alloc] initWithCapacity:numOfMatchers];
    BOOL visibilityMatcherFound = NO;
    // Explicitly copy over the elements because the array can be a remote object.
    for (NSUInteger i = 0; i < numOfMatchers; ++i) {
      id<GREYMatcher> matcher = [matchers objectAtIndex:i];
      if (visibilityMatcherFound) {
        GREYThrowImproperOrderException(matchers);
      } else if (GREYIsVisibilityMatcher(matcher)) {
        visibilityMatcherFound = YES;
      }
      [matchersCopy addObject:matcher];
    }
    _matchers = [NSArray arrayWithArray:matchersCopy];
  }
  return self;
}

- (instancetype)initWithName:(NSString *)name matchers:(NSArray<id<GREYMatcher>> *)matchers {
  self = [self initWithMatchers:matchers];
  if (self) {
    _diagnosticsID = name;
  }
  return self;
}

#pragma mark - GREYMatcher

- (BOOL)matches:(id)item {
  return [self matches:item describingMismatchTo:[[GREYStringDescription alloc] init]];
}

- (BOOL)matches:(id)item describingMismatchTo:(id<GREYDescription>)mismatchDescription {
  for (id<GREYMatcher> matcher in _matchers) {
    
    BOOL success = [matcher matches:item describingMismatchTo:mismatchDescription];
    
    if (!success) {
      return NO;
    }
  }
  return YES;
}

- (void)describeTo:(id<GREYDescription>)description {
  [description appendText:@"("];
  for (NSUInteger i = 0; i < _matchers.count - 1; i++) {
    [[description appendDescriptionOf:_matchers[i]] appendText:@" && "];
  }
  [description appendDescriptionOf:_matchers[_matchers.count - 1]];
  [description appendText:@")"];
}

#pragma mark - GREYDiagnosable

- (NSString *)diagnosticsID {
  return _diagnosticsID;
}

@end
