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

/**
 *  By default, NSObject has pass-by-value behavior during remote invocation.
 *
 *  This category provides APIs to do pass-by-value (or return-by-value) for one invocation, or
 *  statically enable a class to be pass-by-value. All APIs require the class to conform to
 *  NSCoding.
 */
@interface NSObject (EDOValueObject)

/**
 *  Enables this type to be a value type so it will be passed by value.
 *
 *  If a class is enabled as a value type, during remote invocation the objects of the class will
 *  be passed by value. Only classes conforming to @c NSCoding protocol can be passed by value.
 */
+ (void)edo_enableValueType;

/**
 *  Method to be called on invocation target to get a value object from remote invocation.
 *  This should not be called on a non-remote object.
 */
- (instancetype)returnByValue;

/**
 *  Method to be called on method parameter to pass a value object to remote invocation.
 */
- (instancetype)passByValue;

@end

NS_ASSUME_NONNULL_END
