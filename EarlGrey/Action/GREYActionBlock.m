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

#import "Action/GREYActionBlock.h"

#import "Assertion/GREYAssertionDefines.h"
#import "Common/GREYCoder.h"
#import "Common/GREYDefines.h"
#import "Matcher/GREYMatcher.h"

@implementation GREYActionBlock {
  GREYPerformBlock _performBlock;
  id<GREYMatcher> _constraints;
}

+ (instancetype)actionWithName:(NSString *)name performBlock:(GREYPerformBlock)block {
  return [GREYActionBlock actionWithName:name constraints:nil performBlock:block];
}

+ (instancetype)actionWithName:(NSString *)name
                   constraints:(id<GREYMatcher>)constraints
                  performBlock:(GREYPerformBlock)block {
  return [[GREYActionBlock alloc] initWithName:name constraints:constraints performBlock:block];
}

- (instancetype)initWithName:(NSString *)name
                 constraints:(id<GREYMatcher>)constraints
                performBlock:(GREYPerformBlock)block {
  NSParameterAssert(block);
  self = [super initWithName:name constraints:constraints];
  if (self) {
    _performBlock = block;
    _constraints = constraints;
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)coder {
  return [self initWithName:[coder decodeObjectForKey:@"name"]
                constraints:[coder decodeObjectForKey:@"constraints"]
               performBlock:[GREYCoder decodeObject:[coder decodeObjectForKey:@"performBlock"]]];
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:[self name] forKey:@"name"];
  [coder encodeObject:_constraints forKey:@"constraints"];
  [coder encodeObject:[GREYCoder encodeObject:_performBlock] forKey:@"performBlock"];
}

#pragma mark - GREYAction

- (BOOL)perform:(id)element error:(__strong NSError **)errorOrNil {
  if (![self satisfiesConstraintsForElement:element error:errorOrNil]) {
    return NO;
  }
  // Perform actual action.
  return _performBlock(element, errorOrNil);
}

@end
