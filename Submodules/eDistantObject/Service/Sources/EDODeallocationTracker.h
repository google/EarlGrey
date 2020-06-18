//
// Copyright 2019 Google LLC.
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

@class EDOHostPort;
@class EDOWeakObject;

/**
 *  The EDODeallocationTracker is a tracker that manages local object's deallocation.
 *
 *  The tracker is associated with the local object's life cycle. When the local object is wrapped,
 *  the tracker is attached to the local object. When the local object is no longer in use and
 *  deallocates, the EDODeallocationTracker will be deallocated as well. An EDOObjectReleaseRequest
 *  is then sent to remove the remote weak reference from the weak object dictionary.
 */
@interface EDODeallocationTracker : NSObject

/**
 *  Creates an instance of the tracker that is associated with the underlying object.
 *
 *  @param trackedObject The remote object that is stored in the weak object dictionary.
 *  @param hostPort      The host port where weak object dictionary holds the remote object.
 */
+ (void)enableTrackingForObject:(EDOWeakObject *)trackedObject hostPort:(EDOHostPort *)hostPort;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
