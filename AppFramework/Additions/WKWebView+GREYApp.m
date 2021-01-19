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


#include <objc/runtime.h>

#import "GREYWKWebViewNavigationDelegate.h"
#import "GREYFatalAsserts.h"
#import "GREYSwizzler.h"

#if TARGET_OS_IOS
#import <WebKit/WebKit.h>

@implementation WKWebView (GREYApp)

+ (void)load {
  GREYSwizzler *swizzler = [[GREYSwizzler alloc] init];
  BOOL swizzleSuccess = [swizzler swizzleClass:self
                         replaceInstanceMethod:@selector(setNavigationDelegate:)
                                    withMethod:@selector(greyswizzled_setNavigationDelegate:)];
  GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle setNavigationDelegate:");

  swizzleSuccess = [swizzler swizzleClass:self
                    replaceInstanceMethod:@selector(navigationDelegate)
                               withMethod:@selector(greyswizzled_navigationDelegate)];
  GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle navigationDelegate:");

  swizzleSuccess = [swizzler swizzleClass:self
                    replaceInstanceMethod:@selector(loadRequest:)
                               withMethod:@selector(greyswizzled_loadRequest:)];
  GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle setNavigationDelegate:");

  swizzleSuccess = [swizzler swizzleClass:self
                    replaceInstanceMethod:@selector(loadFileURL:allowingReadAccessToURL:)
                               withMethod:@selector(greyswizzled_loadFileURL:
                                                     allowingReadAccessToURL:)];
  GREYFatalAssertWithMessage(swizzleSuccess,
                             @"Cannot swizzle loadFileURL:allowingReadAccessToURL:");

  // Method loadHTMLString:baseURL: invokes the following method internally. Therefore, it does not
  // need swizzling.
  swizzleSuccess =
      [swizzler swizzleClass:self
          replaceInstanceMethod:@selector(loadData:MIMEType:characterEncodingName:baseURL:)
                     withMethod:@selector(greyswizzled_loadData:
                                                       MIMEType:characterEncodingName:baseURL:)];
  GREYFatalAssertWithMessage(swizzleSuccess,
                             @"Cannot swizzle loadData:MIMEType:characterEncodingName:baseURL:");

  swizzleSuccess = [swizzler swizzleClass:self
                    replaceInstanceMethod:@selector(reload)
                               withMethod:@selector(greyswizzled_reload)];
  GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle reload");

  swizzleSuccess = [swizzler swizzleClass:self
                    replaceInstanceMethod:@selector(reloadFromOrigin)
                               withMethod:@selector(greyswizzled_reloadFromOrigin)];
  GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle reloadFromOrigin");

  swizzleSuccess = [swizzler swizzleClass:self
                    replaceInstanceMethod:@selector(stopLoading)
                               withMethod:@selector(greyswizzled_stopLoading)];
  GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle stopLoading");
}

#pragma mark - Swizzled Implementation

- (void)greyswizzled_setNavigationDelegate:(id)navigationDelegate {
  [self setSurrogateDelegateWithOriginalDelegate:navigationDelegate];
}

- (id<WKNavigationDelegate>)greyswizzled_navigationDelegate {
  id<WKNavigationDelegate> delegate =
      INVOKE_ORIGINAL_IMP(id<WKNavigationDelegate>, @selector(greyswizzled_navigationDelegate));
  GREYFatalAssertWithMessage(
      delegate == nil || [delegate isKindOfClass:[GREYWKWebViewNavigationDelegate class]],
      @"Delegate type should be either GREYWKWebViewNavigationDelegate or nil.");
  return [(GREYWKWebViewNavigationDelegate *)delegate originalDelegate];
}

- (WKNavigation *)greyswizzled_loadRequest:(NSURLRequest *)request {
  [[self surrogateDelegate] trackIdlingResourceForWebView:self];
  return INVOKE_ORIGINAL_IMP1(WKNavigation *, @selector(greyswizzled_loadRequest:), request);
}

- (WKNavigation *)greyswizzled_loadFileURL:(NSURL *)URL
                   allowingReadAccessToURL:(NSURL *)readAccessURL {
  [[self surrogateDelegate] trackIdlingResourceForWebView:self];
  return INVOKE_ORIGINAL_IMP2(WKNavigation *,
                              @selector(greyswizzled_loadFileURL:allowingReadAccessToURL:), URL,
                              readAccessURL);
}

- (WKNavigation *)greyswizzled_loadData:(NSData *)data
                               MIMEType:(NSString *)MIMEType
                  characterEncodingName:(NSString *)characterEncodingName
                                baseURL:(NSURL *)baseURL {
  [[self surrogateDelegate] trackIdlingResourceForWebView:self];
  return INVOKE_ORIGINAL_IMP4(
      WKNavigation *, @selector(greyswizzled_loadData:MIMEType:characterEncodingName:baseURL:),
      data, MIMEType, characterEncodingName, baseURL);
}

- (WKNavigation *)greyswizzled_reload {
  [[self surrogateDelegate] trackIdlingResourceForWebView:self];
  return INVOKE_ORIGINAL_IMP(WKNavigation *, @selector(greyswizzled_reload));
}

- (WKNavigation *)greyswizzled_reloadFromOrigin {
  [[self surrogateDelegate] trackIdlingResourceForWebView:self];
  return INVOKE_ORIGINAL_IMP(WKNavigation *, @selector(greyswizzled_reloadFromOrigin));
}

- (void)greyswizzled_stopLoading {
  [[self surrogateDelegate] untrackIdlingResourceForWebView];
  INVOKE_ORIGINAL_IMP(void, @selector(greyswizzled_stopLoading));
}

#pragma mark - Private

/**
 * Sets the @c navigationDelegate of the current WKWebView to a proxy delegate to the original
 * delegate @c delegate.
 *
 * @param delegate The original delegate the GREYWKWebViewNavigationDelegate will proxy to. It can
 *                 be @c nil.
 *
 * @remark Since @c navigationDelegate is a weak property, the current instance will hold a strong
 *         reference to the proxy delegate via objc runtime. Otherwise, @c navigationDelegate will
 *         be auto-released at the end of the method.
 *         https://developer.apple.com/documentation/webkit/wkwebview/1414971-navigationdelegate?language=objc
 */
- (void)setSurrogateDelegateWithOriginalDelegate:(id<WKNavigationDelegate>)delegate {
  GREYWKWebViewNavigationDelegate *proxyDelegate =
      [[GREYWKWebViewNavigationDelegate alloc] initWithOriginalDelegate:delegate isWeak:YES];
  objc_setAssociatedObject(self, @selector(greyswizzled_setNavigationDelegate:), proxyDelegate,
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  INVOKE_ORIGINAL_IMP1(void, @selector(greyswizzled_setNavigationDelegate:), proxyDelegate);
}

/**
 * @return The proxy delegate.
 */
- (GREYWKWebViewNavigationDelegate *)surrogateDelegate {
  GREYWKWebViewNavigationDelegate *delegate =
      objc_getAssociatedObject(self, @selector(greyswizzled_setNavigationDelegate:));
  return delegate;
}

@end
#endif
