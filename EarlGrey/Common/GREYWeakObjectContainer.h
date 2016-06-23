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

/**
 *  Class used to weakly hold an object so that the object can safely be dereferenced even it has
 *  been deallocated.
 */
@interface GREYWeakObjectContainer : NSObject

/**
 *  Initialize the container with @c object.
 *
 *  @param object The object to be weakly held by the container.
 */
- (instancetype)initWithObject:(id)object;

- (instancetype)init NS_UNAVAILABLE;

/**
 *  The weakly held object. Getting the object will return nil if the object has been deallocated.
 */
@property(nonatomic, readonly, weak) id object;

@end

