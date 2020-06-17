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

#import "Service/Sources/EDOParameter.h"
#import "Service/Sources/EDOValueObject.h"

@class EDOHostService;
@class EDOHostPort;

NS_ASSUME_NONNULL_BEGIN

@implementation EDOValueObject (EDOParameter)

/**
 * Box the instance of @c EDOValueObject into a @c EDOParameter.
 *
 * @see -[NSObject edo_parameterForTarget:service:hostPort:]
 * @note Because EDOValueObject is an NSProxy, it doesn't inherit category methods from NSObject and
 *       needs to implement it.
 */
- (EDOParameter *)edo_parameterForTarget:(EDOObject *)target
                                 service:(EDOHostService *)service
                                hostPort:(EDOHostPort *)hostPort {
  return [EDOParameter parameterWithValue:(self.localObject ?: self.remoteObject) objCType:@"@"];
}

@end

NS_ASSUME_NONNULL_END
