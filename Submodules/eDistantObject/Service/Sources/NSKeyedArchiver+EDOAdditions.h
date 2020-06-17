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

/** Extension to archive objects into @c NSData. */
@interface NSKeyedArchiver (EDOAdditions)

/**
 *  Returns an @c NSData object containing the given encoded @c object.
 *
 *  @param object The object to be encoded.
 *  @return The @c NSData object containing the encoded @c object.
 */
+ (NSData *)edo_archivedDataWithObject:(id)object;

@end

NS_ASSUME_NONNULL_END
