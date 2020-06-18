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

#import "Service/Sources/NSKeyedUnarchiver+EDOAdditions.h"

@implementation NSKeyedUnarchiver (EDOAdditions)

+ (id)edo_unarchiveObjectWithData:(NSData *)data {
  // In Xcode 10.0, we can use the newer APIs.
#if (defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 101400) || \
    (defined(__TV_OS_VERSION_MAX_ALLOWED) && __TV_OS_VERSION_MAX_ALLOWED >= 120000) ||       \
    (defined(__WATCH_OS_VERSION_MAX_ALLOWED) && __WATCH_OS_VERSION_MAX_ALLOWED >= 120000) || \
    (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 120000)
  if (@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, *)) {
    // Use instancesRespondToSelector check because it's possible that something loads this on a
    // lower iOS version than what it was built with, in which case the availability macros fail to
    // protect it.
    SEL selector = @selector(initForReadingFromData:error:);
    if ([NSKeyedUnarchiver instancesRespondToSelector:selector]) {
      NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:data
                                                                                  error:nil];
      unarchiver.decodingFailurePolicy = NSDecodingFailurePolicyRaiseException;
      unarchiver.requiresSecureCoding = NO;
      id object = [unarchiver decodeObjectForKey:NSKeyedArchiveRootObjectKey];
      [unarchiver finishDecoding];
      return object;
    }
  }
#endif
  // This API is deprecated in iOS 12/macOS 10.14, so we suppress warning here in case its
  // minimum required SDKs are lower.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  return [NSKeyedUnarchiver unarchiveObjectWithData:data];
#pragma clang diagnostic pop
}

@end
