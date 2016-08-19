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
#import <EarlGrey/GREYMessage.h>
#import <EarlGrey/GREYSerializable.h>

#define GREY_REMOTE(__application, __return)                                                       \
if (![GREYCoder isInApplicationProcess] || __application != [GREYApplication targetApplication]) { \
  GREYSerializable *serializable =                                                                 \
      [[GREYSerializable alloc] initForRPC:YES                                                     \
                                    object:self                                                    \
                                  selector:_cmd                                                    \
                                 arguments:@[]                                                     \
                                     block:^id(GREYSerializable *serializable,                     \
                                               NSError *__strong *errorOrNil) {                    \
    ((void (*)(id, SEL))objc_msgSend)([serializable object], [serializable selector]);             \
    return nil;                                                                                    \
   }];                                                                                             \
  [__application makeRPCWithMessage:[GREYMessage messageForRPC:serializable                        \
                                                    errorIsSet:NO] error:nil];                     \
  __return;                                                                                        \
}

#define GREY_REMOTE1(__application, __return, __name, __type, __arg)                               \
if (![GREYCoder isInApplicationProcess] || __application != [GREYApplication targetApplication]) { \
  GREYSerializable *serializable =                                                                 \
      [[GREYSerializable alloc] initForRPC:YES                                                     \
                                    object:self                                                    \
                                  selector:_cmd                                                    \
                                 arguments:@[GREY_SERIALIZABLE_ENCODE(__name, __arg)]              \
                                     block:^id(GREYSerializable *serializable,                     \
                                               NSError *__strong *errorOrNil) {                    \
    ((void (*)(id, SEL, __type))objc_msgSend)([serializable object],                               \
                                              [serializable selector],                             \
                                              GREY_SERIALIZABLE_DECODE(__name, 1));                \
    return nil;                                                                                    \
  }];                                                                                              \
  [__application makeRPCWithMessage:[GREYMessage messageForRPC:serializable                        \
                                                    errorIsSet:NO] error:nil];                     \
  __return;                                                                                        \
}

#define GREY_REMOTE2(__application, __return, __name1, __type1, __arg1, __name2, __type2, __arg2)  \
if (![GREYCoder isInApplicationProcess] || __application != [GREYApplication targetApplication]) { \
  GREYSerializable *serializable =                                                                 \
      [[GREYSerializable alloc] initForRPC:YES                                                     \
                                    object:self                                                    \
                                  selector:_cmd                                                    \
                                 arguments:@[GREY_SERIALIZABLE_ENCODE(__name1, __arg1)]            \
                                     block:^id(GREYSerializable *serializable,                     \
                                               NSError *__strong *errorOrNil) {                    \
    ((void (*)(id, SEL, __type1, __type2))objc_msgSend)([serializable object],                     \
                                                        [serializable selector],                   \
                                                        GREY_SERIALIZABLE_DECODE(__name1, 1),      \
                                                        errorOrNil);                               \
    return nil;                                                                                    \
  }];                                                                                              \
  [__application makeRPCWithMessage:[GREYMessage messageForRPC:serializable                        \
                                                    errorIsSet:__arg2 != nil] error:__arg2];       \
  __return;                                                                                        \
}

@class GREYElementInteraction;
@protocol GREYMatcher;

@interface GREYApplication : NSObject

@property(nonatomic, readonly) NSString *bundleID;

+ (GREYApplication *)targetApplication;
+ (GREYApplication *)systemApplication;

- (instancetype)init NS_UNAVAILABLE;

- (void)launch;
- (void)terminate;
- (BOOL)isReady;

- (void)executeBlock:(GREYExecBlock)block;
- (void)execute:(GREYExecFunction)function;
- (GREYElementInteraction *)selectElementWithMatcher:(id<GREYMatcher>)elementMatcher;
- (BOOL)rotateDeviceToOrientation:(UIDeviceOrientation)deviceOrientation errorOrNil:(__strong NSError **)errorOrNil;

- (void)makeRPCWithMessage:(GREYMessage *)message error:(__strong NSError **)errorOrNil;

@end
