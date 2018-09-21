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

#import "TestLib/Exception/GREYDefaultFailureHandler.h"

#import <XCTest/XCTest.h>

#import "AppFramework/DistantObject/GREYHostApplicationDistantObject+GREYTestHelper.h"
#import "AppFramework/Error/GREYFailureScreenshotter.h"
#import "CommonLib/Assertion/GREYThrowDefines.h"
#import "CommonLib/Exceptions/GREYFrameworkException.h"
#import "TestLib/Exception/GREYFailureFormatter.h"
#import "TestLib/XCTestCase/XCTestCase+GREYTest.h"

// Counter that is incremented each time a failure occurs in an unknown test.
@implementation GREYDefaultFailureHandler {
  NSString *_fileName;
  NSUInteger _lineNumber;
  id _currentTestCase;
}

#pragma mark - GREYFailureHandler

- (void)setInvocationFile:(NSString *)fileName andInvocationLine:(NSUInteger)lineNumber {
  _fileName = fileName;
  _lineNumber = lineNumber;
}

- (void)setCurrentTestCase:(id)testCase {
  _currentTestCase = testCase;
}

- (void)handleException:(GREYFrameworkException *)exception details:(NSString *)details {
  GREYThrowOnNilParameter(exception);
  id currentTestCase = [XCTestCase grey_currentTestCase];

  NSMutableArray *logger = [[NSMutableArray alloc] init];
  NSString *reason = exception.reason;

  if (reason.length == 0) {
    reason = @"exception.reason was not provided";
  }

  [logger addObject:[NSString stringWithFormat:@"%@: %@", @"Exception Name", exception.name]];
  [logger addObject:[NSString stringWithFormat:@"%@: %@", @"Exception Reason", reason]];

  if (details.length > 0) {
    [logger addObject:[NSString stringWithFormat:@"%@: %@", @"Exception Details", details]];
  }

  NSString *logMessage = [logger componentsJoinedByString:@"\n"];
  NSString *screenshotPrefix =
      [NSString stringWithFormat:@"%@_%@", [currentTestCase grey_testClassName],
                                 [currentTestCase grey_testMethodName]];
  NSDictionary *appScreenshots =
      [GREYFailureScreenshotter generateAppScreenshotsWithPrefix:screenshotPrefix
                                                         failure:exception.name];

  NSArray *stackTrace = [NSThread callStackSymbols];
  NSString *log = [GREYFailureFormatter formatFailureForTestCase:currentTestCase
                                                    failureLabel:@"Exception"
                                                     failureName:exception.name
                                                        filePath:_fileName
                                                      lineNumber:_lineNumber
                                                    functionName:nil
                                                      stackTrace:stackTrace
                                                  appScreenshots:appScreenshots
                                                          format:@"%@\n", logMessage];
  [currentTestCase grey_markAsFailedAtLine:_lineNumber inFile:_fileName description:log];
}

@end
