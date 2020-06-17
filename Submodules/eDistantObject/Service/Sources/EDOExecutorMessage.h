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

@protocol EDOChannel;
@class EDOHostService;
@class EDOServiceRequest;
@class EDOServiceResponse;

/**
 *  The message being sent to the EDOExecutor to process.
 */
@interface EDOExecutorMessage : NSObject

- (instancetype)init NS_UNAVAILABLE;

/** Initializes the message with the given execution block. */
- (instancetype)initWithBlock:(void (^)(void))executeBlock NS_DESIGNATED_INITIALIZER;

/** Waits infinitely until the message is handled. */
- (void)waitForCompletion;

/**
 * Invokes the execution block held by the message. Once it completes the invocation, the message
 * will be marked as handled.
 *
 * @return YES if the block is executed; NO otherwise.
 * @note The block can only be executed once.
 */
- (BOOL)executeBlock;

@end

NS_ASSUME_NONNULL_END
