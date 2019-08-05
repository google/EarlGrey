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
 *  The test application running in the test's process.
 *
 *  @note The class is also stubbed in the app process so it's available in the test. Users can
 *        extend the class in the category and make direct calls, which will become a remote call
 *        automatically invoked in the main thread.
 */
@interface GREYTestApplicationDistantObject : NSObject

/** The port number that the host application listens on. */
// TODO: Use EDOServicePort. // NOLINT
@property(nonatomic, readonly) uint16_t hostPort;

/** The port number that the instance running in the background queue listens on. */
@property(nonatomic, readonly) uint16_t hostBackgroundPort;

/** The @c EDOHostService the test process listens on after the test starts. */
@property(readonly) EDOHostService *service;

/** The singleton of GREYTestApplicationDistantObject. */
@property(readonly, class) GREYTestApplicationDistantObject *sharedInstance;

/** Returns the port for the distant object's service. */
- (uint16_t)servicePort;

@end

/** Stub the class defined in the app under test to the test. */
#define GREY_STUB_CLASS_IN_APP_MAIN_QUEUE(__class) \
  EDO_STUB_CLASS(__class, GREYTestApplicationDistantObject.sharedInstance.hostPort)

/** Fetch a remote class from the app under test. */
#define GREY_REMOTE_CLASS_IN_APP(__class) \
  EDO_REMOTE_CLASS(__class, GREYTestApplicationDistantObject.sharedInstance.hostPort)

/** Alloc a remote class from the app under test. */
#define GREY_ALLOC_REMOTE_CLASS_IN_APP(__class) \
  (__class *)(                                  \
      [EDO_REMOTE_CLASS(__class, GREYTestApplicationDistantObject.sharedInstance.hostPort) alloc])

/**
 *  Stub the class defined in the app under test to the test.
 *
 *  @remark The method sent to this class will be executed in the background
 *          queue.
 */
#define GREY_STUB_CLASS_IN_APP_BACKGROUND_QUEUE(__class) \
  EDO_STUB_CLASS(__class, GREYTestApplicationDistantObject.sharedInstance.hostBackgroundPort)

NS_ASSUME_NONNULL_END
