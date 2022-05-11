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

#import "GREYFailureHandlerHelpers.h"

#import "GREYErrorConstants.h"
#import "GREYFrameworkException.h"
#import "GREYElementHierarchy.h"

NSString *GREYAppUIHierarchyFromException(GREYFrameworkException *exception, NSString *details) {
  NSString *appUIHierarchy = [exception.userInfo valueForKey:kErrorDetailAppUIHierarchyKey];
  // For calls from GREYAsserts in the test side, the hierarchy must be populated here. In case an
  // existing EarlGrey error is being logged, do not re-print it.
  if (!appUIHierarchy) {
    if ([details containsString:kErrorDetailAppUIHierarchyHeaderKey]) {
      NSArray<NSString *> *detailsComponents =
          [details componentsSeparatedByString:kErrorDetailAppUIHierarchyHeaderKey];
      return [detailsComponents lastObject];
    }
    appUIHierarchy = [NSString stringWithFormat:@"\n%@:\n%@\n", kErrorDetailAppUIHierarchyKey,
                                                [GREYElementHierarchy hierarchyString]];
    return appUIHierarchy;
  }
  // Hierarchy must have already been populated by the GREYErrorFormatter.
  return @"";
}

NSString *GREYTestStackTrace(void) {
  // If the exception is thrown from a helper, more than one line will be present beyond the
  // `invoke` value in the stack trace.
  NSArray<NSString *> *callStack = [NSThread callStackSymbols];
  NSMutableArray<NSString *> *trimmedCallStack = [[NSMutableArray alloc] init];
  for (NSString *stackSymbol in callStack) {
    if ([stackSymbol containsString:@"__invoking___"]) {
      break;
    } else if (![stackSymbol containsString:@"-[GREY"] && ![stackSymbol containsString:@" GREY"]) {
      [trimmedCallStack addObject:stackSymbol];
    }
  }
  // The trimmed stack trace should at least contain the test name and exception-raising method.
  NSUInteger trimmedCallStackCount = [trimmedCallStack count];
  if (trimmedCallStackCount >= 2) {
    return [NSString stringWithFormat:@"\n%@", [trimmedCallStack componentsJoinedByString:@"\n"]];
  }
  return nil;
}
