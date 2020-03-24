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

#import "NetworkTestViewController.h"
#import "NetworkProxy.h"

/**
 *  Data used as response for proxied requests.
 */
static NSString *const kTestProxyData = @"kTestProxyData";

/**
 *  Regex matching all YouTube urls.
 */
static NSString *const kProxyRegex = @"^http://www.youtube.com";

/** A dummy NSURLSessionDelegate. **/
@interface SampleNSURLSessionDelegate : NSObject <NSURLSessionDelegate>
@end

@implementation SampleNSURLSessionDelegate

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session
                    task:(NSURLSessionTask *)task
    didCompleteWithError:(NSError *)error {
  // No-op
}

@end

/** A proxy that forwards url session delegate calls to another object. **/
@interface SampleNSURLSessionDelegateProxy : NSObject
- (instancetype)initWithSessionDelegate:(id<NSURLSessionDelegate>)delegate;
@end

@implementation SampleNSURLSessionDelegateProxy {
  id _delegate;
}

- (instancetype)initWithSessionDelegate:(id<NSURLSessionDelegate>)delegate {
  self = [super init];
  if (self) {
    _delegate = delegate;
  }
  return self;
}

- (id)forwardingTargetForSelector:(SEL)sel {
  return _delegate;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
  return [_delegate respondsToSelector:aSelector];
}

@end

@interface NetworkTestViewController () <NSURLSessionDataDelegate>
@property(weak, nonatomic) IBOutlet UILabel *retryIndicator;
@property(weak, nonatomic) IBOutlet UILabel *responseVerifiedLabel;
@property(weak, nonatomic) IBOutlet UILabel *requestCompletedLabel;
@end

@implementation NetworkTestViewController {
  /**
   *  Check for the infinite request. The request should be dismissed once the view controller is
   *  removed.
   */
  BOOL _keepInfiniteRequestOn;
}

- (void)viewWillAppear:(BOOL)animated {
  [NetworkProxy setProxyEnabled:YES];
  [NetworkProxy addProxyRuleForUrlsMatchingRegexString:kProxyRegex responseString:kTestProxyData];
  [super viewWillAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  [NetworkProxy removeMostRecentProxyRuleMatchingUrlRegexString:kProxyRegex];
  [NetworkProxy setProxyEnabled:NO];
  _keepInfiniteRequestOn = NO;
}

/**
 *  Verifies the received @c data by matching it with what is expected via proxy, in case of match
 *  UI is updated by setting @c responseVerifiedLabel to be visible.
 *
 *  @param data The data that was received.
 */
- (void)verifyReceivedData:(NSData *)data {
  // Note: although functionally similar, [NSString stringWithUTF8String:] has been flaky
  // here returning nil for the NSData being passed in from the proxy, using initWithData:encoding:
  // instead.
  NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  if ([kTestProxyData isEqualToString:dataStr]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      self.responseVerifiedLabel.hidden = NO;
    });
  }
}

- (IBAction)userDidTapNSURLSessionDelegateTest:(id)sender {
  NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
  config.protocolClasses =
      [@ [[NetworkProxy class]] arrayByAddingObjectsFromArray:config.protocolClasses];
  NSURLSession *session =
      [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
  NSURLSessionTask *task =
      [session dataTaskWithURL:[NSURL URLWithString:@"http://www.youtube.com/"]];
  // Begin the fetch.
  [task resume];
  [session finishTasksAndInvalidate];
}

- (IBAction)userDidTapNSURLSessionProxyDelegateTest:(id)sender {
  NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
  config.protocolClasses =
      [@ [[NetworkProxy class]] arrayByAddingObjectsFromArray:config.protocolClasses];
  SampleNSURLSessionDelegate *delegate = [[SampleNSURLSessionDelegate alloc] init];
  id delegateProxy = [[SampleNSURLSessionDelegateProxy alloc] initWithSessionDelegate:delegate];
  NSURLSession *session = [NSURLSession sessionWithConfiguration:config
                                                        delegate:delegateProxy
                                                   delegateQueue:nil];
  NSURL *URL = [NSURL URLWithString:@"http://www.youtube.com/"];
  NSURLRequest *request = [NSURLRequest requestWithURL:URL];
  NSURLSessionTask *URLTask = [session dataTaskWithURL:URL];
  NSURLSessionTask *requestTask = [session dataTaskWithRequest:request];
  // Begin the fetch.
  [URLTask resume];
  [requestTask resume];

  [session finishTasksAndInvalidate];
  self->_requestCompletedLabel.hidden = NO;
}

- (IBAction)userDidTapNSURLSessionNoCallbackTest:(id)sender {
  NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
  config.protocolClasses =
      [@ [[NetworkProxy class]] arrayByAddingObjectsFromArray:config.protocolClasses];
  NSURLSession *session =
      [NSURLSession sessionWithConfiguration:config delegate:nil delegateQueue:nil];
  NSURLSessionTask *task =
      [session dataTaskWithURL:[NSURL URLWithString:@"http://www.youtube.com/"]];
  // Begin the fetch.
  [task resume];
  [session finishTasksAndInvalidate];
}

- (IBAction)userDidTapNSURLSessionTest:(id)sender {
  NSURLSession *session = [NSURLSession sharedSession];
  NSURLSessionTask *task =
      [session dataTaskWithURL:[NSURL URLWithString:@"http://www.youtube.com/"]
             completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
               [NSThread sleepForTimeInterval:1.0];
               [self verifyReceivedData:data];
               dispatch_async(dispatch_get_main_queue(), ^{
                 self->_requestCompletedLabel.hidden = NO;
               });
             }];
  // Begin the fetch.
  [task resume];
  [session finishTasksAndInvalidate];
}

- (IBAction)usedTappedOnInfiniteRequest:(id)sender {
  NSURLSession *session = [NSURLSession sharedSession];
  _keepInfiniteRequestOn = YES;
  NSURLSessionTask *task =
      [session dataTaskWithURL:[NSURL URLWithString:@"http://foo.com/"]
             completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
               while (self->_keepInfiniteRequestOn) {
                 [NSThread sleepForTimeInterval:1.0];
               }
             }];
  [task resume];
  [session finishTasksAndInvalidate];
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
  // Simulate some processing time to reliably test network synchronization. Without this network
  // synchronization tests will be flaky.
  [NSThread sleepForTimeInterval:1.0];
  dispatch_async(dispatch_get_main_queue(), ^{
    self->_requestCompletedLabel.hidden = NO;
  });
  [self verifyReceivedData:data];
}

@end
