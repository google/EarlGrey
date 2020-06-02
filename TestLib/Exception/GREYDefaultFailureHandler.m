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

#import "GREYDefaultFailureHandler.h"

#import <XCTest/XCTest.h>

#import "GREYHostApplicationDistantObject+GREYTestHelper.h"
#import "GREYFailureScreenshotter.h"
#import "NSFileManager+GREYCommon.h"
#import "GREYThrowDefines.h"
#import "GREYConfiguration.h"
#import "GREYErrorConstants.h"
#import "GREYFrameworkException.h"
#import "GREYFailureFormatter.h"
#import "GREYFailureScreenshotSaver.h"
#import "XCTestCase+GREYTest.h"
#import "GREYElementHierarchy.h"

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

- (void)handleException:(GREYFrameworkException *)exception details:(NSString *)details {
  GREYThrowOnNilParameter(exception);
  id currentTestCase = [XCTestCase grey_currentTestCase];
  [currentTestCase grey_markAsFailedAtLine:_lineNumber
                                    inFile:_fileName
                               description:details];
}

@end
