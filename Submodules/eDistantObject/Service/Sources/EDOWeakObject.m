//
// Copyright 2019 Google LLC.
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

#import "Service/Sources/EDOWeakObject.h"

#include <objc/runtime.h>

#import "Service/Sources/EDOBlockObject.h"
#import "Service/Sources/EDODeallocationTracker.h"
#import "Service/Sources/EDOHostService+Private.h"
#import "Service/Sources/EDOParameter.h"
#import "Service/Sources/EDOServiceException.h"
#import "Service/Sources/EDOServicePort.h"
#import "Service/Sources/NSProxy+EDOParameter.h"

@implementation EDOWeakObject

- (instancetype)initWithWeakObject:(id)weakObject {
  if ([EDOBlockObject isBlock:weakObject]) {
    // TODO(b/138126290): Currently, RemoteWeak doesn't support block weak references.
    [[NSException exceptionWithName:EDOWeakReferenceBlockObjectException
                             reason:@"RemoteWeak doesn't support weak references for block object."
                           userInfo:nil] raise];
  }
  _weakObject = weakObject;
  return self;
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
  return _weakObject;
}

#pragma mark - NSProxy

- (void)forwardInvocation:(NSInvocation *)invocation {
  NSAssert(NO, @"ForwardInvocation for nil weak object should never be reached.");
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
  NSAssert(_weakObject == nil, @"The weak object has been released.");
  NSString *reasonForException =
      [NSString stringWithFormat:@"The underlying object has been released while "
                                 @"remote referenced weakly for selector %@.",
                                 NSStringFromSelector(sel)];
  [[NSException exceptionWithName:EDOWeakObjectWeakReleaseException
                           reason:reasonForException
                         userInfo:nil] raise];
  return nil;
}

#pragma mark - EDOParameter

- (EDOParameter *)edo_parameterForTarget:(EDOObject *)target
                                 service:(EDOHostService *)service
                                hostPort:(EDOHostPort *)hostPort {
  EDOParameter *parameter = [super edo_parameterForTarget:target service:service hostPort:hostPort];
  if ([[target class] isEqual:[EDOObject class]]) {
    [EDODeallocationTracker enableTrackingForObject:self hostPort:target.servicePort.hostPort];
  }
  return parameter;
}

@end
