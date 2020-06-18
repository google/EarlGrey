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

#import "GREYElementInteractionErrorHandler.h"

#import <XCTest/XCTest.h>

#import "GREYAssertionDefinesPrivate.h"
#import "GREYError+Private.h"
#import "GREYError.h"
#import "GREYErrorConstants.h"
#import "GREYFailureHandler.h"
#import "GREYFrameworkException.h"
#import "GREYInteraction.h"
#import "GREYErrorFormatter.h"

/**
 * @return An NSDictionary containing screenshots obtained from the application on failure along
 *        with an XCUITest screenshot of the app (containing any system alerts) if the application
 *        is still running.
 *
 * @param error The error containing the screenshots.
 */
static NSDictionary<NSString *, UIImage *> *GetScreenshotsFromError(GREYError *error) {
  NSMutableDictionary<NSString *, UIImage *> *mutableScreenshots =
      [error.appScreenshots mutableCopy];
  XCUIApplication *application = [[XCUIApplication alloc] init];
  if (application.state == XCUIApplicationStateRunningForeground) {
    XCUIScreenshot *screenshot = [application screenshot];
    [mutableScreenshots setObject:screenshot.image forKey:kGREYTestScreenshotAtFailure];
  }
  return [mutableScreenshots copy];
}

void GREYHandleInteractionError(__strong GREYError *interactionError,
                                __autoreleasing NSError **outError) {
  if (interactionError) {
    if (outError) {
      *outError = interactionError;
    } else {
      NSDictionary<NSString *, id> *userInfo = interactionError.userInfo;
      NSMutableDictionary<NSString *, id> *mutableUserInfo = [userInfo mutableCopy];
      
      NSDictionary<NSString *, UIImage *> *screenshots = GetScreenshotsFromError(interactionError);
      if (screenshots) {
        mutableUserInfo[kErrorDetailAppScreenshotsKey] = screenshots;
      }
      
      NSString *hierarchy = interactionError.appUIHierarchy;
      if (hierarchy) {
        mutableUserInfo[kErrorDetailAppUIHierarchyKey] = hierarchy;
      }
      
      GREYFrameworkException *exception =
          [GREYFrameworkException exceptionWithName:interactionError.domain
                                             reason:[interactionError localizedDescription]
                                           userInfo:[mutableUserInfo copy]];
      
      id<GREYFailureHandler> failureHandler =
          [NSThread mainThread].threadDictionary[GREYFailureHandlerKey];
      
      if (GREYShouldUseErrorFormatterForError(interactionError)) {
        // Eventually this check will not be needed, and the error's description will
        // always be passed as the `details`
        [failureHandler handleException:exception details:interactionError.description];
      } else {
        NSString *localizedFailureReason = userInfo[NSLocalizedFailureReasonErrorKey];
        NSMutableString *matcherDetails = [NSMutableString stringWithFormat:@"%@\n",
                                           localizedFailureReason];
        if (interactionError.nestedError) {
          [matcherDetails appendFormat:@"\nUnderlying Error: \n%@", interactionError.nestedError];
        }
        
        // TODO(b/147072566): Will show up a (null) in rotation.
        [failureHandler handleException:exception details:matcherDetails];
      }
    }
  }
}
