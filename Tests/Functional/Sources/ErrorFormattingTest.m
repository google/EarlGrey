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

#import "BaseIntegrationTest.h"

#import "GREYError.h"
#import "EarlGrey.h"
#import "FailureHandler.h"

# pragma mark - GREYErrorFormatTestingFailureHandler

/**
 * Failure handler used for testing for correct formatting of errors
 * made with GREYErrorFormatter
 */
@interface ErrorFormatTestingFailureHandler : NSObject <GREYFailureHandler>
@property NSString *fileName;
@property(assign) NSUInteger lineNumber;
@property GREYFrameworkException *exception;
@property NSString *details;
@end

@implementation ErrorFormatTestingFailureHandler

- (void)handleException:(GREYFrameworkException *)exception details:(NSString *)details {
  self.exception = exception;
  self.details = details;
}

- (void)setInvocationFile:(NSString *)fileName andInvocationLine:(NSUInteger)lineNumber {
  self.fileName = fileName;
  self.lineNumber = lineNumber;
}

@end

# pragma mark - ErrorFormattingTest

/**
 * Tests that the user-facing console output follows expectations.
 */
@interface ErrorFormattingTest : BaseIntegrationTest

@end

@implementation ErrorFormattingTest

- (void)testElementNotFoundErrorDescription {
  ErrorFormatTestingFailureHandler *handler = [[ErrorFormatTestingFailureHandler alloc] init];
  [NSThread mainThread].threadDictionary[GREYFailureHandlerKey] = handler;
  
  id<GREYMatcher> matcher =
      [[GREYHostApplicationDistantObject sharedInstance] matcherForFirstElement];
  [[EarlGrey selectElementWithMatcher:grey_allOf(grey_kindOfClass([UITableViewCell class]),
                                                 matcher, nil)]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Basic Views")]
                    assertWithMatcher:grey_notNil()
                                error:nil];
  
  NSString *expectedDetails = @"Interaction cannot continue because the desired element was not "
                              @"found.\n"
                              @"\n"
                              @"Check if the element exists in the UI hierarchy printed below. If "
                              @"it exists, adjust the matcher so that it accurately matches "
                              @"the element.\n"
                              @"\n"
                              @"Element Matcher:\n"
                              @"((kindOfClass('UILabel') || kindOfClass('UITextField') || "
                              @"kindOfClass('UITextView')) && hasText('Basic Views'))";
  XCTAssertTrue([handler.details containsString:expectedDetails]);
}

- (void)testSearchNotFoundErrorDescription {
  ErrorFormatTestingFailureHandler *handler = [[ErrorFormatTestingFailureHandler alloc] init];
  [NSThread mainThread].threadDictionary[GREYFailureHandlerKey] = handler;

  [self openTestViewNamed:@"Scroll Views"];
  id<GREYMatcher> matcher = grey_allOf(grey_accessibilityLabel(@"Label 2"), grey_interactable(),
                                       grey_sufficientlyVisible(), nil);
  [[[EarlGrey selectElementWithMatcher:matcher]
                     usingSearchAction:grey_scrollInDirection(kGREYDirectionDown, 50)
                  onElementWithMatcher:grey_accessibilityLabel(@"Invalid Scroll View")]
                     assertWithMatcher:grey_sufficientlyVisible()
                                 error:nil];

  NSString *expectedDetails = @"Search action failed: Interaction cannot continue because the "
                              @"desired element was not found.\n"
                              @"\n"
                              @"Check if the element exists in the UI hierarchy printed below. If "
                              @"it exists, adjust the matcher so that it accurately matches "
                              @"the element.\n"
                              @"\n"
                              @"Element Matcher:\n"
                              @"(((respondsToSelector(isAccessibilityElement) && "
                              @"isAccessibilityElement) && accessibilityLabel('Label 2')) && "
                              @"interactable Point:{nan, nan} && sufficientlyVisible(Expected: "
                              @"0.750000, Actual: 0.000000))\n"
                              @"\n"
                              @"Search API Info\n"
                              @"Search Action: ";
  XCTAssertTrue([handler.details containsString:expectedDetails]);
}

@end
