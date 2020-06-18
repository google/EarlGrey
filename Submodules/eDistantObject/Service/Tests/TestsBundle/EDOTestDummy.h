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

#import "Service/Tests/TestsBundle/EDOTestNonNSCodingType.h"
#import "Service/Tests/TestsBundle/EDOTestProtocol.h"
#import "Service/Tests/TestsBundle/EDOTestProtocolInApp.h"
#import "Service/Tests/TestsBundle/EDOTestValueType.h"

// Define the constant port number so both the test and the app process can
// share. This will eventually be automatically assigned.
#define EDOTEST_APP_SERVICE_PORT 1234

@interface EDOTestDummyException : NSException
@end

/** The dummy c-struct to test POD type of parameter. */
typedef struct EDOTestDummyStruct {
  int value;
  float a, b, c;
  double x, y, z;
} EDOTestDummyStruct;

/** The dummy class used to test the distant object. */
@interface EDOTestDummy : NSObject <NSFastEnumeration, EDOTestProtocolInApp, NSCopying>
@property int value;
@property void (^block)(void);
@property(readonly, weak) EDOTestDummy *weakDummyInTest;
@property(weak) id weakDelegate;
@property(nonatomic) id<NSCoding> valueObject;

- (instancetype)initWithValue:(int)value;

/// class methods
+ (EDOTestDummy *)classMethodWithNumber:(NSNumber *)value;

/// void return with parameters of different types
- (void)voidWithValuePlusOne;
- (void)voidWithInt:(int)arg1;
- (void)voidWithNumber:(NSNumber *)value1;
- (void)voidWithString:(NSString *)string data:(NSData *)data;
- (void)voidWithClass:(Class)clazz;
- (void)voidWithStruct:(EDOTestDummyStruct)value;
- (void)voidWithId:(id)any;
- (void)voidWithValueOut:(NSNumber **)numberOut;
- (void)voidWithErrorOut:(NSError **)errorOut;
- (void)voidWithOutObject:(EDOTestDummy **)dummyOut;
- (void)voidWithValue:(int)value outSelf:(EDOTestDummy **)dummyOut;
- (void)voidWithProtocol:(Protocol *)protocol;

/// no parameters with returns of different types
- (int)returnInt;
- (EDOTestDummyStruct)returnStruct;
- (NSNumber *)returnNumber;
- (NSString *)returnString;
- (NSData *)returnData;
- (EDOTestDummy *)returnSelf;
- (instancetype)returnDeepCopy;
- (NSDictionary<NSString *, NSNumber *> *)returnDictionary;
- (NSArray<NSNumber *> *)returnArray;
- (NSArray<NSNumber *> *)returnLargeArray;
- (NSSet<NSNumber *> *)returnSet;
- (Class)returnClass;
- (id)returnIdNil;
- (Protocol *)returnWithProtocolInApp;
- (EDOTestDummy *)returnWeakDummy;
- (EDOTestDummy *)weaklyHeldDummyForMemoryTest;
- (void (^)(void))returnBlock;

// block variants
- (void)voidWithBlock:(void (^)(void))block;
- (void)voidWithBlockAssigned:(void (^)(void))block;
- (EDOTestDummyStruct)returnStructWithBlockStret:(EDOTestDummyStruct (^)(void))block;
- (double)returnWithBlockDouble:(double (^)(void))block;
- (id)returnWithBlockObject:(id (^)(EDOTestDummy *))block;
- (EDOTestDummy *)returnWithBlockOutObject:(void (^)(EDOTestDummy **))block;
- (EDOTestDummy *)returnWithInt:(int)intVar
                    dummyStruct:(EDOTestDummyStruct)dummyStruct
                   blockComplex:(EDOTestDummy * (^)(EDOTestDummyStruct, int, EDOTestDummy *))block;
- (void)invokeBlock;

/** Returns the name of the given @c selector. */
- (NSString *)nameFromSelector:(SEL)selector;

/** Returns the selector from the given @c name. */
- (SEL)selectorFromName:(NSString *)name;

/// throw exceptions
- (void)selWithThrow;

/// returns with parameters of different types
- (EDOTestDummyStruct)structWithStruct:(EDOTestDummyStruct)value;
- (EDOTestDummy *)returnIdWithInt:(int)value;
- (Class)classsWithClass:(Class)clz;
- (NSNumber *)returnNumberWithInt:(int)arg value:(NSNumber *)value;
- (BOOL)returnBoolWithError:(NSError **)errorOrNil;
- (NSString *)returnClassNameWithObject:(id)object;
- (NSInteger)returnCountWithArray:(NSArray *)value;
- (NSInteger)returnSumWithArray:(NSArray *)value;
- (NSInteger)returnSumWithArrayAndProxyCheck:(NSArray *)value;

/**
 *  Gets the class name for the given object reference.
 *
 *  @param objRef The reference to an object.
 *  @return @c nil if objRef is @c nil; @"" if *objRef is @c nil; otherwise the
 *          class name of *objRef.
 */
- (NSString *)returnClassNameWithObjectRef:(id *)objRef;

/** Gets the given argument's local address. */
- (UInt64)memoryAddressFromObject:(id)object;

/** Gets the given argument pointee's local address. */
- (UInt64)memoryAddressFromObjectRef:(id *)objRef;

/// helper methods
- (NSException *)exceptionWithReason:(NSString *)reason;
- (NSError *)error;
+ (void)enumerateSelector:(void (^)(SEL selector))block;

@end

/** The extension for AppDelegate. */
@interface EDOTestDummy (AppDelegate)
- (void)invalidateService;
@end

@class EDOTestDummyInTest;

/** Extension for multiplex invocation between the Host and the Client. */
@interface EDOTestDummy (InTest)

- (int)callBackToTest:(EDOTestDummyInTest *)dummy withValue:(int)value;
- (int)selWithOutEDO:(EDOTestDummyInTest **)dummyOut dummy:(EDOTestDummyInTest *)dummyIn;
- (EDOTestDummyInTest *)selWithInOutEDO:(EDOTestDummyInTest **)dummyInOut;
- (void)setDummInTest:(EDOTestDummyInTest *)dummyInTest withDummy:(EDOTestDummyInTest *)dummy;
- (EDOTestDummyInTest *)getRootObject:(UInt16)port;
- (EDOTestDummyInTest *)createEDOWithPort:(UInt16)port;

- (int)returnPlus10AndAsyncExecuteBlock:(EDOTestDummyInTest *)dummyInTest;
@end
