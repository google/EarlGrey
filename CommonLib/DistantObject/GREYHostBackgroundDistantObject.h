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

#import <Foundation/Foundation.h>

@class EDOHostService;

NS_ASSUME_NONNULL_BEGIN

/**
 *  The instance running in a non-main dispatch queue in the app-under-test's
 *  process.
 */
@interface GREYHostBackgroundDistantObject : NSObject

/** The EDOHostService the application process listens on. */
@property(nonatomic, readonly) EDOHostService *service;

/** The singleton of GREYHostApplicationDistantObject. */
@property(readonly, class) GREYHostBackgroundDistantObject *sharedInstance;

/**
 *  The dispatch queue that the instance of GREYHostBackgroundDistantObject runs on in the
 *  application process.
 */
@property(nonatomic, readonly) dispatch_queue_t backgroundQueue;

/** Returns the port for the distant object's service. */
- (uint16_t)servicePort;

@end

NS_ASSUME_NONNULL_END
