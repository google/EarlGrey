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

import EarlGrey
import XCTest

class EarlGreyContribsSwiftTests: XCTestCase {
  func testBasicViewController() {
    EarlGrey().selectElementWithMatcher(grey_text("Basic View Controller"))
      .performAction(grey_tap())
    EarlGrey().selectElementWithMatcher(grey_accessibilityLabel("textField"))
      .performAction(grey_typeText("Foo"))
    EarlGrey().selectElementWithMatcher(grey_accessibilityLabel("showButton"))
      .performAction(grey_tap())
    EarlGrey().selectElementWithMatcher(grey_accessibilityLabel("textLabel"))
      .assertWithMatcher(grey_text("Foo"))
  }

  func testCountOfTableViewCells() {
    var error: NSError? = nil
    let matcher: GREYMatcher! = grey_kindOfClass(UITableViewCell.self)
    let countOfTableViewCells: UInt = count(matcher)
    GREYAssert(countOfTableViewCells > 1, reason: "There are more than one cell present.")
    EarlGrey().selectElementWithMatcher(matcher)
      .atIndex(countOfTableViewCells + 1)
      .assertWithMatcher(grey_notNil(), error: &error)
    let errorCode: GREYInteractionErrorCode = GREYInteractionErrorCode.MatchedElementIndexOutOfBoundsErrorCode
    GREYAssert(error?.code == errorCode.rawValue,
               reason: "The Interaction element's index being used was over the count of matched" +
      " elements available.")
  }
}

func count(matcher: GREYMatcher!) -> UInt {
  var error: NSError? = nil
  var index: UInt = 0
  while (true) {
    EarlGrey().selectElementWithMatcher(matcher)
      .atIndex(index)
      .assertWithMatcher(grey_notNil(), error: &error)
    if ((error) != nil) {
      break
    } else {
      print(index)
      index = index + 1
    }
  }
  return index
}
