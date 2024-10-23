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

#import "GREYDispatchQueueIdlingResource.h"

#import "GREYIdlingResource.h"
#import "GREYDispatchQueueTracker.h"
#import "GREYUIThreadExecutor+Private.h"
#import "GREYUIThreadExecutor.h"
#import "GREYThrowDefines.h"

@implementation GREYDispatchQueueIdlingResource {
  /** Name of the idling resource itself. */
  NSString *_idlingResourceName;
  /** The underlying dispatch queue tracker or interposer that backs the idling resource tracker. */
  id _dispatchQueueTracker;
}

+ (instancetype)resourceWithDispatchQueue:(dispatch_queue_t)queue name:(NSString *)name {
  return [[GREYDispatchQueueIdlingResource alloc] initWithDispatchQueue:queue name:name];
}

- (instancetype)initWithDispatchQueue:(dispatch_queue_t)queue name:(NSString *)name {
  GREYThrowOnNilParameter(queue);
  GREYThrowOnNilParameter(name);

  self = [super init];
  if (self) {
    _idlingResourceName = [name copy];
    _dispatchQueueTracker = [GREYDispatchQueueTracker trackerForDispatchQueue:queue];
  }
  return self;
}

#pragma mark - GREYIdlingResource

- (NSString *)idlingResourceName {
  return _idlingResourceName;
}

- (NSString *)idlingResourceDescription {
  return [_dispatchQueueTracker description];
}

- (BOOL)isIdleNow {
  BOOL trackerIsIdle = [_dispatchQueueTracker isIdleNow];
  // It is possible that all external references to the dispatch queue have been dropped, but that
  // the queue is still kept active by enqueued blocks. In that case, the queue is a "zombie" and
  // no longer a "live" queue. We want to track live and zombie queues, so we will only untrack the
  // queue if it is no longer alive and it has no more enqueued blocks.
  BOOL isDead = ![_dispatchQueueTracker isTrackingALiveQueue];
  if (trackerIsIdle && isDead) {
    [[GREYUIThreadExecutor sharedInstance] deregisterIdlingResource:self];
  }
  // In apps with unusually high main thread activity, the main thread may never be condidered
  // idle, or may only rarely become idle.  This is a safety valve to allow this tracker to be
  // selectively disabled, because otherwise, tests that should take seconds can take minues or
  // even hours.
  BOOL mainQueueTrackingEnabled = [GREYConfiguration.sharedConfiguration
      valueForConfigKey:kGREYConfigKeyMainQueueTrackingEnabled];
  return trackerIsIdle || !mainQueueTrackingEnabled;
}

@end
