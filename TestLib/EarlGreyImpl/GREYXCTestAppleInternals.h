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

/**
 *  @file GREYXCTestAppleInternals.h
 *  @brief Exposes interfaces that are otherwise private.
 */

/**
 *  Category for using private methods on XCUIApplication needed for backgrounding and foregrounding
 *  an application.
 */
@interface XCUIApplication (Private)

/**
 *  Obtain a reference to an application on the device under test.
 *
 *  @param path Path to application. Optional.
 *  @param bundleID Bundle ID of application.
 *
 *  @return Reference to application.
 */
- (nullable id)initPrivateWithPath:(nullable NSString *)path bundleID:(nonnull NSString *)bundleID;

/**
 *  Resolve the XCUIApplication instance that was retrieved from initPrivateWithPath:bundleID:
 */
- (void)resolve;

#if defined(__IPHONE_11_0)
/**
 *  Foregrounds the application that is being tested by the test target.
 */
- (void)activate NS_AVAILABLE_IOS(11_0);
#endif

@end

/**
 *  Used for enabling accessibility on device.
 */
@interface XCAXClient_iOS

/**
 *  Singleton shared instance when initialized will try to background the current process.
 */
+ (nullable id)sharedClient;

/**
 *  Method that calls the provided block when the passed in application no longer has any active
 *  UIAnimations.
 *
 *  @param app   An XCUIApplication whose activity is to be checked.
 *  @param block Block that will be called as soon as all the UIAnimations in the passed in
 *               application are completed.
 */
- (void)notifyWhenNoAnimationsAreActiveForApplication:(nonnull XCUIApplication *)app
                                                reply:(nonnull void (^)(void))block;

@end
