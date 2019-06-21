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

#import "GREYUIWebViewDelegate.h"
#import "GREYAppStateTracker.h"
#import "GREYHostApplicationDistantObject+WebViewTest.h"

/**
 *  Required for testing UIWebView states.
 */
@interface GREYAppStateTracker (ExposedForTesting)
- (GREYAppState)grey_lastKnownStateForObject:(id)object;
@end

@interface UIWebView (ExposedForTesting)
- (void)grey_trackAJAXLoading;
- (GREYAppStateTrackerObject *)trackerObjectForWebView;
@end

@interface GREYHostApplicationDistantObject () <UIWebViewDelegate>
@end

@implementation GREYHostApplicationDistantObject (WebViewTest)

- (BOOL)delegateIsProxyDelegate {
  UIWebView *webView = [[UIWebView alloc] init];
  GREYUIWebViewDelegate *delegate = [webView delegate];
  return [delegate isKindOfClass:[GREYUIWebViewDelegate class]];
}

- (BOOL)delegateIsProxyDelegateAfterSettingCustomDelegate {
  UIWebView *webView = [[UIWebView alloc] init];
  webView.delegate = self;
  GREYUIWebViewDelegate *delegate = [webView delegate];
  return [delegate isKindOfClass:[GREYUIWebViewDelegate class]];
}

- (BOOL)delegateIsNotNilAfterClearingDelegate {
  UIWebView *webView = [[UIWebView alloc] init];
  webView.delegate = nil;
  GREYUIWebViewDelegate *delegate = [webView delegate];
  return [delegate isKindOfClass:[GREYUIWebViewDelegate class]];
}

- (BOOL)delegateIsNotDeallocAfterClearingDelegate {
  UIWebView *webView = [[UIWebView alloc] init];
  __weak GREYUIWebViewDelegate *delegate;
  {
    delegate = [webView delegate];
    NSAssert([delegate isKindOfClass:[GREYUIWebViewDelegate class]], @"%@", [delegate class]);
    [webView setDelegate:nil];
  }

  __weak GREYUIWebViewDelegate *secondDelegate;
  {
    secondDelegate = [webView delegate];
    NSAssert([secondDelegate isKindOfClass:[GREYUIWebViewDelegate class]], @"%@", [delegate class]);
    [webView setDelegate:nil];
  }

  NSAssert(delegate != nil, @"should not be nil");
  NSAssert(secondDelegate != nil, @"should not be nil");
  NSAssert(delegate != secondDelegate, @"should not be equal");
  return YES;
}

- (BOOL)webViewDeallocClearsAllDelegates {
  __weak GREYUIWebViewDelegate *delegate;
  __weak GREYUIWebViewDelegate *secondDelegate;

  @autoreleasepool {
    __autoreleasing UIWebView *webView = [[UIWebView alloc] init];
    {
      delegate = [webView delegate];
      [webView setDelegate:nil];
    }

    {
      secondDelegate = [webView delegate];
      [webView setDelegate:nil];
    }
    NSAssert([delegate isKindOfClass:[GREYUIWebViewDelegate class]], @"%@", [delegate class]);
    NSAssert([secondDelegate isKindOfClass:[GREYUIWebViewDelegate class]], @"%@", [delegate class]);
  }
  NSAssert(delegate == nil, @"should be nil");
  NSAssert(secondDelegate == nil, @"should be nil");
  return YES;
}

- (BOOL)webViewProxyDelegateClearsOutDeallocedDelegates:(id<UIWebViewDelegate>)autoRelDelegate {
  UIWebView *webView = [[UIWebView alloc] init];
  id<UIWebViewDelegate> delegate;

  @autoreleasepool {
    [webView setDelegate:autoRelDelegate];
    delegate = [webView delegate];
    NSAssert([delegate isKindOfClass:[GREYUIWebViewDelegate class]], @"%@", [delegate class]);
  }

  // Should not crash.
  [delegate webViewDidFinishLoad:webView];
  return YES;
}

- (BOOL)ajaxTrackedWhenAJAXListenerSchemeIsPending {
  UIWebView *webView = [[UIWebView alloc] init];
  [webView grey_trackAJAXLoading];

  GREYAppState lastState =
      [[GREYAppStateTracker sharedInstance] grey_lastKnownStateForObject:webView];
  BOOL isAsyncRequestPending = ((lastState & kGREYPendingUIWebViewAsyncRequest) != 0);
  return isAsyncRequestPending;
}

- (BOOL)stopLoadingClearsStateInStateTracker {
  UIWebView *webView = [[UIWebView alloc] init];
  [webView grey_trackAJAXLoading];

  [webView stopLoading];
  GREYAppState lastState =
      [[GREYAppStateTracker sharedInstance] grey_lastKnownStateForObject:webView];
  BOOL isAsyncRequestPending = ((lastState & kGREYPendingUIWebViewAsyncRequest) != 0);
  return isAsyncRequestPending;
}

- (BOOL)ajaxTrackedWhenAJAXListenerSchemeIsStarting {
  UIWebView *webView = [[UIWebView alloc] init];
  NSURLRequest *req =
      [NSURLRequest requestWithURL:[NSURL URLWithString:@"greyajaxlistener://starting"]];
  // Invoke manually since loadRequest doesn't work.
  [[webView delegate] webView:webView
      shouldStartLoadWithRequest:req
                  navigationType:UIWebViewNavigationTypeOther];
  GREYAppState lastState =
      [[GREYAppStateTracker sharedInstance] grey_lastKnownStateForObject:webView];
  BOOL isAsyncRequestPending = ((lastState & kGREYPendingUIWebViewAsyncRequest) != 0);
  return isAsyncRequestPending;
}

- (BOOL)ajaxUnTrackedWhenAJAXListenerSchemeIsCompleted {
  UIWebView *webView = [[UIWebView alloc] init];
  [webView grey_trackAJAXLoading];

  NSURLRequest *req =
      [NSURLRequest requestWithURL:[NSURL URLWithString:@"greyajaxlistener://completed"]];
  // Invoke manually since loadRequest doesn't work.
  [[webView delegate] webView:webView
      shouldStartLoadWithRequest:req
                  navigationType:UIWebViewNavigationTypeOther];
  GREYAppState lastState =
      [[GREYAppStateTracker sharedInstance] grey_lastKnownStateForObject:webView];
  BOOL isAsyncRequestPending = ((lastState & kGREYPendingUIWebViewAsyncRequest) != 0);
  return isAsyncRequestPending;
}

@end
