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

#import "Service/Sources/EDOServiceRequest.h"

#import "Service/Sources/EDOServiceError.h"

static NSString *const kEDOServiceResponseErrorKey = @"error";
static NSString *const kEDOServiceResponseDurationKey = @"duration";

@implementation EDOServiceRequest

+ (BOOL)supportsSecureCoding {
  return YES;
}

+ (EDORequestHandler)requestHandler {
  // Default handler that only bounces the request.
  return ^(EDOServiceRequest *request, EDOHostService *service) {
    return [EDOErrorResponse unhandledErrorResponseForRequest:request];
  };
}

- (BOOL)matchesService:(EDOServicePort *)unused {
  return YES;
}

@end

@implementation EDOServiceResponse

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (self) {
    _duration = [aDecoder decodeDoubleForKey:kEDOServiceResponseDurationKey];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [super encodeWithCoder:aCoder];
  [aCoder encodeDouble:self.duration forKey:kEDOServiceResponseDurationKey];
}

@end

@implementation EDOErrorResponse

+ (BOOL)supportsSecureCoding {
  return YES;
}

+ (instancetype)errorResponse:(NSError *)error forRequest:(EDOServiceRequest *)request {
  return [[self alloc] initWithMessageID:request.messageID error:error];
}

+ (instancetype)unhandledErrorResponseForRequest:(EDOServiceRequest *)request {
  NSDictionary<NSErrorUserInfoKey, id> *userInfo = @{
    EDOErrorRequestKey : request.description ?: @"(empty request)",
  };
  NSError *unhandledError = [NSError errorWithDomain:EDOServiceErrorDomain
                                                code:EDOServiceErrorRequestNotHandled
                                            userInfo:userInfo];
  return [self errorResponse:unhandledError forRequest:request];
}

- (instancetype)initWithMessageID:(NSString *)messageID error:(NSError *)error {
  self = [super initWithMessageID:messageID];
  if (self) {
    _error = error;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (self) {
    _error = [aDecoder decodeObjectOfClass:[NSError class] forKey:kEDOServiceResponseErrorKey];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:self.error forKey:kEDOServiceResponseErrorKey];
}

@end
