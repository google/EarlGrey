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

#import "GREYBaseTest.h"

@interface GREYInterposerTest : GREYBaseTest
@end

@implementation GREYInterposerTest

- (void)testDispatchSyncIsInterposed {
  dispatch_sync(dispatch_get_global_queue(0, 0), ^{
    NSArray *symbols = [NSThread callStackSymbols];
    BOOL found = NO;
    for (NSString *symbol in symbols) {
      if ([symbol rangeOfString:@"grey_dispatch_sync"].location != NSNotFound) {
        found = YES;
        break;
      }
    }
    XCTAssertTrue(found, @"dispatch_sync should be interposed");
  });
}

@end
