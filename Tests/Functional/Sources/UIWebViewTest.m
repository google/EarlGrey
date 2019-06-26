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

#import "GREYHostApplicationDistantObject+WebViewTest.h"
#import "BaseIntegrationTest.h"

@interface UIWebViewTest : BaseIntegrationTest <UIWebViewDelegate>
@end

@implementation UIWebViewTest

- (void)setUp {
  [super setUp];
  [self openTestViewNamed:@"UIWebView"];
}

- (void)testSynchronizationWhenSwitchingBetweenLoadingMethods {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"loadLocalFile")]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Row 1")]
      assertWithMatcher:grey_sufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"loadHTMLString")]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Row 1")]
      assertWithMatcher:grey_sufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"loadLocalFile")]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Row 1")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

- (void)testPDFIdlesCorrectly {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"loadPDF")]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"loadLocalFile")]
      performAction:grey_tap()];
}

/*
 * These tests are really unit tests but since we hit EXC_BAD_ACCESS initializing a UIWebView in
 * a unit test environment, we are moving these to UI test suite
 */
- (void)testDelegateIsProxyDelegate {
  XCTAssertTrue([[GREYHostApplicationDistantObject sharedInstance] delegateIsProxyDelegate]);
}

- (void)testDelegateIsProxyDelegateAfterSettingCustomDelegate {
  XCTAssertTrue([[GREYHostApplicationDistantObject sharedInstance]
      delegateIsProxyDelegateAfterSettingCustomDelegate]);
}

- (void)testDelegateIsNotNilAfterClearingDelegate {
  XCTAssertTrue(
      [[GREYHostApplicationDistantObject sharedInstance] delegateIsNotNilAfterClearingDelegate]);
}

- (void)testDelegateIsNotDeallocAfterClearingDelegate {
  XCTAssertTrue([[GREYHostApplicationDistantObject sharedInstance]
      delegateIsNotDeallocAfterClearingDelegate]);
}

- (void)testWebViewDeallocClearsAllDelegates {
  XCTAssertTrue(
      [[GREYHostApplicationDistantObject sharedInstance] webViewDeallocClearsAllDelegates]);
}

- (void)testWebViewProxyDelegateClearsOutDeallocedDelegates {
  __autoreleasing id<UIWebViewDelegate> autoRelDelegate = [[UIWebViewTest alloc] init];
  XCTAssertTrue([[GREYHostApplicationDistantObject sharedInstance]
      webViewProxyDelegateClearsOutDeallocedDelegates:autoRelDelegate]);
}

- (void)testAjaxUnTrackedWhenAJAXListenerSchemeIsPending {
  XCTAssertTrue([[GREYHostApplicationDistantObject sharedInstance]
                    ajaxTrackedWhenAJAXListenerSchemeIsPending],
                @"should be pending");
}

- (void)testStopLoadingClearsStateInStateTracker {
  XCTAssertFalse(
      [[GREYHostApplicationDistantObject sharedInstance] stopLoadingClearsStateInStateTracker],
      @"should not be pending");
  ;
}

- (void)testAjaxTrackedWhenAJAXListenerSchemeIsStarting {
  XCTAssertTrue([[GREYHostApplicationDistantObject sharedInstance]
                    ajaxTrackedWhenAJAXListenerSchemeIsStarting],
                @"should be pending");
}

- (void)testAjaxUnTrackedWhenAJAXListenerSchemeIsCompleted {
  XCTAssertFalse([[GREYHostApplicationDistantObject sharedInstance]
                     ajaxUnTrackedWhenAJAXListenerSchemeIsCompleted],
                 @"should not be pending");
}

@end
