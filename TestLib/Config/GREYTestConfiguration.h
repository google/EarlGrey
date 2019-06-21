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

#import "GREYConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@class GREYAppConfiguration;

/**
 *  The implementation for the test.
 *
 *  The configuration in the test is the source of truth. Each write will signal the counterpart
 *  in the app to do a merge next time when there is a read in the app.
 */
@interface GREYTestConfiguration : GREYConfiguration
// The remote configuration this will push and synchronize with.
@property(nonatomic) GREYAppConfiguration *remoteConfiguration;

/**
 *  @return An NSData version of [self mergedConfiguration] using
 *          NSKeyedArchiver.
 */
- (NSDictionary<NSString *, id> *)mergedConfiguration;

/**
 *  Push the configuration to the remote application process.
 */
- (void)updateRemoteConfiguration;

@end

NS_ASSUME_NONNULL_END
