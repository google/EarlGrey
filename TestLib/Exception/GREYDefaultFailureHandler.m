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
#import "GREYErrorFormatter.h"
#import "GREYObjectFormatter.h"

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

- (NSString *)errorDescriptionForException:(GREYFrameworkException *)exception
                                   details:(NSString *)details {
  NSMutableString *logMessage = [[NSMutableString alloc] init];
  NSString *reason = exception.reason;

  if (reason.length == 0) {
    reason = @"exception.reason was not provided";
  }

  NSString *logName = [NSString stringWithFormat:@"%@: %@", @"Exception Name", exception.name];
  [logMessage appendString:logName];
  NSString *logReason = [NSString stringWithFormat:@"\n%@: %@\n", @"Exception Reason", reason];
  [logMessage appendString:logReason];

  if (details.length > 0) {
    NSString *logDetails = [NSString stringWithFormat:@"Exception Details: %@", details];
    [logMessage appendString:logDetails];
  }
  
  return logMessage;
}

- (NSString *)appUIHierarchyForException:(GREYFrameworkException *)exception {
  NSString *appUIHierarchy = [exception.userInfo valueForKey:kErrorDetailAppUIHierarchyKey];
  // For calls from GREYAsserts in the test side, the hierarchy must be populated here.
  if (!appUIHierarchy) {
    appUIHierarchy = [GREYElementHierarchy hierarchyString];
  }
  return appUIHierarchy;
}

- (GREYFailureScreenshots *)screenshotPathsForException:(GREYFrameworkException *)exception {
  NSDictionary<NSString *, UIImage *> *appScreenshots =
      [exception.userInfo valueForKey:kErrorDetailAppScreenshotsKey];
  // Re-obtain the screenshots when a user might be using GREYAsserts. Since this is from the test
  // process, the delay here would be minimal.
  if (!appScreenshots) {
    appScreenshots = [GREYFailureScreenshotter screenshots];
  }

  NSString *uniqueSubDirName =
      [NSString stringWithFormat:@"%@-%@", exception.name, [[NSUUID UUID] UUIDString]];
  NSString *screenshotDir = [GREY_CONFIG_STRING(kGREYConfigKeyArtifactsDirLocation)
      stringByAppendingPathComponent:uniqueSubDirName];
  GREYFailureScreenshots *screenshotPaths =
      [GREYFailureScreenshotSaver saveFailureScreenshotsInDictionary:appScreenshots
                                                         toDirectory:screenshotDir];
  NSAssert(screenshotPaths, @"Screenshots must be present");
  return screenshotPaths;
}

- (NSString *)consoleLogForException:(GREYFrameworkException *)exception
                             details:(NSString *)details
                     screenshotPaths:(GREYFailureScreenshots *)screenshotPaths
                      appUIhierarchy:(NSString *)appUIHierarchy
                     currentTestCase:(XCTestCase *)currentTestCase
                          stackTrace:(NSArray *)stackTrace {
  if (GREYShouldUseErrorFormatterForExceptionReason(exception.reason)) {
    NSMutableString *output = [details mutableCopy];
    for (NSString *key in screenshotPaths.allKeys) {
      [output appendFormat:@"\n%@: %@\n", key, screenshotPaths[key]];
    }
    return output;
  }
  NSString *errorDescription = [self errorDescriptionForException:exception details:details];
  return [GREYFailureFormatter formatFailureForTestCase:currentTestCase
                                           failureLabel:@"Exception"
                                            failureName:exception.name
                                               filePath:_fileName
                                             lineNumber:_lineNumber
                                           functionName:nil
                                             stackTrace:stackTrace
                                         appScreenshots:screenshotPaths
                                              hierarchy:appUIHierarchy
                                       errorDescription:errorDescription];
}

- (void)handleException:(GREYFrameworkException *)exception details:(NSString *)details {
  GREYThrowOnNilParameter(exception);
  XCTestCase *currentTestCase = [XCTestCase grey_currentTestCase];
  GREYFailureScreenshots *screenshotPaths = [self screenshotPathsForException:exception];
  NSString *appUIHierarchy = [self appUIHierarchyForException:exception];
  NSString *log = [self consoleLogForException:exception
                                       details:details
                               screenshotPaths:screenshotPaths
                                appUIhierarchy:appUIHierarchy
                               currentTestCase:currentTestCase
                                    stackTrace:nil];
  [currentTestCase grey_markAsFailedAtLine:_lineNumber inFile:_fileName description:log];
}

@end
