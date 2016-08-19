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

#import <UIKit/UIKit.h>

#import <EarlGrey/GREYDefines.h>

typedef NS_ENUM(NSInteger, GREYCoderType) {
  kGREYCoderTypeGlobalBlock = 1,
  kGREYCoderTypeMallocBlock,
  kGREYCoderTypeFunction,
  kGREYCoderTypeCGFloat,
  kGREYCoderTypeCGPoint,
  kGREYCoderTypeNSInteger,
  kGREYCoderTypeNSUInteger,
  kGREYCoderTypeSelector,
  kGREYCoderTypeProtocol,
  kGREYCoderTypeClass,
  kGREYCoderTypeOut,
  kGREYCoderTypeObject,
};

@interface GREYCoder : NSObject

+ (BOOL)isInApplicationProcess;
+ (BOOL)isInXCTestProcess;

+ (NSString *)relativeEarlGreyPath;

+ (NSDictionary *)encodeObject:(id)object;
+ (NSDictionary *)encodeNSInteger:(NSInteger)value;
+ (NSDictionary *)encodeNSUInteger:(NSUInteger)value;
+ (NSDictionary *)encodeSelector:(SEL)selector;
+ (NSDictionary *)encodeFunction:(GREYExecFunction)function;
+ (NSDictionary *)encodeCGPoint:(CGPoint)value;
+ (NSDictionary *)encodeCGFloat:(CGFloat)value;
+ (NSDictionary *)encodeProtocol:(Protocol *)protocol;
+ (NSDictionary *)encodeOut:(out __strong id *)outObject;

+ (id)decodeObject:(NSDictionary *)dictionary;
+ (SEL)decodeSelector:(NSDictionary *)dictionary;
+ (NSInteger)decodeNSInteger:(NSDictionary *)dictionary;
+ (NSUInteger)decodeNSUInteger:(NSDictionary *)dictionary;
+ (GREYExecFunction)decodeFunction:(NSDictionary *)dictionary;
+ (CGPoint)decodeCGPoint:(NSDictionary *)dictionary;
+ (CGFloat)decodeCGFloat:(NSDictionary *)dictionary;
+ (Protocol *)decodeProtocol:(NSDictionary *)dictionary;
+ (out __strong id *)decodeOut:(NSDictionary *)dictionary;

@end
