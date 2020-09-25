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

/**
 * @file GREYLogger.h
 * @brief Macro for printing more logs for aiding in debugging.
 */
#import "GREYConstants.h"

/**
 * NSUserDefaults key for checking if verbose logging is turned on. (i.e. logs with
 * GREYLogVerbose are printed.)
 */
GREY_EXTERN NSString* _Nonnull const kGREYAllowVerboseLogging;

/**
 * Enum values for verbose logging.
 */
typedef NS_OPTIONS(NSInteger, GREYVerboseLogType) {
  /** Prints Interaction Verbose Logs.*/
  kGREYVerboseLogTypeInteraction = 1 << 0,
  /** Prints App State Tracker Verbose Logs.*/
  kGREYVerboseLogTypeAppState = 1 << 1,
  /** Prints all logs Verbose Logs (Use sparingly and never in prod).*/
  kGREYVerboseLogTypeAll = NSIntegerMax
};

/**
 * Prints a log statement if any of the following keys are present in NSUserDefaults at the start
 * of the launch of the application process:
 *
 * 1. @c kGREYAllowVerboseLogging which prints interaction related logs.
 * 2. @c kGREYAllowVerboseAppStateLogging which prints interaction and App-state related logs.
 *
 * To turn on for a test run - pass in @c kGREYAllowVerboseLogging or
 * @c kGREYAllowVerboseAppStateLogging key in -[XCUIApplication launchArguments] to @c YES.
 * @code
 *   NSMutableArray<NSString *> *launchArguments = [[NSMutableArray alloc] init];
 *   [launchArguments addObject:[@"-" stringByAppendingString:kGREYAllowVerboseAppStateLogging]];
 *   [launchArguments addObject:@"1"];
 *   self.application.launchArguments = launchArguments;
 *   [self.application launch];
 * @endcode
 *
 * In the App side, you can also pass it in the scheme's Environment Variables.
 *
 * @remark Once you set this, as with any NSUserDefaults, you need to
 *         explicitly turn it off or delete and re-install the app under test.
 *
 * @param format The string format to be printed.
 * @param ...    The parameters to be added to the string format.
 */
void GREYLogVerbose(NSString* format, ...);
