//
// Copyright 2018 Google Inc.
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

@class EDOTestDummy;

// EDO UI test base class.
@interface EDOServiceUIBaseTest : XCTestCase

/** The root object hosted by @c EDOHostServicein the application process for testing. */
@property(nonatomic, readonly) EDOTestDummy *remoteRootObject;

/**
 *  Launches the application with the @c port serving @c EDOHostService
 *
 *  @param port  The port to serve @c EDOHostService.
 *  @param value The value to initialize the root object @c EDOTestDummy.
 *  @return The instance of the launched XCUIApplication, which can be used to terminate or
 *          query the status of the running application.
 */
- (XCUIApplication *)launchApplicationWithPort:(int)port initValue:(int)value;

/**
 *  Launches the application with the @c serviceName of an @c EDOHostService.
 *
 *  @param serviceName  The service name of @c EDOHostService to be started.
 *  @param value        The value to initialize the root object @c EDOTestDummy.
 *  @return The instance of the launched XCUIApplication, which can be used to terminate or
 *          query the status of the running application.
 */
- (XCUIApplication *)launchApplicationWithServiceName:(NSString *)serviceName initValue:(int)value;

@end
