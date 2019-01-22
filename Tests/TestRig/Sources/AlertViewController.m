//
// Copyright 2017 Google Inc.
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

#import "AlertViewController.h"

@interface AlertViewController ()

@property(strong, nonatomic) UIAlertController *alertController;

@end

@implementation AlertViewController

- (instancetype)init {
  NSAssert(NO, @"Invalid Initializer");
  return nil;
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];

  if (self.alertController) {
    [self.alertController dismissViewControllerAnimated:NO completion:nil];
  }
}

- (IBAction)showSimpleAlert:(id)sender {
  self.alertController = [UIAlertController alertControllerWithTitle:@"Alert!"
                                                             message:@"Danger Will Robinson!"
                                                      preferredStyle:UIAlertControllerStyleAlert];
  UIAlertAction *cancelAction =
      [UIAlertAction actionWithTitle:@"Flee" style:UIAlertActionStyleCancel handler:nil];
  [self.alertController addAction:cancelAction];
  [self presentViewController:self.alertController animated:YES completion:nil];
}

- (IBAction)showMultiOptionAlert:(id)sender {
  self.alertController = [UIAlertController alertControllerWithTitle:@"Alert!"
                                                             message:@"Danger Will Robinson!"
                                                      preferredStyle:UIAlertControllerStyleAlert];
  UIAlertAction *usePhaserAction =
      [UIAlertAction actionWithTitle:@"Use Phaser"
                               style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction *_Nonnull action) {
                               [self presentViewController:[self chainedViewController]
                                                  animated:YES
                                                completion:nil];
                             }];
  UIAlertAction *useSlingshotAction =
      [UIAlertAction actionWithTitle:@"Use Slingshot" style:UIAlertActionStyleDefault handler:nil];
  UIAlertAction *cancelAction =
      [UIAlertAction actionWithTitle:@"Flee" style:UIAlertActionStyleCancel handler:nil];
  [self.alertController addAction:usePhaserAction];
  [self.alertController addAction:useSlingshotAction];
  [self.alertController addAction:cancelAction];

  [self presentViewController:self.alertController animated:YES completion:nil];
}

- (IBAction)showStyledAlert:(id)sender {
  self.alertController = [UIAlertController alertControllerWithTitle:@"Styled alert!"
                                                             message:@"Who are you?"
                                                      preferredStyle:UIAlertControllerStyleAlert];
  [self.alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
    textField.placeholder = @"Login";
  }];
  [self.alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
    textField.placeholder = @"Password";
    textField.secureTextEntry = YES;
  }];
  UIAlertAction *leaveAction =
      [UIAlertAction actionWithTitle:@"Leave"
                               style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction *_Nonnull action) {
                               [self presentViewController:[self chainedViewController]
                                                  animated:YES
                                                completion:nil];
                             }];
  UIAlertAction *cancelAction =
      [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
  [self.alertController addAction:leaveAction];
  [self.alertController addAction:cancelAction];

  [self presentViewController:self.alertController animated:YES completion:nil];
}

- (UIAlertController *)chainedViewController {
  UIAlertController *styledAlertController =
      [UIAlertController alertControllerWithTitle:@"Danger!"
                                          message:@"*zap*"
                                   preferredStyle:UIAlertControllerStyleAlert];
  UIAlertAction *cancelAction =
      [UIAlertAction actionWithTitle:@"Roger" style:UIAlertActionStyleCancel handler:nil];
  [styledAlertController addAction:cancelAction];
  return styledAlertController;
}

@end
