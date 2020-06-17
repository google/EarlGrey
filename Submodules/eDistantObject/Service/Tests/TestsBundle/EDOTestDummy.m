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

#import "Service/Tests/TestsBundle/EDOTestDummy.h"

#include <objc/runtime.h>

#import "Service/Sources/EDOClientService.h"
#import "Service/Sources/NSObject+EDOWeakObject.h"
#import "Service/Tests/FunctionalTests/EDOTestDummyInTest.h"

static const NSInteger kLargeArraySize = 1000;

@implementation EDOTestDummyException
@end

@implementation EDOTestDummy

+ (EDOTestDummy *)classMethodWithNumber:(NSNumber *)value {
  return [[self alloc] initWithValue:value.intValue];
}

- (instancetype)initWithValue:(int)value {
  self = [self init];
  if (self) {
    _value = value;
  }
  return self;
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(nullable NSZone *)zone {
  return self;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"Test Dummy %d", self.value];
}

- (void)voidWithValuePlusOne {
  ++_value;
}

- (void)voidWithInt:(int)arg1 {
  _value += arg1;
}

- (void)voidWithNumber:(NSNumber *)value {
  _value += value.intValue;
}

- (void)voidWithString:(NSString *)string data:(NSData *)data {
  _value += (int)(string.length + data.length);
}

- (void)voidWithClass:(Class)clazz {
  // Use the @c clazz to make sure it will not crash.
  NSLog(@"%@", clazz);
}

- (void)voidWithStruct:(EDOTestDummyStruct)value {
  _value += value.value;
}

- (void)voidWithId:(id)any {
  if (!any) {
    [[self exceptionWithReason:@"NilArg"] raise];
  } else if ([any class] == NSClassFromString(@"EDOObject")) {
    [[self exceptionWithReason:@"EDOArg"] raise];
  } else {
    [[self exceptionWithReason:@"NonNilArg"] raise];
  }
}

- (void)voidWithValueOut:(NSNumber **)numberOut {
  if (!numberOut) {
    [[self exceptionWithReason:@"NilOutArg"] raise];
  } else if (*numberOut != nil) {
    *numberOut = [NSNumber numberWithInt:(*numberOut).intValue + _value];
  } else {
    *numberOut = [NSNumber numberWithInt:_value];
  }
}

- (void)voidWithErrorOut:(NSError **)errorOut {
  if (errorOut) {
    *errorOut = [self error];
  } else {
    [[self exceptionWithReason:@"NilErrorOut"] raise];
  }
}

- (void)voidWithOutObject:(EDOTestDummy **)dummyOut {
  if (!dummyOut) {
    [[self exceptionWithReason:@"dummyOut is nil"] raise];
  } else if (*dummyOut) {
    (*dummyOut).value += 5;
  } else {
    *dummyOut = [[EDOTestDummy alloc] initWithValue:self.value + 5];
  }
}

- (void)voidWithValue:(int)value outSelf:(EDOTestDummy **)dummyOut {
  self.value += value + (*dummyOut).value;
  *dummyOut = self;
}

- (void)voidWithBlock:(void (^)(void))block {
  // Block_copy should work on the remote block.
  block = (__bridge id)Block_copy((__bridge void *)block);
  if (block) {
    block();
  }
}

- (void)voidWithBlockAssigned:(void (^)(void))block {
  // Regular assignment should do copy internally and maintain its lifecycle.
  _block = block;
}

- (void)voidWithProtocol:(Protocol *)protocol {
  // Do nothing.
}

- (EDOTestDummyStruct)returnStructWithBlockStret:(EDOTestDummyStruct (^)(void))block {
  return block();
}

- (double)returnWithBlockDouble:(double (^)(void))block {
  // copy should work on the remote block.
  block = [block copy];
  return block();
}

- (id)returnWithBlockObject:(id (^)(EDOTestDummy *))block {
  return block(self);
}

- (EDOTestDummy *)returnWithBlockOutObject:(void (^)(EDOTestDummy **))block {
  EDOTestDummy *dummy;
  block(&dummy);
  return dummy;
}

- (EDOTestDummy *)returnWithInt:(int)intVar
                    dummyStruct:(EDOTestDummyStruct)dummyStruct
                   blockComplex:(EDOTestDummy * (^)(EDOTestDummyStruct, int, EDOTestDummy *))block {
  return block(dummyStruct, intVar, self);
}

- (void)invokeBlock {
  self.block();
}

- (int)returnInt {
  return _value;
}

- (EDOTestDummyStruct)returnStruct {
  return (EDOTestDummyStruct){.value = _value};
}

- (NSNumber *)returnNumber {
  return [NSNumber numberWithInt:_value];
}

- (NSString *)returnString {
  return [NSString stringWithFormat:@"%d", _value];
}

- (NSData *)returnData {
  return [NSMutableData dataWithLength:_value];
}

- (EDOTestDummy *)returnSelf {
  return self;
}

- (instancetype)returnDeepCopy {
  return [[EDOTestDummy alloc] initWithValue:self.value];
}

- (NSDictionary<NSString *, NSNumber *> *)returnDictionary {
  return @{ @"one" : @1, @"two" : @2, @"three" : @3, @"four" : @4 };
}

- (NSArray<NSNumber *> *)returnArray {
  return @[ @1, @2, @3, @4 ];
}

- (NSArray<NSNumber *> *)returnLargeArray {
  NSMutableArray<NSNumber *> *array = [[NSMutableArray alloc] initWithCapacity:kLargeArraySize];
  for (int i = 0; i < kLargeArraySize; i++) {
    [array addObject:@(i)];
  }
  return [array copy];
}

- (NSSet<NSNumber *> *)returnSet {
  return [NSSet setWithObjects:@1, @2, @3, @4, nil];
}

- (Class)returnClass {
  return [self class];
}

- (id)returnIdNil {
  return nil;
}

- (Protocol *)returnWithProtocolInApp {
  return @protocol(EDOTestProtocolInApp);
}

- (EDOTestDummy *)returnWeakDummy {
  return _weakDummyInTest;
}

- (EDOTestDummy *)weaklyHeldDummyForMemoryTest {
  EDOTestDummy *dummy = [[EDOTestDummy alloc] initWithValue:10];
  _weakDummyInTest = dummy;
  return dummy;
}

- (void (^)(void))returnBlock {
  static void (^sameBlock)(void) = ^{
  };
  return sameBlock;
}

- (NSString *)nameFromSelector:(SEL)selector {
  return NSStringFromSelector(selector);
}

- (SEL)selectorFromName:(NSString *)name {
  return NSSelectorFromString(name);
}

- (void)selWithThrow {
  [[self exceptionWithReason:@"Just Throw"] raise];
}

- (EDOTestDummyStruct)structWithStruct:(EDOTestDummyStruct)value {
  _value += value.value;
  return (EDOTestDummyStruct){.value = _value};
}

- (EDOTestDummy *)returnIdWithInt:(int)value {
  int oldValue = _value;
  _value += value * 2;
  return [[EDOTestDummy alloc] initWithValue:value + oldValue];
}

- (Class)classsWithClass:(Class)clz {
  return clz;
}

- (NSNumber *)returnNumberWithInt:(int)arg value:(NSNumber *)value {
  return [NSNumber numberWithInteger:arg + value.intValue + _value];
}

- (BOOL)returnBoolWithError:(NSError **)errorOrNil {
  if (!errorOrNil) {
    return NO;
  } else {
    *errorOrNil = [self error];
    return YES;
  }
}

- (NSString *)returnClassNameWithObject:(id)object {
  return NSStringFromClass(object_getClass(object));
}

- (NSString *)returnClassNameWithObjectRef:(id *)objRef {
  if (!objRef) {
    return nil;
  } else if (!*objRef) {
    return @"";
  } else {
    return NSStringFromClass(object_getClass(*objRef));
  }
}

- (NSInteger)returnCountWithArray:(NSArray *)value {
  return value.count;
}

- (NSInteger)returnSumWithArray:(NSArray *)value {
  NSInteger result = 0;
  for (NSNumber *number in value) {
    result += number.integerValue;
  }
  return result;
}

- (NSInteger)returnSumWithArrayAndProxyCheck:(NSArray *)value {
  NSAssert(!value.isProxy,
           @"This method is to test pass-by-value. The parameter should not be a proxy.");
  return [self returnSumWithArray:value];
}

- (UInt64)memoryAddressFromObject:(id)object {
  return (UInt64)(__bridge void *)object;
}

- (UInt64)memoryAddressFromObjectRef:(id *)objRef {
  return (UInt64)(__bridge void *)(*objRef);
}

- (NSException *)exceptionWithReason:(NSString *)reason {
  return [EDOTestDummyException
      exceptionWithName:[NSString stringWithFormat:@"Dummy %@ %d", reason, _value]
                 reason:reason
               userInfo:nil];
}

- (NSError *)error {
  return [NSError errorWithDomain:NSOSStatusErrorDomain code:self.value userInfo:nil];
}

+ (void)enumerateSelector:(void (^)(SEL selector))block {
  SEL allSelectors[] = {
      @selector(voidWithValuePlusOne),
      @selector(voidWithInt:),
      @selector(voidWithNumber:),
      @selector(voidWithString:data:),
      @selector(voidWithClass:),
      @selector(voidWithStruct:),
      @selector(voidWithId:),
      @selector(voidWithValueOut:),
      @selector(voidWithErrorOut:),
      @selector(voidWithOutObject:),
      @selector(voidWithValue:outSelf:),

      @selector(returnInt),
      @selector(returnStruct),
      @selector(returnNumber),
      @selector(returnString),
      @selector(returnData),
      @selector(returnSelf),
      @selector(returnDeepCopy),
      @selector(returnClass),
      @selector(returnDictionary),
      @selector(returnArray),
      @selector(returnSet),
      @selector(returnIdNil),

      @selector(selWithThrow),

      @selector(structWithStruct:),
      @selector(returnIdWithInt:),
      @selector(classsWithClass:),
      @selector(returnNumberWithInt:value:),
      @selector(returnBoolWithError:),
  };

  for (int i = 0; i < sizeof(allSelectors) / sizeof(SEL); ++i) {
    block(allSelectors[i]);
  }
}

#pragma mark - NSFastEnumeration

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained _Nullable[_Nonnull])buffer
                                    count:(NSUInteger)len {
  // Dummy implementation, not throw anything and succeed quietly.
  return 0;
}

#pragma mark - EDOTestProtocolInApp

- (NSString *)protocolName {
  return NSStringFromProtocol(@protocol(EDOTestProtocolInApp));
}

@end

@implementation EDOTestDummy (InTest)

- (int)callBackToTest:(EDOTestDummyInTest *)dummy withValue:(int)value {
  value += [dummy callTestDummy:self];
  return value + self.value;
}

- (int)selWithOutEDO:(EDOTestDummyInTest **)dummyOut dummy:(EDOTestDummyInTest *)dummyIn {
  NSAssert(NSClassFromString(@"EDOTestDummyInTest") == nil,
           @"EDOTestDummyInTest shouldn't be defined.");
  if (!dummyOut) {
    [[self exceptionWithReason:@"dummyOut is nil"] raise];
  } else {
    return (*dummyOut = [dummyIn makeAnotherDummy:self.value]).value.intValue;
  }
  return 0;
}

- (EDOTestDummyInTest *)selWithInOutEDO:(EDOTestDummyInTest **)dummyInOut {
  if (!dummyInOut) {
    [[self exceptionWithReason:@"DummyIn is nil"] raise];
    return nil;
  } else {
    return [*dummyInOut makeAnotherDummy:self.value];
  }
}

- (void)setDummInTest:(EDOTestDummyInTest *)dummyInTest withDummy:(EDOTestDummyInTest *)dummy {
  dummyInTest.dummyInTest = dummy;
}

- (EDOTestDummyInTest *)getRootObject:(UInt16)port {
  return [EDOClientService rootObjectWithPort:port];
}

- (EDOTestDummyInTest *)createEDOWithPort:(UInt16)port {
  EDOTestDummyInTest *dummyInTest = [EDOClientService rootObjectWithPort:port];
  // This returns a EDOObject.
  return [dummyInTest makeAnotherDummy:5];
}

- (int)returnPlus10AndAsyncExecuteBlock:(EDOTestDummyInTest *)dummyInTest {
  // Dispatch to the background queue to invoke the remote method to avoid the deadlock.
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [dummyInTest invokeBlock];
  });
  return self.value + 10;
}

@end
