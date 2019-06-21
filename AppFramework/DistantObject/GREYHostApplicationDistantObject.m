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

#import "GREYHostApplicationDistantObject.h"

#import <UIKit/UIKit.h>

#import "GREYFatalAsserts.h"
#import "GREYHostBackgroundDistantObject.h"
#import "GREYTestApplicationDistantObject+Private.h"
#import "GREYTestApplicationDistantObject.h"

/** The port number for the app under test. */
static uint16_t gGREYPortForTestApplication = 0;

@interface GREYHostApplicationDistantObject ()

/** @see GREYHostApplicationDistantObject.service, make this readwrite. */
@property EDOHostService *service;

@end

@implementation GREYHostApplicationDistantObject

__attribute__((constructor)) static void InitHostApplication() { InitiateCommunicationWithTest(); }

static void InitiateCommunicationWithTest() {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    // Load app-side helper bundles if provided.
    // The bundles are loaded from application container under directory named
    // EarlGreyHelperBundles.
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSArray *bundlePaths = [mainBundle pathsForResourcesOfType:@"bundle"
                                                   inDirectory:@"EarlGreyHelperBundles"];
    BOOL success = NO;
    NSError *error = nil;
    for (NSString *bundlePath in bundlePaths) {
      NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
      success = [bundle loadAndReturnError:&error];
      NSCAssert(success, @"An error: %@ was seen when loading the distant object categories bundle",
                error);
    }

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    // Init with the port number so we can make a remote call after.
    gGREYPortForTestApplication = (uint16_t)[userDefaults integerForKey:@"edoTestPort"];

    // If the app is launched without the port assigned, we silently ignore the error and only
    // report it when the code is attempting to access the test process.
    if (gGREYPortForTestApplication == 0) {
      return;
    }

    GREYTestApplicationDistantObject.sharedInstance.hostPort =
        GREYHostApplicationDistantObject.sharedInstance.service.port.port;
    GREYTestApplicationDistantObject.sharedInstance.hostBackgroundPort =
        [GREYHostBackgroundDistantObject.sharedInstance servicePort];
  });
}

+ (instancetype)sharedInstance {
  static dispatch_once_t onceToken;
  static GREYHostApplicationDistantObject *application;
  dispatch_once(&onceToken, ^{
    application = [[self alloc] init];
  });
  return application;
}

+ (uint16_t)testPort {
  // It's possible that +testPort is called before +load, in which case, the class loaders are
  // accessing the test process, so we initialize the port number here.
  if (gGREYPortForTestApplication == 0) {
    InitiateCommunicationWithTest();
    GREYFatalAssertWithMessage(gGREYPortForTestApplication != 0,
                               @"EarlGrey's app component has been launched without edoPort "
                               @"assigned. You are probably running the application under test by "
                               @"itself, which does not work since the embedded EarlGrey component "
                               @"needs its test counterpart present. ");
  }
  return gGREYPortForTestApplication;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _service = [EDOHostService serviceWithPort:0 rootObject:self queue:dispatch_get_main_queue()];
  }
  return self;
}

- (uint16_t)servicePort {
  return self.service.port.port;
}

@end
