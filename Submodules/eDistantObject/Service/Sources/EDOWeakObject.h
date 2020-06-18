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

/**
 *  The EDOWeakObject wraps the weak object as an NSProxy. EDOWeakObject is weakly associated with
 *  the underlying object (weak object). For a weak object, users would use [object remoteWeak],
 *  which will wrap the object inside the EDOWeakObject and return the EDOWeakObject. NSProxy helps
 *  to monitor the case where remote object has been released yet being called by the other process.
 */
@interface EDOWeakObject : NSProxy

/** The weak underlying object. */
@property(readonly, nonatomic, weak) id weakObject;

- (instancetype)init NS_UNAVAILABLE;

/**
 *  Creates EDOWeakObject by wrapping the underlying weak object.
 *
 *  @param weakObject The underlying object that is weakly referenced.
 */
- (instancetype)initWithWeakObject:(id)weakObject;

@end

NS_ASSUME_NONNULL_END
