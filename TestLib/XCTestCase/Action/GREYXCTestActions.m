//
// Copyright 2024 Google Inc.
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

#import "GREYXCTestActions.h"
#import <Foundation/Foundation.h>
#import "GREYXCTestActionTap.h"

typedef NS_ENUM(NSUInteger, GREYXCTestActionType) {
  GREYXCTestActionTypeTap,
  GREYXCTestActionTypeUnsupported,
};

// Expose method for EDOObject as it's not a public class.
@interface NSObject (GREYExposed)
@property(readonly) NSString *className;
@end

@implementation GREYXCTestActions

// Given a GREYAction instance, returns the corresponding GREYXCTestActionType.
GREYXCTestActionType GREYActionToXCTestActionType(id action) {
  static NSDictionary<NSString *, NSNumber *> *gGreyActionToXCTestActionTypeMap;
  static dispatch_once_t onceToken;
  NSString *actionClassName = NSStringFromClass([action class]);
  if ([actionClassName isEqualToString:@"EDOObject"]) {
    actionClassName = [action className];
  }
  dispatch_once(&onceToken, ^{
    gGreyActionToXCTestActionTypeMap = @{
      @"GREYTapAction" : @(GREYXCTestActionTypeTap),
    };
  });
  NSNumber *actionType = gGreyActionToXCTestActionTypeMap[actionClassName];
  return actionType ? actionType.unsignedIntegerValue : GREYXCTestActionTypeUnsupported;
}

/**
 * In iOS 18, SwiftUI accessbility node can't be an UIResponder for UIApplication's sendEvent api
 * that worked with EG in the previous iOS versions. In this method, given a GREYAction instance, we
 * create and returns the corresponding GREYXCTestAction that we will use to perform the action
 * instead in XCUI.
 */
+ (id<GREYXCTestAction>)XCTestActionForGREYAction:(id<GREYAction>)action {
  GREYXCTestActionType actionType = GREYActionToXCTestActionType(action);
  switch (actionType) {
    case GREYXCTestActionTypeTap:
      return [[GREYXCTestActionTap alloc] init];
    default:
      return nil;
  }
}

@end
