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

/** NSObject extension to help with weak referenced objects. */
@interface NSObject (EDOWeakObject)

/**
 *  Wraps an NSObject into a EDOWeakObject.
 *
 *  Boxes an object into a EDOWeakObject, which is an NSProxy that directs any call to the original
 *  object. User would use this method when testing with weakly referenced objects.
 *
 *  Usage for assigning a weak reference to object:
 *  Original usage: weakReference = object;
 *  Updated usage:  weakReference = [object remoteWeak];
 *
 *  When a user references an underlying object weakly across processes remotely, since there were
 *  no ownership to the object across processes, the underlying object will be deallocated
 *  immediately. Through the usage of remoteWeak, the underlying object is wrapped to an
 *  EDOWeakObject which directs any call to the underlying object. At the same time, EDOWeakObject
 *  is added and owned by a weakly referenced objects library at the host side. It is then retained
 *  and won't get deallocated immediately. After the underlying object is out of scope, the
 *  deallocation tracker helps to remove the strong reference to EDOWeakObject, so the memory gets
 *  released.
 */
- (instancetype)remoteWeak;

@end

NS_ASSUME_NONNULL_END
