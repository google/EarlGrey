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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** The type for the message ID. */
typedef NSString EDOMessageID;

/** The base class for the message to be transferred within a single service. */
@interface EDOMessage : NSObject <NSSecureCoding>

/** The unique message identifier to track the request and response. */
@property(readonly) EDOMessageID *messageID;

/** Init with a random UUID message Id. */
- (instancetype)init;

/** @see -[NSCoding initWithCoder:]. */
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

/**
 *  Init with a given message identifier.
 *
 *  @param messageID The message identifier.
 *  @remark The message Id is a unique identifier to track, it is usually generated via UUID
 *          generator. For instance, the message Id will be the same if the response is for a
 *          request.
 */
- (instancetype)initWithMessageID:(NSString *)messageID NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
