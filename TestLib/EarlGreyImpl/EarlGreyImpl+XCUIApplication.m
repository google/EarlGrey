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

#import "EarlGreyImpl+XCUIApplication.h"

#import "GREYFatalAsserts.h"
#import "GREYError.h"
#import "GREYDefines.h"
#import "GREYXCTestAppleInternals.h"
#import "GREYCondition.h"

/**
 *  Amount to scroll to move to the next springboard page.
 */
static const NSInteger kSpringboardPageScrollAmount = 500.0;

/**
 *  Timeout for foregrounding the application.
 */
static const CFTimeInterval kForegroundTimeout = 10.0;

/**
 *  Time interval to poll the backgrounding/foregrounding events.
 */
static const CFTimeInterval kPollInterval = 5.0;

@implementation EarlGreyImpl (XCUIApplication)

- (BOOL)backgroundApplication {
#if defined(__IPHONE_11_0)
  XCUIApplication *currentApplication = [[XCUIApplication alloc] init];
  // Tell the system to background the app.
  [[XCUIDevice sharedDevice] pressButton:XCUIDeviceButtonHome];
  BOOL (^conditionBlock)(void) = ^BOOL {
    return currentApplication.state == XCUIApplicationStateRunningBackground ||
           currentApplication.state == XCUIApplicationStateRunningBackgroundSuspended;
  };
  // TODO: Make GREYCondition support event driven checks. // NOLINT
  GREYCondition *condition =
      [GREYCondition conditionWithName:@"check if backgrounded" block:conditionBlock];
  return [condition waitWithTimeout:10.0 pollInterval:kPollInterval];
#else
  NSString *errorDescription =
      @"Cannot perform backgrounding because it is not supported with the current system version.";
  GREYError *notSupportedError =
      GREYErrorMake(kGREYDeeplinkErrorDomain, GREYDeeplinkNotSupported, errorDescription);
  I_GREYFail(@"%@\nError: %@", @"Unsupported system for backgrounding.",
             [GREYError grey_nestedDescriptionForError:notSupportedError]);
  return NO;
#endif
}

- (XCUIApplication *)foregroundApplicationWithBundleID:(NSString *)bundleID
                                                 error:(NSError **)errorOrNil {
  __block XCUIApplication *application = [XCUIApplication alloc];
  __block int launchCount = 3;
  // Check if the application was foregrounded.
  GREYCondition *condition = [GREYCondition
      conditionWithName:@"appplication_foreground"
                  block:^BOOL {
                    if ([application respondsToSelector:@selector(initWithBundleIdentifier:)]) {
                      application = [application initWithBundleIdentifier:bundleID];
                    } else {
                      application = [application initPrivateWithPath:nil bundleID:bundleID];
                    }
#if defined(__IPHONE_11_0)
                    if (application.state == XCUIApplicationStateRunningForeground) {
                      return YES;
                    }
#endif
                    if ([application respondsToSelector:@selector(activate)]) {
                      [application activate];
                    } else {
                      [application launch];
                    }
                    launchCount--;
                    if (launchCount == 0) {
                      application = nil;
                      return YES;
                    }
                    return [[application.windows firstMatch] exists];
                  }];
  // If we were successful in invoking to foreground the application, then wait and check if the
  // application is foregrounded within the @c kForegroundTimeout.
  BOOL success = [condition waitWithTimeout:kForegroundTimeout pollInterval:kPollInterval];
  if (success && application) {
    return application;
  } else {
    if (errorOrNil) {
      *errorOrNil =
          GREYErrorMake(kErrorDetailForegroundApplicationFailed, kGREYInteractionTimeoutErrorCode,
                        @"Failed to foreground application within the timeout.");
    }
    return nil;
  }
}

#pragma mark - Private Methods
/**
 *  Performs a horizontal XCUITest Swipe across a provided XCUIElement.
 *
 *  @remark Before iOS 10, the direction of the swipe action was based on the direction of the
 *          keyplane moving. After iOS 10, this was changed to the direction of the finger
 *          movement.
 *
 *  @param element An XCUIElement element to be swiped on.
 *  @param isRight BOOL specifying if the direction of the swipe element is the right
 *                 direction.
 */
- (void)grey_swipeHorizontallyInElement:(XCUIElement *)element
                withTheDirectionAsRight:(BOOL)isRight {
  XCUICoordinate *startPoint = [element coordinateWithNormalizedOffset:CGVectorMake(0.0, 0.5)];
  XCUICoordinate *endPoint;
  if (isRight) {
    CGVector rightScrollVector = CGVectorMake(kSpringboardPageScrollAmount, 0.0);
    startPoint = [element coordinateWithNormalizedOffset:CGVectorMake(0.0, 0.5)];
    endPoint = [startPoint coordinateWithOffset:rightScrollVector];
  } else {
    CGVector leftScrollVector = CGVectorMake((-1) * kSpringboardPageScrollAmount, 0.0);
    startPoint = [element coordinateWithNormalizedOffset:CGVectorMake(1.0, 0.5)];
    endPoint = [startPoint coordinateWithOffset:leftScrollVector];
  }
  [startPoint pressForDuration:0.1 thenDragToCoordinate:endPoint];
}

@end
