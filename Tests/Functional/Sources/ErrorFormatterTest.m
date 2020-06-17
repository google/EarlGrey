//
//  ErrorFormatterTest.m
//  FunctionalTests
//
//  Created by Will Said on 6/16/20.
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
