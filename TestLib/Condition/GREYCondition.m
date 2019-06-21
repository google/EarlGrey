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

#import "GREYCondition.h"

#import <QuartzCore/QuartzCore.h>
#import <mach/mach_time.h>

#import "GREYFatalAsserts.h"
#import "GREYThrowDefines.h"
#import "GREYConstants.h"
#import "GREYDefines.h"

@implementation GREYCondition {
  BOOL (^_conditionBlock)(void);
  NSString *_name;
}

+ (instancetype)conditionWithName:(NSString *)name block:(BOOL (^)(void))conditionBlock {
  return [[GREYCondition alloc] initWithName:name block:conditionBlock];
}

- (instancetype)initWithName:(NSString *)name block:(BOOL (^)(void))conditionBlock {
  GREYThrowOnNilParameter(name);
  GREYThrowOnNilParameter(conditionBlock);

  self = [super init];
  if (self) {
    _name = [name copy];
    _conditionBlock = [conditionBlock copy];
  }
  return self;
}

- (BOOL)waitWithTimeout:(CFTimeInterval)seconds {
  return [self waitWithTimeout:seconds pollInterval:0];
}

- (BOOL)waitWithTimeout:(CFTimeInterval)seconds pollInterval:(CFTimeInterval)interval {
  GREYThrowOnFailedConditionWithMessage(seconds >= 0, @"timeout seconds must be >= 0.");
  GREYThrowOnFailedConditionWithMessage(interval >= 0, @"poll interval must be >= 0.");

  __block CFTimeInterval nextPollTime = CACurrentMediaTime();

  if (seconds == 0) {
    return _conditionBlock();
  } else {
    while (seconds > 0) {
      CFTimeInterval now = CACurrentMediaTime();
      if (now >= nextPollTime) {
        nextPollTime = now + interval;
        if (_conditionBlock()) {
          return YES;
        }
      }
      CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, NO);
      seconds = seconds - (CACurrentMediaTime() - now);
    }
  }
  return NO;
}

- (NSString *)name {
  return _name;
}

@end
