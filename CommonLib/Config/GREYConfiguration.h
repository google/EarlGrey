//
// Copyright 2017 Google Inc.
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

/**
 *  @file GREYConfiguration.h
 *  @brief A key-value store for configuring global behavior. Configuration values are read just
 *         before performing a related function. On-going functions may not be affected by the
 *         changes in the configuration until the values are re-read.
 */

#import <Foundation/Foundation.h>

// GREYConfiguration's Configuration Key Strings are indirectly exposed through here, to prevent
// users from having to import the Configuration Strings directly.
#import "GREYConfigKey.h"
#import "GREYDefines.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Provides an interface for runtime configuration of EarlGrey's behavior.
 */
@interface GREYConfiguration : NSObject

/**
 *  The singleton GREYConfiguration instance.
 *
 *  @note The actual instance can be GREYAppConfiguration or GREYTestConfiguration depending on the
 *        process/target to run against.
 */
@property(class, readonly, strong) GREYConfiguration *sharedConfiguration;

/**
 *  If a user-configured value is associated with the given @c configKey, it is returned,
 *  otherwise the default value is returned. If a default value is not found, or an
 *  NSInvalidArgumentException is raised.
 *
 *  @param configKey The key whose value is being queried. Must be a valid @c NSString.
 *
 *  @throws NSInvalidArgumentException If no value could be found associated with @c configKey.
 *
 *  @return The value for the configuration stored associate with @c configKey.
 */
- (id)valueForConfigKey:(GREYConfigKey)configKey;

/**
 *  If a user-configured value is associated with the given @c configKey, it is returned, otherwise
 *  the default value is returned. If a default value is not found, NSInvalidArgumentException is
 *  raised.
 *
 *  @param configKey The key whose value is being queried. Must be a valid @c NSString.
 *
 *  @throws NSInvalidArgumentException If no value could be found for the given @c configKey.
 *
 *  @return The @c BOOL value for the configuration associated with @c configKey.
 */
- (BOOL)boolValueForConfigKey:(GREYConfigKey)configKey;

/**
 *  If a user-configured value is associated with the given @c configKey, it is returned, otherwise
 *  the default value is returned. If a default value is not found, NSInvalidArgumentException is
 *  raised.
 *
 *  @param configKey The key whose value is being queried. Must be a valid @c NSString.
 *
 *  @throws NSInvalidArgumentException If no value could be found for the given @c configKey.
 *
 *  @return The integer value for the configuration associated with @c configKey.
 */
- (NSInteger)integerValueForConfigKey:(GREYConfigKey)configKey;

/**
 *  If a user-configured value is associated with the given @c configKey, it is returned, otherwise
 *  the default value is returned. If a default value is not found, NSInvalidArgumentException is
 *  raised.
 *
 *  @param configKey The key whose value is being queried. Must be a valid @c NSString.
 *
 *  @throws NSInvalidArgumentException If no value could be found for the given @c configKey.
 *
 *  @return The unsigned integer value for the configuration associated with @c configKey.
 */
- (NSUInteger)unsignedIntegerValueForConfigKey:(GREYConfigKey)configKey;

/**
 *  If a user-configured value is associated with the given @c configKey, it is returned, otherwise
 *  the default value is returned. If a default value is not found, NSInvalidArgumentException is
 *  raised.
 *
 *  @param configKey The key whose value is being queried. Must be a valid @c NSString.
 *
 *  @throws NSInvalidArgumentException If no value could be found for the given @c configKey.
 *
 *  @return The @c double value for the configuration associated with @c configKey.
 */
- (double)doubleValueForConfigKey:(GREYConfigKey)configKey;

/**
 *  If a user-configured value is associated with the given @c configKey, it is returned, otherwise
 *  the default value is returned. If a default value is not found, NSInvalidArgumentException is
 *  raised.
 *
 *  @param configKey The key whose value is being queried. Must be a valid @c NSString.
 *
 *  @throws NSInvalidArgumentException If no value could be found for the given @c configKey.
 *
 *  @return The string value for the configuration associated with @c configKey.
 */
- (NSString *)stringValueForConfigKey:(GREYConfigKey)configKey;

/**
 *  If a user-configured value is associated with the given @c configKey, it is returned, otherwise
 *  the default value is returned. If a default value is not found, NSInvalidArgumentException is
 *  raised.
 *
 *  @param configKey The key whose value is being queried. Must be a valid @c NSString.
 *
 *  @throws NSInvalidArgumentException If no value could be found for the given @c configKey.
 *
 *  @return The array value for the configuration associated with @c configKey.
 */
- (NSArray *)arrayValueForConfigKey:(GREYConfigKey)configKey;

/**
 *  Resets all configurations to default values, removing all the configured values.
 *
 *  @remark Any default values added by calling GREYConfiguration:setDefaultValue:forConfigKey:
 *  are not reset.
 */
- (void)reset;

/**
 *  Given a value and a key that identifies a configuration, set the value of the configuration.
 *  Overwrites any previous value for the configuration.
 *
 *  @remark To restore original values, call GREYConfiguration::reset.
 *
 *  @param value     The configuration value to be set. Scalars should we wrapped in an NSValue.
 *                   NSString and NSArrays can also be passed here depending on the Config Key.
 *  @param configKey Key identifying an existing or new configuration. Must be a valid
 *                   GREYConfigKey.
 */
- (void)setValue:(id)value forConfigKey:(GREYConfigKey)configKey;

/**
 *  Associates configuration identified by @c configKey with the provided @c value.
 *
 *  @remark Default values persist even after resetting the configuration
 *          (using GREYConfiguration::reset)
 *
 *  @param value     The configuration value to be set. Scalars should be wrapped in @c NSValue or
 * @c NSString.
 *  @param configKey Key identifying an existing or new configuration. Must be a valid
 * GREYConfigKey.
 */
- (void)setDefaultValue:(id)value forConfigKey:(GREYConfigKey)configKey;

#pragma mark - Unavailable

/** These methods often cause confusion with the setValue:forConfigKey: and
    setDefaultValue:forConfigKey: methods. Marking them as unavailable to prevent autocomplete
    errors. */

- (void)setValue:(nullable id)value forKey:(NSString *)key NS_UNAVAILABLE;
- (void)setValue:(nullable id)value forKeyPath:(NSString *)keyPath NS_UNAVAILABLE;
- (void)setValue:(nullable id)value forUndefinedKey:(NSString *)key NS_UNAVAILABLE;

@end

/**
 *  @return the value of type @c id associated with the given @c __configName.
 */
#define GREY_CONFIG(__configName) \
  [GREYConfiguration.sharedConfiguration valueForConfigKey:(__configName)]

/**
 *  @return @c BOOL value associated with the given @c __configName.
 */
#define GREY_CONFIG_BOOL(__configName) \
  [GREYConfiguration.sharedConfiguration boolValueForConfigKey:(__configName)]

/**
 *  @return @c NSInteger value associated with the given @c __configName.
 */
#define GREY_CONFIG_INTEGER(__configName) \
  [GREYConfiguration.sharedConfiguration integerValueForConfigKey:(__configName)]

/**
 *  @return @c NSUInteger value associated with the given @c __configName.
 */
#define GREY_CONFIG_UINTEGER(__configName) \
  [GREYConfiguration.sharedConfiguration unsignedIntegerValueForConfigKey:(__configName)]

/**
 *  @return @c double value associated with the given @c __configName.
 */
#define GREY_CONFIG_DOUBLE(__configName) \
  [GREYConfiguration.sharedConfiguration doubleValueForConfigKey:(__configName)]

/**
 *  @return @c NSString value associated with the given @c __configName.
 */
#define GREY_CONFIG_STRING(__configName) \
  [GREYConfiguration.sharedConfiguration stringValueForConfigKey:(__configName)]

/**
 *  @return @c NSArray value associated with the given @c __configName.
 */
#define GREY_CONFIG_ARRAY(__configName) \
  [GREYConfiguration.sharedConfiguration arrayValueForConfigKey:(__configName)]

NS_ASSUME_NONNULL_END
