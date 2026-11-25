//
// Copyright 2026 Google LLC.
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
#if __has_include(<XCUIAutomation/XCUIAutomation.h>)
#import <XCUIAutomation/XCUIAutomation.h>
#else
#import <XCTest/XCTest.h>
#endif

#import "EarlGreyImpl.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Exposes private EarlGreyImpl methods for internal testing.
 */
@interface EarlGreyImpl (Private)

#if TARGET_OS_IOS

/**
 * Waits for the activity sheet to appear and returns its container element.
 *
 * @param[out] error Error that will be populated on failure. If @c nil, a test failure will be
 *                   reported instead.
 *
 * @return The activity sheet @c XCUIElement if present, or @c nil otherwise.
 */
- (nullable XCUIElement *)activitySheetWithError:(NSError **)error API_AVAILABLE(ios(17));

#endif  // TARGET_OS_IOS

@end

NS_ASSUME_NONNULL_END
