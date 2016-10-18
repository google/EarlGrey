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

import XCTest

class EarlGreyContribsSwiftTests: XCTestCase {
  func testBasicViewController() {
    EarlGrey.select(elementWithMatcher: grey_text("Basic View Controller"))
      .perform(grey_tap()).assert(grey_anything())
    EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("textField"))
      .perform(grey_typeText("Foo"))
    EarlGrey.select(elementWithMatcher:
      grey_allOfMatchers([grey_accessibilityLabel("showButton")])).perform(grey_tap())
    EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("textLabel"))
      .assert(grey_text("Foo"))
  }
}
