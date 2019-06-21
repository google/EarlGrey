//
// Copyright 2019 Google Inc.
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

#import "GREYActionBlock.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Private category for diagnostics purpose.
 */
@interface GREYActionBlock (Private)

/**
 *  Internal initializer for GREYActionBlock to incorporate with Diagnostics. All EarlGrey actions
 *  should be initialized with this initializer in order to be tracked with Diagnostics.
 *  See GREYActionBlock.h for full documentation.
 *
 *  @remark Do NOT use this externally.
 *
 *  @param name          The name of the action.
 *  @param diagnosticsID Identifier of the action for diagnostics purpose.
 *  @param constraints   Constraints that must be satisfied before the action is performed
 *                       This is optional and can be @c nil.
 *  @param block         A block that contains the action to execute.
 *
 *  @return A GREYActionBlock instance with the given name and constraints.
 */
+ (instancetype)actionWithName:(NSString *)name
                 diagnosticsID:(NSString *)diagnosticsID
                   constraints:(__nullable id<GREYMatcher>)constraints
                  performBlock:(GREYPerformBlock)block;

/**
 *  Counterpart internal initializer of the designated internal initializer for GREYActionBlock to
 *  incorporate with Diagnostics. All EarlGrey actions should be initialized with this initializer
 *  in order to be tracked with Diagnostics. See GREYActionBlock.h for full documentation.
 *
 *  @remark Do NOT use this externally.
 *
 *  @param name          The name of the action.
 *  @param diagnosticsID Identifier of the action for diagnostics purpose.
 *  @param constraints   Constraints that must be satisfied before the action is performed.
 *                       This is optional and can be @c nil.
 *  @param block         A block that contains the action to execute.
 *
 *  @note GREYActions are not performed by default on the main thread. The threading
 *        behavior of the GREYAction has to be specified by the user.
 *
 *  @return A GREYActionBlock instance with the given @c name and @c constraints.
 */
- (instancetype)initWithName:(NSString *)name
               diagnosticsID:(NSString *)diagnosticsID
                 constraints:(__nullable id<GREYMatcher>)constraints
                performBlock:(GREYPerformBlock)block;

@end

NS_ASSUME_NONNULL_END
