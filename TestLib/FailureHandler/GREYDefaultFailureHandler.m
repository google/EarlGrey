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

#import "GREYFailureScreenshotter.h"
#import "GREYFatalAsserts.h"
#import "GREYThrowDefines.h"
#import "GREYErrorConstants.h"
#import "GREYFrameworkException.h"
#import "GREYFailureHandlerHelpers.h"
#import "GREYFailureScreenshotSaver.h"
#import "XCTestCase+GREYTest.h"

/** Counter that is incremented each time a failure occurs in an unknown test. */
@implementation GREYDefaultFailureHandler {
  NSString *_fileName;
  NSUInteger _lineNumber;
}

#pragma mark - GREYFailureHandler

- (void)setInvocationFile:(NSString *)fileName andInvocationLine:(NSUInteger)lineNumber {
  _fileName = fileName;
  _lineNumber = lineNumber;
}

- (void)handleException:(GREYFrameworkException *)exception details:(NSString *)details {
  GREYThrowOnNilParameter(exception);
  XCTestCase *currentTestCase = [XCTestCase grey_currentTestCase];
  NSString *log = [self logForException:exception details:details currentTestCase:currentTestCase];
  [currentTestCase grey_markAsFailedAtLine:_lineNumber inFile:_fileName description:log];
}

/**
 * @return A dictionary of the app side and test side screenshot paths.
 *
 * @param exception The exception containing the screenshot images in its user info dictionary.
 */
- (GREYFailureScreenshots *)screenshotPathsForException:(GREYFrameworkException *)exception {
  NSDictionary<NSString *, UIImage *> *appScreenshots =
      [exception.userInfo valueForKey:kErrorDetailAppScreenshotsKey];
  // Re-obtain the screenshots when a user might be using GREYAsserts. Since this is from the test
  // process, the delay here would be minimal.
  if (!appScreenshots) {
    appScreenshots = [GREYFailureScreenshotter screenshots];
  }

  NSString *screenshotDir =
      [GREYFailureScreenshotSaver failureScreenshotPathForException:exception];
  GREYFailureScreenshots *screenshotPaths =
      [GREYFailureScreenshotSaver saveFailureScreenshotsInDictionary:appScreenshots
                                                         toDirectory:screenshotDir];
  GREYFatalAssertWithMessage(screenshotPaths, @"Screenshots must be present");
  return screenshotPaths;
}

/**
 * @return The console log that should be outputted.
 *
 * @param exception       The exception causing the failure.
 * @param details         The detail string passed into the failure handler, which can be the
 *                        GREYError description.
 * @param currentTestCase The test case that has failed.
 */
- (NSString *)logForException:(GREYFrameworkException *)exception
                      details:(NSString *)details
              currentTestCase:(XCTestCase *)currentTestCase {
  GREYFailureScreenshots *screenshotPaths = [self screenshotPathsForException:exception];
  NSMutableString *output = [details mutableCopy];
  for (NSString *key in screenshotPaths.allKeys) {
    [output appendFormat:@"\n%@: %@\n", key, screenshotPaths[key]];
  }
  [output appendString:GREYAppUIHierarchyFromException(exception)];
  return output;
}

@end
