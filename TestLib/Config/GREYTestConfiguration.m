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

#import "GREYTestConfiguration.h"

#import "GREYAppConfiguration.h"
#import "GREYFatalAsserts.h"
#import "GREYThrowDefines.h"
#import "GREYAppState.h"
#import "GREYConfigKey.h"
#import "GREYConfiguration+Private.h"
#import "GREYConfiguration.h"
#import "GREYConstants.h"
#import "GREYLogger.h"
#import "NSObject+EDOValueObject.h"

GREYConfiguration *GREYCreateConfiguration(void) { return [[GREYTestConfiguration alloc] init]; }

@implementation GREYTestConfiguration {
  NSMutableDictionary<NSString *, id>
      *_mergedConfiguration;  // Dict for storing the merged default/overridden dicts
  NSMutableDictionary<NSString *, id>
      *_defaultConfiguration;  // Dict for storing the default configurations
  NSMutableDictionary<NSString *, id>
      *_overriddenConfiguration;                  // Dict for storing the user-defined overrides
  dispatch_queue_t _configurationIsolationQueue;  // The isolation queue to access configurations.
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _mergedConfiguration = [[NSMutableDictionary alloc] init];
    _defaultConfiguration = [[NSMutableDictionary alloc] init];
    _overriddenConfiguration = [[NSMutableDictionary alloc] init];
    _configurationIsolationQueue =
        dispatch_queue_create("com.google.earlgrey.TestConfiguration", DISPATCH_QUEUE_SERIAL);
    NSArray<NSString *> *searchPaths =
        NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    GREYFatalAssertWithMessage(searchPaths.count > 0, @"Couldn't find a valid documents directory");
    [self setDefaultValue:searchPaths.firstObject forConfigKey:kGREYConfigKeyArtifactsDirLocation];

    // These are common config keys that the AppFramework can run without as well. If modified,
    // update GREYAppConfiguration as well.
    [self setDefaultValue:@YES forConfigKey:kGREYConfigKeyActionConstraintsEnabled];
    [self setDefaultValue:@(30) forConfigKey:kGREYConfigKeyInteractionTimeoutDuration];
    [self setDefaultValue:@(10) forConfigKey:kGREYConfigKeyCALayerMaxAnimationDuration];
    [self setDefaultValue:@YES forConfigKey:kGREYConfigKeySynchronizationEnabled];
    [self setDefaultValue:@(1.5) forConfigKey:kGREYConfigKeyNSTimerMaxTrackableInterval];
    [self setDefaultValue:@YES forConfigKey:kGREYConfigKeyCALayerModifyAnimations];
    [self setDefaultValue:@(1.5) forConfigKey:kGREYConfigKeyDispatchAfterMaxTrackableDelay];
    [self setDefaultValue:@(1.5) forConfigKey:kGREYConfigKeyDelayedPerformMaxTrackableDuration];
    [self setDefaultValue:@[] forConfigKey:kGREYConfigKeyBlockedURLRegex];
    [self setDefaultValue:@(kGREYIdle) forConfigKey:kGREYConfigKeyIgnoreAppStates];
    [self setDefaultValue:@NO forConfigKey:kGREYConfigKeyIgnoreHiddenAnimations];
    [self setDefaultValue:@NO forConfigKey:kGREYConfigKeyIgnoreIsAccessible];
    [self setDefaultValue:@(kGREYAppLaunchTimeout) forConfigKey:kGREYConfigKeyAppLaunchTimeout];
    [self setDefaultValue:@NO forConfigKey:kGREYConfigKeyAutoUntrackMDCActivityIndicators];
    [self setDefaultValue:@NO forConfigKey:kGREYConfigKeyAutoHideScrollViewIndicators];
  }
  return self;
}

- (NSDictionary<NSString *, id> *)mergedConfiguration {
  __block NSDictionary<NSString *, id> *configuration;
  dispatch_sync(_configurationIsolationQueue, ^{
    // TODO: Remove needsMerge as all the writes are sync'd because of remoteConfig. // NOLINT
    if (self.needsMerge) {
      [self->_mergedConfiguration removeAllObjects];
      [self->_mergedConfiguration addEntriesFromDictionary:self->_defaultConfiguration];
      [self->_mergedConfiguration addEntriesFromDictionary:self->_overriddenConfiguration];
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

- (void)setValue:(id)value forConfigKey:(GREYConfigKey)configKey {
  GREYThrowOnNilParameter(value);
  GREYValidateValueType(value);
  dispatch_sync(_configurationIsolationQueue, ^{
    [self->_overriddenConfiguration setObject:value forKey:configKey];
    self.needsMerge = YES;
  });
  [self updateRemoteConfiguration];
  GREYLogVerbose(@"Config Key: %@ was set to: %@", configKey, value);
}

- (void)setDefaultValue:(id)value forConfigKey:(NSString *)configKey {
  GREYThrowOnNilParameter(value);
  GREYValidateValueType(value);
  dispatch_sync(_configurationIsolationQueue, ^{
    [self->_defaultConfiguration setObject:value forKey:configKey];
    self.needsMerge = YES;
  });
  [self updateRemoteConfiguration];
  GREYLogVerbose(@"Default Value for Configuration Key: %@ was set to: %@", configKey, value);
}

- (void)reset {
  dispatch_sync(_configurationIsolationQueue, ^{
    [self->_overriddenConfiguration removeAllObjects];
    self.needsMerge = YES;
  });
  [self updateRemoteConfiguration];
}

/**
 * Validates if the configuration value is of type NSValue, NSString, NSPathS, NSDictionary or
 * NSArray.
 *
 * @param value An id specifying the config value to be validated.
 */
static void GREYValidateValueType(id value) {
  if (![value isKindOfClass:[NSValue class]] && ![value isKindOfClass:[NSString class]] &&
      ![value isKindOfClass:[NSArray class]] && ![value isKindOfClass:[NSDictionary class]]) {
    [NSException raise:@"NSUnknownKeyException"
                format:@"Config Value: %@ is not an NSValue, NSString, NSDictionary or NSArray.",
                       [value class]];
  }
}

@end
