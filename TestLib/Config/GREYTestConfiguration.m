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

#import "TestLib/Config/GREYTestConfiguration.h"

#import "AppFramework/Config/GREYAppConfiguration.h"
#import "CommonLib/Assertion/GREYFatalAsserts.h"
#import "CommonLib/Assertion/GREYThrowDefines.h"
#import "CommonLib/Config/GREYAppState.h"
#import "CommonLib/Config/GREYConfigKey.h"
#import "CommonLib/Config/GREYConfiguration+Private.h"
#import "CommonLib/GREYLogger.h"
#import "Service/Sources/NSObject+EDOValueObject.h"

GREYConfiguration *GREYCreateConfiguration(void) { return [[GREYTestConfiguration alloc] init]; }

@implementation GREYTestConfiguration {
  NSMutableDictionary *_mergedConfiguration;  // Dict for storing the merged default/overriden dicts
  NSMutableDictionary *_defaultConfiguration;     // Dict for storing the default configurations
  NSMutableDictionary *_overridenConfiguration;   // Dict for storing the user-defined overrides
  dispatch_queue_t _configurationIsolationQueue;  // The isolation queue to access configurations.
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _mergedConfiguration = [[NSMutableDictionary alloc] init];
    _defaultConfiguration = [[NSMutableDictionary alloc] init];
    _overridenConfiguration = [[NSMutableDictionary alloc] init];
    _configurationIsolationQueue =
        dispatch_queue_create("com.google.earlgrey.TestConfiguration", DISPATCH_QUEUE_SERIAL);
    NSArray *searchPaths =
        NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    GREYFatalAssertWithMessage(searchPaths.count > 0, @"Couldn't find a valid documents directory");
    [self setDefaultValue:searchPaths.firstObject forConfigKey:kGREYConfigKeyArtifactsDirLocation];
    [self setDefaultValue:@YES forConfigKey:kGREYConfigKeyAnalyticsEnabled];
    [self setDefaultValue:@YES forConfigKey:kGREYConfigKeyActionConstraintsEnabled];
    [self setDefaultValue:@(30) forConfigKey:kGREYConfigKeyInteractionTimeoutDuration];
    [self setDefaultValue:@(10) forConfigKey:kGREYConfigKeyCALayerMaxAnimationDuration];
    [self setDefaultValue:@YES forConfigKey:kGREYConfigKeySynchronizationEnabled];
    [self setDefaultValue:@(1.5) forConfigKey:kGREYConfigKeyNSTimerMaxTrackableInterval];
    [self setDefaultValue:@YES forConfigKey:kGREYConfigKeyCALayerModifyAnimations];
    [self setDefaultValue:@(1.5) forConfigKey:kGREYConfigKeyDispatchAfterMaxTrackableDelay];
    [self setDefaultValue:@(1.5) forConfigKey:kGREYConfigKeyDelayedPerformMaxTrackableDuration];
    [self setDefaultValue:@[] forConfigKey:kGREYConfigKeyURLBlacklistRegex];
    [self setDefaultValue:@(kGREYIdle) forConfigKey:kGREYConfigKeyIgnoreAppStates];
  }
  return self;
}

- (NSDictionary<NSString *, id> *)mergedConfiguration {
  __block NSDictionary *configuration;
  dispatch_sync(_configurationIsolationQueue, ^{
    // TODO: Remove needsMerge as all the writes are sync'd because of remoteConfig. // NOLINT
    if (self.needsMerge) {
      [self->_mergedConfiguration removeAllObjects];
      [self->_mergedConfiguration addEntriesFromDictionary:self->_defaultConfiguration];
      [self->_mergedConfiguration addEntriesFromDictionary:self->_overridenConfiguration];
      self.needsMerge = NO;
    }
    configuration = [[NSDictionary alloc] initWithDictionary:self->_mergedConfiguration];
  });
  return configuration;
}

- (void)updateRemoteConfiguration {
  GREYAppConfiguration *remoteConfiguration = self.remoteConfiguration;
  if (!remoteConfiguration) {
    return;
  }
  [remoteConfiguration updateConfiguration:[self.mergedConfiguration passByValue]];
}

- (void)setValue:(id)value forConfigKey:(NSString *)configKey {
  GREYThrowOnNilParameter(value);

  [self grey_validateConfigKey:configKey];
  dispatch_sync(_configurationIsolationQueue, ^{
    [self->_overridenConfiguration setObject:value forKey:configKey];
    self.needsMerge = YES;
  });
  [self updateRemoteConfiguration];
  GREYLogVerbose(@"Config Key: %@ was set to: %@", configKey, value);
}

- (void)setDefaultValue:(id)value forConfigKey:(NSString *)configKey {
  GREYThrowOnNilParameter(value);

  [self grey_validateConfigKey:configKey];
  dispatch_sync(_configurationIsolationQueue, ^{
    [self->_defaultConfiguration setObject:value forKey:configKey];
    self.needsMerge = YES;
  });
  [self updateRemoteConfiguration];
  GREYLogVerbose(@"Default Value for Configuration Key: %@ was set to: %@", configKey, value);
}

- (void)reset {
  dispatch_sync(_configurationIsolationQueue, ^{
    [self->_overridenConfiguration removeAllObjects];
    self.needsMerge = YES;
  });
  [self updateRemoteConfiguration];
}

@end
