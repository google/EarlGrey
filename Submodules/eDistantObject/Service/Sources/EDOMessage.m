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

#import "Service/Sources/EDOMessage.h"

static NSString *const kEDOEDOMessageCoderMessageIDKey = @"messageID";

@implementation EDOMessage

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (instancetype)init {
  return [self initWithMessageID:[NSUUID UUID].UUIDString];
}

- (instancetype)initWithMessageID:(NSString *)messageID {
  self = [super init];
  if (self) {
    _messageID = messageID;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [super init];
  if (self) {
    _messageID = [aDecoder decodeObjectOfClass:[NSString class]
                                        forKey:kEDOEDOMessageCoderMessageIDKey];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:self.messageID forKey:kEDOEDOMessageCoderMessageIDKey];
}

@end
