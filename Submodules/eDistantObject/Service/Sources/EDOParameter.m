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

#import "Service/Sources/EDOParameter.h"

#import "Service/Sources/EDOBlockObject.h"
#import "Service/Sources/EDOObject+Private.h"
#import "Service/Sources/EDOObject.h"

static NSString *const kObjCIdType = @"@";
static NSString *const kObjCSelectorType = @":";
static NSString *const kEDOParameterCoderValueKey = @"value";
static NSString *const kEDOParameterCoderTypeKey = @"type";

#pragma mark -

/** The placeholder type to save the NULL pointer that points to an object. */
@interface EDONull : NSObject <NSSecureCoding>
@end

@implementation EDONull

+ (BOOL)supportsSecureCoding {
  return YES;
}

/// TODO(haowoo): This will not be needed if use EDOParameter.
- (void)encodeWithCoder:(NSCoder *)aCoder {
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [super init];
  return self;
}

@end

#pragma mark -

@implementation EDOParameter

+ (BOOL)supportsSecureCoding {
  return YES;
}

+ (instancetype)parameterWithValue:(id<NSCoding>)value objCType:(NSString *)objCType {
  return [[self alloc] initWithValue:value objCType:objCType];
}

+ (instancetype)parameterWithBytes:(void *)bytes objCType:(const char *)objCType {
  if (EDO_IS_OBJECT_OR_CLASS(objCType)) {
    id<NSCoding> __strong *value = (id<NSCoding> __strong *)bytes;
    return [self parameterWithValue:*(value) objCType:kObjCIdType];
  } else if (EDO_IS_SELECTOR(objCType)) {
    SEL selector = *(SEL *)bytes;
    return [self parameterWithValue:NSStringFromSelector(selector) objCType:kObjCSelectorType];
  } else {
    NSUInteger typeSize = 0L;
    NSGetSizeAndAlignment(objCType, &typeSize, NULL);
    return [self parameterWithValue:(bytes ? [NSData dataWithBytes:bytes length:typeSize] : nil)
                           objCType:[NSString stringWithUTF8String:objCType]];
  }
}

+ (instancetype)parameterWithObject:(id<NSCoding>)object {
  return [self parameterWithValue:object objCType:@"@"];
}

+ (instancetype)parameterForNilValue {
  static EDOParameter *kNilValue;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    kNilValue = [self parameterWithValue:nil objCType:kObjCIdType];
  });
  return kNilValue;
}

+ (instancetype)parameterForDoublePointerNullValue {
  static EDOParameter *kNullPointerValue;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    kNullPointerValue = [self parameterWithValue:[[EDONull alloc] init] objCType:kObjCIdType];
  });
  return kNullPointerValue;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [super init];
  if (self) {
    // EDOParameter can carry any type of object as long as it's serializable, so it whitelists all
    // the types inheriting from NSObject. EDOObject and EDOBlockObject are NSProxy's and need to be
    // whitelisted as well.
    NSSet *anyClasses =
        [NSSet setWithObjects:[EDOBlockObject class], [EDOObject class], [NSObject class], nil];
    _value = [aDecoder decodeObjectOfClasses:anyClasses forKey:kEDOParameterCoderValueKey];
    _valueObjCType = [aDecoder decodeObjectOfClass:[NSString class]
                                            forKey:kEDOParameterCoderTypeKey];
  }
  return self;
}

- (instancetype)initWithValue:(id<NSCoding>)value objCType:(NSString *)objCType {
  self = [super init];
  if (self) {
    _value = value;
    _valueObjCType = objCType;
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:self.value forKey:kEDOParameterCoderValueKey];
  [aCoder encodeObject:self.valueObjCType forKey:kEDOParameterCoderTypeKey];
}

- (char const *)objCType {
  return self.valueObjCType.UTF8String;
}

- (void)getValue:(void *)buffer {
  char const *ctype = self.objCType;
  if (EDO_IS_OBJECT_OR_CLASS(ctype)) {
    NSAssert(sizeof(id) == sizeof(Class), @"The buffer is not suitable for both Id and Class.");
    memcpy(buffer, (void *)&_value, sizeof(id));
  } else if (EDO_IS_SELECTOR(ctype)) {
    SEL selector = NSSelectorFromString((NSString *)self.value);
    memcpy(buffer, (void *)&selector, sizeof(SEL));
  } else {
    NSData *value = (NSData *)self.value;

    NSUInteger typeSize = 0L;
    NSGetSizeAndAlignment(ctype, &typeSize, NULL);
    NSAssert(!value || typeSize == value.length, @"The buffer size is incorrect.");
    [value getBytes:buffer length:value.length];
  }
}

- (BOOL)isDoublePointerNullValue {
  static Class kNullClass;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    kNullClass = [EDONull class];
  });

  id __unsafe_unretained value;
  [self getValue:&value];
  return [[value class] isEqual:kNullClass];
}

@end
