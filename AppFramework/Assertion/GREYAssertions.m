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

#import "AppFramework/Assertion/GREYAssertions.h"

#import "AppFramework/Additions/NSObject+GREYApp.h"
#import "AppFramework/Assertion/GREYAssertionBlock.h"
#import "AppFramework/Core/GREYInteraction.h"
#import "CommonLib/Additions/NSObject+GREYCommon.h"
#import "CommonLib/Assertion/GREYAssertionDefines.h"
#import "CommonLib/Assertion/GREYFatalAsserts.h"
#import "CommonLib/Error/GREYError.h"
#import "CommonLib/GREYLogger.h"
#import "CommonLib/Matcher/GREYMatcher.h"
#import "CommonLib/Matcher/GREYStringDescription.h"

@implementation GREYAssertions

#pragma mark - Package Internal

+ (id<GREYAssertion>)assertionWithMatcher:(id<GREYMatcher>)matcher {
  GREYFatalAssert(matcher);

  NSString *assertionName = [NSString stringWithFormat:@"assertWithMatcher:%@", matcher];
  return [GREYAssertionBlock
            assertionWithName:assertionName
      assertionBlockWithError:^BOOL(id element, __strong NSError **errorOrNil) {
        GREYStringDescription *mismatch = [[GREYStringDescription alloc] init];
        if (![matcher matches:element describingMismatchTo:mismatch]) {
          NSMutableString *reason = [[NSMutableString alloc] init];
          NSMutableDictionary *glossary = [[NSMutableDictionary alloc] init];
          if (!element) {
            [reason appendFormat:@"Assertion with matcher [M] failed: No UI element was matched."];
            glossary[@"M"] = [matcher description];

            GREYPopulateErrorNotedOrLog(errorOrNil, kGREYInteractionErrorDomain,
                                        kGREYInteractionElementNotFoundErrorCode, reason, glossary);
          } else {
            [reason appendFormat:
                        @"Assertion with matcher [M] failed: UI element [E] failed to match "
                        @"the following matcher(s): [S]"];
            glossary[@"M"] = [matcher description];
            glossary[@"E"] = [element grey_description];
            glossary[@"S"] = [mismatch description];

            GREYPopulateErrorNotedOrLog(errorOrNil, kGREYInteractionErrorDomain,
                                        kGREYInteractionAssertionFailedErrorCode, reason, glossary);
          }
          return NO;
        }
        return YES;
      }];
}

@end
