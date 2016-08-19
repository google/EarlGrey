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

#import "GREYSerializable.h"

#import "Common/GREYCoder.h"

@implementation GREYSerializable

- (instancetype)initForRPC:(BOOL)isRPC
                    object:(id)object
                  selector:(SEL)selector
                 arguments:(NSArray *)args
                     block:(GREYUnserializeBlock)block {
  self = [super init];
  if (self) {
    _isRPC = isRPC;
    _object = object;
    _selector = selector;
    _args = args;
    _block = block;
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    _isRPC = [coder decodeBoolForKey:@"isRPC"];
    _object = [GREYCoder decodeObject:[coder decodeObjectForKey:@"object"]];
    _selector = [GREYCoder decodeSelector:[coder decodeObjectForKey:@"selector"]];
    _args = [coder decodeObjectForKey:@"args"];
    _block = [GREYCoder decodeObject:[coder decodeObjectForKey:@"block"]];
  }
  return self;
}

- (id)awakeAfterUsingCoder:(NSCoder *)coder {
  // Substitute real object in application process.
  return !_isRPC && [GREYCoder isInApplicationProcess] ? _block(self, nil) : self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeBool:_isRPC forKey:@"isRPC"];
  [coder encodeObject:[GREYCoder encodeObject:_object] forKey:@"object"];
  [coder encodeObject:[GREYCoder encodeSelector:_selector] forKey:@"selector"];
  [coder encodeObject:_args forKey:@"args"];
  [coder encodeObject:[GREYCoder encodeObject:_block] forKey:@"block"];
}

@end
