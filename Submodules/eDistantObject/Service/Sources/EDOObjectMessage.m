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

#import "Service/Sources/EDOObjectMessage.h"

#import "Channel/Sources/EDOHostPort.h"
#import "Service/Sources/EDOHostService+Private.h"

static NSString *const kEDOObjectCoderObjectKey = @"object";
static NSString *const kEDOObjectCoderHostPortKey = @"hostPort";

#pragma mark -

@interface EDOObjectRequest ()

@property(readonly) EDOHostPort *hostPort;

@end

@implementation EDOObjectRequest

// Only the type placeholder, don't need to override the [initWithCoder:] and [encodeWithCoder:]

+ (EDORequestHandler)requestHandler {
  return ^(EDOServiceRequest *request, EDOHostService *service) {
    EDOObject *object =
        [service distantObjectForLocalObject:service.rootLocalObject
                                    hostPort:((EDOObjectRequest *)request).hostPort];
    return [EDOObjectResponse responseWithObject:object forRequest:request];
  };
}

+ (instancetype)requestWithHostPort:(EDOHostPort *)hostPort {
  return [[self alloc] initWithHostPort:hostPort];
}

- (instancetype)initWithHostPort:(EDOHostPort *)hostPort {
  self = [super init];
  if (self) {
    _hostPort = hostPort;
  }
  return self;
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (self) {
    _hostPort = [aDecoder decodeObjectOfClass:[EDOHostPort class]
                                       forKey:kEDOObjectCoderHostPortKey];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:self.hostPort forKey:kEDOObjectCoderHostPortKey];
}

@end

#pragma mark -

@implementation EDOObjectResponse

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (instancetype)initWithObject:(EDOObject *)object forRequest:(EDOServiceRequest *)request {
  self = [self initWithMessageID:request.messageID];
  if (self) {
    _object = object;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (self) {
    _object = [aDecoder decodeObjectOfClass:[EDOObject class] forKey:kEDOObjectCoderObjectKey];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:self.object forKey:kEDOObjectCoderObjectKey];
}

+ (EDOServiceResponse *)responseWithObject:(EDOObject *)object
                                forRequest:(EDOServiceRequest *)request {
  return [[self alloc] initWithObject:object forRequest:request];
}

@end
