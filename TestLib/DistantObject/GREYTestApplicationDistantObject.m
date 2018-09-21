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

#import "CommonLib/DistantObject/GREYTestApplicationDistantObject.h"

#import "CommonLib/DistantObject/GREYHostBackgroundDistantObject.h"
#import "CommonLib/DistantObject/GREYTestApplicationDistantObject+Private.h"

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

@end
