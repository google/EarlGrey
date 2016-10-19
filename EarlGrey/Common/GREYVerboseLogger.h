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

/**
 *  @file GREYVerboseLogger.h
 *  @brief Macro for printing more verbose logs for aiding in debugging.
 */

#import <EarlGrey/GREYConstants.h>

/**
 *  Prints a log statement if @c kGREYAllowVerboseLogging is present and turned to @c YES in
 *  NSUserDefaults. You can pass it in the command line arguments as:
 *  To turn on,
 *  @code
 *    -kGREYAllowVerboseLogging YES
 *  @endcode
 *  Or from NSUserDefaults, by adding the @c kGREYAllowVerboseLogging key.
 *  @code
 *    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kGREYAllowVerboseLogging];
 *  @endcode
 *
 *  @remark Once you set this, as with any NSUserDefault, you need to explicitly turn it off
 *          or delete and re-install the app under test.
 *
 *  @param format The string format to be printed.
 *  @param ...    The parameters to be added to the string format.
 */
#define GREYLogVerbose(format, ...) \
  do { \
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kGREYAllowVerboseLogging]) { \
      NSLog(format, ##__VA_ARGS__); \
    } \
  } while (0)
