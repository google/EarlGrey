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

#import <Foundation/Foundation.h>

@class EDOTestDummy;

/**
 *  The test dummy class defined in the test process to test the distant object.
 */
@interface EDOTestDummyInTest : NSObject
@property NSNumber *value;
@property EDOTestDummyInTest *dummyInTest;
@property void (^block)(void);
@property(nullable) void (^deallocHandlerBlock)(void);

- (instancetype)initWithValue:(int)value;

- (void)noArgSelector;
- (int)callTestDummy:(EDOTestDummy *)dummy;
- (EDOTestDummyInTest *)makeAnotherDummy:(int)value;

/** Invoke the previous set block, usually called from the test app. */
- (void)invokeBlock;

+ (NSException *)exceptionWithReason:(NSString *)reason value:(int)value;
@end

/** The test dummy class that is used in blacklisting test. */
@interface EDOBlacklistedTestDummyInTest : EDOTestDummyInTest
@end
