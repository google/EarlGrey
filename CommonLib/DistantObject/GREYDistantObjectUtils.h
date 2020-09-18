//
// Copyright 2020 Google LLC.
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
 * Creates a local NSArray object from a remote NSArray. The local array shallow copies the elements
 * of the @c remoteArray.
 *
 * @param remoteArray The remote array object.
 *
 * @return A local array that has the same elements as @c remoteArray.
 */
NSArray<id> *GREYGetLocalArrayShallowCopy(NSArray<id> *remoteArray);

/**
 * Creates a remote NSArray object from a local NSArray. The remote array shallow copies the
 * elements of the @c localArray.
 *
 * @note If this function is called at the test process, the resulting array is owned by the test
 *       process; If this function is called at the app process, the resulting array is owned by
 *       the app process.
 *
 * @param localArray The local array object.
 *
 * @return A remote array that has the same elements as @c localArray.
 */
NSArray<id> *GREYGetRemoteArrayShallowCopy(NSArray<id> *localArray);

NS_ASSUME_NONNULL_END
