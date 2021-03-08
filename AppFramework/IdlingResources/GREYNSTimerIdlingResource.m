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

#import "GREYNSTimerIdlingResource.h"

#import "GREYUIThreadExecutor+Private.h"
#import "GREYUIThreadExecutor.h"
#import "GREYThrowDefines.h"
@implementation GREYNSTimerIdlingResource {
  NSString *_name;
  __weak NSTimer *_trackedTimer;
  BOOL _removeOnIdle;
  NSArray<NSString *> *_callStack;
}

+ (instancetype)trackTimer:(NSTimer *)timer name:(NSString *)name removeOnIdle:(BOOL)removeOnIdle {
  GREYNSTimerIdlingResource *resource =
      [[GREYNSTimerIdlingResource alloc] initWithTimer:timer name:name removeOnIdle:removeOnIdle];
  [[GREYUIThreadExecutor sharedInstance] registerIdlingResource:resource];
  return resource;
}

- (instancetype)initWithTimer:(NSTimer *)timer
                         name:(NSString *)name
                 removeOnIdle:(BOOL)removeOnIdle {
  GREYThrowOnNilParameter(timer);
  GREYThrowOnNilParameter(name);

  self = [super init];
  if (self) {
    _trackedTimer = timer;
    _name = [name copy];
    _removeOnIdle = removeOnIdle;
    _callStack = [NSThread callStackSymbols];
  }
  return self;
}

#pragma mark - GREYIdlingResource

- (NSString *)idlingResourceName {
  return _name;
}

- (NSString *)idlingResourceDescription {
  return [NSString
      stringWithFormat:@"Waiting for timer %@ to fire (next fire in %g seconds).\nYou can ignore a "
                        "timer by setting kNSTimerIgnoreTrackingKey:@(YES) as an "
                        "associated object on the NSTimer.  \nCreated at:\n%@",
                       _trackedTimer, [_trackedTimer.fireDate timeIntervalSinceNow], _callStack];
}

- (BOOL)isIdleNow {
  // Note that |_trackedTimer| is a weak pointer and we make use of the side effect that if it
  // becomes nil, isIdle will be @c YES.
  BOOL isIdle = ![_trackedTimer isValid];
  if (isIdle && _removeOnIdle) {
    [[GREYUIThreadExecutor sharedInstance] deregisterIdlingResource:self];
  }
  return isIdle;
}

@end
