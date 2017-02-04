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

#import "EarlGrey.h"

#import "Common/GREYAnalytics.h"
#import "Event/GREYSyntheticEvents.h"
#import "Exception/GREYDefaultFailureHandler.h"

NSString *const kGREYFailureHandlerKey = @"GREYFailureHandlerKey";

@implementation EarlGreyImpl

+ (void)load {
  @autoreleasepool {
    // These need to be set in load since someone might call GREYAssertXXX APIs without calling
    // into EarlGrey.
    resetFailureHandler();
  }
}

+ (instancetype)invokedFromFile:(NSString *)fileName lineNumber:(NSUInteger)lineNumber {
  static EarlGreyImpl *instance = nil;
  static dispatch_once_t token = 0;
  dispatch_once(&token, ^{
    instance = [[EarlGreyImpl alloc] initOnce];
  });

  SEL invocationFileAndLineSEL = @selector(setInvocationFile:andInvocationLine:);
  id<GREYFailureHandler> failureHandler;
  @synchronized (self) {
    failureHandler = getFailureHandler();
  }
  if ([failureHandler respondsToSelector:invocationFileAndLineSEL]) {
    [failureHandler setInvocationFile:fileName andInvocationLine:lineNumber];
  }
  [[GREYAnalytics sharedInstance] didInvokeEarlGrey];
  return instance;
}

- (instancetype)initOnce {
  self = [super init];
  return self;
}

- (GREYElementInteraction *)selectElementWithMatcher:(id<GREYMatcher>)elementMatcher {
  return [[GREYElementInteraction alloc] initWithElementMatcher:elementMatcher];
}

- (void)setFailureHandler:(id<GREYFailureHandler>)handler {
  @synchronized ([self class]) {
    if (handler) {
      NSMutableDictionary *TLSDict = [[NSThread currentThread] threadDictionary];
      [TLSDict setValue:handler forKey:kGREYFailureHandlerKey];
    } else {
      resetFailureHandler();
    }
  }
}

- (void)handleException:(GREYFrameworkException *)exception details:(NSString *)details {
  @synchronized ([self class]) {
    id<GREYFailureHandler> failureHandler = getFailureHandler();
    [failureHandler handleException:exception details:details];
  }
}

- (BOOL)rotateDeviceToOrientation:(UIDeviceOrientation)deviceOrientation
                       errorOrNil:(__strong NSError **)errorOrNil {
  return [GREYSyntheticEvents rotateDeviceToOrientation:deviceOrientation errorOrNil:errorOrNil];
}

#pragma mark - Private

// Resets the failure handler. Not thread safe.
static inline void resetFailureHandler() {
  NSMutableDictionary *TLSDict = [[NSThread currentThread] threadDictionary];
  [TLSDict setValue:[[GREYDefaultFailureHandler alloc] init] forKey:kGREYFailureHandlerKey];
}

inline id<GREYFailureHandler> getFailureHandler() {
  NSMutableDictionary *TLSDict = [[NSThread currentThread] threadDictionary];
  return [TLSDict valueForKey:kGREYFailureHandlerKey];
}

@end
