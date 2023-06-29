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

#import "GREYElementFinder.h"

#import "GREYFatalAsserts.h"
#import "GREYThrowDefines.h"
#import "GREYMatcher.h"
#import "GREYProvider.h"
#import "GREYElementProvider.h"
#import "GREYUIWindowProvider.h"

@implementation GREYElementFinder

- (instancetype)initWithMatcher:(id<GREYMatcher>)matcher {
  GREYThrowOnNilParameter(matcher);

  self = [super init];
  if (self) {
    _matcher = matcher;
  }
  return self;
}

- (NSArray<id> *)elementsMatchedInProvider:(id<GREYProvider>)elementProvider {
  GREYThrowOnNilParameter(elementProvider);
  GREYFatalAssertMainThread();

  NSMutableOrderedSet<id> *matchingElements = [[NSMutableOrderedSet alloc] init];
  for (id element in [elementProvider dataEnumerator]) {
    @autoreleasepool {
      if ([_matcher matches:element]) {
        [matchingElements addObject:element];
      }
    }
  }
  return [matchingElements array];
}

- (NSArray<id> *)elementsMatchedInAllWindowsIncludingStatusBar:(BOOL)includeStatusBar {
  GREYUIWindowProvider *windowProvider =
      [GREYUIWindowProvider providerWithAllWindowsWithStatusBar:includeStatusBar];
  GREYElementProvider *elementProvider =
      [GREYElementProvider providerWithRootProvider:windowProvider];
  return [self elementsMatchedInProvider:elementProvider];
}

@end
