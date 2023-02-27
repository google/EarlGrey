//
// Copyright 2022 Google Inc.
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
 * An umbrella header that contains all of the headers required for creating
 * custom actions, matchers and assertions along with testing APIs.
 *
 * This file is to only be imported in the source code of the testing binary.
 */

// EarlGrey interaction APIs
#import "EarlGreyImpl.h"

// Headers shared for both the app-under-test binary and testing binary,
// including actions, matchers and assertions.
#import "ExposedForTesting.h"

// EarlGrey conditional assertion APIs
#import "GREYAssertionDefines.h"
#import "GREYWaitFunctions.h"

// Miscellaneous APIs
#import "XCTestCase+GREYSystemAlertHandler.h"
#import "GREYCondition.h"
#import "EarlGreyImpl+XCUIApplication.h"
#import "GREYElementInteractionProxy.h"
#import "XCTestCase+GREYTest.h"
