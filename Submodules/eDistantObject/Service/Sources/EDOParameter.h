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
#import <objc/runtime.h>

#import "Service/Sources/EDOObject.h"

NS_ASSUME_NONNULL_BEGIN

/** Check if the given C-string type is an Id type. */
#define EDO_IS_OBJECT(__type) ((__type)[0] == _C_ID)
/** Check if the given C-string type is a class type. */
#define EDO_IS_CLASS(__type) ((__type)[0] == _C_CLASS && (__type)[1] == '\0')
/** Check if the given C-string type is an Id type or a class type. */
#define EDO_IS_OBJECT_OR_CLASS(__type) (EDO_IS_OBJECT(__type) || EDO_IS_CLASS(__type))
/** Check if the given C-string type is a pointer type that points to an Id. */
#define EDO_IS_OBJPOINTER(__type) \
  ((__type)[0] == _C_PTR && (__type)[1] == _C_ID && (__type)[2] == '\0')
/** Check if the given C-string type is a pointer type that points to any type. */
#define EDO_IS_POINTER(__type) ((__type)[0] == _C_PTR)
/** Check if the given C-string type is a selector type. */
#define EDO_IS_SELECTOR(__type) ((__type)[0] == _C_SEL)

/** The boxed value to serialize data and objects when transferring invocations. */
@interface EDOParameter : NSObject <NSSecureCoding>

/** The runtime type encoding for the boxed value. */
@property(nonatomic, readonly) NSString *valueObjCType;
/** The runtime type c-string encoding for the boxed value. */
@property(nonatomic, readonly) char const *objCType NS_RETURNS_INNER_POINTER;
/** The boxed value. */
@property(nonatomic, readonly, nullable) id<NSCoding> value;

- (instancetype)init NS_UNAVAILABLE;

/**
 *  Unbox the value to save it to the given buffer.
 *
 *  @note   It will not retain nor release any hold object.
 *  @param  buffer The buffer to save the value.
 */
- (void)getValue:(void *)buffer;

/** Create a EDOParameter with the given value and type encoding. */
+ (instancetype)parameterWithValue:(id<NSCoding> _Nullable)value objCType:(NSString *)objCType;

/** Create a EDOParameter with the buffer saving the data and type encoding for the data. */
+ (instancetype)parameterWithBytes:(void *_Nullable)bytes objCType:(const char *)objCType;

/** Create a EDOParameter with the @c object. */
+ (instancetype)parameterWithObject:(id<NSCoding>)object;

/** The placeholder for the value = nil. */
+ (instancetype)parameterForNilValue;

/** The placeholder for the double pointer value = nil, for example, NSError ** = nil. */
+ (instancetype)parameterForDoublePointerNullValue;

/**
 *  Check if the double pointer is nil.
 *
 *  When passing down a pointer to an object, the value will be coerced into the object itself:
 *  a) if the value is nullBoxedValue, the original pointer is nil;
 *  b) if the value is nilBoxedValue, the original pointer points to an address that's nil.
 *  c) if the value is an object, the original pointer points to that address, and the address is
 *     reconstructed in the local memory space.
 */
- (BOOL)isDoublePointerNullValue;

@end

NS_ASSUME_NONNULL_END
