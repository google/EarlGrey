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

#import "Service/Sources/EDOValueObject.h"

#include <objc/runtime.h>

#import "Service/Sources/EDOObject+Private.h"

@implementation EDOValueObject

- (instancetype)initWithRemoteObject:(EDOObject *)remoteObject {
  _remoteObject = remoteObject;
  _localObject = nil;
  return self;
}

- (instancetype)initWithLocalObject:(id<NSCoding>)localObject {
  NSAssert(object_getClass(localObject) != [EDOObject class],
           @"Using remote object as local object.");
  _remoteObject = nil;
  _localObject = localObject;
  return self;
}

/**
 *  forwardingTargetForSelector will be triggered firstly when unrecognized message is sent to
 *  the target. If _localObject is nil, it will fallback to methodSignatureForSelector and
 *  forwardInvocation.
 */
- (id)forwardingTargetForSelector:(SEL)aSelector {
  return _localObject;
}

// Keep the original behavior when nested pass-by-value is called.
- (id)passByValue {
  return self;
}

// Keep the original behavior when nested return-by-value is called.
- (id)returnByValue {
  return self;
}

- (NSString *)description {
  return [_remoteObject description];
}

#pragma mark - NSProxy

- (void)forwardInvocation:(NSInvocation *)invocation {
  NSAssert(_localObject == nil, @"The EDOValueObject should not wrap a local object in this case.");
  [_remoteObject edo_forwardInvocation:invocation selector:invocation.selector returnByValue:YES];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
  NSAssert(_localObject == nil, @"The EDOValueObject should not wrap a local object in this case.");
  return [_remoteObject methodSignatureForSelector:sel];
}

@end
