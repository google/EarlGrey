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

#import "GREYAssertionBlock.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Private category for diagnostics purpose.
 */
@interface GREYAssertionBlock (Private)

/**
 *  Internal initializer for GREYAssertionBlock to incorporate with Diagnostics.
 *  @remark Do NOT use this externally.
 *
 *  @param name  The assertion name.
 *  @param block The block that will be invoked to perform the assertion.
 *
 *  @return A new block-based assertion object.
 */
+ (instancetype)assertionWithName:(NSString *)name
          assertionBlockWithError:(GREYCheckBlockWithError)block
                    diagnosticsID:(NSString *)diagnosticsID;

@end

NS_ASSUME_NONNULL_END
