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

/**
 * An example bridging header to add to a Swift EarlGrey test to satisfy the
 * dependencies required by EarlGrey.swift.
 */

#import "AppFramework/Action/GREYAction.h"
#import "AppFramework/Action/GREYActionBlock.h"
#import "AppFramework/Action/GREYActions.h"
#import "CommonLib/DistantObject/GREYHostApplicationDistantObject.h"
#import "CommonLib/Matcher/GREYElementMatcherBlock.h"
#import "CommonLib/Matcher/GREYMatcher.h"
#import "TestLib/AlertHandling/XCTestCase+GREYSystemAlertHandler.h"
#import "TestLib/EarlGreyImpl/EarlGrey.h"
