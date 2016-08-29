//
// Copyright 2016 Google Inc.
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

#import "Exception/GREYDefaultFailureHandler.h"

#import <XCTest/XCTest.h>

#import "Additions/XCTestCase+GREYAdditions.h"
#import "Common/GREYConfiguration.h"
#import "Common/GREYElementHierarchy.h"
#import "Common/GREYPrivate.h"
#import "Common/GREYScreenshotUtil.h"
#import "Common/GREYVisibilityChecker.h"
#import "Exception/GREYFrameworkException.h"
#import "Provider/GREYUIWindowProvider.h"

// Counter that is incremented each time a failure occurs in an unknown test.
static NSUInteger gUnknownTestExceptionCounter = 0;

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
  NSParameterAssert(exception);

  // Test case can be nil if EarlGrey is invoked outside the context of an XCTestCase.
  XCTestCase *currentTestCase = [XCTestCase grey_currentTestCase];
  if (!currentTestCase) {
    gUnknownTestExceptionCounter++;
  }

  NSMutableString *log = [[NSMutableString alloc] init];
  // Start on fresh new line.
  [log appendString:@"\n"];
  [log appendFormat:@"Exception: %@\n", exception.name];
  NSString *reason =
      exception.reason.length > 0 ? exception.reason : @"exception.reason was not provided";
  [log appendFormat:@"Reason: %@\n", reason];
  if (details.length > 0) {
    [log appendFormat:@"%@\n", details];
  }
  [log appendString:@"\n"];

  NSString *screenshotName;
  if (currentTestCase) {
    screenshotName = [NSString stringWithFormat:@"%@_%@",
                                                [currentTestCase grey_testClassName],
                                                [currentTestCase grey_testMethodName]];
  } else {
    screenshotName =
        [NSString stringWithFormat:@"unknown_%lu", (unsigned long)gUnknownTestExceptionCounter];
  }

  // Save and log screenshot and before and after images (if available).
  NSString *screenshotDir = GREY_CONFIG_STRING(kGREYConfigKeyScreenshotDirLocation);
  [self grey_savePNGImage:[GREYScreenshotUtil grey_takeScreenshotAfterScreenUpdates:NO]
              toFileNamed:[NSString stringWithFormat:@"%@.png", screenshotName]
              inDirectory:screenshotDir
              forCategory:@"Screenshot At Failure"
          appendingLogsTo:log];
  [self grey_savePNGImage:[GREYVisibilityChecker grey_lastActualBeforeImage]
              toFileNamed:[NSString stringWithFormat:@"%@_before.png", screenshotName]
              inDirectory:screenshotDir
              forCategory:@"Visibility Checker's Most Recent Before Image"
          appendingLogsTo:log];
  [self grey_savePNGImage:[GREYVisibilityChecker grey_lastExpectedAfterImage]
              toFileNamed:[NSString stringWithFormat:@"%@_after_expected.png", screenshotName]
              inDirectory:screenshotDir
              forCategory:@"Visibility Checker's Most Recent Expected After Image"
          appendingLogsTo:log];
  [self grey_savePNGImage:[GREYVisibilityChecker grey_lastActualAfterImage]
              toFileNamed:[NSString stringWithFormat:@"%@_after_actual.png", screenshotName]
              inDirectory:screenshotDir
              forCategory:@"Visibility Checker's Most Recent Actual After Image"
          appendingLogsTo:log];

  // UI hierarchy and legend. Print windows from front to back.
  [log appendString:@"\n"
                    @"Application window hierarchy (ordered by window level, front to back):\n\n"
                    @"Legend:\n"
                    @"[Window 1] = [Frontmost Window]\n"
                    @"[AX] = [Accessibility]\n"
                    @"[UIE] = [User Interaction Enabled]\n\n"];
  int index = 0;
  for (UIWindow *window in [GREYUIWindowProvider allWindows]) {
    index++;
    [log appendFormat:@"========== Window %d ==========\n\n%@\n\n",
                      index, [GREYElementHierarchy hierarchyStringForElement:window]];
  }

  if (currentTestCase) {
    [currentTestCase grey_markAsFailedAtLine:_lineNumber
                                      inFile:_fileName
                                      reason:exception.reason
                           detailDescription:log];
  } else {
    // Happens when exception is thrown outside a valid test context (i.e. +setUp, +tearDown, etc.)
    [[GREYFrameworkException exceptionWithName:exception.name
                                        reason:log
                                      userInfo:nil] raise];
  }
}

#pragma mark - Private

/**
 *  Saves the given @c image as a PNG file to the given @c fileName and appends a log to
 *  @c allLogs with the saved image's absolute path under the specified @c category.
 *
 *  @param image     Image to be saved as a PNG file.
 *  @param fileName  The file name for the @c image to be saved.
 *  @param directory The directory where @c image will be saved.
 *  @param category  The category for which the @c image is being saved.
 *                   This will be added to the front of the log.
 *  @param allLogs   Existing logs to which any new log statements are appended.
 */
- (void)grey_savePNGImage:(UIImage *)image
              toFileNamed:(NSString *)fileName
              inDirectory:(NSString *)directory
              forCategory:(NSString *)category
          appendingLogsTo:(NSMutableString *)allLogs {
  if (!image) {
    // nothing to save.
    return;
  }
  NSString *screenshotPath = [GREYScreenshotUtil saveImageAsPNG:image
                                                         toFile:fileName
                                                    inDirectory:directory];
  if (screenshotPath) {
    [allLogs appendFormat:@"%@: %@\n", category, screenshotPath];
  } else {
    [allLogs appendFormat:@"Unable to save %@ as %@ in directory %@\n",
                          category, fileName, directory];
  }
}

@end
