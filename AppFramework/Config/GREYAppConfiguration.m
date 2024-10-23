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

#import "GREYAppConfiguration.h"

#import "GREYAppState.h"
#import "GREYConfigKey.h"
#import "GREYConfiguration+Private.h"
#import "GREYConfiguration.h"
#import "GREYHostApplicationDistantObject.h"
#import "GREYHostBackgroundDistantObject.h"
#import "GREYConstants.h"
#import "GREYLogger.h"
#import "GREYTestConfiguration.h"
#import "EDOClientService.h"
#import "NSObject+EDOValueObject.h"

GREYConfiguration *GREYCreateConfiguration(void) { return [[GREYAppConfiguration alloc] init]; }

@implementation GREYAppConfiguration {
  /**
   * The remote test configuration that contains the source of truth data.
   */
  GREYTestConfiguration *_testConfiguration;
  /**
   * The merged configuration dictionary containing the most updated configuration values.
   */
  NSDictionary<NSString *, id> *_mergedConfiguration;
  /**
   * The isolation queue to access _mergedConfiguration.
   */
  dispatch_queue_t _configurationIsolationQueue;
}

- (instancetype)init {
  self = [super init];

  if (self) {
    _configurationIsolationQueue =
        dispatch_queue_create("com.google.earlgrey.ConfigurationIsolation", DISPATCH_QUEUE_SERIAL);
    if (IsStandaloneMode()) {
      [self updateConfiguration:GetFakeLocalTestingAppConfig()];
      GREYLog(@"The application is now being run in EarlGreyStandaloneMode with the default "
              @"GREYConfiguration.");
    } else {
      _testConfiguration =
          (GREYTestConfiguration *)GREY_REMOTE_CLASS_IN_TEST(GREYConfiguration).sharedConfiguration;
      dispatch_sync(GREYHostBackgroundDistantObject.sharedInstance.backgroundQueue, ^{
        // This effectively makes the remote invocations on self running on the background queue
        // because it will be wrapped by the host service running on the background queue.
        self->_testConfiguration.remoteConfiguration = self;
      });
      [self updateConfiguration:[[_testConfiguration returnByValue] mergedConfiguration]];
      GREYLog(@"The application is now being run with EarlGrey embedded in it.");
    }
  }
  return self;
}

- (NSDictionary *)mergedConfiguration {
  __block NSDictionary<NSString *, id> *configuration;
  dispatch_sync(_configurationIsolationQueue, ^{
    configuration = self->_mergedConfiguration;
  });
  return configuration;
}

- (void)updateConfiguration:(NSDictionary<NSString *, id> *)configuration {
  dispatch_sync(_configurationIsolationQueue, ^{
    self->_mergedConfiguration = configuration;
  });
}

- (void)setValue:(id)value forConfigKey:(NSString *)configKey {
  [_testConfiguration setValue:[value passByValue] forConfigKey:configKey];
}

- (void)setDefaultValue:(id)value forConfigKey:(NSString *)configKey {
  [_testConfiguration setDefaultValue:[value passByValue] forConfigKey:configKey];
}

- (void)reset {
  [_testConfiguration reset];
}

#pragma mark - Local Testing Config

/**
 * Signifies if the configuration is launched in an application directly. Allows the configuration
 * to load fake data.
 */
static BOOL IsStandaloneMode(void) {
  static dispatch_once_t onceToken;
  static BOOL isStandaloneMode;
  dispatch_once(&onceToken, ^{
    NSDictionary<NSString *, NSString *> *environment = [[NSProcessInfo processInfo] environment];
    isStandaloneMode = [[environment valueForKey:@"EarlGreyStandaloneMode"] isEqualToString:@"1"];
  });
  return isStandaloneMode;
}

/**
 * @return An NSDictionary containing the default configuration values. These aid local testing of
 *         AppFramework without the test side.
 * @note Ensure this is kept in parity with the common Configuration keys in GREYTestConfiguration.
 */
static NSDictionary *GetFakeLocalTestingAppConfig(void) {
  static dispatch_once_t onceToken;
  static NSDictionary<GREYConfigKey, id> *fakeLocalTestingAppConfig;
  dispatch_once(&onceToken, ^{
    fakeLocalTestingAppConfig = @{
      kGREYConfigKeyActionConstraintsEnabled : @YES,
      kGREYConfigKeyInteractionTimeoutDuration : @(30),
      kGREYConfigKeyCALayerMaxAnimationDuration : @(10),
      kGREYConfigKeySynchronizationEnabled : @YES,
      kGREYConfigKeyMainQueueTrackingEnabled : @YES,
      kGREYConfigKeyNSTimerMaxTrackableInterval : @(1.5),
      kGREYConfigKeyCALayerModifyAnimations : @YES,
      kGREYConfigKeyDispatchAfterMaxTrackableDelay : @(1.5),
      kGREYConfigKeyDelayedPerformMaxTrackableDuration : @(1.5),
      kGREYConfigKeyBlockedURLRegex : @[],
      kGREYConfigKeyIgnoreAppStates : @(kGREYIdle),
      kGREYConfigKeyIgnoreHiddenAnimations : @NO,
      kGREYConfigKeyIgnoreIsAccessible : @NO,
      kGREYConfigKeyAppLaunchTimeout : @(kGREYAppLaunchTimeout),
      kGREYConfigKeyAutoUntrackMDCActivityIndicators : @NO,
      kGREYConfigKeyAutoHideScrollViewIndicators : @NO,
    };
  });
  return fakeLocalTestingAppConfig;
}

@end
