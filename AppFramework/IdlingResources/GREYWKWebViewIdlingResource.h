//
// Copyright 2020 Google Inc.
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

#import "GREYIdlingResource.h"

#if TARGET_OS_IOS
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface GREYWKWebViewIdlingResource : NSObject <GREYIdlingResource>

/**
 * Registers the idling resource for a WKWebView to @c GREYUIThreadExecutor and
 * starts tracking its content loading progress.
 *
 * @param webView The WKWebView whose loading progress is being tracked.
 *
 * @return An idling resource for the specified @c webView.
 */
+ (instancetype)trackContentLoadingProgressForWebView:(WKWebView *)webView;

/**
 * @remark init is not an available initializer. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 * Deregisters itself from @c GREYUIThreadExecutor. Idling resource will be deregistered
 * automatically when the navigation succeeds. However, if the navigation fails for any reason, it
 * should be manually deregistered.
 */
- (void)untrackContentLoadingProgressForWebView;

@end

NS_ASSUME_NONNULL_END
#endif  // TARGET_OS_IOS
