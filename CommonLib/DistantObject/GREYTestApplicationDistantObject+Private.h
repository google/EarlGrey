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

#import <Foundation/Foundation.h>

#import "GREYTestApplicationDistantObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface GREYTestApplicationDistantObject (Private)

// Make it readwrite, so when the app under test starts, it signals the test where to send an remote
// invocation.
@property(nonatomic) uint16_t hostPort;
@property(nonatomic) uint16_t hostBackgroundPort;

@end

NS_ASSUME_NONNULL_END
