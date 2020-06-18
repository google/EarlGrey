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

#import "Service/Sources/NSObject+EDOParameter.h"

#include <objc/runtime.h>

#import "Channel/Sources/EDOHostPort.h"
#import "Service/Sources/EDOHostService+Private.h"
#import "Service/Sources/EDOParameter.h"
#import "Service/Sources/EDOProtocolObject.h"
#import "Service/Sources/NSObject+EDOValue.h"

// Create a static protocol class.
static Class GetProtocolClass() {
  static Class protocolClass = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    protocolClass = NSClassFromString(@"Protocol");
  });
  NSCAssert(protocolClass != nil, @"protocolClass was nil");
  return protocolClass;
}

@implementation NSObject (EDOParameter)

- (EDOParameter *)edo_parameterForTarget:(EDOObject *)target
                                 service:(EDOHostService *)service
                                hostPort:(EDOHostPort *)hostPort {
  id boxedObject = self;

  if ([boxedObject class] == GetProtocolClass()) {
    boxedObject = [[EDOProtocolObject alloc] initWithProtocol:boxedObject];
  } else if (![boxedObject edo_isEDOValueType]) {
    // TODO(haowoo): Add the proper handler.
    NSAssert(service, @"The service isn't set up to create the remote object.");

    // Wrap it with EDOObject from the service associated with the execution queue.
    boxedObject = [service distantObjectForLocalObject:self hostPort:hostPort];
  }
  return [EDOParameter parameterWithObject:boxedObject];
}

@end
