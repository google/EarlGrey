//
// Copyright 2021 Google Inc.
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

// Class that controls SliderViewController.xib view. The view contains six sliders, each of
// which have properties listed below. The top slider is slider1 and the bottom most slider6.

#import <UIKit/UIKit.h>

@interface SwitchViewController : UIViewController

@property(weak, nonatomic) IBOutlet UISwitch *switch1;

- (instancetype)init NS_UNAVAILABLE;
@end
