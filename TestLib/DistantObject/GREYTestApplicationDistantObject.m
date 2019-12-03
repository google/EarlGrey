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

#import "GREYTestApplicationDistantObject.h"

#import <XCTest/XCTest.h>

#import "GREYHostBackgroundDistantObject.h"
#import "GREYTestApplicationDistantObject+Private.h"
#import "GREYFrameworkException.h"
#import "EDOHostPort.h"
#import "EDOClientService.h"
#import "EDOHostService.h"
#import "EDOServiceError.h"
#import "EDOServiceException.h"
#import "EDOServicePort.h"

@interface GREYTestApplicationDistantObject ()
/** @see GREYTestApplicationDistantObject.hostPort, make this readwrite. */
@property(nonatomic) uint16_t hostPort;
/** @see GREYTestApplicationDistantObject.hostBackgroundPort, make this readwrite. */
@property(nonatomic) uint16_t hostBackgroundPort;
/** @see GREYTestApplicationDistantObject.service, make this readwrite. */
@property EDOHostService *service;

/**
 *  Checks if @c port is a permanent eDO host port that is listening by the test host. A permanent
 *  eDO host runs throughout the app's life cycle. This declaration is required by the constructor
 *  C function.
 *
 *  @param port The port number to check.
 *
 *  @return @c YES if @c port is the port number that is listened by any eDO host running in the
 *          test host; @c NO otherwise.
 */
- (BOOL)isPermanentAppHostPort:(uint16_t)port;
@end

/** Intializes test-side distant object and failure handler. */;
__attribute__((constructor)) static void SetupTestDistantObject() {
  GREYTestApplicationDistantObject *testDistantObject =
      GREYTestApplicationDistantObject.sharedInstance;
  testDistantObject.service = [EDOHostService serviceWithPort:0
                                                   rootObject:testDistantObject
                                                        queue:dispatch_get_main_queue()];

  // Registers custom handler of EDO connection failure and translates the error message to UI
  // testing scenarios to users. The custom handler will fall back to use EDO's default error
  // handler if the state of the test doesn't conform to any pattern of the UI testing failure.
  void (^defaultHandler)(NSError *) = EDOClientService.errorHandler;
  EDOClientService.errorHandler = ^(NSError *error) {
    if (error.code == EDOServiceErrorCannotConnect) {
      EDOHostPort *hostPort = error.userInfo[EDOErrorPortKey];
      if ([testDistantObject isPermanentAppHostPort:hostPort.port]) {
        NSString *errorInfo =
            @"App-under-test crashed and disconnected. Unless your tests explicitly relaunch the "
            @"app, the app won't be restarted and thus any requests from test to app side will "
            @"fail. To troubleshoot app's crash, please refer to app.log.";
        [[GREYFrameworkException exceptionWithName:kGREYGenericFailureException
                                            reason:errorInfo] raise];
      }
    }
    defaultHandler(error);
  };
}

@implementation GREYTestApplicationDistantObject

+ (instancetype)sharedInstance {
  static dispatch_once_t onceToken;
  static GREYTestApplicationDistantObject *application;
  dispatch_once(&onceToken, ^{
    application = [[self alloc] init];
  });
  return application;
}

- (uint16_t)servicePort {
  return self.service.port.port;
}

- (uint16_t)hostPort {
  if (_hostPort == 0) {
    XCTWaiterResult result = [self grey_waitForKeyPathToBeNonZero:@"hostPort"];
    if (result != XCTWaiterResultCompleted) {
      NSLog(@"Host port not assigned. Application under test may have failed to launch and/or does "
            @"not link to EarlGrey's AppFramework.");
      abort();
    }
  }
  return _hostPort;
}

- (uint16_t)hostBackgroundPort {
  if (_hostBackgroundPort == 0) {
    XCTWaiterResult result = [self grey_waitForKeyPathToBeNonZero:@"hostBackgroundPort"];
    if (result != XCTWaiterResultCompleted) {
      NSLog(@"Host background port not assigned. Application under test may have failed to launch "
            @"and/or does not link to EarlGrey's AppFramework.");
      abort();
    }
  }
  return _hostBackgroundPort;
}

- (BOOL)isPermanentAppHostPort:(uint16_t)port {
  return port != 0 && (port == _hostPort || port == _hostBackgroundPort);
}

#pragma mark - Private

/** Waits 30 seconds until the given @c keyPath has been changed to a nonzero value. */
- (XCTWaiterResult)grey_waitForKeyPathToBeNonZero:(NSString *)keyPath {
  XCTKVOExpectation *expectation = [[XCTKVOExpectation alloc] initWithKeyPath:keyPath object:self];
  expectation.handler = ^BOOL(id observedObject, NSDictionary *change) {
    int newPort = [change[NSKeyValueChangeNewKey] intValue];
    return newPort != 0;
  };
  return [XCTWaiter waitForExpectations:@[ expectation ] timeout:30];
}

@end
