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

#import "Service/Tests/TestsBundle/EDOTestClassDummy.h"

@implementation EDOTestClassDummy

+ (instancetype)allocDummy {
  return [self alloc];
}

+ (instancetype)_allocDummy {
  return [self alloc];
}

+ (instancetype)allocateDummy {
  return [self alloc];
}

+ (int)classMethodWithInt:(int)value {
  return [self classMethodWithIdReturn:value].value + 9;
}

+ (EDOTestClassDummy *)classMethodWithIdReturn:(int)value {
  return [[self alloc] initWithValue:value];
}

- (instancetype)initWithValue:(int)value {
  self = [super init];
  if (self) {
    _value = value;
  }
  return self;
}

@end
