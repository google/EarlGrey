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

NS_ASSUME_NONNULL_BEGIN

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
 * of the launch of the application process.
 *
 * To turn on for a test run - pass in a @c GREYLogVerboseType key with a non-zero string value in
 * -[XCUIApplication launchArguments].
 *
 * e.g. Prints all interaction related logs.
 * @code
 *   NSMutableArray<NSString *> *launchArguments = [[NSMutableArray alloc] init];
 *   [launchArguments addObject:[@"-" stringByAppendingString:@"kGREYVerboseLogTypeInteraction"]];
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

NS_ASSUME_NONNULL_END
