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
#import "FTRBaseIntegrationTest.h"

/**
 *  A constant to wait for the locally loaded HTML page.
 */
static const NSTimeInterval kLocalHTMLPageLoadDelay = 10.0;

@interface FTRUIWebViewTest : FTRBaseIntegrationTest <UIWebViewDelegate>
@end

@implementation FTRUIWebViewTest

- (void)setUp {
  [super setUp];
  [self openTestViewNamed:@"UIWebView"];
}

- (void)DISABLED_testComponentsOnLocallyLoadedRichHTMLWithBounce {
  [self ftr_verifyComponentsOnLocallyLoadedRichHTML:YES];
}

- (void)DISABLED_testComponentsOnLocallyLoadedRichHTMLWithoutBounce {
  // TODO: Temporarily disable the test due to a swipe resistance detection bug. // NOLINT
  // Link: https://github.com/google/EarlGrey/issues/152
  [self ftr_verifyComponentsOnLocallyLoadedRichHTML:NO];
}

- (void)DISABLED_testLongTableOnLocallyLoadedRichHTMLWithBounce {
  [self ftr_verifyLongTableOnLocallyLoadedRichHTML:YES];
}

- (void)DISABLED_testLongTableOnLocallyLoadedRichHTMLWithoutBounce {
  // TODO: Temporarily disable the test due to a swipe resistance detection bug. // NOLINT
  // Link: https://github.com/google/EarlGrey/issues/152
  [self ftr_verifyLongTableOnLocallyLoadedRichHTML:NO];
}

// TODO: Temporarily disable the test due to the flakiness. // NOLINT
// Link: https://github.com/google/EarlGrey/issues/181
- (void)DISABLED_testScrollingOnLocallyLoadedHTMLPagesWithBounce {
  [self ftr_verifyScrollingOnLocallyLoadedHTMLPagesWithBounce:YES];
}

// TODO: Temporarily disable the test due to the flakiness. // NOLINT
// Link: https://github.com/google/EarlGrey/issues/181
- (void)DISABLED_testScrollingOnLocallyLoadedHTMLPagesWithoutBounce {
  [self ftr_verifyScrollingOnLocallyLoadedHTMLPagesWithBounce:NO];
}

// TODO: Temporarily disable the test due to the flakiness. // NOLINT
// Link: https://github.com/google/EarlGrey/issues/181
- (void)DISABLED_testScrollingOnPagesLoadedUsingLoadHTMLStringWithBounce {
  [self ftr_verifyScrollingOnPagesLoadedUsingLoadHTMLStringWithBounce:YES];
}

// TODO: Temporarily disable the test due to the flakiness. // NOLINT
// Link: https://github.com/google/EarlGrey/issues/181
- (void)DISABLED_testScrollingOnPagesLoadedUsingLoadHTMLStringWithoutBounce {
  [self ftr_verifyScrollingOnPagesLoadedUsingLoadHTMLStringWithBounce:NO];
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
  __autoreleasing id<UIWebViewDelegate> autoRelDelegate = [[FTRUIWebViewTest alloc] init];
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

// TODO: Temporarily disable the test due to that it fails to detect the UIWebView // NOLINT
// is idling.
// Link: https://github.com/google/EarlGrey/issues/365
- (void)DISABLED_testLongPressLinkInUIWebView {
  // Load local page first.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"loadLocalFile")]
      performAction:grey_tap()];

  // Wait for the local page to load.
  [self ftr_waitForElementWithAccessibilityLabelToAppear:@"Row 1"];

  // Long press on the next test link.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Link to Next Test")]
      performAction:grey_longPress()];

  // Click on 'Open' button to validate the popup
  id<GREYMatcher> openLabelMatcher = grey_allOf(grey_accessibilityTrait(UIAccessibilityTraitButton),
                                                grey_accessibilityLabel(@"Open"), nil);
  [[EarlGrey selectElementWithMatcher:openLabelMatcher] performAction:grey_tap()];
}

#pragma mark - Private

// All the following private functions starting with "ftr_" are being used by
// disabled tests.

- (void)ftr_waitForElementWithAccessibilityLabelToAppear:(NSString *)axLabel {
  NSString *conditionName = [NSString stringWithFormat:@"WaitFor%@", axLabel];
  GREYCondition *conditionForElement = [GREYCondition
      conditionWithName:conditionName
                  block:^BOOL {
                    NSError *error;
                    [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(axLabel)]
                        assertWithMatcher:grey_sufficientlyVisible()
                                    error:&error];
                    return (error == nil);
                  }];
  BOOL elementAppeared = [conditionForElement waitWithTimeout:kLocalHTMLPageLoadDelay];
  GREYAssertTrue(elementAppeared, @"%@ failed to appear after %.2f seconds", axLabel,
                 kLocalHTMLPageLoadDelay);
}

- (void)ftr_navigateToLocallyLoadedRichHTML:(BOOL)bounceEnabled {
  // Load local page first.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"loadLocalFile")]
      performAction:grey_tap()];

  // Bounce is enabled by default, turn it off if not required.
  if (!bounceEnabled) {
    [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"bounceSwitch")]
        performAction:grey_turnSwitchOn(NO)];
  }

  // Wait local page to load.
  [self ftr_waitForElementWithAccessibilityLabelToAppear:@"Row 1"];
  // Tap on the next test link.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Link to Next Test")]
      performAction:grey_tap()];
  // Wait for the rich HTML page loading.
  [self ftr_waitForElementWithAccessibilityLabelToAppear:@"MORE ..."];
}

- (void)ftr_navigateToLocallyLoadedRichHTMLLongTable:(BOOL)bounceEnabled {
  // Navigate to Rich HTML.
  [self ftr_navigateToLocallyLoadedRichHTML:bounceEnabled];
  // Navigate to LongTable
  [[EarlGrey selectElementWithMatcher:grey_allOf(grey_accessibilityLabel(@"LONG TABLE"),
                                                 grey_accessibilityTrait(UIAccessibilityTraitLink),
                                                 nil)] performAction:grey_tap()];
  // Wait for the test text to appear.
  [self ftr_waitForElementWithAccessibilityLabelToAppear:@"R1C1"];
}

- (void)ftr_verifyLongTableOnLocallyLoadedRichHTML:(BOOL)bounceEnabled {
  [self ftr_navigateToLocallyLoadedRichHTMLLongTable:bounceEnabled];
  // Check the initial visibility of Row1
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"R1C2")]
      assertWithMatcher:grey_sufficientlyVisible()];
  // TODO: Tap on <input> tag will not correctly trigger the full checkbox animation. // NOLINT
  // We shall probably tap on the <span> tag instead to trigger all html5 effect.
  // Tap on "check all" checkbox to check all checkboxs.
  GREYElementInteraction *r0checkboxInteraction =
      [EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"R0CHECKBOX")];
  // Find row 1 checkbox to verify if the check all JavaScript works.
  GREYElementInteraction *r1checkboxInteraction =
      [EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"R1CHECKBOX")];
  // Verify if they are visible.
  [r0checkboxInteraction assertWithMatcher:grey_sufficientlyVisible()];
  [r1checkboxInteraction assertWithMatcher:grey_sufficientlyVisible()];
  // Tap on it
  [r0checkboxInteraction performAction:grey_tap()];
  // Verify if it is checked.
  [r0checkboxInteraction assertWithMatcher:grey_accessibilityValue(@"1")];
  [r1checkboxInteraction assertWithMatcher:grey_accessibilityValue(@"1")];
  // TODO: When using 50 rows, the search action actually gives up pre-maturally, // NOLINT
  // even though the timeout is not exceeded in iOS 8.4/iPhone setting. Maybe it is due to
  // the unstable swipe resistance detection.
  // Check visibility of row 30 after scrolling.
  id<GREYMatcher> matcher = grey_allOf(grey_accessibilityLabel(@"R30C2"), grey_interactable(),
                                       grey_sufficientlyVisible(), nil);
  [[[EarlGrey selectElementWithMatcher:matcher]
         usingSearchAction:grey_scrollInDirectionWithStartPoint(kGREYDirectionDown, 400, 0.75, 0.75)
      onElementWithMatcher:grey_accessibilityID(@"FTRTestWebView")]
      assertWithMatcher:grey_sufficientlyVisible()];
  // Verify if we can scroll to the top of the web page.
  // Here, we cannot use scrollToContentEdge(kGREYContentEdgeTop) to the top. Because it will not
  // work with a float fixed navbar at the top.
  matcher = grey_allOf(grey_accessibilityLabel(@"R1C2"), grey_interactable(),
                       grey_sufficientlyVisible(), nil);
  [[[EarlGrey selectElementWithMatcher:matcher]
         usingSearchAction:grey_scrollInDirectionWithStartPoint(kGREYDirectionUp, 400, 0.25, 0.25)
      onElementWithMatcher:grey_accessibilityID(@"FTRTestWebView")]
      assertWithMatcher:grey_sufficientlyVisible()];
  // Verify if they are visible.
  [r0checkboxInteraction assertWithMatcher:grey_sufficientlyVisible()];
  [r1checkboxInteraction assertWithMatcher:grey_sufficientlyVisible()];
  // Tap on "check all" checkbox again.
  [r0checkboxInteraction performAction:grey_tap()];
  // Verify if the "check all" JavaScript works.
  [r0checkboxInteraction assertWithMatcher:grey_accessibilityValue(@"0")];
  [r1checkboxInteraction assertWithMatcher:grey_accessibilityValue(@"0")];
}

- (void)ftr_verifyScrollingOnLocallyLoadedHTMLPagesWithBounce:(BOOL)bounceEnabled {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"loadLocalFile")]
      performAction:grey_tap()];

  // Bounce is enabled by default, turn it off if not required.
  if (!bounceEnabled) {
    [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"bounceSwitch")]
        performAction:grey_turnSwitchOn(NO)];
  }

  // TODO: Add an GREYCondition to wait for webpage loads, to fix EarlGrey // NOLINT
  // synchronization issues with loading webpages. These issues induce flakiness in tests that have
  // html files loaded, whether local or over the web. The GREYCondition added in this test checks
  // if the file was loaded to mask issues in this particular set of tests, surfacing that the page
  // load error was what caused the test flake.
  [self ftr_waitForElementWithAccessibilityLabelToAppear:@"Row 1"];

  // Verify we can scroll to the bottom of the web page.
  id<GREYMatcher> matcher = grey_allOf(grey_accessibilityLabel(@"Row 50"), grey_interactable(),
                                       grey_sufficientlyVisible(), nil);
  [[[EarlGrey selectElementWithMatcher:matcher]
         usingSearchAction:grey_scrollInDirection(kGREYDirectionDown, 200)
      onElementWithMatcher:grey_accessibilityID(@"FTRTestWebView")]
      assertWithMatcher:grey_sufficientlyVisible()];
  // Verify we can scroll to the top of the web page.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"FTRTestWebView")]
      performAction:grey_scrollToContentEdge(kGREYContentEdgeTop)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Row 1")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

- (void)ftr_verifyScrollingOnPagesLoadedUsingLoadHTMLStringWithBounce:(BOOL)bounceEnabled {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"loadHTMLString")]
      performAction:grey_tap()];

  // Bounce is enabled by default, turn it off if not required.
  if (!bounceEnabled) {
    [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"bounceSwitch")]
        performAction:grey_turnSwitchOn(NO)];
  }

  // Verify we can scroll to the bottom of the web page.
  id<GREYMatcher> matcher = grey_allOf(grey_accessibilityLabel(@"Row 50"), grey_interactable(),
                                       grey_sufficientlyVisible(), nil);
  [[[EarlGrey selectElementWithMatcher:matcher]
         usingSearchAction:grey_scrollInDirection(kGREYDirectionDown, 200)
      onElementWithMatcher:grey_accessibilityID(@"FTRTestWebView")]
      assertWithMatcher:grey_sufficientlyVisible()];
  // Verify we can scroll to the top of the web page.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"FTRTestWebView")]
      performAction:grey_scrollToContentEdge(kGREYContentEdgeTop)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Row 1")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

- (void)ftr_verifyComponentsOnLocallyLoadedRichHTML:(BOOL)bounceEnabled {
  // Navigate to Rich HTML.
  [self ftr_navigateToLocallyLoadedRichHTML:bounceEnabled];
  // Verify if the image is visible.
  [[EarlGrey
      selectElementWithMatcher:grey_allOf(grey_accessibilityLabel(@"A img image."),
                                          grey_accessibilityTrait(UIAccessibilityTraitImage), nil)]
      assertWithMatcher:grey_sufficientlyVisible()];
  // Verify if the static text is visible.
  [[EarlGrey
      selectElementWithMatcher:grey_allOf(grey_accessibilityLabel(@"Static Text"),
                                          grey_accessibilityTrait(UIAccessibilityTraitStaticText),
                                          nil)] assertWithMatcher:grey_sufficientlyVisible()];
  // Search until the input field is visible.
  id<GREYMatcher> matcher =
      grey_allOf(grey_accessibilityLabel(@"INPUT FIELD"), grey_interactable(), nil);
  GREYElementInteraction *interaction = [[EarlGrey selectElementWithMatcher:matcher]
         usingSearchAction:grey_scrollInDirection(kGREYDirectionDown, 200)
      onElementWithMatcher:grey_accessibilityID(@"FTRTestWebView")];
  [interaction assertWithMatcher:grey_sufficientlyVisible()];
  // Clear text in the input field.
  [interaction performAction:grey_clearText()];
  // Check if the text was successfully cleared.
  [interaction assertWithMatcher:grey_accessibilityValue(@"")];
  // TODO: It is a temporary workaround to pass the input field test. It performs // NOLINT
  // an extra tap onto the input field then type in the text.
  [interaction performAction:grey_tap()];
  // Type "HELLO WORLD" into the input field.
  [interaction performAction:grey_typeText(@"HELLO WORLD")];
  // Verify if the "HELLO WORLD" message has been correctly typed.
  [interaction assertWithMatcher:grey_accessibilityValue(@"HELLO WORLD")];
  // Close the keyboard.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"FTRTestWebView")]
      performAction:grey_javaScriptExecution(@"document.activeElement.blur();", nil)];
  // Check visibility of the button.
  matcher = grey_allOf(grey_accessibilityLabel(@"DONT CLICK ME"), grey_interactable(),
                       grey_accessibilityTrait(UIAccessibilityTraitButton), nil);
  interaction = [[EarlGrey selectElementWithMatcher:matcher]
         usingSearchAction:grey_scrollInDirection(kGREYDirectionDown, 200)
      onElementWithMatcher:grey_accessibilityID(@"FTRTestWebView")];
  [interaction assertWithMatcher:grey_sufficientlyVisible()];
  // Click on the button and wait until the test text appears.
  [interaction performAction:grey_tap()];
  // Wait for the test text to appear.
  [self ftr_waitForElementWithAccessibilityLabelToAppear:@"Told ya."];
}

@end
