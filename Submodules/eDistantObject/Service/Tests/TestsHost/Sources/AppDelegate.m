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

#import "Service/Tests/TestsHost/Sources/AppDelegate.h"

#import "Service/Sources/EDOHostNamingService.h"
#import "Service/Sources/EDOHostService.h"
#import "Service/Tests/TestsBundle/EDOTestDummy.h"

@interface AppDelegate ()
@property(readonly) EDOHostService *service;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)opt {
  // Override point for customization after application launch.

  NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];

  int dummyInitValue = (int)[standardDefaults integerForKey:@"dummyInitValue"];
  int portNumber = (int)[standardDefaults integerForKey:@"servicePort"];
  NSString *serviceName = [standardDefaults stringForKey:@"serviceName"];
  if (serviceName) {
    _service = [EDOHostService
        serviceWithRegisteredName:serviceName
                       rootObject:[[EDOTestDummy alloc] initWithValue:dummyInitValue]
                            queue:dispatch_get_main_queue()];
  } else {
    _service = [EDOHostService serviceWithPort:(portNumber ?: EDOTEST_APP_SERVICE_PORT)
                                    rootObject:[[EDOTestDummy alloc] initWithValue:dummyInitValue]
                                         queue:dispatch_get_main_queue()];
  }
  [EDOHostNamingService.sharedService start];
  return YES;
}

@end

@implementation EDOTestDummy (AppDelegate)

- (void)invalidateService {
  AppDelegate *delegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
  [delegate.service invalidate];
}

@end
