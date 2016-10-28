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

#import "Additions/NSURL+GREYAdditions.h"
#import "Common/GREYVerboseLogger.h"

#import <objc/runtime.h>

#import "Common/GREYConfiguration.h"

@implementation NSURL (GREYAdditions)

- (BOOL)grey_shouldSynchronize {
  NSArray *blacklistRegExs = [[self class] grey_blacklistRegEx];
  if (blacklistRegExs.count == 0) {
    return YES;
  }

  NSString *stringURL = [self absoluteString];
  NSRegularExpression *regex;
  NSError *error;
  for (NSString *regexStr in blacklistRegExs) {
    regex = [NSRegularExpression regularExpressionWithPattern:regexStr
                                                      options:0
                                                        error:&error];
    NSAssert(!error, @"Invalid regex:\"%@\". See error: %@", regex, error);
    NSUInteger numMatches =
        [regex numberOfMatchesInString:stringURL
                               options:0
                                 range:NSMakeRange(0, [stringURL length])];
    if (numMatches > 0) {
      GREYLogVerbose(@"Matched a blacklisted URL: %@", stringURL);
      return NO;
    }
  }
  return YES;
}

// Returns an @c NSArray of @c NSString representing regexs of URLs that shouldn't be synchronized
// with.
+ (NSArray *)grey_blacklistRegEx {
  // Get user blacklisted URLs.
  NSMutableArray *blacklist = GREY_CONFIG_ARRAY(kGREYConfigKeyURLBlacklistRegex).mutableCopy;
  @synchronized (self) {
    // Merge with framework blacklisted URLs.
    NSArray *frameworkBlacklist = objc_getAssociatedObject(self, @selector(grey_blacklistRegEx));
    if (frameworkBlacklist) {
      [blacklist addObjectsFromArray:frameworkBlacklist];
    }
  }
  return blacklist;
}

+ (void)grey_addBlacklistRegEx:(NSString *)URLRegEx {
  NSParameterAssert(URLRegEx);
  @synchronized (self) {
    NSMutableArray *blacklist = objc_getAssociatedObject(self, @selector(grey_blacklistRegEx));
    if (!blacklist) {
      blacklist = [[NSMutableArray alloc] init];
      objc_setAssociatedObject(self,
                               @selector(grey_blacklistRegEx),
                               blacklist,
                               OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [blacklist addObject:URLRegEx];
  }
}

@end
