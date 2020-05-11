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

#import "WKWebViewController.h"

@implementation WKWebViewController

/**
 * Returns the url to the test HTML file.
 */
+ (NSURL *)URLToTestHTMLFile {
  return [[NSBundle mainBundle] URLForResource:@"testpage" withExtension:@"html"];
}

/**
 * Returns the url to the test a PDF file.w
 */
+ (NSURL *)URLToTestPDF {
  return [[NSBundle mainBundle] URLForResource:@"bigtable" withExtension:@"pdf"];
}

- (instancetype)init {
  NSAssert(NO, @"Invalid Initializer");
  return nil;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.webView =
      [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, self.containerView.frame.size.width,
                                                  self.containerView.frame.size.height)];
  self.webView.layer.borderColor = [UIColor redColor].CGColor;
  self.webView.layer.borderWidth = 3.0f;
  self.webView.backgroundColor = [UIColor blackColor];
  [self.containerView addSubview:self.webView];
  self.webView.navigationDelegate = self;
  self.containerView.isAccessibilityElement = NO;
  self.webView.superview.isAccessibilityElement = NO;
  self.webView.accessibilityElementsHidden = NO;
  self.webView.userInteractionEnabled = YES;
  self.webView.accessibilityIdentifier = @"TestWKWebView";
  self.navigationController.navigationBar.backItem.title = @"Back";
  [self.activityIndicator setHidesWhenStopped:YES];
  self.activityIndicator.accessibilityIdentifier = @"ActivityIndicator";
  [self.activityIndicator setIsAccessibilityElement:YES];
}

- (IBAction)userDidTapLoadGoogle {
  NSURL *url = [NSURL URLWithString:@"https://www.google.com/#q=test"];
  NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
  [self.webView loadRequest:requestObj];
}

- (IBAction)userDidTapLoadLocalTestPage {
  NSURLRequest *request = [NSURLRequest requestWithURL:[WKWebViewController URLToTestHTMLFile]];
  [self.webView loadRequest:request];
}

- (IBAction)userDidTapLoadHTMLUsingLoadHTMLString {
  NSString *html = [NSString stringWithContentsOfURL:[WKWebViewController URLToTestHTMLFile]
                                            encoding:NSUTF8StringEncoding
                                               error:nil];
  [self.webView loadHTMLString:html baseURL:[NSURL URLWithString:@"http://www.earlgrey.com"]];
  self.webView.scrollView.bounces = _webViewBounceSwitch.isOn;
}

- (IBAction)userDidTapLoadPDF {
  NSURL *urlForPDF = [[self class] URLToTestPDF];
  [self.webView loadFileURL:urlForPDF allowingReadAccessToURL:urlForPDF];
}

- (IBAction)userDidToggleBounce:(UISwitch *)sender {
  self.webView.scrollView.bounces = sender.isOn;
}

#pragma mark - WKNavigationDelegate methods

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
  [self.activityIndicator startAnimating];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
  // Add an artificial delay to ensure the activity indicator is up.
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)),
                 dispatch_get_main_queue(), ^{
                   [self.activityIndicator stopAnimating];
                 });
}

- (void)webView:(WKWebView *)webView
    didFailNavigation:(WKNavigation *)navigation
            withError:(NSError *)error {
  [self.activityIndicator stopAnimating];
}

@end
