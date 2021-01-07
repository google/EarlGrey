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

#import "GREYSurrogateDelegate.h"

#if TARGET_OS_IOS
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Surrogate delegate for WKWebView::navigationDelegate to track the progress for loading content.
 */
@interface GREYWKWebViewNavigationDelegate
    : GREYSurrogateDelegate <WKNavigationDelegate, WKUIDelegate>

/**
 * Creates and registers an idling resource that tracks the content loading progress of @c webView.
 *
 * @param webView The WKWebView whose loading progress is being tracked.
 */
- (void)trackIdlingResourceForWebView:(WKWebView *)webView;

/**
 * Forcefully untracks the idling resource of the WKWebView tied to the current delegate object.
 * Normally, the WKWebView is untracked within the delegate when either navigation fails or content
 * process terminates. However, in case the user cancels the loading with @c stopLoading
 *
 * @note this needs to be called within the swizzled WKWebView methods to untrack the idling
 *       resource for the WKWebView.
 */
- (void)untrackIdlingResourceForWebView;

@end

NS_ASSUME_NONNULL_END

#endif  // TARGET_OS_IOS
