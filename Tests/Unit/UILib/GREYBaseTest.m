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

#include <dlfcn.h>
#import <objc/message.h>

#import "CommonLib/Assertion/GREYFatalAsserts.h"
#import "CommonLib/GREYAppleInternals.h"
#import "CommonLib/GREYSwizzler.h"
#import "Tests/Unit/UILib/GREYBaseTest.h"
#import "third_party/objective_c/ocmock/v3/Source/OCMock/OCMock.h"

// A list containing UIImage that are returned by each invocation of takeScreenShot of
// GREYScreenshotter. After a screenshot is returned (in-order), it is removed from this list.
static NSMutableArray *gScreenShotsToReturnByGREYScreenshotter;

// A CGRect value to use for instantiating views.
const CGRect kTestRect = {{0.0f, 0.0f}, {10.0f, 10.0f}};

#pragma mark - GREYScreenshotter

// We don't want to take screenshot during unit tests or save an image for that matter.
@implementation GREYScreenshotter (UnitTest)

+ (void)load {
  Class screenshotterClass = [GREYScreenshotter class];
  GREYSwizzler *swizzler = [[GREYSwizzler alloc] init];
  SEL fakeScreenshotSelector = @selector(greyswizzled_fakeTakeScreenshotAfterScreenUpdates:
                                                                             withStatusBar:);
  SEL originalSelector = @selector(grey_takeScreenshotAfterScreenUpdates:withStatusBar:);
  BOOL success = [swizzler swizzleClass:screenshotterClass
                     replaceClassMethod:originalSelector
                             withMethod:fakeScreenshotSelector];
  NSAssert(success, @"Couldn't swizzle GREYScreenshotter takeScreenshot");

  SEL fakeSaveImageSelector = @selector(greyswizzled_fakeSaveImageAsPNG:toFile:inDirectory:);
  success = [swizzler swizzleClass:screenshotterClass
                replaceClassMethod:@selector(saveImageAsPNG:toFile:inDirectory:)
                        withMethod:fakeSaveImageSelector];
  NSAssert(success, @"Couldn't swizzle GREYScreenshotter saveImageAsPNG:toFile:");

  gScreenShotsToReturnByGREYScreenshotter = [[NSMutableArray alloc] init];
}

#pragma mark - Swizzled Implementation

+ (UIImage *)greyswizzled_fakeTakeScreenshotAfterScreenUpdates:(BOOL)afterScreenUpdates
                                                 withStatusBar:(BOOL)included {
  UIImage *image;

  if (gScreenShotsToReturnByGREYScreenshotter.count > 0) {
    image = [gScreenShotsToReturnByGREYScreenshotter firstObject];
    [gScreenShotsToReturnByGREYScreenshotter removeObjectAtIndex:0];
  }
  return image;
}

+ (NSString *)greyswizzled_fakeSaveImageAsPNG:(UIImage *)image
                                       toFile:(NSString *)filename
                                  inDirectory:(NSString *)directoryPath {
  return nil;
}

@end

#pragma mark - GREYBaseTest

@implementation GREYBaseTest {
  id _mockSharedApplication;
}

#pragma mark - Accessibility

+ (void)load {
  NSLog(@"Enabling accessibility for automation on Simulator.");
  static NSString *path =
      @"/System/Library/PrivateFrameworks/AccessibilityUtilities.framework/AccessibilityUtilities";
  char const *const localPath = [path fileSystemRepresentation];
  GREYFatalAssertWithMessage(localPath, @"localPath should not be nil");

  void *handle = dlopen(localPath, RTLD_LOCAL);
  GREYFatalAssertWithMessage(handle, @"dlopen couldn't open AccessibilityUtilities at path %s",
                             localPath);

  Class AXBackBoardServerClass = NSClassFromString(@"AXBackBoardServer");
  GREYFatalAssertWithMessage(AXBackBoardServerClass, @"AXBackBoardServer class not found");
  id server = [AXBackBoardServerClass server];
  GREYFatalAssertWithMessage(server, @"server should not be nil");

  CFStringRef notificationRef = (CFStringRef) @"com.apple.accessibility.cache.app.ax";
  [server setAccessibilityPreferenceAsMobile:(CFStringRef) @"ApplicationAccessibilityEnabled"
                                       value:kCFBooleanTrue
                                notification:notificationRef];
  [server setAccessibilityPreferenceAsMobile:(CFStringRef) @"AccessibilityEnabled"
                                       value:kCFBooleanTrue
                                notification:(CFStringRef) @"com.apple.accessibility.cache.ax"];
}

- (void)setUp {
  [super setUp];

  // Setup Mocking for UIApplication.
  _mockSharedApplication = OCMClassMock([UIApplication class]);
  id classMockApplication = OCMClassMock([UIApplication class]);
  [OCMStub([classMockApplication sharedApplication]) andReturn:_mockSharedApplication];
}

- (void)tearDown {
  [gScreenShotsToReturnByGREYScreenshotter removeAllObjects];
  CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, false);
  _mockSharedApplication = nil;
  [super tearDown];
}

- (void)addToScreenshotListReturnedByScreenshotter:(UIImage *)screenshot {
  [gScreenShotsToReturnByGREYScreenshotter addObject:screenshot];
}

- (id)mockSharedApplication {
  NSAssert([UIApplication sharedApplication] == _mockSharedApplication,
           @"UIApplication sharedApplication isn't a mock.");
  return _mockSharedApplication;
}

@end
