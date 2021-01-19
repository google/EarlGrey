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

#import "GREYWKWebViewNavigationDelegate.h"

#if TARGET_OS_IOS
#import "GREYWKWebViewIdlingResource.h"

@implementation GREYWKWebViewNavigationDelegate {
  __weak GREYWKWebViewIdlingResource *_idlingResource;
}

- (void)trackIdlingResourceForWebView:(WKWebView *)webView {
  // If WKWebView is not in the hierarchy, do not track.
  if (!webView.window) {
    return;
  }
  _idlingResource = [GREYWKWebViewIdlingResource trackContentLoadingProgressForWebView:webView];
}

- (void)untrackIdlingResourceForWebView {
  [_idlingResource untrackContentLoadingProgressForWebView];
}

- (void)webView:(WKWebView *)webView
    didFailNavigation:(null_unspecified WKNavigation *)navigation
            withError:(nonnull NSError *)error {
  if ([[self originalDelegate] respondsToSelector:@selector(webView:
                                                      didFailNavigation:withError:)]) {
    [[self originalDelegate] webView:webView didFailNavigation:navigation withError:error];
  }
  [_idlingResource untrackContentLoadingProgressForWebView];
}

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
  id delegate = [self originalDelegate];
  if ([delegate respondsToSelector:@selector(webViewWebContentProcessDidTerminate:)]) {
    [delegate webViewWebContentProcessDidTerminate:webView];
  }
  [_idlingResource untrackContentLoadingProgressForWebView];
}

- (void)webView:(WKWebView *)webView
    didFailProvisionalNavigation:(WKNavigation *)navigation
                       withError:(NSError *)error {
  if ([[self originalDelegate] respondsToSelector:@selector(webView:
                                                      didFailProvisionalNavigation:withError:)]) {
    [[self originalDelegate] webView:webView
        didFailProvisionalNavigation:navigation
                           withError:error];
  }
  [_idlingResource untrackContentLoadingProgressForWebView];
}

@end
#endif  // TARGET_OS_IOS
