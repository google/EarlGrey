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

#import "AppFramework/IdlingResources/GREYIdlingResource.h"
#import "AppFramework/Synchronization/GREYAppStateTracker.h"
#import "AppFramework/Synchronization/GREYUIThreadExecutor.h"
#import "CommonLib/Exceptions/GREYFailureHandler.h"

// Failure handler for EarlGrey unit tests.
@interface GREYUTFailureHandler : NSObject <GREYFailureHandler>
@end

// Base test class for every unit test.
// Each subclass must call through to super's implementation.
@interface GREYAppBaseTest : XCTestCase

// Currently active runloop mode.
@property(nonatomic, copy) NSString *activeRunLoopMode;

// @c YES indicates to use the real (unmocked) @c UIApplication for the current test case, and it
// must be set before calling base test class's -setUp method. By default, this value is @c NO and
// every test case will have its @c UIApplication mocked.
@property(nonatomic, assign) BOOL useRealUIApplication;

// Returns the real (original, unmocked) shared application. This can be set from a test case that
// needs the real shared application.
@property(nonatomic, readwrite) id realSharedApplication;

// Returns mocked shared application.
- (id)mockSharedApplication;

#pragma mark - XCTestCase

- (void)setUp;
- (void)tearDown;

@end

#pragma mark - GREYUIThreadExecutor Category

@interface GREYUIThreadExecutor (GREYIdlingResources)
- (BOOL)grey_isTrackingIdlingResource:(id<GREYIdlingResource>)idlingResource;
- (BOOL)grey_areAllResourcesIdle;
@end

#pragma mark - GREYAppStateTracker Category

@interface GREYAppStateTracker (GREYAppBaseTest)
- (GREYAppState)grey_lastKnownStateForObject:(id)object;
@end
