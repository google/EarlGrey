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

#include <dlfcn.h>

#import "GREYErrorConstants.h"
#import "GREYFrameworkException.h"
#import "GREYElementHierarchy.h"

static NSString *DemangleSymbol(NSString *symbol) {
  static char *(*swiftDemangle)(const char *mangledName, size_t mangledNameLength,
                                char *outputBuffer, size_t *outputBufferSize, uint32_t flags);
  // Exports a function from the Swift stdlib that isn't exposed by default, for demangling Swift
  // symbol names.
  //
  // https://github.com/swiftlang/swift/blob/80050bb455b22cf2eee6fd77816cd41411b975c9/stdlib/public/runtime/Demangle.cpp#L930
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    swiftDemangle = dlsym(RTLD_DEFAULT, "swift_demangle");
  });
  if (!swiftDemangle) {
    return symbol;
  }

  char *demangledSymbolCString = swiftDemangle(symbol.UTF8String, symbol.length, nil, nil, 0);
  if (!demangledSymbolCString) {
    return symbol;
  }

  NSString *demangledSymbol = [NSString stringWithUTF8String:demangledSymbolCString];
  free(demangledSymbolCString);
  return demangledSymbol;
}

// Trims the stack symbol to make it more readable.
static NSString *TrimStackSymbol(NSString *symbol) {
  // The stack symbol is of the form:
  // <index> <module> <address> <function> + <offset>
  //
  // For example:
  // 4   EarlGrey   0x0000000100000000 -[EarlGreyImpl handleException:details:] + 123
  //
  // Note: The implementation relies on how the stack trace is formatted. But since this is strictly
  // used to improve the debugging experience by making the stack trace more readable, it is fine if
  // any of the steps fails, as long as it fails gracefully (i.e. returns the original symbol
  // without crashing).
  NSString *functionName =
      [symbol stringByReplacingOccurrencesOfString:@".+0x[0-9a-fA-F]+\\s(.+)\\s\\+\\s\\d+$"
                                        withString:@"$1"
                                           options:NSRegularExpressionSearch
                                             range:NSMakeRange(0, symbol.length)];
  NSString *demangledFunctionName = DemangleSymbol(functionName);
  // Trim the top module name.
  NSString *trimmedFunctionName = [demangledFunctionName
      stringByReplacingOccurrencesOfString:@"\\w+\\.(\\w+)"
                                withString:@"$1"
                                   options:NSRegularExpressionSearch
                                     range:NSMakeRange(0, demangledFunctionName.length)];
  return [symbol stringByReplacingOccurrencesOfString:functionName withString:trimmedFunctionName];
}

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
      [trimmedCallStack addObject:TrimStackSymbol(stackSymbol)];
    }
  }
  // The trimmed stack trace should at least contain the test name and exception-raising method.
  NSUInteger trimmedCallStackCount = [trimmedCallStack count];
  if (trimmedCallStackCount >= 2) {
    return [NSString stringWithFormat:@"\n%@", [trimmedCallStack componentsJoinedByString:@"\n"]];
  }
  return nil;
}
