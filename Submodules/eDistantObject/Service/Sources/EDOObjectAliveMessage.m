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

#import "Service/Sources/EDOObjectAliveMessage.h"

#import "Service/Sources/EDOBlockObject.h"
#import "Service/Sources/EDOHostService+Private.h"

static NSString *const kEDOObjectAliveCoderObjectKey = @"object";

#pragma mark -

@interface EDOObjectAliveRequest ()
// The proxy object that needs to check if its underlying object is alive. It could either be an
// EDOObject or block object.
@property(readonly) id object;
@end

#pragma mark -

@implementation EDOObjectAliveRequest

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (instancetype)initWithObject:(EDOObject *)object {
  self = [super init];
  if (self) {
    _object = object;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (self) {
    NSSet *objectClasses = [NSSet setWithObjects:[EDOBlockObject class], [EDOObject class], nil];
    _object = [aDecoder decodeObjectOfClasses:objectClasses forKey:kEDOObjectAliveCoderObjectKey];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:self.object forKey:kEDOObjectAliveCoderObjectKey];
}

+ (EDORequestHandler)requestHandler {
  return ^(EDOServiceRequest *request, EDOHostService *service) {
    EDOObjectAliveRequest *retainRequest = (EDOObjectAliveRequest *)request;
    EDOObject *object = [EDOBlockObject isBlock:retainRequest.object]
                            ? [EDOBlockObject EDOBlockObjectFromBlock:retainRequest.object]
                            : retainRequest.object;
    object = [service isObjectAlive:object] ? object : nil;
    return [EDOObjectAliveResponse responseWithObject:object forRequest:request];
  };
}

+ (instancetype)requestWithObject:(EDOObject *)object {
  return [[self alloc] initWithObject:object];
}

@end

#pragma mark -

@implementation EDOObjectAliveResponse

+ (BOOL)supportsSecureCoding {
  return YES;
}

@end
