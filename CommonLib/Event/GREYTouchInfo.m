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

#import "GREYTouchInfo.h"

// TODO: Consider to use XCUITest injections, and may move this back to app framework. // NOLINT
@implementation GREYTouchInfo

- (instancetype)initWithPoints:(NSArray<NSValue *> *)points
                              phase:(UITouchPhase)phase
    deliveryTimeDeltaSinceLastTouch:(NSTimeInterval)timeDeltaSinceLastTouchSeconds {
  return [self initWithPoints:points
                         withTapCount:1
                                phase:phase
      deliveryTimeDeltaSinceLastTouch:timeDeltaSinceLastTouchSeconds];
}

- (instancetype)initWithPoints:(NSArray<NSValue *> *)points
                       withTapCount:(NSUInteger)tapCount
                              phase:(UITouchPhase)phase
    deliveryTimeDeltaSinceLastTouch:(NSTimeInterval)timeDeltaSinceLastTouchSeconds {
  return [self initWithPoints:points
                         withTapCount:tapCount
                                phase:phase
      deliveryTimeDeltaSinceLastTouch:timeDeltaSinceLastTouchSeconds
                            responder:nil];
}

- (instancetype)initWithPoints:(NSArray<NSValue *> *)points
                       withTapCount:(NSUInteger)tapCount
                              phase:(UITouchPhase)phase
    deliveryTimeDeltaSinceLastTouch:(NSTimeInterval)timeDeltaSinceLastTouchSeconds
                          responder:(UIResponder *)responder {
  self = [super init];
  if (self) {
    _points = points;
    _tapCount = tapCount;
    _phase = phase;
    _deliveryTimeDeltaSinceLastTouch = timeDeltaSinceLastTouchSeconds;
    _responder = responder;
  }
  return self;
}

- (NSString *)description {
  NSMutableString *desc = [[NSMutableString alloc] init];
  [desc appendFormat:@"%@", NSStringFromClass([self class])];
  [desc appendFormat:@" with phase: %ld\n", (long)_phase];
  [desc appendFormat:@" with delivery delta time: %g\n", _deliveryTimeDeltaSinceLastTouch];
  [desc appendFormat:@" with points: %@\n", _points];
  return desc;
}

@end
