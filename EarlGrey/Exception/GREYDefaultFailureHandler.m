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
static NSUInteger gUnknownTestExceptionCounter;

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
  // Testcase can be nil if EarlGrey is invoked outside the context of an XCTestCase.
  XCTestCase *currentTestCase = [XCTestCase grey_currentTestCase];
  if (!currentTestCase) {
    gUnknownTestExceptionCounter++;
  }

  NSMutableString *exceptionLog = [[NSMutableString alloc] init];
  // Start on fresh new line.
  [exceptionLog appendString:@"\n"];
  [exceptionLog appendFormat:@"Exception: %@\n", [exception name]];
  if ([exception reason]) {
    [exceptionLog appendFormat:@"Reason: %@\n", [exception reason]];
  } else {
    [exceptionLog appendString:@"Reason for exception was not provided.\n"];
  }
  if (details.length > 0) {
    [exceptionLog appendFormat:@"%@\n", details];
  }
  [exceptionLog appendString:@"\n"];

  NSString *screenshotName;
  if (currentTestCase) {
    screenshotName = [NSString stringWithFormat:@"%@_%@",
                                                [currentTestCase grey_testClassName],
                                                [currentTestCase grey_testMethodName]];
  } else {
    screenshotName =
        [NSString stringWithFormat:@"unknown_%lu", (unsigned long)gUnknownTestExceptionCounter];
  }

  NSString *screenshotDir = GREY_CONFIG_STRING(kGREYConfigKeyScreenshotDirLocation);
  // Log the screenshot.
  [self grey_savePNGImage:[GREYScreenshotUtil grey_takeScreenshotAfterScreenUpdates:NO]
              toFileNamed:[NSString stringWithFormat:@"%@.png", screenshotName]
              inDirectory:screenshotDir
              forCategory:@"Screenshot At Failure"
          appendingLogsTo:exceptionLog];

  // Log before and after images (if available) for the element under test.
  UIImage *beforeImage = [GREYVisibilityChecker grey_lastActualBeforeImage];
  UIImage *afterExpectedImage = [GREYVisibilityChecker grey_lastExpectedAfterImage];
  UIImage *afterActualImage = [GREYVisibilityChecker grey_lastActualAfterImage];

  [self grey_savePNGImage:beforeImage
              toFileNamed:[NSString stringWithFormat:@"%@_before.png", screenshotName]
              inDirectory:screenshotDir
              forCategory:@"Visibility Checker's Most Recent Before Image"
          appendingLogsTo:exceptionLog];
  [self grey_savePNGImage:afterExpectedImage
              toFileNamed:[NSString stringWithFormat:@"%@_after_expected.png", screenshotName]
              inDirectory:screenshotDir
              forCategory:@"Visibility Checker's Most Recent Expected After Image"
          appendingLogsTo:exceptionLog];
  [self grey_savePNGImage:afterActualImage
              toFileNamed:[NSString stringWithFormat:@"%@_after_actual.png", screenshotName]
              inDirectory:screenshotDir
              forCategory:@"Visibility Checker's Most Recent Actual After Image"
          appendingLogsTo:exceptionLog];

  [exceptionLog appendString:@"\n\n"];

  // UI hierarchy.
  [exceptionLog appendString:@"Application window hierarchy (ordered by window level, "
                             @"from front to back):\n\n"];

  // Legend.
  [exceptionLog appendString:@"Legend:\n"
                             @"[Window 1] = [Frontmost Window]\n"
                             @"[AX] = [Accessibility]\n"
                             @"[UIE] = [User Interaction Enabled]\n\n"];

  // Print windows from front to back.
  int index = 0;
  for (UIWindow *window in [GREYUIWindowProvider allWindows]) {
    index++;
    NSString *hierarchy = [GREYElementHierarchy hierarchyStringForElement:window];
    [exceptionLog appendFormat:@"========== Window %d ==========\n\n%@\n\n",
                               index, hierarchy];
  }

  if (currentTestCase) {
    [currentTestCase grey_markAsFailedAtLine:_lineNumber
                                      inFile:_fileName
                                      reason:exception.reason
                           detailDescription:exceptionLog];
  } else {
    // Happens when exception is thrown outside a valid test context (i.e. +setUp, +tearDown, etc.)
    [[GREYFrameworkException exceptionWithName:exception.name
                                        reason:exceptionLog
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
