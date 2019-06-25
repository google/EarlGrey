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
#import "EDOClientService.h"
#import "EDOHostService.h"
#import "EDOServicePort.h"

/** The port number for the test process. */
uint16_t GREYPortForTestApplication = 0;

@interface GREYTestApplicationDistantObject ()
/** @see GREYTestApplicationDistantObject.hostPort, make this readwrite. */
@property(nonatomic) uint16_t hostPort;
/** @see GREYTestApplicationDistantObject.hostBackgroundPort, make this readwrite. */
@property(nonatomic) uint16_t hostBackgroundPort;
/** @see GREYTestApplicationDistantObject.session, make this readwrite. */
@property EDOHostService *service;
@end

@implementation GREYTestApplicationDistantObject

+ (void)load {
  self.sharedInstance.service = [EDOHostService serviceWithPort:0
                                                     rootObject:self.sharedInstance
                                                          queue:dispatch_get_main_queue()];
  GREYPortForTestApplication = [self.sharedInstance servicePort];
}

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
