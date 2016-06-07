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

#import <EarlGrey/GREYConfiguration.h>

#import "GREYBaseTest.h"

@interface GREYConfigurationTest : GREYBaseTest {
  GREYConfiguration* _configuration;
}
@end

@implementation GREYConfigurationTest

- (void)setUp {
  [super setUp];
  _configuration = [GREYConfiguration sharedInstance];
}

- (void)testQueryForUnsetConfigurationsThrowsException {
  [self grey_assertThatExceptionThrownWithName:@"NSUnknownKeyException"
                                andDescription:@"Unknown configuration key: Unset"
                           whileExecutingBlock:^{
                             [_configuration valueForConfigKey:@"Unset"];
                           }];

  [self grey_assertThatExceptionThrownWithName:@"NSUnknownKeyException"
                                andDescription:@"Unknown configuration key: Unset"
                           whileExecutingBlock:^{
                             [_configuration boolValueForConfigKey:@"Unset"];
                           }];

  [self grey_assertThatExceptionThrownWithName:@"NSUnknownKeyException"
                                andDescription:@"Unknown configuration key: Unset"
                           whileExecutingBlock:^{
                             [_configuration intValueForConfigKey:@"Unset"];
                           }];

  [self grey_assertThatExceptionThrownWithName:@"NSUnknownKeyException"
                                andDescription:@"Unknown configuration key: Unset"
                           whileExecutingBlock:^{
                             [_configuration stringValueForConfigKey:@"Unset"];
                           }];
}

- (void)testKeysCannotBeNilOrEmpty {
  [self grey_assertThatExceptionThrownWithName:NSInvalidArgumentException
                                andDescription:@"Configuration keys cannot be empty strings or nil."
                           whileExecutingBlock:^{
                             [_configuration setValue:@"Some value" forConfigKey:nil];
                           }];

  [self grey_assertThatExceptionThrownWithName:NSInvalidArgumentException
                                andDescription:@"Configuration keys cannot be empty strings or nil."
                           whileExecutingBlock:^{
                             [_configuration setValue:@"Some value" forConfigKey:@""];
                           }];

  [self grey_assertThatExceptionThrownWithName:NSInvalidArgumentException
                                andDescription:@"Configuration keys cannot be empty strings or nil."
                           whileExecutingBlock:^{
                             [_configuration setValue:@"Some value" forConfigKey:@"\t\r\n"];
                           }];

  [self grey_assertThatExceptionThrownWithName:NSInvalidArgumentException
                                andDescription:@"Configuration keys cannot be empty strings or nil."
                           whileExecutingBlock:^{
                             [_configuration setValue:@"Some value" forConfigKey:@"  "];
                           }];

  [self grey_assertThatExceptionThrownWithName:NSInvalidArgumentException
                                andDescription:@"Configuration keys cannot be empty strings or nil."
                           whileExecutingBlock:^{
                             [_configuration valueForConfigKey:nil];
                           }];

  [self grey_assertThatExceptionThrownWithName:NSInvalidArgumentException
                                andDescription:@"Configuration keys cannot be empty strings or nil."
                           whileExecutingBlock:^{
                             [_configuration valueForConfigKey:@""];
                           }];

  [self grey_assertThatExceptionThrownWithName:NSInvalidArgumentException
                                andDescription:@"Configuration keys cannot be empty strings or nil."
                           whileExecutingBlock:^{
                             [_configuration valueForConfigKey:@"   "];
                           }];

  [self grey_assertThatExceptionThrownWithName:NSInvalidArgumentException
                                andDescription:@"Configuration keys cannot be empty strings or nil."
                           whileExecutingBlock:^{
                             [_configuration boolValueForConfigKey:nil];
                           }];

  [self grey_assertThatExceptionThrownWithName:NSInvalidArgumentException
                                andDescription:@"Configuration keys cannot be empty strings or nil."
                           whileExecutingBlock:^{
                             [_configuration intValueForConfigKey:nil];
                           }];

  [self grey_assertThatExceptionThrownWithName:NSInvalidArgumentException
                                andDescription:@"Configuration keys cannot be empty strings or nil."
                           whileExecutingBlock:^{
                             [_configuration stringValueForConfigKey:nil];
                           }];
}

- (void)testQueryForDefaultConfigurationReturnsDefaultValue {
  [_configuration setDefaultValue:@"foo" forConfigKey:@"bar"];

  XCTAssertNotNil([_configuration valueForConfigKey:kGREYConfigKeyActionConstraintsEnabled]);
  XCTAssertEqualObjects([_configuration valueForConfigKey:@"bar"], @"foo");
}

- (void)testCustomDefaultValueCanBeOverritten {
  [_configuration setDefaultValue:@(1.0) forConfigKey:@"bar"];
  [_configuration setDefaultValue:@(2.0) forConfigKey:@"bar"];

  XCTAssertEqual([[_configuration valueForConfigKey:@"bar"] doubleValue], 2.0);

  [_configuration setValue:@(3.0) forConfigKey:@"bar"];
  XCTAssertEqual([[_configuration valueForConfigKey:@"bar"] doubleValue], 3.0);
}

- (void)testQueryForSetConfigurationReturnsUpdatedValue {
  [_configuration setValue:@NO forConfigKey:kGREYConfigKeyActionConstraintsEnabled];
  XCTAssertEqual(@NO, [_configuration valueForConfigKey:kGREYConfigKeyActionConstraintsEnabled]);

  [_configuration setValue:@YES forConfigKey:kGREYConfigKeyActionConstraintsEnabled];
  XCTAssertEqual(@YES, [_configuration valueForConfigKey:kGREYConfigKeyActionConstraintsEnabled]);
}

- (void)testResetDoesNotRemoveCustomDefaultValues {
  [_configuration setDefaultValue:@NO forConfigKey:@"defaultValue1"];
  [_configuration setDefaultValue:@(5.0) forConfigKey:@"defaultValue2"];

  [_configuration reset];

  XCTAssertEqual([_configuration valueForConfigKey:@"defaultValue1"], @NO);

  double actualValue = [[_configuration valueForConfigKey:@"defaultValue2"] doubleValue];
  XCTAssertEqual(actualValue, 5.0);
}

- (void)testResetRemovesValue {
  [_configuration setValue:@NO forConfigKey:kGREYConfigKeyActionConstraintsEnabled];
  [_configuration setValue:@(1.1) forConfigKey:kGREYConfigKeyCALayerMaxAnimationDuration];
  [_configuration setValue:@(1.7) forConfigKey:kGREYConfigKeySpeedUpAnimations];

  [_configuration reset];

  XCTAssertEqual([_configuration valueForConfigKey:kGREYConfigKeyActionConstraintsEnabled], @YES);
  double actualValue =
  [[_configuration valueForConfigKey:kGREYConfigKeyCALayerMaxAnimationDuration] doubleValue];
  XCTAssertEqual(actualValue, 10.0);

  actualValue =
  [[_configuration valueForConfigKey:kGREYConfigKeySpeedUpAnimations] doubleValue];
  XCTAssertEqual(actualValue, 100.0);
}

- (void)testQueryBoolReturnsConvertedValue {
  [_configuration setValue:@NO forConfigKey:kGREYConfigKeyActionConstraintsEnabled];
  XCTAssertFalse([_configuration boolValueForConfigKey:kGREYConfigKeyActionConstraintsEnabled]);

  [_configuration setValue:@YES forConfigKey:kGREYConfigKeyActionConstraintsEnabled];
  XCTAssertTrue([_configuration boolValueForConfigKey:kGREYConfigKeyActionConstraintsEnabled]);
}

- (void)testQueryDoubleReturnsConvertedValue {
  [_configuration setValue:@(1.0) forConfigKey:kGREYConfigKeyCALayerMaxAnimationDuration];
  double actualValue =
      [_configuration doubleValueForConfigKey:kGREYConfigKeyCALayerMaxAnimationDuration];
  XCTAssertEqual(1.0, actualValue);

  [_configuration setValue:@(1.0) forConfigKey:kGREYConfigKeySpeedUpAnimations];
  actualValue =
  [_configuration doubleValueForConfigKey:kGREYConfigKeySpeedUpAnimations];
  XCTAssertEqual(1.0, actualValue);

  [_configuration setValue:@(1.3) forConfigKey:kGREYConfigKeyCALayerMaxAnimationDuration];
  actualValue = [_configuration doubleValueForConfigKey:kGREYConfigKeyCALayerMaxAnimationDuration];
  XCTAssertEqual(1.3, actualValue);

  [_configuration setValue:@(1.9) forConfigKey:kGREYConfigKeySpeedUpAnimations];
  actualValue = [_configuration doubleValueForConfigKey:kGREYConfigKeySpeedUpAnimations];
  XCTAssertEqual(1.9, actualValue);
}

- (void)testQueryStringThrowsExceptionIfNotAStringValue {
  [_configuration setValue:@12345 forConfigKey:@"NonStringConfig"];

  [self grey_assertThatExceptionThrownWithName:NSInternalInconsistencyException
                                andDescription:@"NonStringConfig's value type __NSCFNumber is not"
                                               @" of type NSString."
                           whileExecutingBlock:^{
                             [_configuration stringValueForConfigKey:@"NonStringConfig"];
                           }];
}

- (void)testMacrosHaveSameResultsAsRespectiveMethods {
  [_configuration setValue:[NSNumber class] forConfigKey:@"valueConfig"];
  XCTAssertEqualObjects(GREY_CONFIG(@"valueConfig"),
                        [_configuration valueForConfigKey:@"valueConfig"]);

  [_configuration setValue:@YES forConfigKey:@"boolConfig"];
  XCTAssertEqual(GREY_CONFIG_BOOL(@"boolConfig"),
                 [_configuration boolValueForConfigKey:@"boolConfig"]);

  [_configuration setValue:@1234 forConfigKey:@"intConfig"];
  XCTAssertEqual(GREY_CONFIG_INT(@"intConfig"),
                 [_configuration intValueForConfigKey:@"intConfig"]);

  [_configuration setValue:@"StringValue" forConfigKey:@"stringConfig"];
  XCTAssertEqualObjects(GREY_CONFIG_STRING(@"stringConfig"),
                        [_configuration stringValueForConfigKey:@"stringConfig"]);

  [_configuration setValue:@(1.2) forConfigKey:@"doubleConfig"];
  XCTAssertEqual(GREY_CONFIG_DOUBLE(@"doubleConfig"),
                 [_configuration doubleValueForConfigKey:@"doubleConfig"]);
}

#pragma mark - Private

/**
 *  Utility method that invokes a block and asserts that it throws an exception.
 *
 *  @param exceptionName The name of the exception that is expected to be thrown.
 *  @param description   The description of the exception that is expected to be thrown.
 *  @param block         The block to be executed.
 */
- (void)grey_assertThatExceptionThrownWithName:(NSString *)exceptionName
                                andDescription:description
                           whileExecutingBlock:(void (^)())block {
  @try {
    block();
    XCTFail(@"Block should fail with %@", exceptionName);
  }
  @catch (NSException *exception) {
    XCTAssertEqualObjects(exceptionName, exception.name);
    XCTAssertEqualObjects(description, exception.description);
  }
}

@end
