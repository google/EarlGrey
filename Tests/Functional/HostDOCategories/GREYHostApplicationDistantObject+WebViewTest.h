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

#import "EarlGreyApp.h"
#import "GREYHostApplicationDistantObject.h"

/** GREYHostApplicationDistantObject extension for the WebView test. */
@interface GREYHostApplicationDistantObject (WebViewTest)

/**
 *  @return If the delegate is a proxy delegate.
 */
- (BOOL)delegateIsProxyDelegate;

/**
 *  @return If the delegate is a proxy delegate after setting a custom delegate.
 */
- (BOOL)delegateIsProxyDelegateAfterSettingCustomDelegate;

/**
 *  @return If the delegate is not nil after clearing delegate.
 */
- (BOOL)delegateIsNotNilAfterClearingDelegate;

/**
 *  @return If the delegate is not deallocated after clearing delegate.
 */
- (BOOL)delegateIsNotDeallocAfterClearingDelegate;

/**
 *  @return If the delegate is deallocated after clearing delegate.
 */
- (BOOL)webViewDeallocClearsAllDelegates;

/**
 *  @return If the webview proxy delegate clears out deallocated delegates.
 */
- (BOOL)webViewProxyDelegateClearsOutDeallocedDelegates:(id<UIWebViewDelegate>)autoRelDelegate;

/**
 *  @return If AJAX is tracked when AJAX listener scheme is pending.
 */
- (BOOL)ajaxTrackedWhenAJAXListenerSchemeIsPending;

/**
 *  @return If AJAX is untracked when webview stops loading.
 */
- (BOOL)stopLoadingClearsStateInStateTracker;

/**
 *  @return If AJAX is tracked when AJAX listener scheme is starting.
 */
- (BOOL)ajaxTrackedWhenAJAXListenerSchemeIsStarting;

/**
 *  @return If AJAX is untracked when AJAX listener scheme is completed.
 */
- (BOOL)ajaxUnTrackedWhenAJAXListenerSchemeIsCompleted;

@end
