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

#import "GREYAppState.h"

static NSDictionary<NSNumber *, NSString *> *GREYStateTrackerDescriptions() {
  static dispatch_once_t onceToken;
  static NSDictionary<NSNumber *, NSString *> *descriptions;
  dispatch_once(&onceToken, ^{
    descriptions = @{
      @(kGREYPendingDrawLayoutPass) : @"PendingDrawLayoutPass",
      @(kGREYPendingViewsToAppear) : @"PendingViewsToAppear",
      @(kGREYPendingViewsToDisappear) : @"PendingViewsToDisappear",
      @(kGREYPendingKeyboardTransition) : @"PendingKeyboardTransition",
      @(kGREYPendingCAAnimation) : @"PendingCAAnimation",
      @(kGREYPendingUIAnimation) : @"PendingUIAnimation",
      @(kGREYPendingRootViewControllerToAppear) : @"PendingRootViewControllerToAppear",
      @(kGREYPendingNetworkRequest) : @"PendingNetworkRequest",
      @(kGREYPendingGestureRecognition) : @"PendingGestureRecognition",
      @(kGREYPendingUIScrollViewScrolling) : @"PendingUIScrollViewScrolling",
      @(kGREYIgnoringSystemWideUserInteraction) : @"IgnoringSystemWideUserInteraction",
      @(kGREYPendingScreenRotation) : @"PendingScreenRotation",
    };
  });
  return descriptions;
}

BOOL GREYIsValidAppState(GREYAppState state) {
  static NSUInteger allValidStatesMask = 0;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    for (NSNumber *key in GREYStateTrackerDescriptions()) {
      allValidStatesMask |= key.unsignedIntegerValue;
    }
  });
  return (state & ~allValidStatesMask) == 0;
}

// LINT.IfChange
NSString *GREYKeyForAppState(GREYAppState state) {
  if (!GREYIsValidAppState(state)) {
    return [NSString stringWithFormat:@"ERROR: Unknown state: %lu", (unsigned long)state];
  }
  if (state == kGREYIdle) {
    return @"Idle";
  }
  NSDictionary<NSNumber *, NSString *> *descriptionsMap = GREYStateTrackerDescriptions();
  NSMutableArray<NSString *> *descriptions = [NSMutableArray array];
  for (NSNumber *key in descriptionsMap) {
    if (state & key.unsignedIntegerValue) {
      [descriptions addObject:descriptionsMap[key]];
    }
  }
  return [descriptions componentsJoinedByString:@", "];
}
// LINT.ThenChange(//depot/google3/third_party/objective_c/EarlGreyV2/CommonLib/Config/GREYAppState.h)
