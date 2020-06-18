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

/** NSObject extension for boxing the value type. */
@interface NSObject (EDOValue)

/**
 *  Check if the type is a value type to pass by copy.
 *
 *  Override this property to return true if the object is passed by copy. By default, the built-in
 *  value types (NSValue, NSString, NSError, NSException) and the container types (NSArray, NSSet,
 *  NSDictionary) will be passed by value.
 */
@property(readonly, getter=edo_isEDOValueType) BOOL edoValueType;

@end

NS_ASSUME_NONNULL_END
