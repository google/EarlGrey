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

#import "GREYAssertionDefinesPrivate.h"
#import "GREYError+Private.h"
#import "GREYErrorConstants.h"
#import "GREYFailureHandler.h"
#import "GREYFrameworkException.h"

void GREYHandleInteractionError(__strong GREYError *interactionError,
                                __autoreleasing NSError **outError) {
  if (interactionError) {
    if (outError) {
      *outError = interactionError;
    } else {
      NSMutableString *matcherDetails;
      NSDictionary<NSString *, id> *userInfo = interactionError.userInfo;

      // Add Screenshots and UI Hierarchy.
      NSMutableDictionary<NSString *, id> *mutableUserInfo = [userInfo mutableCopy];
      NSDictionary<NSString *, UIImage *> *screenshots = interactionError.appScreenshots;
      NSString *hierarchy = interactionError.appUIHierarchy;
      if (screenshots) {
        mutableUserInfo[kErrorDetailAppScreenshotsKey] = screenshots;
      }
      if (hierarchy) {
        mutableUserInfo[kErrorDetailAppUIHierarchyKey] = hierarchy;
      }
      NSString *localizedFailureReason = userInfo[NSLocalizedFailureReasonErrorKey];
      NSMutableString *reason = [[interactionError localizedDescription] mutableCopy];
      matcherDetails = [NSMutableString stringWithFormat:@"%@\n", localizedFailureReason];
      if (interactionError.nestedError) {
        [matcherDetails appendFormat:@"\nUnderlying Error: \n%@", interactionError.nestedError];
      }
      GREYFrameworkException *exception =
          [GREYFrameworkException exceptionWithName:interactionError.domain
                                             reason:reason
                                           userInfo:[mutableUserInfo copy]];

      id<GREYFailureHandler> failureHandler =
          [NSThread mainThread].threadDictionary[GREYFailureHandlerKey];
      // TODO(b/147072566): Will show up a (null) in rotation.
      [failureHandler handleException:exception details:matcherDetails];
    }
  }
}
