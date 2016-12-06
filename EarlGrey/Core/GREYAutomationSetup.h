//
// Copyright 2016 Google Inc.
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

/**
 *  Class responsible for preparing the test environment for automation.
 */
@interface GREYAutomationSetup : NSObject

/**
 *  @return The singleton instance.
 */
+ (instancetype)sharedInstance;

/**
 *  @remark init is not an available initializer. Use singleton instance.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 * Prepare the device for automation by doing one-time setup:
 * * Turn on accessibility
 * * Install crash handlers
 * * Turn off autocorrect on software keyboard
 *
 * @remark Must be called during XCTestCase invocation, otherwise the behavior is undefined.
 */
- (void)prepare;

@end
