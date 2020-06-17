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

#import "Service/Tests/FunctionalTests/EDOTestDummyInTest.h"

#import "Service/Sources/NSObject+EDOWeakObject.h"
#import "Service/Tests/TestsBundle/EDOTestDummy.h"

// Also define this in the test process.
@implementation EDOTestDummyException
@end

@implementation EDOTestDummyInTest

+ (NSException *)exceptionWithReason:(NSString *)reason value:(int)value {
  return [EDOTestDummyException exceptionWithName:[NSString stringWithFormat:@"Dummy %d", value]
                                           reason:reason
                                         userInfo:nil];
}

- (instancetype)initWithValue:(int)value {
  self = [self init];
  if (self) {
    _value = @(value);
  }
  return self;
}

- (void)dealloc {
  if (_deallocHandlerBlock) {
    _deallocHandlerBlock();
  }
}

- (int)callTestDummy:(EDOTestDummy *)dummy {
  return self.value.intValue + [dummy returnIdWithInt:10].value + 3;
}

- (EDOTestDummyInTest *)makeAnotherDummy:(int)value {
  return [[EDOTestDummyInTest alloc] initWithValue:self.value.intValue + 7 + value];
}

- (EDOTestDummyInTest *)callWithDummy:(EDOTestDummyInTest *)dummy {
  return self;
}

- (void)noArgSelector {
}

- (void)invokeBlock {
  if (self.block) {
    self.block();
  }
}

@end

@implementation EDOBlacklistedTestDummyInTest

- (EDOTestDummyInTest *)makeAnotherDummy:(int)value {
  return [[EDOBlacklistedTestDummyInTest alloc] initWithValue:0];
}

@end
