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

#import "NSURL+GREYApp.h"

#include <objc/runtime.h>

#import "GREYFatalAsserts.h"
#import "GREYThrowDefines.h"
#import "GREYConfigKey.h"
#import "GREYConfiguration.h"
#import "GREYConstants.h"
#import "GREYLogger.h"

@implementation NSURL (GREYApp)

- (BOOL)grey_shouldSynchronize {
  if ([[self scheme] isEqualToString:@"data"]) {
    // skip data schemes. They can be huge and we can get stuck evaluating them.
    return NO;
  }

  NSArray<NSString *> *blockedRegExs = [[self class] grey_blockedRegEx];
  if (blockedRegExs.count == 0) {
    return YES;
  }

  NSString *stringURL = [self absoluteString];
  NSError *error;
  for (NSString *regexStr in blockedRegExs) {
    NSRegularExpression *regex =
        [NSRegularExpression regularExpressionWithPattern:regexStr options:0 error:&error];
    GREYFatalAssertWithMessage(!error, @"Invalid regex:\"%@\". See error: %@", regex, error);
    NSRange firstMatch = [regex rangeOfFirstMatchInString:stringURL
                                                  options:0
                                                    range:NSMakeRange(0, [stringURL length])];
    if (firstMatch.location != NSNotFound) {
      GREYLogVerbose(@"Matched a blocked URL: %@", stringURL);
      return NO;
    }
  }
  return YES;
}

// Returns an @c NSArray of @c NSString representing regexs of URLs that shouldn't be synchronized
// with.
+ (NSArray<NSString *> *)grey_blockedRegEx {
  // Get user blocked URLs.
  NSMutableArray<NSString *> *blocked =
      GREY_CONFIG_ARRAY(kGREYConfigKeyBlockedURLRegex).mutableCopy;
  @synchronized(self) {
    // Merge with framework blocked URLs.
    NSArray<NSString *> *frameworkBlocked =
        objc_getAssociatedObject(self, @selector(grey_blockedRegEx));
    if (frameworkBlocked) {
      [blocked addObjectsFromArray:frameworkBlocked];
    }
  }
  return blocked;
}

+ (void)grey_addBlockedRegEx:(NSString *)URLRegEx {
  GREYThrowOnNilParameter(URLRegEx);

  @synchronized(self) {
    NSMutableArray<NSString *> *blocked =
        objc_getAssociatedObject(self, @selector(grey_blockedRegEx));
    if (!blocked) {
      blocked = [[NSMutableArray alloc] init];
      objc_setAssociatedObject(self, @selector(grey_blockedRegEx), blocked,
                               OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [blocked addObject:URLRegEx];
  }
}

@end
