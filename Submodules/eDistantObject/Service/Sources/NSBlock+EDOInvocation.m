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
#include <objc/runtime.h>

#import "Channel/Sources/EDOHostPort.h"
#import "Service/Sources/EDOBlockObject.h"
#import "Service/Sources/EDOHostService+Private.h"
#import "Service/Sources/EDOObject+Private.h"
#import "Service/Sources/EDOParameter.h"

/** Expose the private class interface. */
@interface NSBlock : NSObject
+ (Class)class;
@end

/**
 *  Adding forwardInvocation: and methodSignatureForSelector: to NSBlock so when _objc_msgForward
 *  is attempting to recover from the failure, we can capture the invocation to reconstruct the
 *  call stack.
 */
@implementation NSBlock (EDOInvocation)

__attribute__((constructor)) static void SetupBlockInvocationForward() {
  IMP forwardInvocationImp = imp_implementationWithBlock(^(id block, NSInvocation *invocation) {
    EDOBlockObject *blockObject = [EDOBlockObject EDOBlockObjectFromBlock:block];
    NSCAssert(blockObject, @"No block object to forward.");
    [blockObject edo_forwardInvocation:invocation selector:nil returnByValue:NO];
  });
  BOOL forwardInvocationAdded =
      class_addMethod([NSBlock class], @selector(forwardInvocation:), forwardInvocationImp, "v@:@");
  if (!forwardInvocationAdded) {
    // TODO(haowoo): Convert this and below into macros/methods.
    NSLog(@"Failed to add forwardInvocation:.");
    abort();
  }

  IMP methodSignatureImp = imp_implementationWithBlock(^(id block, SEL selector) {
    EDOBlockObject *blockObject = [EDOBlockObject EDOBlockObjectFromBlock:block];
    if (blockObject) {
      return [NSMethodSignature signatureWithObjCTypes:blockObject.signature.UTF8String];
    } else {
      return [NSMethodSignature signatureWithObjCTypes:[EDOBlockObject signatureFromBlock:block]];
    }
  });
  BOOL methodSignatureAdded = class_addMethod(
      [NSBlock class], @selector(methodSignatureForSelector:), methodSignatureImp, "v@::");
  if (!methodSignatureAdded) {
    NSLog(@"Failed to add methodSignatureForSelector:.");
    abort();
  }
}

- (EDOParameter *)edo_parameterForTarget:(EDOObject *)target
                                 service:(EDOHostService *)service
                                hostPort:(EDOHostPort *)hostPort {
  EDOBlockObject *blockObject = [EDOBlockObject EDOBlockObjectFromBlock:self];
  return [EDOParameter parameterWithObject:blockObject
                                               ?: [service distantObjectForLocalObject:self
                                                                              hostPort:hostPort]];
}

@end
