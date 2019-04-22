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

#import <XCTest/XCTest.h>

/**
 *  @file GREYXCTestAppleInternals.h
 *  @brief Exposes interfaces that are otherwise private.
 */

/**
 *  Category for using private methods on XCUIApplication needed for backgrounding and foregrounding
 *  an application.
 */
@interface XCUIApplication (Private)

// The application's bundle ID under test.
@property(readonly, copy, nonnull) NSString *bundleID;

/**
 *  Returns a proxy for an application associated with the specified bundle identifier.
 *
 *  @note Expose this signature in the older Xcode versions.
 *  @param bundleID Bundle ID of application.
 *  @return Reference to application.
 */
- (nullable instancetype)initWithBundleIdentifier:(nonnull NSString *)bundleID;

/**
 *  Obtain a reference to an application on the device under test.
 *
 *  @param path Path to application. Optional.
 *  @param bundleID Bundle ID of application.
 *
 *  @return Reference to application.
 */
- (nullable instancetype)initPrivateWithPath:(nullable NSString *)path
                                    bundleID:(nonnull NSString *)bundleID;

/**
 *  Resolve the XCUIApplication instance that was retrieved from initPrivateWithPath:bundleID:
 */
- (void)resolve;

/**
 *  Foregrounds the application that is being tested by the test target.
 */
- (void)activate;

@end

/**
 *  Used for enabling accessibility on device.
 */
@interface XCAXClient_iOS

/**
 *  Singleton shared instance when initialized will try to background the current process.
 */
+ (nullable id)sharedClient;

@end
