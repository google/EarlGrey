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
// distributed under the License is distributed on an "AS IS" BASIS,ssss
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "GREYLogger.h"

NSString* const kGREYAllowVerboseLogging = @"eg_verbose_logs";

NSString* const kGREYVerboseLoggingKeyAll = @"all";
NSString* const kGREYVerboseLoggingKeyInteraction = @"interaction";
NSString* const kGREYVerboseLoggingKeyAppState = @"app_state";

BOOL GREYVerboseLoggingEnabled(void) {
  return [[NSUserDefaults standardUserDefaults] integerForKey:kGREYAllowVerboseLogging] > 0;
}

BOOL GREYVerboseLoggingEnabledForLevel(GREYVerboseLogType level) {
  NSInteger verboseLoggingValue =
      [[NSUserDefaults standardUserDefaults] integerForKey:kGREYAllowVerboseLogging];
  return verboseLoggingValue | level;
}

GREYVerboseLogType GREYVerboseLogTypeFromString(NSString* verboseLoggingString) {
  static NSDictionary<NSString*, NSNumber*>* verboseType = nil;
  if (!verboseType) {
    verboseType = @{
      kGREYVerboseLoggingKeyInteraction : @(kGREYVerboseLogTypeInteraction),
      kGREYVerboseLoggingKeyAppState : @(kGREYVerboseLogTypeAppState),
      kGREYVerboseLoggingKeyAll : @(kGREYVerboseLogTypeAll),
    };
  }

  return [verboseType[verboseLoggingString] intValue];
}

void GREYLogVerbose(NSString* format, ...) {
  static BOOL gPrintVerboseLog;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    gPrintVerboseLog = GREYVerboseLoggingEnabled();
  });
  if (gPrintVerboseLog) {
    va_list args;
    va_start(args, format);
    NSLogv(format, args);
    va_end(args);
  }
}

#pragma mark - Testing only.
