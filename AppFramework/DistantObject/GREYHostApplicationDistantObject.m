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
#import <objc/runtime.h>

#import "GREYFatalAsserts.h"
#import "GREYHostBackgroundDistantObject.h"
#import "GREYTestApplicationDistantObject+Private.h"
#import "GREYTestApplicationDistantObject.h"
#import "GREYFrameworkException.h"
#import "GREYConstants.h"
#import "EDOChannel.h"
#import "EDOHostPort.h"
#import "EDOSocket.h"
#import "EDOSocketChannel.h"
#import "EDOSocketPort.h"
#import "EDOHostService.h"
#import "EDOServiceError.h"
#import "EDOServicePort.h"

/** The port number for the app under test. */
static uint16_t gGREYPortForTestApplication = 0;

@interface GREYHostApplicationDistantObject ()

/** @see GREYHostApplicationDistantObject.service, make this readwrite. */
@property(nonatomic, readwrite) EDOHostService *service;

/** The TCP socket that is used to receive ping data from other processes. */
@property(nonatomic, readwrite) EDOSocket *pingMessageListener;

@end

/**
 * @return The socket listener that accepts ping connections and creates a channel to process ping
 *         requests.
 */
static id GetPingMessageListener() {
  return ^(EDOSocket *_Nullable socket, NSError *_Nullable socketError) {
    id<EDOChannel> channel = [EDOSocketChannel channelWithSocket:socket];
    id pingMessageHandler = ^(id<EDOChannel> targetChannel, NSData *data, NSError *channelError) {
      // When `data` is nil, it means the channel is closed from the client side.
      if (data) {
        NSString *request = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if ([request isEqualToString:kHostPingRequestMessage]) {
          NSData *response = [kHostPingSuccessMessage dataUsingEncoding:NSUTF8StringEncoding];
          [targetChannel sendData:response withCompletionHandler:nil];
        }
        // The `pingMessageHandler` needs to repetitively add itself to the channel. Since the block
        // cannot get itself within the implementation, it is stored weakly in the channel as an
        // associate object.
        id handler = objc_getAssociatedObject(channel, @selector(receiveDataWithHandler:));
        [channel receiveDataWithHandler:handler];
      }
    };
    objc_setAssociatedObject(channel, @selector(receiveDataWithHandler:), pingMessageHandler,
                             OBJC_ASSOCIATION_ASSIGN);
    [channel receiveDataWithHandler:pingMessageHandler];
  };
}

static void InitiateCommunicationWithTest() {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    // Load app-side helper bundles if provided.
    // The bundles are loaded from application container under directory named
    // EarlGreyHelperBundles.
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSArray<NSString *> *bundlePaths =
        [mainBundle pathsForResourcesOfType:@"bundle" inDirectory:@"EarlGreyHelperBundles"];
    BOOL success = NO;
    NSError *error;
    for (NSString *bundlePath in bundlePaths) {
      NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
      success = [bundle loadAndReturnError:&error];
      __unused NSString *errorString =
          [NSString stringWithFormat:@"The following was seen when loading the distant object "
                                     @"categories bundle. Confirm that your bundle has source "
                                     @"files added to it and you have added a Copy Files Build "
                                     @"Phase to load the bundle in your Test Target's Build "
                                     @"Phases: %@",
                                     error];
      NSCAssert(success, errorString);
    }

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    // Init with the port number so we can make a remote call after.
    gGREYPortForTestApplication = (uint16_t)[userDefaults integerForKey:@"edoTestPort"];

    // Registers custom handler of EDO connection failure and translates the error message to UI
    // testing scenarios to users. The custom handler will fall back to use EDO's default error
    // handler if the state of the test doesn't conform to any pattern of the UI testing failure.
    __block EDOClientErrorHandler previousErrorHandler;
    previousErrorHandler = EDOSetClientErrorHandler(^(NSError *clientError) {
      if (clientError.code == EDOServiceErrorCannotConnect) {
        EDOHostPort *hostPort = clientError.userInfo[EDOErrorPortKey];
        if (gGREYPortForTestApplication == hostPort.port) {
          NSString *errorInfo =
              @"App-under-test is unable to connect to the test process. Here are the reasons that "
              @"may have caused it:\n"
              @"    1. Your test doesn't link to EarlGrey's TestLib.\n"
              @"    2. You launched the app-under-test directly and not through a test.\n"
              @"    3. You overrode the 'edoTestPort' launch arg when launching the app-under-test";
          [[GREYFrameworkException exceptionWithName:kGREYGenericFailureException
                                              reason:errorInfo] raise];
        }
      }
      previousErrorHandler(clientError);
    });

    // If the app is launched without the port assigned, we silently ignore the error and only
    // report it when the code is attempting to access the test process.
    if (gGREYPortForTestApplication == 0) {
      return;
    }

    GREYHostApplicationDistantObject *hostDO = GREYHostApplicationDistantObject.sharedInstance;
    GREYTestApplicationDistantObject *testApplicationDistantObject =
        GREYTestApplicationDistantObject.sharedInstance;
    testApplicationDistantObject.hostPort = hostDO.servicePort;
    testApplicationDistantObject.hostBackgroundPort =
        GREYHostBackgroundDistantObject.sharedInstance.servicePort;

    hostDO.pingMessageListener = [EDOSocket listenWithTCPPort:0
                                                        queue:nil
                                               connectedBlock:GetPingMessageListener()];
    testApplicationDistantObject.pingMessagePort = hostDO.pingMessageListener.socketPort.port;

    // [GREYHostApplicationDistantObject -application:didFinishLaunchingWithOptions:] is a special
    // method for the class. By default, this method is not implemented by EarlGrey. Developers can
    // implement this method in the class extension, and if it is the case, EarlGrey framework
    // will invoke this method when UIApplicationDidFinishLaunchingNotification is fired by the app.
    [NSNotificationCenter.defaultCenter
        addObserverForName:UIApplicationDidFinishLaunchingNotification
                    object:nil
                     queue:NSOperationQueue.mainQueue
                usingBlock:^(NSNotification *notification) {
                  id appDO = GREYHostApplicationDistantObject.sharedInstance;
                  if ([appDO respondsToSelector:@selector(application:
                                                    didFinishLaunchingWithOptions:)]) {
                    [appDO application:UIApplication.sharedApplication
                        didFinishLaunchingWithOptions:notification.userInfo];
                  }
                }];
  });
}

@implementation GREYHostApplicationDistantObject

+ (instancetype)sharedInstance {
  static dispatch_once_t onceToken;
  static GREYHostApplicationDistantObject *appDistantObject;
  dispatch_once(&onceToken, ^{
    appDistantObject = [[self alloc] initOnce];
  });
  return appDistantObject;
}

+ (uint16_t)testPort {
  // The testPort is lazily initialized as EarlGrey's synchronization requires properties
  // from the test component's GREYConfiguration before any initialization in an attribute
  // constructor can be done.
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

- (instancetype)initOnce {
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
