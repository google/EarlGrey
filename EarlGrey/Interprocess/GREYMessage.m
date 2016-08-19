//
// Copyright 2016 Google Inc.
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

#import "GREYMessage.h"

#import "Additions/XCTestCase+GREYAdditions.h"
#import "Common/GREYSerializable.h"

@implementation GREYMessage {
  NSDictionary *_dictionary;
}

+ (instancetype)messageForType:(GREYMessageType)type {
  return [[GREYMessage alloc] initWithType:type dictionary:nil];
}

+ (instancetype)messageForInvocationFile:(NSString *)filename lineNumber:(NSUInteger)lineNumber {
  NSParameterAssert(filename);

  return [[GREYMessage alloc] initWithType:kGREYMessageInvocationFileLine
                                dictionary:@{ @"filename" : filename,  @"lineNumber" : @(lineNumber) }];
}

+ (instancetype)messageForNSError:(NSError *)error {
  NSParameterAssert(error);

  // TODO: userInfo not supported yet, because it can contain CFError
  return [[GREYMessage alloc] initWithType:kGREYMessageNSError
                                dictionary:@{ @"code" : @(error.code), @"domain" : error.domain }];
}

+ (instancetype)messageForException:(NSException *)exception details:(NSString *)details {
  NSParameterAssert(exception);

  return [[GREYMessage alloc] initWithType:kGREYMessageException
                                dictionary:@{ @"exception" : exception, @"details" : details.length > 0 ? details : @"" }];
}

+ (instancetype)messageForRPC:(GREYSerializable *)serializable errorIsSet:(BOOL)errorIsSet {
  NSParameterAssert(serializable);
  NSParameterAssert([serializable isRPC]);
  
  XCTestCase *currentTestCase = [XCTestCase grey_currentTestCase];
  NSString *screenshotName =
      [NSString stringWithFormat:@"%@_%@", [currentTestCase grey_testClassName], [currentTestCase grey_testMethodName]];
  return [[GREYMessage alloc] initWithType:kGREYMessageRPC
                                dictionary:@{ @"serializable"   : serializable,
                                              @"errorIsSet"     : @(errorIsSet),
                                              @"screenshotName" : screenshotName }];
}

- (id)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    _type = [coder decodeIntegerForKey:@"type"];
    _origin = [coder decodeObjectForKey:@"origin"];
    _dictionary = [coder decodeObjectForKey:@"dictionary"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeInteger:_type forKey:@"type"];
  [coder encodeObject:_origin forKey:@"origin"];
  [coder encodeObject:_dictionary forKey:@"dictionary"];
}

- (GREYSerializable *)serializable {
  NSAssert(_type == kGREYMessageRPC && _dictionary[@"serializable"], @"only RPC message and not nil");
  return _dictionary[@"serializable"];
}

- (NSString *)screenshotName {
  NSAssert(_type == kGREYMessageRPC, @"only RPC message");
  return _dictionary[@"screenshotName"];
}

- (BOOL)errorIsSet {
  NSAssert(_type == kGREYMessageRPC, @"only RPC message");
  return [_dictionary[@"errorIsSet"] boolValue];
}

- (NSException *)exception {
  NSAssert(_type == kGREYMessageException, @"only exception message");
  return _dictionary[@"exception"];
}

- (NSString *)details {
  NSAssert(_type == kGREYMessageException, @"only exception message");
  return _dictionary[@"details"];
}

- (NSError *)nsError {
  NSAssert(_type == kGREYMessageNSError, @"only NSError message");
  return [NSError errorWithDomain:_dictionary[@"domain"]
                             code:[_dictionary[@"code"] integerValue]
                         userInfo:_dictionary[@"userInfo"]];
}

- (NSString *)filename {
  NSAssert(_type == kGREYMessageInvocationFileLine, @"only invocation message");
  return _dictionary[@"filename"];
}

- (NSUInteger)lineNumber {
  NSAssert(_type == kGREYMessageInvocationFileLine, @"only invocation message");
  return [_dictionary[@"lineNumber"] unsignedIntegerValue];
}

#pragma mark - Private

- (instancetype)initWithType:(GREYMessageType)type dictionary:(NSDictionary *)dictionary {
  self = [super init];
  if (self) {
    _type = type;
    _origin = [[NSBundle mainBundle] bundleIdentifier];
    _dictionary = dictionary;
  }
  return self;
}

@end
