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

#import <Foundation/Foundation.h>

// Use modular imports for CocoaPods release.
#import <eDistantObject/EDOClientService.h>
#import <eDistantObject/EDOHostService.h>
#import <eDistantObject/EDOServicePort.h>
// End CocoaPods modular imports

/*
#import "EDOClientService.h"
#import "EDOHostService.h"
#import "EDOServicePort.h"
*/

NS_ASSUME_NONNULL_BEGIN

/**
 *  The application instance running in the app-under-test's process.
 *
 *  @note The class is also stubbed in the test process so it's available in the test. Users can
 *        extend the class in the category and make direct calls, which will become a remote call
 *        automatically invoked in the main thread.
 */
@interface GREYHostApplicationDistantObject : NSObject

/** The port number that the test process listens on. */
// TODO: Use EDOServicePort. // NOLINT
@property(nonatomic, readonly, class) uint16_t testPort;

/** The EDOHostService the application process listens on. */
@property(nonatomic, readonly) EDOHostService *service;

/** The singleton of GREYHostApplicationDistantObject. */
@property(readonly, class) GREYHostApplicationDistantObject *sharedInstance;

/** Returns the port for the distant object's service. */
- (uint16_t)servicePort;

@end

/** Stub the class defined in the test to app under the test. */
#define GREY_STUB_CLASS_IN_TEST_MAIN_QUEUE(__class) \
  EDO_STUB_CLASS(__class, [GREYHostApplicationDistantObject testPort])

/** Fetch a remote class defined in the test. */
#define GREY_REMOTE_CLASS_IN_TEST(__class) \
  EDO_REMOTE_CLASS(__class, [GREYHostApplicationDistantObject testPort])

NS_ASSUME_NONNULL_END
