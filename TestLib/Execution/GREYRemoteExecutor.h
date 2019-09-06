//
// Copyright 2019 Google Inc.
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

#ifdef __cplusplus
extern "C" {
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 *  Runs the given block in a background queue. It also takes the current (caller) thread's runloop
 *  and spins it, in order to enable the test's main thread to process messages from other threads.
 *  On completion of the block in the background thread, it stops spinning the runloop on the caller
 *  thread.
 *
 *  @note This is essential for calls made on the test side to remote objects on the application
 *        side. If a resource is required in the app-side call from the test process' main thread,
 *        the application's thread which is running the block will make a call to the test's main
 *        thread in order to acquire the resource for execution. However, the test's main thread may
 *        be waiting on some other state change in the application e.g. synchronization or something
 *        enqueued from the background thread. This would lead to a deadlock. Adding the call
 *        within the specified @c block will ensure that no deadlock happens as the resource will
 *        be accessed via a background queue.
 *
 *  @param block A void block that will be run in a background queue created in the method.
 */
void GREYExecuteSyncBlockInBackgroundQueue(void (^block)(void));

NS_ASSUME_NONNULL_END

#ifdef __cplusplus
}
#endif
