//
// Copyright 2017 Google Inc.
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

#import "GREYStringDescription.h"

#import "GREYMatcher.h"

/**
 *  The key to encode the string description with.
 */
NSString *const kStringDescriptionKey = @"description";

@implementation GREYStringDescription {
  NSMutableString *_description;
}

- (void)encodeWithCoder:(NSCoder *)enCoder {
  [enCoder encodeObject:_description forKey:kStringDescriptionKey];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  if (self = [super init]) {
    _description = [aDecoder decodeObjectForKey:@"kStringDescriptionKey"];
  }
  return self;
}

- (id<GREYDescription>)appendText:(NSString *)text {
  if (!_description) {
    _description = [[NSMutableString alloc] init];
  }
  [_description appendString:text];
  return self;
}

- (id<GREYDescription>)appendDescriptionOf:(id)object {
  if (!object) {
    [self appendText:@"nil"];
  } else if ([object conformsToProtocol:@protocol(GREYMatcher)]) {
    [object describeTo:self];
  } else if ([object isKindOfClass:[NSString class]]) {
    [self appendText:[NSString stringWithFormat:@"\"%@\"", object]];
  } else {
    if ([object respondsToSelector:@selector(description)]) {
      [self appendText:[object description]];
    } else {
      NSString *tag = [NSString stringWithFormat:@"%@:%p", [object class], object];
      [[[self appendText:@"<"] appendText:tag] appendText:@">"];
    }
  }
  return self;
}

- (NSString *)description {
  return _description ? _description : @"";
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
  return YES;
}

@end
