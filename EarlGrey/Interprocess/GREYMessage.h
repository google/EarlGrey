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

typedef NS_ENUM(NSInteger, GREYMessageType) {
  /* Client to Server */
  kGREYMessageConnect = 1,
  kGREYMessageConnectionOK,
  kGREYMessageActionWillBegin,
  kGREYMessageActionDidFinish,
  kGREYMessageInvocationFileLine,
  kGREYMessageException,
  kGREYMessageNSError,
  /* Server to Client */
  kGREYMessageAcceptConnection,
  kGREYMessageCheckConnection,
  kGREYMessageRPC,
};

@class GREYSerializable;

@interface GREYMessage : NSObject

@property (nonatomic, readonly) GREYMessageType type;
@property (nonatomic, readonly) NSString *origin;

- (instancetype)init NS_UNAVAILABLE;

/* Bidirectional */
+ (instancetype)messageForType:(GREYMessageType)type;

/* Client to Server */
+ (instancetype)messageForInvocationFile:(NSString *)filename lineNumber:(NSUInteger)lineNumber;
+ (instancetype)messageForException:(NSException *)exception details:(NSString *)details;
+ (instancetype)messageForNSError:(NSError *)error;

/* Server to Client */
+ (instancetype)messageForRPC:(GREYSerializable *)serializable errorIsSet:(BOOL)errorIsSet;

/* Client to Server */
- (NSString *)filename;
- (NSUInteger)lineNumber;
- (NSException *)exception;
- (NSString *)details;
- (NSError *)nsError;
- (BOOL)errorIsSet;

/* Server to Client */
- (GREYSerializable *)serializable;
- (NSString *)screenshotName;

@end
