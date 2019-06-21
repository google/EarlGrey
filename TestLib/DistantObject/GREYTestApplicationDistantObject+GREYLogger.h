//
// Copyright 2018 Google Inc.
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

#import "GREYTestApplicationDistantObject.h"

/**
 *  Prints a log statement in the format provided in the Test Logs.
 *
 *  @param logStatement The NSString to be printed using NSLog in the Test Process.
 *  @remark Use this macro for logging any app statements from the test since the underlying
 *          implementation might be changed.
 */
#define NSLogInTest(__format, ...)                                                   \
  ({                                                                                 \
    NSString *logStatement = [NSString stringWithFormat:(__format), ##__VA_ARGS__];  \
    [[GREYTestApplicationDistantObject sharedInstance] printLogInTest:logStatement]; \
  })

/** GREYTestApplicationDistantObject extension for the EarlGrey AppFramework. */
@interface GREYTestApplicationDistantObject (GREYLogger)

/**
 *  Prints the provided statement using NSLog.
 *
 *  @param logStatement The NSString to print in the test process.
 *  @remark Do not use this method, but instead use the NSLogTest macro.
 */
- (void)printLogInTest:(NSString *)logStatement;

@end
