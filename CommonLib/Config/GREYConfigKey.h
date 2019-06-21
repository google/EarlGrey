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

#import <UIKit/UIKit.h>

#import "GREYDefines.h"

NS_ASSUME_NONNULL_BEGIN

typedef NSString *GREYConfigKey NS_STRING_ENUM;

/**
 *  Configuration that enables or disables usage tracking for the framework.
 *
 *  Accepted values: @c BOOL (i.e. @c YES or @c NO)
 *  Default value: @c YES
 *  @remark Set this value right after the XCUIApplication is launched to ensure the change works
 *          for all analytics calls.
 */
GREY_EXTERN GREYConfigKey const kGREYConfigKeyAnalyticsEnabled;

/**
 *  Configuration that enables or disables constraint checks before performing an action.
 *
 *  Accepted values: @c BOOL (i.e. @c YES or @c NO)
 *  Default value: @c YES
 */
GREY_EXTERN GREYConfigKey const kGREYConfigKeyActionConstraintsEnabled;

/**
 *  Configuration that holds timeout duration (in seconds) for actions and assertions. Actions or
 *  assertions that are not scheduled within this time will fail with a timeout. If the action or
 *  assertion starts within the timeout duration and if a search action is provided, then the search
 *  action will execute at least once regardless of the timeout duration.
 *
 *  Accepted values: @c double (negative values are invalid)
 *  Default value: 30.0
 */
GREY_EXTERN GREYConfigKey const kGREYConfigKeyInteractionTimeoutDuration;

/**
 *  Configuration that enables or disables EarlGrey's synchronization feature.
 *  When disabled, any command that used to wait for the app to idle before proceeding will no
 *  longer do so.
 *
 *  @remark For more fine-grained control over synchronization parameters, you can tweak other
 *          provided configuration options below.
 *
 *  Accepted values: @c BOOL (i.e. @c YES or @c NO)
 *  Default value: @c YES
 */
GREY_EXTERN GREYConfigKey const kGREYConfigKeySynchronizationEnabled;

/**
 *  Configuration that enables synchronization for different app state. By default, EarlGrey will
 *  wait for all tracked app state resources to be idle. Set this config value to options with @c
 *  GREYAppState will skip resources with those options.
 *  Example:
 *      [GREYConfiguration.sharedConfiguration setValue:@(kGREYPendingCAAnimation)
 *                                         forConfigKey:kGREYConfigKeyIgnoreAppStates];
 *
 *  Accepted values: NS_OPTIONS with value of @c GREYAppState that's wrapped in NSNumber.
 *  Default value: @c kGREYIdle, which indicates no state is ignored.
 */
GREY_EXTERN GREYConfigKey const kGREYConfigKeyIgnoreAppStates;

/**
 *  Configuration for setting the max interval (in seconds) of non-repeating NSTimers that EarlGrey
 *  will automatically track.
 *
 *  Accepted values: @c double (negative values are invalid)
 *  Default value: 1.5
 */
GREY_EXTERN GREYConfigKey const kGREYConfigKeyNSTimerMaxTrackableInterval;

/**
 *  Configuration for setting the max delay (in seconds) for dispatch_after and dispatch_after_f
 *  calls that EarlGrey will automatically track. dispatch_after and dispatch_after_f calls
 *  exceeding the specified time won't be tracked by the framework.
 *
 *  Accepted values: @c double (negative values are invalid)
 *  Default value: 1.5
 */
GREY_EXTERN GREYConfigKey const kGREYConfigKeyDispatchAfterMaxTrackableDelay;

/**
 *  Configuration for setting the max duration (in seconds) for delayed executions on the
 *  main thread originating from any performSelector:afterDelay invocations that EarlGrey will
 *  automatically track.
 *
 *  Accepted values: @c double (negative values are invalid)
 *  Default value: 1.5
 */
GREY_EXTERN GREYConfigKey const kGREYConfigKeyDelayedPerformMaxTrackableDuration;

/**
 *  Configuration that determines whether or not CALayer animations are modified. If @c YES, then
 *  cyclic animations are set to run only once and the animation duration is limited to a maximum
 *  of @c kGREYConfigKeyCALayerMaxAnimationDuration.
 *
 *  @remark This should only be used if synchronization is disabled; otherwise cyclic animations
 *          will cause EarlGrey to timeout and fail tests.
 *
 *  Accepted values: @c BOOL (i.e. @c YES or @c NO)
 *  Default value: @c YES
 */
GREY_EXTERN GREYConfigKey const kGREYConfigKeyCALayerModifyAnimations;

/**
 *  Configuration for setting max allowable animation duration (in seconds) for any CALayer based
 *  animation. Animations exceeding the specified time will have their duration truncated to value
 *  specified by this config.
 *
 *  Accepted values: @c double (negative values are invalid)
 *  Default value: 10.0
 */
GREY_EXTERN GREYConfigKey const kGREYConfigKeyCALayerMaxAnimationDuration;

/**
 *  Configuration that holds regular expressions for URLs that are blacklisted from synchronization.
 *  EarlGrey will not wait for any network request with URLs matching the blacklisted regular
 *  expressions to complete. Most frequently blacklisted URLs include those used for sending
 *  analytics, pingbacks, and background network tasks that don't interfere with testing.
 *
 *  @remark By default, EarlGrey will not synchronize with any URLs with "data" scheme.
 *
 *  Accepted values: @c An @c NSArray of valid regular expressions as @c NSString.
 *                   The strings must be accepted by @c NSRegularExpression.
 *  Default value: an empty @c NSArray
 */
GREY_EXTERN GREYConfigKey const kGREYConfigKeyURLBlacklistRegex;

/**
 *  Configuration for setting a directory location where any test artifacts such as screenshots,
 *  test logs, etc. are stored. The user should ensure that the location provided is writable by
 *  the test.
 *
 *  Accepted values: NSString containing a valid absolute filepath that is writable by the test.
 *  Default value: @c nil
 */
GREY_EXTERN GREYConfigKey const kGREYConfigKeyArtifactsDirLocation;

NS_ASSUME_NONNULL_END
