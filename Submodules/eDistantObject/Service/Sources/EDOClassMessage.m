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

#import "Service/Sources/EDOClassMessage.h"

#import "Channel/Sources/EDOHostPort.h"
#import "Service/Sources/EDOHostService+Private.h"

static NSString *const kEDOObjectCoderClassNameKey = @"className";
static NSString *const kEDOObjectCoderHostPortKey = @"hostPort";

#pragma mark -

@interface EDOClassRequest ()
/** The class name. */
@property(readonly) NSString *className;
/** The host port. */
@property(readonly) EDOHostPort *hostPort;
@end

#pragma mark -

@implementation EDOClassRequest

+ (BOOL)supportsSecureCoding {
  return YES;
}

+ (EDORequestHandler)requestHandler {
  return ^(EDOServiceRequest *request, EDOHostService *service) {
    EDOClassRequest *classRequest = (EDOClassRequest *)request;
    Class clz = NSClassFromString(classRequest.className);
    EDOObject *object =
        clz ? [service distantObjectForLocalObject:clz hostPort:classRequest.hostPort] : nil;
    return [EDOClassResponse responseWithObject:object forRequest:request];
  };
}

+ (instancetype)requestWithClassName:(NSString *)className hostPort:(EDOHostPort *)hostPort {
  return [[self alloc] initWithClassName:className hostPort:hostPort];
}

- (instancetype)initWithClassName:(NSString *)className hostPort:(EDOHostPort *)hostPort {
  self = [super init];
  if (self) {
    _className = className;
    _hostPort = hostPort;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (self) {
    _className = [aDecoder decodeObjectOfClass:[NSString class] forKey:kEDOObjectCoderClassNameKey];
    _hostPort = [aDecoder decodeObjectOfClass:[EDOHostPort class]
                                       forKey:kEDOObjectCoderHostPortKey];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:self.className forKey:kEDOObjectCoderClassNameKey];
  [aCoder encodeObject:self.hostPort forKey:kEDOObjectCoderHostPortKey];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"Class request (%@) name: %@", self.messageID, self.className];
}

@end

#pragma mark -

@implementation EDOClassResponse

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"Class response (%@)", self.messageID];
}

@end
