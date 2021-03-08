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
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "GREYLogger.h"


NSString* const kGREYAllowVerboseLogging = @"kGREYAllowVerboseLogging";

void GREYLogVerbose(NSString* format, ...) {
  static BOOL gPrintVerboseLog;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    gPrintVerboseLog =
        [[NSUserDefaults standardUserDefaults] integerForKey:kGREYAllowVerboseLogging] > 0;
  });
  if (gPrintVerboseLog > 0) {
    va_list args;
    va_start(args, format);
    NSLogv(format, args);
    va_end(args);
  }
}
