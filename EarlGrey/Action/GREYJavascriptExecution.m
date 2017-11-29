//
// Copyright 2016 Google Inc.
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

#import "GREYJavascriptExecution.h"

#import "Action/GREYActionBlock.h"
#import "GREYMatcher.h"
#import "GREYMatchers.h"
#import "Matcher/GREYAllOf.h"
#import "Matcher/GREYAnyOf.h"
#import "Matcher/GREYNot.h"
#import "Synchronization/GREYUIThreadExecutor.h"
#import <WebKit/WebKit.h>

@implementation GREYJavascriptExecution

+ (GREYActionBlock *)executeJavascript:(NSString *)js output:(out __strong NSString **)outResult {
    // TODO: JS Errors should be propagated up.
    id<GREYMatcher> constraints = grey_allOf(grey_not(grey_systemAlertViewShown()),
                                             grey_anyOf(grey_kindOfClass([UIWebView class]), grey_kindOfClass([WKWebView class]) ,nil),
                                             nil);
    return [[GREYActionBlock alloc] initWithName:@"Execute JavaScript"
                                     constraints:constraints
                                    performBlock:^BOOL (UIView *webView,
                                                        __strong NSError **errorOrNil) {
                                        if ([webView isKindOfClass:[UIWebView class]]) {
                                          UIWebView *uiKitWebView = (UIWebView*)webView;
                                          if (outResult) {
                                            *outResult = [uiKitWebView stringByEvaluatingJavaScriptFromString:js];
                                          } else {
                                            [uiKitWebView stringByEvaluatingJavaScriptFromString:js];
                                          }
                                        } else if ([webView isKindOfClass:[WKWebView class]]) {
                                          WKWebView *webKitWebView = (WKWebView*)webView;
                                          if (outResult) {
                                            [webKitWebView evaluateJavaScript:js completionHandler:^(id _Nullable result, NSError * _Nullable error) {
                                            *outResult = result;
                                            }];
                                          } else {
                                            [webKitWebView evaluateJavaScript:js completionHandler:nil];
                                          }
                                        }
                                        // TODO: Delay should be removed once webview sync is stable.
                                        [[GREYUIThreadExecutor sharedInstance] drainForTime:0.5];  // Wait for actions to register.
                                        return YES;
                                    }];
}

@end

