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

#import "Service/Sources/EDOMethodSignatureMessage.h"

#import "Service/Sources/EDOHostService.h"
#import "Service/Sources/EDOServicePort.h"

#import <objc/runtime.h>

static NSString *const kEDOMethodSignatureCoderObjectKey = @"object";
static NSString *const kEDOMethodSignatureCoderPortKey = @"port";
static NSString *const kEDOMethodSignatureCoderSignatureKey = @"signature";
static NSString *const kEDOMethodSignatureCoderSelectorKey = @"selector";

#pragma mark - EDOMethodSignatureResponse

@implementation EDOMethodSignatureResponse

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (instancetype)initWithSignature:(NSString *)signature forRequest:(EDOServiceRequest *)request {
  self = [super initWithMessageID:request.messageID];
  if (self) {
    _signature = signature;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (self) {
    _signature = [aDecoder decodeObjectOfClass:[NSString class]
                                        forKey:kEDOMethodSignatureCoderSignatureKey];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:self.signature forKey:kEDOMethodSignatureCoderSignatureKey];
}

- (NSString *)description {
  return [NSString
      stringWithFormat:@"Method signature response (%@): (%@)", self.messageID, self.signature];
}

@end

#pragma mark - EDOMethodSignatureRequest

@interface EDOMethodSignatureRequest ()
/** The pointer to the class. */
@property(readonly) EDOPointerType object;
/** The service port for the underlying object. */
@property(readonly, nullable) EDOServicePort *port;
/** The selector name. */
@property(readonly) NSString *selectorName;
@end

@implementation EDOMethodSignatureRequest

+ (BOOL)supportsSecureCoding {
  return YES;
}

+ (instancetype)requestWithObject:(EDOPointerType)object
                             port:(EDOServicePort *)port
                         selector:(SEL)selector {
  return [[self alloc] initWithObject:object port:port selName:NSStringFromSelector(selector)];
}

+ (EDORequestHandler)requestHandler {
  return ^EDOServiceResponse *(EDOServiceRequest *request, EDOHostService *service) {
    if (![request matchesService:service.port]) {
      return nil;
    }

    EDOMethodSignatureRequest *methodRequest = (EDOMethodSignatureRequest *)request;
    id object = (__bridge Class)(void *)methodRequest.object;
    Class clazz = object_getClass(object);
    SEL sel = NSSelectorFromString(methodRequest.selectorName);

    NSMutableString *encoding = nil;
    Method method = class_getInstanceMethod(clazz, sel);
    if (method) {
      encoding = [NSMutableString stringWithUTF8String:method_getTypeEncoding(method)];
    } else {
      // It's possible that the underlying object is a proxy and implements
      // -[methodSignatureForSelector:] to forward the invocation, i.e. OCMock.
      NSMethodSignature *signature = [object methodSignatureForSelector:sel];
      encoding =
          signature ? [NSMutableString stringWithUTF8String:signature.methodReturnType] : nil;
      for (NSUInteger i = 0; i < signature.numberOfArguments; ++i) {
        [encoding appendFormat:@"%s", [signature getArgumentTypeAtIndex:i]];
      }
    }
    return [[EDOMethodSignatureResponse alloc] initWithSignature:encoding forRequest:request];
  };
}

- (instancetype)initWithObject:(EDOPointerType)object
                          port:(EDOServicePort *)port
                       selName:(NSString *)selName {
  self = [super init];
  if (self) {
    _object = object;
    _port = port;
    _selectorName = selName;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (self) {
    _object = [aDecoder decodeInt64ForKey:kEDOMethodSignatureCoderObjectKey];
    _selectorName = [aDecoder decodeObjectOfClass:[NSString class]
                                           forKey:kEDOMethodSignatureCoderSelectorKey];
    _port = [aDecoder decodeObjectOfClass:[EDOServicePort class]
                                   forKey:kEDOMethodSignatureCoderPortKey];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [super encodeWithCoder:aCoder];
  [aCoder encodeInt64:self.object forKey:kEDOMethodSignatureCoderObjectKey];
  [aCoder encodeObject:self.selectorName forKey:kEDOMethodSignatureCoderSelectorKey];
  [aCoder encodeObject:self.port forKey:kEDOMethodSignatureCoderPortKey];
}

- (BOOL)matchesService:(EDOServicePort *)originatorPort {
  return [self.port match:originatorPort];
}

- (NSString *)description {
  return [NSString
      stringWithFormat:@"Method signature request (%@): (%@)", self.messageID, self.selectorName];
}

@end
