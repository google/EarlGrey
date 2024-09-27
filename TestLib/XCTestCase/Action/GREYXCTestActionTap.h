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

#import "GREYXCTestAction.h"

@class GREYError;

NS_ASSUME_NONNULL_BEGIN
@interface GREYXCTestActionTap : NSObject <GREYXCTestAction>

/**
 * In iOS 18, SwiftUI accessbility node can't be an UIResponder for UIApplication's sendEvent api
 * that worked with EG in the previous iOS versions.
 * This method performs XCUIAction on a given Element instance instead.
 *
 * @param element The element to perform the action on.
 */
- (void)performOnElement:(id)element;

@end

NS_ASSUME_NONNULL_END
