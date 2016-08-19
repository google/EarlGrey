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

#import "GREYCoder.h"

#include <dlfcn.h>
#include <mach-o/dyld.h>
#include <objc/runtime.h>

#import "Additions/CGGeometry+GREYAdditions.h"
#import "Assertion/GREYAssertionDefines.h"
#import "Common/GREYExposed.h"

static const size_t kMaxBlockSize = 128;

@implementation GREYCoder

+ (NSDictionary *)encodeObject:(id)object {
  if (object_isClass(object)) {
    return @{ @"type" : @(kGREYCoderTypeClass), @"string" : NSStringFromClass(object) };
  } else if ([NSStringFromClass([object class]) isEqualToString:@"__NSGlobalBlock__"] ||
             [NSStringFromClass([object class]) isEqualToString:@"__NSMallocBlock__"]) {
    struct Block_layout *blockPtr = (__bridge struct Block_layout *)object;
    NSAssert(!(blockPtr->flags & BLOCK_HAS_COPY_DISPOSE),
             @"Blocks that must be encoded may not capture any objects.");

    Dl_info dl_info;
    int result = dladdr(blockPtr->descriptor, &dl_info);
    NSAssert(result != 0, @"failed getting address info");

    NSString *path = [NSString stringWithCString:dl_info.dli_fname encoding:NSUTF8StringEncoding];
    NSString *relativePath = nil;
    if ([path hasSuffix:@"/EarlGrey.framework/EarlGrey"]) {
      relativePath = [self relativeEarlGreyPath];
    } else if ([path containsString:@".xctest/"]) {
      relativePath = [self grey_relativeXCTestPluginPath];
    } else {
      NSAssert(NO, @"unexpected filename when encoding block");
    }
    if ([NSStringFromClass([object class]) isEqualToString:@"__NSGlobalBlock__"]) {
      return @{ @"type"         : @(kGREYCoderTypeGlobalBlock),
                @"path"         : path,
                @"relativePath" : relativePath,
                @"slide"        : [NSData dataWithBytes:&dl_info.dli_fbase length:sizeof(intptr_t)],
                @"pointer"      : [NSData dataWithBytes:&blockPtr length:sizeof(intptr_t)]};
    } else if ([NSStringFromClass([object class]) isEqualToString:@"__NSMallocBlock__"]) {
      return @{ @"type"         : @(kGREYCoderTypeMallocBlock),
                @"path"         : path,
                @"relativePath" : relativePath,
                @"slide"        : [NSData dataWithBytes:&dl_info.dli_fbase length:sizeof(intptr_t)],
                @"data"         : [NSData dataWithBytes:blockPtr length:blockPtr->descriptor->size],
                @"size"         : [NSData dataWithBytes:&(blockPtr->descriptor->size)
                                                 length:sizeof(unsigned long int)]};
    } else {
      NSAssert(NO, @"not a supported block type: %@", object);
      return nil;
    }
  } else {
    return object ? @{ @"type" : @(kGREYCoderTypeObject), @"object" : object } : @{ @"type" : @(kGREYCoderTypeObject) };
  }
}

+ (id)decodeObject:(NSDictionary *)dictionary {
  NSParameterAssert(dictionary);

  GREYCoderType type = [[dictionary objectForKey:@"type"] integerValue];
  switch (type) {
    case kGREYCoderTypeClass:
      return NSClassFromString(dictionary[@"string"]);
    case kGREYCoderTypeGlobalBlock:
    case kGREYCoderTypeMallocBlock: {
      intptr_t newSlide = [self grey_slideForExecutableWithPath:dictionary[@"relativePath"]];
      if (newSlide == 0) {
        newSlide = [self grey_slideForExecutableWithPath:dictionary[@"path"]];
        if (newSlide == 0) {
          NSAssert(NO, @"couldn't get the slide of executable with path: %@", dictionary[@"path"]);
        }
      }
      intptr_t slide;
      [dictionary[@"slide"] getBytes:&slide length:sizeof(intptr_t)];

      if (type == kGREYCoderTypeGlobalBlock) {
        struct Block_layout *block;
        [dictionary[@"pointer"] getBytes:&block length:sizeof(intptr_t)];
        return (__bridge id)(struct Block_layout *)((intptr_t)block - slide + newSlide);
      } else if (type == kGREYCoderTypeMallocBlock) {
        unsigned long int blockSize;
        [dictionary[@"size"] getBytes:&blockSize length:sizeof(unsigned long int)];
        NSAssert(blockSize < kMaxBlockSize, @"increase block size constant");

        // Copy block data to the stack.
        char blockData[kMaxBlockSize];
        [dictionary[@"data"] getBytes:blockData length:blockSize];
        struct Block_layout *block = (struct Block_layout *)&blockData;
        // Change to a valid stack block.
        block->isa = _NSConcreteStackBlock;
        block->flags &= ~(BLOCK_REFCOUNT_MASK);
        block->flags &= ~(BLOCK_NEEDS_FREE);
        block->invoke = block->invoke - slide + newSlide;
        block->descriptor = (struct Block_descriptor *)((intptr_t)block->descriptor - slide + newSlide);
        // Copy to the heap and return.
        return [(__bridge id)block copy];
      }
      NSAssert(NO, @"should never happen");
      return nil;
    }
    case kGREYCoderTypeObject:
      return dictionary[@"object"];
    default:
      NSAssert(NO, @"not a valid object type");
      return nil;
  }
}

+ (NSDictionary *)encodeFunction:(GREYExecFunction)function {
  NSParameterAssert(function != NULL);

  NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
  Dl_info dl_info;
  int result = dladdr(function, &dl_info);
  NSAssert(result != 0, @"failed getting address info");

  dictionary[@"path"] = [NSString stringWithCString:dl_info.dli_fname
                                           encoding:NSUTF8StringEncoding];
  if ([dictionary[@"path"] hasSuffix:@"/EarlGrey.framework/EarlGrey"]) {
    dictionary[@"relativePath"] = [self relativeEarlGreyPath];
  } else if ([dictionary[@"path"] containsString:@".xctest/"]) {
    dictionary[@"relativePath"] = [self grey_relativeXCTestPluginPath];
  } else {
    NSAssert(NO, @"unexpected file name");
  }
  dictionary[@"slide"] = [NSData dataWithBytes:&dl_info.dli_fbase length:sizeof(intptr_t)];
  dictionary[@"pointer"] = [NSData dataWithBytes:&function length:sizeof(intptr_t)];
  dictionary[@"type"] = @(kGREYCoderTypeFunction);
  return dictionary;
}

+ (GREYExecFunction)decodeFunction:(NSDictionary *)dictionary {
  NSParameterAssert(dictionary);
  NSParameterAssert([dictionary[@"type"] integerValue] == kGREYCoderTypeFunction);

  intptr_t newSlide = [self grey_slideForExecutableWithPath:dictionary[@"relativePath"]];
  if (newSlide == 0) {
    newSlide = [self grey_slideForExecutableWithPath:dictionary[@"path"]];
    if (newSlide == 0) {
      NSAssert(NO, @"couldn't get the slide of executable with path: %@", dictionary[@"path"]);
    }
  }
  intptr_t slide;
  [dictionary[@"slide"] getBytes:&slide length:sizeof(intptr_t)];
  GREYExecFunction function;
  [dictionary[@"pointer"] getBytes:&function length:sizeof(intptr_t)];
  return function - slide + newSlide;
}

+ (NSDictionary *)encodeCGPoint:(CGPoint)value {
  return @{ @"type" : @(kGREYCoderTypeCGPoint), @"string" : NSStringFromCGPoint(value) };
}

+ (CGPoint)decodeCGPoint:(NSDictionary *)dictionary {
  NSParameterAssert(dictionary);
  NSParameterAssert([dictionary[@"type"] integerValue] == kGREYCoderTypeCGPoint);

  NSString *string = dictionary[@"string"];
  return [string isEqualToString:@"{nan, nan}"] ? GREYCGPointNull : CGPointFromString(string);
}

+ (NSDictionary *)encodeNSInteger:(NSInteger)value {
  return @{ @"type" : @(kGREYCoderTypeNSInteger),
            @"data" : [NSData dataWithBytes:&value length:sizeof(NSInteger)] };
}

+ (NSInteger)decodeNSInteger:(NSDictionary *)dictionary {
  NSParameterAssert(dictionary);
  NSParameterAssert([dictionary[@"type"] integerValue] == kGREYCoderTypeNSInteger);

  NSInteger value;
  [dictionary[@"data"] getBytes:&value length:sizeof(NSInteger)];
  return value;
}

+ (NSDictionary *)encodeNSUInteger:(NSUInteger)value {
  return @{ @"type" : @(kGREYCoderTypeNSUInteger),
            @"data" : [NSData dataWithBytes:&value length:sizeof(NSUInteger)] };
}

+ (NSUInteger)decodeNSUInteger:(NSDictionary *)dictionary {
  NSParameterAssert(dictionary);
  NSParameterAssert([dictionary[@"type"] integerValue] == kGREYCoderTypeNSUInteger);

  NSUInteger value;
  [dictionary[@"data"] getBytes:&value length:sizeof(NSUInteger)];
  return value;
}

+ (NSDictionary *)encodeCGFloat:(CGFloat)value {
  return @{ @"type" : @(kGREYCoderTypeCGFloat),
            @"data" : [NSData dataWithBytes:&value length:sizeof(CGFloat)] };
}

+ (CGFloat)decodeCGFloat:(NSDictionary *)dictionary {
  NSParameterAssert(dictionary);
  NSParameterAssert([dictionary[@"type"] integerValue] == kGREYCoderTypeCGFloat);

  CGFloat value;
  [dictionary[@"data"] getBytes:&value length:sizeof(CGFloat)];
  return value;
}

+ (NSDictionary *)encodeSelector:(SEL)selector {
  return @{ @"type" : @(kGREYCoderTypeSelector), @"string" : NSStringFromSelector(selector) };
}

+ (SEL)decodeSelector:(NSDictionary *)dictionary {
  NSParameterAssert(dictionary);
  NSParameterAssert([dictionary[@"type"] integerValue] == kGREYCoderTypeSelector);
  
  return NSSelectorFromString(dictionary[@"string"]);
}

+ (NSDictionary *)encodeProtocol:(Protocol *)protocol {
  return @{ @"type" : @(kGREYCoderTypeProtocol), @"string" : NSStringFromProtocol(protocol) };
}

+ (Protocol *)decodeProtocol:(NSDictionary *)dictionary {
  NSParameterAssert(dictionary);
  NSParameterAssert([dictionary[@"type"] integerValue] == kGREYCoderTypeProtocol);
  
  return NSProtocolFromString(dictionary[@"string"]);
}

+ (NSDictionary *)encodeOut:(out __strong id *)outObject {
  id encoded = outObject ? [NSData dataWithBytes:outObject length:sizeof(intptr_t)] : [NSNull null];
  return @{ @"type" : @(kGREYCoderTypeOut), @"pointer" : encoded, @"isNil" : @(!outObject)};
}

+ (out __strong id *)decodeOut:(NSDictionary *)dictionary {
  NSParameterAssert(dictionary);
  NSParameterAssert([dictionary[@"type"] integerValue] == kGREYCoderTypeOut);
  
  if([[dictionary objectForKey:@"isNil"] boolValue]) {
    return nil;
  } else {
    NSAssert(NO, @"TODO: not implemented");
    return nil;
  }
}

+ (BOOL)isInApplicationProcess {
  static BOOL value = NO;
  static dispatch_once_t token = 0;
  dispatch_once(&token, ^{
    value = ![[[NSProcessInfo processInfo] processName] isEqualToString:@"XCTRunner"];
  });
  return value;
}

+ (BOOL)isInXCTestProcess {
  static BOOL value = NO;
  static dispatch_once_t token = 0;
  dispatch_once(&token, ^{
    // Odd: autoreleasepool is required here to prevent a crashes in autoreleasepool pop when
    // when exceptions are thrown.
    @autoreleasepool {
      NSDictionary *environmentVars = [[NSProcessInfo processInfo] environment];
      NSAssert(environmentVars, @"should not be nil");
      value = ([environmentVars objectForKey:@"XCTestConfigurationFilePath"] != nil);
    }
  });
  return value;
}

+ (NSString *)relativeEarlGreyPath {
  I_CHECK_XCTEST_PROCESS();

  NSString *pluginPath = [self grey_relativeXCTestPluginPath];
  NSString *basePath = [pluginPath stringByDeletingLastPathComponent];
  return [basePath stringByAppendingPathComponent:@"EarlGrey.framework/EarlGrey"];
}

#pragma mark - Private

+ (NSString *)grey_relativeXCTestPluginPath {
  I_CHECK_XCTEST_PROCESS();

  NSString *absolutePath = [self grey_absoluteXCTestPluginPath];
  NSMutableArray *pathComponents = [NSMutableArray arrayWithArray:[absolutePath pathComponents]];
  [pathComponents removeObjectsInRange:NSMakeRange(0, [pathComponents count] - 4)];
  [pathComponents replaceObjectAtIndex:0 withObject:@"@executable_path"];
  return [NSString pathWithComponents:pathComponents];
}

+ (NSString *)grey_absoluteXCTestPluginPath {
  I_CHECK_XCTEST_PROCESS();

  for (NSBundle *bundle in [NSBundle allBundles]) {
    if ([[bundle executablePath] containsString:@".xctest/"]) {
      return [bundle executablePath];
    }
  }
  NSAssert(NO, @"couldn't find XCTest plugin");
  return nil;
}

+ (intptr_t)grey_slideForExecutableWithPath:(NSString *)path {
  NSParameterAssert(path);

  const char *pathCString = [path cStringUsingEncoding:NSUTF8StringEncoding];
  NSAssert(pathCString, @"encoding failed");

  // If the path is not for EarlGrey, we may need to dlopen the executable. This should only be
  // allowed in a remote application process. We use RTLD_LOCAL, because DYLD just needs to load
  // this executable into memory, there is no need to expose the symbols to other executables.
  // TODO: Only allow EarlGrey (which should never be loaded here) and XCTest plugin.
  if (![path hasSuffix:@"/EarlGrey.framework/EarlGrey"] &&
      ![self isInXCTestProcess] &&
      !dlopen(pathCString, RTLD_LOCAL | RTLD_LAZY)) {
    return 0;
  }
  NSArray *pathComponents = [path pathComponents];
  for (uint32_t img = 0; img < _dyld_image_count(); img++) {
    NSArray *imgPathComponents = [[NSString stringWithCString:_dyld_get_image_name(img)
                                                     encoding:NSUTF8StringEncoding] pathComponents];
    // The last 2 components must be compared to ensure the path (if it is relative) is the same as
    // the absolute path from the DYLD image.
    BOOL last2Equal = YES;
    for (unsigned long part = 1; part <= 2; part++) {
      NSString *newComponent = pathComponents[[pathComponents count] - part];
      NSString *imageComponent = imgPathComponents[[imgPathComponents count] - part];
      if (![newComponent isEqualToString:imageComponent]) {
        last2Equal = NO;
        break;
      }
    }
    if (last2Equal) {
      return _dyld_get_image_vmaddr_slide(img);
    }
  }
  return 0;
}

@end
