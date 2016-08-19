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

#import <Foundation/Foundation.h>
#include <objc/message.h>

#import <EarlGrey/GREYCoder.h>

@class GREYSerializable;

typedef id (^GREYUnserializeBlock)(GREYSerializable *serializable, __strong NSError **errorOrNil);

#define GREY_SERIALIZABLE_ENCODE(__name, __arg) [GREYCoder encode##__name:(__arg)]
#define GREY_SERIALIZABLE_DECODE(__name, __n) [GREYCoder decode##__name:[serializable args][__n-1]]

#define GREY_SERIALIZE(__name, __type, __arg)                                                      \
if (![GREYCoder isInApplicationProcess]) {                                                         \
  GREYSerializable *serializable =                                                                 \
      [[GREYSerializable alloc] initForRPC:NO                                                      \
                                    object:self                                                    \
                                  selector:_cmd                                                    \
                                 arguments:@[GREY_SERIALIZABLE_ENCODE(__name, __arg)]              \
                                     block:^id(GREYSerializable *serializable,                     \
                                               NSError *__strong *errorOrNil) {                    \
    return ((id (*)(id, SEL, __type))objc_msgSend)([serializable object],                          \
                                                   [serializable selector],                        \
                                                   GREY_SERIALIZABLE_DECODE(__name, 1));           \
  }];                                                                                              \
  return (id)serializable;                                                                         \
}

#define GREY_SERIALIZE2(__name1, __type1, __arg1, __name2, __type2, __arg2)                        \
if (![GREYCoder isInApplicationProcess]) {                                                         \
  GREYSerializable *serializable =                                                                 \
      [[GREYSerializable alloc] initForRPC:NO                                                      \
                                    object:self                                                    \
                                  selector:_cmd                                                    \
                                 arguments:@[GREY_SERIALIZABLE_ENCODE(__name1, __arg1),            \
                                             GREY_SERIALIZABLE_ENCODE(__name2, __arg2)]            \
                                     block:^id(GREYSerializable *serializable,                     \
                                               NSError *__strong *errorOrNil) {                    \
    return ((id (*)(id, SEL, __type1, __type2))objc_msgSend)([serializable object],                \
                                                             [serializable selector],              \
                                                             GREY_SERIALIZABLE_DECODE(__name1, 1), \
                                                             GREY_SERIALIZABLE_DECODE(__name2, 2));\
  }];                                                                                              \
  return (id)serializable;                                                                         \
}

@interface GREYSerializable : NSObject

@property (nonatomic, readonly) BOOL isRPC;
@property (nonatomic, readonly) id object;
@property (nonatomic, readonly) SEL selector;
@property (nonatomic, readonly) NSArray *args;
@property (nonatomic, readonly) GREYUnserializeBlock block;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initForRPC:(BOOL)isRPC
                    object:(id)object
                  selector:(SEL)selector
                 arguments:(NSArray *)args
                     block:(GREYUnserializeBlock)block;

@end
