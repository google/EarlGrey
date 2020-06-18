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

#import "Service/Sources/EDOBlockObject.h"

#include <objc/message.h>
#include <objc/runtime.h>

#import "Service/Sources/EDOObject+Private.h"

@class EDOServicePort;

static NSString *const kEDOBlockObjectCoderSignatureKey = @"signature";
static NSString *const kEDOBlockObjectCoderHasStretKey = @"hasStret";

/**
 *  The block structure defined in ABI here:
 *  https://clang.llvm.org/docs/Block-ABI-Apple.html#id2
 */
typedef struct EDOBlockHeader {
  void *isa;
  int flags;
  int reserved;
  void (*invoke)(void);  // The block implementation, which is either _objc_msgForward or
                         // _objc_msgForward_stret to trigger message forwarding.
  struct {
    unsigned long int reserved;
    unsigned long int size;
    union {
      struct {
        // Optional helper functions
        void (*copy_helper)(void *dst, void *src);  // IFF (flag & 1<<25)
        void (*dispose_helper)(void *src);          // IFF (flag & 1<<25)
        const char *signature;
      } helper;
      // Required ABI.2010.3.16
      const char *signature;  // IFF (flag & 1<<30)
    };
  } * descriptor;
  // Captured variables by the block.
  // Note: The order of imported variables are not defined in ABI, but we only have one
  // EDOBlockObject imported.
  id __unsafe_unretained object;
} EDOBlockHeader;

/** The enums for the block flag. */
typedef NS_ENUM(NSUInteger, EDOBlockFlags) {
  EDOBlockFlagsHasCopyDispose = (1 << 25),  // If the block has copy and dispose function pointer.
  EDOBlockFlagsIsGlobal = (1 << 28),        // If the block is a global block.
  EDOBlockFlagsHasStret = (1 << 29),        // If we should use _stret calling convention.
  EDOBlockFlagsHasSignature = (1 << 30)     // If the signature is filled.
};

/* Get @c NSBlock class. */
static Class GetBlockBaseClass() {
  static Class blockClass;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    blockClass = NSClassFromString(@"NSBlock");
    NSCAssert(blockClass, @"Couldn't load NSBlock class.");
  });
  return blockClass;
}

/** Check if the @c block has struct returns. */
static BOOL HasStructReturnForBlock(id block) {
  EDOBlockHeader *blockHeader = (__bridge EDOBlockHeader *)block;
  return (blockHeader->flags & EDOBlockFlagsHasStret) != 0;
}

@implementation EDOBlockObject

+ (BOOL)supportsSecureCoding {
  return YES;
}

+ (BOOL)isBlock:(id)object {
  if ([object isProxy]) {
    return NO;
  }

  // We use runtime primitive APIs to go through the class hierarchy in case any subclass to
  // override -[isKindOfClass:] and cause unintended behaviours, i.e. OCMock.
  Class blockClass = GetBlockBaseClass();
  Class objClass = object_getClass(object);
  while (objClass) {
    if (objClass == blockClass) {
      return YES;
    }
    objClass = class_getSuperclass(objClass);
  }
  return NO;
}

+ (EDOBlockObject *)EDOBlockObjectFromBlock:(id)block {
  EDOBlockHeader *header = (__bridge EDOBlockHeader *)block;
#if !defined(__arm64__)
  if (header->invoke == (void (*)(void))_objc_msgForward ||
      header->invoke == (void (*)(void))_objc_msgForward_stret) {
    return header->object;
  }
#else
  if (header->invoke == (void (*)(void))_objc_msgForward) {
    return header->object;
  }
#endif
  return nil;
}

+ (char const *)signatureFromBlock:(id)block {
  EDOBlockHeader *blockHeader = (__bridge EDOBlockHeader *)block;
  NSCAssert(blockHeader->flags & EDOBlockFlagsHasSignature, @"The block doesn't have signature.");
  if (blockHeader->flags & EDOBlockFlagsHasCopyDispose) {
    return blockHeader->descriptor->helper.signature;
  } else {
    return blockHeader->descriptor->signature;
  }
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (self) {
    _signature = [aDecoder decodeObjectOfClass:[NSString class]
                                        forKey:kEDOBlockObjectCoderSignatureKey];
    _returnsStruct = [aDecoder decodeBoolForKey:kEDOBlockObjectCoderHasStretKey];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:self.signature forKey:kEDOBlockObjectCoderSignatureKey];
  [aCoder encodeBool:self.returnsStruct forKey:kEDOBlockObjectCoderHasStretKey];
}

// When we decode it, we swap with the actual block object so the receiver can invoke on it.
- (id)awakeAfterUsingCoder:(NSCoder *)aDecoder {
  void (^dummy)(void) = ^{
    // Capture self, the @c EDOBlockObject, to associate it with the block so we can retrieve it
    // later.
    [self class];
  };
  // Move the block from the stack to the heap.
  dummy = [dummy copy];
  EDOBlockHeader *header = (__bridge EDOBlockHeader *)dummy;
  header->invoke = (void (*)(void))_objc_msgForward;
#if !defined(__arm64__)
  if (self.returnsStruct) {
    header->invoke = (void (*)(void))_objc_msgForward_stret;
  }
#endif

  // Swap the ownership: the unarchiver retains `self` and autoreleases the `dummy` block. Here we
  // capture self within the `dummy` block, replace `self` with the `dummy` block. This
  // effectively transfers the ownership of dummy to the caller of the unarchiver.
  CFBridgingRelease((__bridge void *)self);
  return (__bridge id)CFBridgingRetain(dummy);
}

- (instancetype)edo_initWithLocalObject:(id)target port:(EDOServicePort *)port {
  // object is self. This does the same as self = [super initWithLocalObject:target port:port], but
  // because we have the prefix to avoid the naming collisions, the compiler complains assigning
  // self in a non-init method.
  EDOBlockObject *object = [super edo_initWithLocalObject:target port:port];

  _returnsStruct = HasStructReturnForBlock(target);
  _signature = [NSString stringWithUTF8String:[EDOBlockObject signatureFromBlock:target]];
  return object;
}

@end
