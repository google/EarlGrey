//
// Copyright 2020 Google Inc.
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

#import <XCTest/XCTest.h>

#import "GREYError.h"
#import "EarlGrey.h"
#import "GREYErrorFormatter.h"

@interface ErrorFormatterTest : XCTestCase

@end

@implementation ErrorFormatterTest

- (void)testFormatFailureWithError {
  NSString *errorDescription = @"ErrorDescription";
  NSString *hierarchy = @"AppHierarchy";
  
  NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
  userInfo[NSLocalizedDescriptionKey] = errorDescription;
  userInfo[kErrorDetailActionNameKey] = @"ActionName";
  userInfo[kErrorDetailElementMatcherKey] = @"ElementMatcher";
  userInfo[kErrorDetailRecoverySuggestionKey] = @"RecoverySuggestion";
  userInfo[kErrorDetailSearchActionInfoKey] = @"searchAPIInfo";
  
  GREYError *error = I_GREYErrorMake(kGREYInteractionErrorDomain,
                                     kGREYInteractionElementNotFoundErrorCode,
                                     userInfo,
                                     [NSString stringWithUTF8String:__FILE__],
                                     __LINE__,
                                     [NSString stringWithUTF8String:__PRETTY_FUNCTION__],
                                     [NSThread callStackSymbols],
                                     hierarchy,
                                     nil);
  
  NSString *failure = [GREYErrorFormatter formattedDescriptionForError:error];
  
  NSString *expectedDetails = @"ErrorDescription\n"
                              @"\n"
                              @"RecoverySuggestion\n"
                              @"\n"
                              @"Element Matcher:\n"
                              @"ElementMatcher\n"
                              @"\n"
                              @"Action Name: ActionName\n"
                              @"\n"
                              @"Search API Info\n"
                              @"searchAPIInfo\n"
                              @"\n"
                              @"UI Hierarchy (ordered by window level, back to front):";
  XCTAssertTrue([failure containsString:expectedDetails]);
  XCTAssertTrue([failure containsString:hierarchy]);
}
@end
