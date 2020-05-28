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

#import "GREYAssertions.h"

#import "NSObject+GREYApp.h"
#import "GREYInteraction.h"
#import "GREYAppError.h"
#import "NSObject+GREYCommon.h"
#import "GREYAssertionBlock+Private.h"
#import "GREYFatalAsserts.h"
#import "GREYLogger.h"
#import "GREYMatcher.h"
#import "GREYStringDescription.h"

@implementation GREYAssertions

#pragma mark - Package Internal

+ (id<GREYAssertion>)assertionWithMatcher:(id<GREYMatcher>)matcher {
  GREYFatalAssert(matcher);
  NSString *assertionName = [NSString stringWithFormat:@"assertWithMatcher:%@", matcher];
  GREYCheckBlockWithError assertionBlock = ^BOOL(id element, __strong NSError **errorOrNil) {
    GREYStringDescription *mismatch = [[GREYStringDescription alloc] init];
    if (![matcher matches:element describingMismatchTo:mismatch]) {
      NSMutableString *reason = [[NSMutableString alloc] init];
      if (!element) {
        [reason appendFormat:@"Assertion with Matcher failed: No UI element was matched."];
        [reason appendFormat:@"Matcher: %@", [matcher description]];
        I_GREYPopulateError(errorOrNil, kGREYInteractionErrorDomain,
                            kGREYInteractionElementNotFoundErrorCode, reason);
      } else {
        [reason appendFormat:@"An assertion failed."];
        I_GREYPopulateError(errorOrNil, kGREYInteractionErrorDomain,
                            kGREYInteractionAssertionFailedErrorCode, reason);
      }
      return NO;
    }
    return YES;
  };

  if ([matcher respondsToSelector:@selector(diagnosticsID)]) {
    NSString *matcherDiagnosticsID = [matcher diagnosticsID];
    if (matcherDiagnosticsID) {
      NSString *assertionDiagnosticsID =
          [NSString stringWithFormat:@"assertWithMatcher:%@", matcherDiagnosticsID];
      return [GREYAssertionBlock assertionWithName:assertionName
                           assertionBlockWithError:assertionBlock
                                     diagnosticsID:assertionDiagnosticsID];
    }
  }
  return [GREYAssertionBlock assertionWithName:assertionName
                       assertionBlockWithError:assertionBlock];
}

@end
