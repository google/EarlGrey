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

#import "GREYWKWebViewIdlingResource.h"

#if TARGET_OS_IOS
#import "GREYIdlingResource.h"
#import "GREYUIThreadExecutor+Private.h"
#import "GREYUIThreadExecutor.h"

@implementation GREYWKWebViewIdlingResource {
  __weak WKWebView *_webView;
}

+ (instancetype)trackContentLoadingProgressForWebView:(WKWebView *)webView {
  GREYWKWebViewIdlingResource *resource =
      [[GREYWKWebViewIdlingResource alloc] initWithWebView:webView];
  [[GREYUIThreadExecutor sharedInstance] registerIdlingResource:resource];
  return resource;
}

- (void)untrackContentLoadingProgressForWebView {
  [[GREYUIThreadExecutor sharedInstance] deregisterIdlingResource:self];
}

- (instancetype)initWithWebView:(WKWebView *)webView {
  self = [super init];
  if (self) {
    _webView = webView;
  }
  return self;
}

- (BOOL)isIdleNow {
  if (_webView.estimatedProgress == 1 && _webView.loading == NO) {
    [self untrackContentLoadingProgressForWebView];
    return YES;
  }
  return NO;
}

- (NSString *)idlingResourceDescription {
  return @"WKWebView";
}

- (NSString *)idlingResourceName {
  return @"WKWebView";
}

@end
#endif  // TARGET_OS_IOS
