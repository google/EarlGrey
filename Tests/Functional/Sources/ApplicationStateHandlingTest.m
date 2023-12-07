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

#import "EarlGrey.h"

@interface ApplicationStateHandlingTest : XCTestCase
@end

@implementation ApplicationStateHandlingTest {
  XCUIApplication *_application;
}

- (void)setUp {
  [super setUp];
  _application = [[XCUIApplication alloc] init];
  [_application launch];
  PerformSampleEarlGreyStatement();
}

- (void)tearDown {
  NSError *rotateError;
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationPortrait error:&rotateError];
  XCTAssertNil(rotateError);
  [super tearDown];
}

- (void)testBottomDockInIPadInPortrait {
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
    [self openBottomDockInLandscape:NO];
    [self closeBottomDockInLandscape:NO];
  }
}

- (void)testBottomDockInIPadInLandscape {
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
    // Rotate to Landscape Left orientation.
    NSError *rotateError;
    [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeLeft error:&rotateError];
    XCTAssertNil(rotateError);

    [self openBottomDockInLandscape:YES];
    [self closeBottomDockInLandscape:YES];
  }
}

- (void)testBackgroundingAndForegrounding {
  BOOL success = [EarlGrey backgroundApplication];
  XCTAssertTrue(success);
  NSString *applicationBundleID = @"com.google.earlgreyftr.dev";
  XCUIApplication *application = [EarlGrey foregroundApplicationWithBundleID:applicationBundleID
                                                                       error:nil];
  XCTAssertNotNil(application);
  [[EarlGrey selectElementWithMatcher:GREYKeyWindow()]
      assertWithMatcher:GREYSufficientlyVisible()];
  XCTAssertNoThrow([EarlGrey foregroundApplicationWithBundleID:applicationBundleID error:nil]);
}

// Flakiness will be seen in these tests since the wait times for launching an app were too small
// (10 seconds). On filing an applebug for this, the timeout has been extended to 30 seconds.
- (void)testOpenSettingsApplicationAndReturning_flaky {
  XCUIApplication *settingsApp =
      [EarlGrey foregroundApplicationWithBundleID:@"com.apple.Preferences" error:nil];
  XCTAssertTrue([settingsApp.staticTexts[@"General"] waitForExistenceWithTimeout:30]);
  [_application activate];
  // TODO(b/191156739): Remove this once synchronization is added for session activation. This line
  //                    only adds a small wait until the applicatino's activationState changes to
  //                    UISceneActivationStateForegroundActive.
  [[EarlGrey selectElementWithMatcher:GREYButtonTitle(@"EarlGrey TestApp")]
      performAction:GREYTap()];
  [[EarlGrey selectElementWithMatcher:GREYKeyWindow()]
      assertWithMatcher:GREYSufficientlyVisible()];
}

#pragma mark - Test app relaunch

/**
 * Test launching app post termination without causing issues in loading the `AppFramework` library
 * injected using DYLD_INSERT_LIBRARIES.
 */
- (void)testApplicationRestartOnce {
  [_application terminate];
  [_application launch];
  [[EarlGrey selectElementWithMatcher:GREYKeyWindow()]
      assertWithMatcher:GREYSufficientlyVisible()];
}

/** Test by relaunching twice. */
- (void)testApplicationRestartTwice {
  [_application terminate];
  [_application launch];
  [[EarlGrey selectElementWithMatcher:GREYKeyWindow()]
      assertWithMatcher:GREYSufficientlyVisible()];

  [_application terminate];
  [_application launch];
  [[EarlGrey selectElementWithMatcher:GREYKeyWindow()]
      assertWithMatcher:GREYSufficientlyVisible()];
}

#pragma mark - End Test app relaunch

- (void)openBottomDockInLandscape:(BOOL)isLandscape {
  XCUIApplication *springboardApplication =
      [[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.springboard"];
  CGVector startVector = isLandscape ? CGVectorMake(0.0, 0.5) : CGVectorMake(0.5, 1.0);
  XCUICoordinate *startCoordinate =
      [[springboardApplication.windows firstMatch] coordinateWithNormalizedOffset:startVector];
  CGVector endVector = isLandscape ? CGVectorMake(200.0f, 0.5f) : CGVectorMake(0.5f, -200.0f);
  XCUICoordinate *endCoordinate = [startCoordinate coordinateWithOffset:endVector];
  [startCoordinate pressForDuration:0 thenDragToCoordinate:endCoordinate];

  XCTAssertTrue([springboardApplication.otherElements[@"Dock"] isHittable]);
  [[EarlGrey selectElementWithMatcher:GREYKeyWindow()] performAction:GREYTap()];
}

- (void)closeBottomDockInLandscape:(BOOL)isLandscape {
  XCUIApplication *springboardApplication =
      [[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.springboard"];
  CGVector startReverseVector = isLandscape ? CGVectorMake(0.20, 0.5) : CGVectorMake(0.5, 0.85);
  XCUICoordinate *startReverseCoordinate = [[springboardApplication.windows firstMatch]
      coordinateWithNormalizedOffset:startReverseVector];
  CGVector endReverseVector =
      isLandscape ? CGVectorMake(-200.0f, 0.5f) : CGVectorMake(0.5f, 200.0f);
  XCUICoordinate *endReverseCoordinate =
      [startReverseCoordinate coordinateWithOffset:endReverseVector];
  [startReverseCoordinate pressForDuration:0 thenDragToCoordinate:endReverseCoordinate];
  XCTAssertFalse([springboardApplication.otherElements[@"Dock"] exists]);
}

#pragma mark - Launch related tests

/**
 * Ensures that there's no crashing on setting the configuration post-relaunch after terminating the
 * app.
 **/
- (void)testConfigurationChangesPostRelaunch {
  [self addTeardownBlock:^{
    [[GREYConfiguration sharedConfiguration] reset];
  }];
  [_application terminate];
  [[GREYConfiguration sharedConfiguration] setValue:@(NO)
                                       forConfigKey:kGREYConfigKeySynchronizationEnabled];
  [_application launch];
  BOOL changedSyncValue = GREY_CONFIG_BOOL(kGREYConfigKeySynchronizationEnabled);
  XCTAssertFalse(changedSyncValue, @"Changed config value applied.");
  [[GREYConfiguration sharedConfiguration] setValue:@(YES)
                                       forConfigKey:kGREYConfigKeySynchronizationEnabled];
  PerformSampleEarlGreyStatement();
}

#pragma mark - Logging related tests

/**
 * Ensures that the application's process info has the right verbose logging vars.
 */
- (void)testApplicationVerboseLogging {
  [_application terminate];
  setenv(kGREYAllowVerboseLogging.UTF8String, "all", 1);
  [_application launch];
  XCTAssertEqual([[GREY_REMOTE_CLASS_IN_APP(NSUserDefaults) standardUserDefaults]
                     integerForKey:kGREYAllowVerboseLogging],
                 kGREYVerboseLogTypeAll);

  [_application terminate];
  setenv(kGREYAllowVerboseLogging.UTF8String, "app_state", 1);
  [_application launch];
  XCTAssertEqual([[GREY_REMOTE_CLASS_IN_APP(NSUserDefaults) standardUserDefaults]
                     integerForKey:kGREYAllowVerboseLogging],
                 kGREYVerboseLogTypeAppState);

  [_application terminate];
  setenv(kGREYAllowVerboseLogging.UTF8String, "interaction", 1);
  [_application launch];
  XCTAssertEqual([[GREY_REMOTE_CLASS_IN_APP(NSUserDefaults) standardUserDefaults]
                     integerForKey:kGREYAllowVerboseLogging],
                 kGREYVerboseLogTypeInteraction);
  unsetenv(kGREYAllowVerboseLogging.UTF8String);
}

#pragma mark - Private

/** Perform a sample EarlGrey statement which will always work on the main page. */
static void PerformSampleEarlGreyStatement(void) {
  [[EarlGrey selectElementWithMatcher:GREYText(@"Basic Views")] performAction:GREYTap()];
}

@end

/** Class for specifically testing the application launch timeout. */
@interface ApplicationLaunchTest : XCTestCase
@end

@implementation ApplicationLaunchTest

/**
 * Ensures that if the application launch takes longer than expected, EarlGrey will raise an
 * exception.
 */
- (void)testLaunchTimeoutFailsTest {
  XCUIApplication *application = [[XCUIApplication alloc] init];
  NSMutableDictionary<NSString *, NSString *> *launchEnv =
      [[NSMutableDictionary alloc] initWithDictionary:application.launchEnvironment];

  __block XCUIApplication *blockApplication = application;
  [self addTeardownBlock:^{
    [GREYConfiguration.sharedConfiguration reset];
    [launchEnv removeObjectForKey:@"SLEEP_FOR_TEST"];
    blockApplication.launchEnvironment = launchEnv;
  }];

  launchEnv[@"SLEEP_FOR_TEST"] = @"1";
  application.launchEnvironment = launchEnv;
  [GREYConfiguration.sharedConfiguration setValue:@(10)
                                     forConfigKey:kGREYConfigKeyAppLaunchTimeout];
  XCTAssertThrows([application launch]);
}

@end
