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

/**
 *  The implementation for the app under test.
 *
 *  The configuration only caches the values and forward any write to the counterpart in the test.
 *  And this merges with the configuration in the test before a read if there is a write.
 */
@interface GREYAppConfiguration : GREYConfiguration

/**
 *  Update the configuration. The valid keys are defined in @c GREYConfigKey.
 *
 *  @param configuration The config dictionary.
 */
- (void)updateConfiguration:(NSDictionary<NSString *, id> *)configuration;
@end

NS_ASSUME_NONNULL_END
