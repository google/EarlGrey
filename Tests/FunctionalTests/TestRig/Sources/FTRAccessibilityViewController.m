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

#import "FTRAccessibilityViewController.h"

#import <MessageUI/MessageUI.h>

@implementation FTRAccessibilityViewController

- (IBAction)openMessageComposeView:(id)sender {
  void (^completionBlock)(void) = ^{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
                     [self dismissViewControllerAnimated:NO completion:NULL];
                   });
  };
  if ([MFMessageComposeViewController canSendText]) {
    MFMessageComposeViewController *mvc = [[MFMessageComposeViewController alloc] init];
    [self presentViewController:mvc animated:NO completion:completionBlock];
  } else if ([MFMailComposeViewController canSendMail]) {
    MFMailComposeViewController *mvc = [[MFMailComposeViewController alloc] init];
    [self presentViewController:mvc animated:NO completion:completionBlock];
  }
}

@end
