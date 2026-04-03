//
// Copyright 2026 Google Inc.
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
#include <pthread.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A wrapper for pthread_mutex_t and pthread_cond_t with priority inheritance.
 * This class ensures that the mutex and condition variable are properly initialized
 * and destroyed, and provides a stable memory address for use in blocks.
 */
@interface GREYWaitToken : NSObject

/** The mutex used for synchronization. */
@property(nonatomic, readonly) pthread_mutex_t *mutex;

/** The condition variable used for signaling. */
@property(nonatomic, readonly) pthread_cond_t *cond;

/** A flag to indicate if the token has been signaled. */
@property(nonatomic, assign) BOOL signaled;

/**
 * Initializes the wait token with a priority-inheriting mutex.
 */
- (instancetype)init;

/**
 * Signals the condition variable.
 */
- (void)signal;

/**
 * Waits for the condition variable to be signaled.
 *
 * @return YES if signaled, NO if error occurred.
 */
- (BOOL)wait;

/**
 * Waits for the condition variable to be signaled until the specified timeout.
 *
 * @param timeout The timeout interval in seconds.
 * @return YES if signaled, NO if timed out or error occurred.
 */
- (BOOL)waitWithTimeout:(NSTimeInterval)timeout;

@end

NS_ASSUME_NONNULL_END
