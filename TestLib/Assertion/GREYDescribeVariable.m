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

#import "GREYDescribeVariable.h"
#import "GREYThrowDefines.h"
#import "GREYDefines.h"

#include <ctype.h>
#include <objc/runtime.h>

NSString *_Nonnull GREYDescribeValue(const char *_Nonnull encoding, void *_Nonnull valuePointer) {
  GREYThrowInFunctionOnNilParameter(encoding);
  GREYThrowInFunctionOnNilParameter(valuePointer);
  // For general reference on encoding strings, see
  // NOLINTNEXTLINE
  // https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html#//apple_ref/doc/uid/TP40008048-CH100-SW1
  // particularly tables 6-1 and 6-2.
  char firstChar = *encoding;
  // Ignore modifier characters like the ones for const, etc.
  while (strchr("rnNoORV", firstChar)) {
    encoding++;
    firstChar = *encoding;
  }
  switch (firstChar) {
    case 0:
      return @"value with empty encoding";  // Something went horribly wrong.
    case 'c': {                             // char, also BOOL prior to 64-bit
      char c = *(char *)valuePointer;
      if (isprint(c)) {
        return [NSString stringWithFormat:@"'%c'", c];
      }
      return [NSString stringWithFormat:@"%d", (int)c];
    }
    case 'i':  // int, also int32_t
      return [NSString stringWithFormat:@"%d", *(int *)valuePointer];
    case 's':  // short
      return [NSString stringWithFormat:@"%d", (int)(*(short *)valuePointer)];
    case 'q':  // long, also long long
      return [NSString stringWithFormat:@"%ld", *(long *)valuePointer];
    case 'C': {
      unsigned char c = *(unsigned char *)valuePointer;
      if (isprint(c)) {
        return [NSString stringWithFormat:@"'%c'", c];
      }
      return [NSString stringWithFormat:@"%d", (int)c];
    }
    case 'I':
      return [NSString stringWithFormat:@"%u", *(unsigned int *)valuePointer];
    case 'S':
      return [NSString stringWithFormat:@"%u", (unsigned int)*(unsigned short *)valuePointer];
    case 'Q':
      return [NSString stringWithFormat:@"%lu", *(unsigned long *)valuePointer];
    case 'f':
      return [NSString stringWithFormat:@"%g", (double)*(float *)valuePointer];
    case 'd':
      return [NSString stringWithFormat:@"%G", *(double *)valuePointer];
    case 'B':
      return (*(bool *)valuePointer) ? @"true" : @"false";
    case '*':
      GREY_FALLTHROUGH_INTENDED;
    case '^':
      GREY_FALLTHROUGH_INTENDED;
    case ':':
      return [NSString stringWithFormat:@"%p", *(void **)valuePointer];
    case '@': {
      void **rawPointer = *(void **)valuePointer;
      if (rawPointer == NULL) {
        return @"nil";
      }
      id object = (__bridge id) * (void **)valuePointer;
      if (object == nil) {
        return @"nil";
      }
      return [NSString stringWithFormat:@"%s(%p)", object_getClassName(object), object];
    }
    case '#': {
      const char *className = "nil";
      if (valuePointer) {
        Class classPointer = *(Class *)valuePointer;
        className = class_getName(classPointer);
      }
      return [NSString stringWithFormat:@"%s", className];
    }
    case '{':  // struct or C++ object
      GREY_FALLTHROUGH_INTENDED;
    case '(': {  // union
      NSString *typeString = (firstChar == '{') ? @"class/struct" : @"union";
      NSString *name = @"";
      char *equalsSign = strchr(encoding, '=');
      if (equalsSign) {  // Docs claim there will always be a equals sign, but being paranoid.
        name = [[NSString alloc] initWithBytes:encoding + 1
                                        length:equalsSign - (encoding + 1)
                                      encoding:NSASCIIStringEncoding];
      }
      return [NSString stringWithFormat:@"%@%@%@", typeString, name ? @" " : @"", name];
    }
    default:
      return @"value of unknown type";
  }
}

NSString *_Nonnull GREYDescribeObject(NSObject *_Nullable object) {
  return object ? [object description] : @"nil";
}
