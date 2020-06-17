//
// Copyright 2019 Google Inc.
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
#import "Service/Sources/NSObject+EDOBlacklistedType.h"

#include <objc/runtime.h>

#import "Channel/Sources/EDOHostPort.h"
#import "Service/Sources/EDOHostService.h"
#import "Service/Sources/EDOObject.h"
#import "Service/Sources/EDOServiceException.h"
#import "Service/Sources/NSObject+EDOParameter.h"

@implementation NSObject (EDOBlacklistedType)

+ (void)edo_disallowRemoteInvocation {
  @synchronized(self.class) {
    if (self.edo_remoteInvocationDisallowed) {
      return;
    }
    SEL originalSelector = @selector(edo_parameterForTarget:service:hostPort:);
    Method originalMethod = class_getInstanceMethod(self, originalSelector);
    void (^impBlock)(id obj, EDOObject *target, EDOHostService *service, EDOHostPort *port) = ^(
        id obj, EDOObject *target, EDOHostService *service, EDOHostPort *port) {
      NSString *reason =
          [NSString stringWithFormat:@"%@ instance is not allowed to be part of remote invocation",
                                     NSStringFromClass([self class])];
      [[NSException exceptionWithName:EDOParameterTypeException reason:reason userInfo:nil] raise];
    };
    IMP newImp = imp_implementationWithBlock(impBlock);
    if (!class_addMethod(self, originalSelector, newImp, method_getTypeEncoding(originalMethod))) {
      method_setImplementation(originalMethod, newImp);
    }
    objc_setAssociatedObject(self, @selector(edo_remoteInvocationDisallowed), @(YES),
                             OBJC_ASSOCIATION_RETAIN);
  }
}

+ (BOOL)edo_remoteInvocationDisallowed {
  return objc_getAssociatedObject(self, @selector(edo_remoteInvocationDisallowed)) != nil;
}

@end
