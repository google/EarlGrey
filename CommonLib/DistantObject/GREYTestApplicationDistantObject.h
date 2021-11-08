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
// #import <eDistantObject/EDOClientService.h>
// End CocoaPods modular imports
#if COCOAPODS
#import <eDistantObject/EDOClientService.h>
#else
#import "EDOClientService.h"
#endif  // COCOAPODS

@class EDOHostService;

NS_ASSUME_NONNULL_BEGIN

/**
 * An enumeration that defines if the execution of a remote invocation on the distant object will
 * take place on the main queue or a background queue.
 */
typedef NS_ENUM(NSUInteger, GREYRemoteExecutionDispatchPolicy) {
  /** The policy that dispatches a remote execution to the main queue. */
  GREYRemoteExecutionDispatchPolicyMain = 0,
  /** The policy that dispatches a remote execution to the background queue. */
  GREYRemoteExecutionDispatchPolicyBackground,
};

/**
 * The test application running in the test's process.
 *
 * @note The class is also stubbed in the app process so it's available in the test. Users can
 *       extend the class in the category and make direct calls, which will become a remote call
 *       automatically invoked in the main thread.
 */
@interface GREYTestApplicationDistantObject : NSObject

/** The singleton of GREYTestApplicationDistantObject. */
@property(readonly, class) GREYTestApplicationDistantObject *sharedInstance;

/**
 * The port number that the eDO service on the app-under-test's main queue listens on. Set on
 * HostApplicationDistantObject creation when the application makes its first call to the test.
 */
// TODO: Use EDOServicePort. // NOLINT
@property(nonatomic, readonly) uint16_t hostPort;

/**
 * The port number that the eDO service on the app-under-test's background queue listens on. Set on
 * HostApplicationDistantObject creation when the application makes its first call to the test.
 */
@property(nonatomic, readonly) uint16_t hostBackgroundPort;

/**
 * The port number that the ping message service on the app-under-test's background queue listens
 * on. The service is used to check the status of the app-under-test process.
 */
@property(nonatomic) uint16_t pingMessagePort;

/** The remote execution dispatch policy of the eDO service, which is held by this class. */
@property(nonatomic, readonly) GREYRemoteExecutionDispatchPolicy dispatchPolicy;

/** The @c EDOHostService the test process listens on after the test starts. */
@property(nonatomic, readonly) EDOHostService *service;

/** Returns the port for the distant object's service. */
@property(nonatomic, readonly) uint16_t servicePort;

/**
 * A BOOL set to @c YES only if the host application is running with EarlGrey's application
 * component statically-linked inside it.
 *
 * @note There are two ways to use this API:
 *
 *       1. The testing process is sure that the host application statically links to the EarlGrey's
 *          application component, and want to check if the host application is running. In this
 *          case, this API can be called at anytime to check the application's status.
 *       2. The testing process is not sure that the host application statically links to the
 *          EarlGrey's application component. In this case, the testing process can verify it by
 *          calling this API after [XCUIApplication -launch];
 */
@property(nonatomic, readonly) BOOL hostActiveWithAppComponent;

/**
 * @deprecated This API is no longer used. It is kept only for legacy pre-compiled test binary.
 *             Use -hostActiveWithAppComponent instead.
 */
@property(nonatomic) BOOL hostLaunchedWithAppComponent;

/** @remark init is not an available initializer. Use sharedInstance instead. */
- (instancetype)init NS_UNAVAILABLE;

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
 * Stub the class defined in the app under test to the test.
 *
 * @remark The method sent to this class will be executed in the background
 *         queue.
 */
#define GREY_STUB_CLASS_IN_APP_BACKGROUND_QUEUE(__class) \
  EDO_STUB_CLASS(__class, GREYTestApplicationDistantObject.sharedInstance.hostBackgroundPort)

NS_ASSUME_NONNULL_END
