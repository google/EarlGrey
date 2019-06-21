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

#import "EarlGrey.h"

#import <XCTest/XCTest.h>

@interface EarlGreyImpl (XCUIApplication)

/**
 *  Backgrounds the current open application.
 *
 *  @remark This is only supported for iOS 11 or above.
 *
 *  @return A BOOL indicating if the background was successful or not.
 */
- (BOOL)backgroundApplication;

/**
 *  Foregrounds the application specified by the bundle ID provided.
 *
 *  @remark This method will preserve the state of the application only if used with iOS 11 or
 *          higher. Else, the app being foregrounded will be re-launched from scratch, erasing any
 *          interactions already done.
 *
 *  @param      bundleID   The bundle ID of the application to be tested.
 *  @param[out] errorOrNil Error that will be populated on failure.
 *
 *  @return The XCUIApplication foregrounded if successful, @c nil otherwise.
 */
- (XCUIApplication *)foregroundApplicationWithBundleID:(NSString *)bundleID
                                                 error:(NSError **)errorOrNil;

@end
