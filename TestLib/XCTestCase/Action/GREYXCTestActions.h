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

#import <Foundation/Foundation.h>

@protocol GREYAction;
@protocol GREYXCTestAction;

/**
 * A interface that exposes UI element actions.
 */
@interface GREYXCTestActions : NSObject

/**
 * In iOS 18, SwiftUI accessbility node can't be an UIResponder for UIApplication's sendEvent: API
 * that worked with EG in the previous iOS versions. In this method, given a GREYAction instance, we
 * create and return the corresponding GREYXCTestAction that we will use to perform the action
 * instead in XCUI.
 * @param action A GREYAction instance.
 * @return A GREYXCTestAction to tap on an element.
 */
+ (id<GREYXCTestAction>)xctestActionForGREYAction:(id<GREYAction>)action;

@end
