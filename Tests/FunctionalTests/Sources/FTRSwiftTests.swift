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

class FunctionalTestRigSwiftTests: XCTestCase {

  override func tearDown() {
    super.tearDown()
    let delegateWindow:UIWindow! = UIApplication.sharedApplication().delegate!.window!
    var navController:UINavigationController?
    if ((delegateWindow.rootViewController?.isKindOfClass(UINavigationController)) != nil) {
      navController = delegateWindow.rootViewController as? UINavigationController
    } else {
      navController = delegateWindow.rootViewController!.navigationController
    }
    navController?.popToRootViewControllerAnimated(true)
  }

  func testOpeningView() {
    EarlGrey().selectElementWithMatcher(grey_keyWindow())
    self.openTestView("Typing Views")
  }

  func testTyping() {
    EarlGrey().selectElementWithMatcher(grey_keyWindow())
    self.openTestView("Typing Views")
    EarlGrey().selectElementWithMatcher(grey_accessibilityID("TypingTextField"))
        .performAction(grey_typeText("Sample Swift Test"))
        .assertWithMatcher(grey_text("Sample Swift Test"))
  }

  func testButtonPressWithGREYAllOf() {
    self.openTestView("Basic Views")
    EarlGrey().selectElementWithMatcher(grey_text("Tab 2")).performAction(grey_tap())
    let matcher = GREYAllOf.init(matchers: [grey_text("Long Press"),
                                            grey_sufficientlyVisible()])
    EarlGrey().selectElementWithMatcher(matcher).performAction(grey_longPressWithDuration(1.0))
        .assertWithMatcher(grey_notVisible())
  }

  func openTestView(name:NSString) {
    var error : NSError?
    let cellMatcher = grey_accessibilityLabel(name as String)
    EarlGrey().selectElementWithMatcher(cellMatcher).performAction(grey_tap(), error: &error)
    if ((error == nil)) {
      return
    }
    EarlGrey().selectElementWithMatcher(grey_kindOfClass(UITableView))
      .performAction(grey_scrollToContentEdge(GREYContentEdge.Top))
    EarlGrey().selectElementWithMatcher(GREYAllOf.init(matchers: [cellMatcher,grey_interactable()]))
      .usingSearchAction(grey_scrollInDirection(GREYDirection.Down, 200),
                         onElementWithMatcher: grey_kindOfClass(UITableView))
  }
}
