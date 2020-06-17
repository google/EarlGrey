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

#import "Service/Sources/EDOProtocolObject.h"

static NSString *const kEDOProtocolObjectCoderProtocolName = @"protocolName";

@implementation EDOProtocolObject

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (instancetype)initWithProtocol:(Protocol *)protocol {
  self = [super init];
  if (self) {
    _protocolName = NSStringFromProtocol(protocol);
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [super init];
  if (self) {
    _protocolName = [aDecoder decodeObjectOfClass:[NSString class]
                                           forKey:kEDOProtocolObjectCoderProtocolName];
  }
  return self;
}

#pragma mark - NSCoder

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:self.protocolName forKey:kEDOProtocolObjectCoderProtocolName];
}

- (id)awakeAfterUsingCoder:(NSCoder *)aDecoder {
  Protocol *protocol = NSProtocolFromString(_protocolName);
  if (protocol) {
    // There is no need to release this object since it will be maintained until the process exist.
    // Calling release on it does nothing.
    return protocol;
  } else {
    NSString *reason = [NSString stringWithFormat:@"Protocol %@ couldn't be loaded", _protocolName];
    @throw
        [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];
  }
}

@end
