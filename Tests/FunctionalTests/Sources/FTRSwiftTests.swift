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

class TextFieldEventsRecorder {
  var textDidBeginEditing = false
  var textDidChange = false
  var textDidEndEditing = false
  var editingDidBegin = false
  var editingChanged = false
  var editingDidEndOnExit = false
  var editingDidEnd = false

  func registerActionBlock() -> GREYActionBlock {
    NotificationCenter.default.addObserver(self,
      selector: #selector(textDidBeginEditingHandler),
      name: NSNotification.Name.UITextFieldTextDidBeginEditing, object: nil)
    NotificationCenter.default.addObserver(self,
      selector: #selector(textDidChangeHandler),
      name: NSNotification.Name.UITextFieldTextDidChange,
      object: nil)
    NotificationCenter.default.addObserver(self,
      selector: #selector(textDidEndEditingHandler),
      name: NSNotification.Name.UITextFieldTextDidEndEditing, object: nil)
    return GREYActionBlock.action(withName: "Register to editing events") {
      (element: Any?, errorOrNil: UnsafeMutablePointer<NSError?>?) -> Bool in
      let element:UIControl = element as! UIControl
      element.addTarget(self,
        action: #selector(self.editingDidBeginHandler), for: .editingDidBegin)
      element.addTarget(self,
        action: #selector(self.editingChangedHandler), for: .editingChanged)
      element.addTarget(self,
        action: #selector(self.editingDidEndOnExitHandler), for: .editingDidEndOnExit)
      element.addTarget(self,
        action: #selector(self.editingDidEndHandler), for: .editingDidEnd)
      return true
    }
  }

  func verify() -> Bool {
    return textDidBeginEditing && textDidChange && textDidEndEditing &&
      editingDidBegin && editingChanged && editingDidEndOnExit && editingDidEnd
  }

  @objc func textDidBeginEditingHandler() { textDidBeginEditing = true }
  @objc func textDidChangeHandler() { textDidChange = true }
  @objc func textDidEndEditingHandler() { textDidEndEditing = true }
  @objc func editingDidBeginHandler() { editingDidBegin = true }
  @objc func editingChangedHandler() { editingChanged = true }
  @objc func editingDidEndOnExitHandler() { editingDidEndOnExit = true }
  @objc func editingDidEndHandler() { editingDidEnd = true }
}

class FunctionalTestRigSwiftTests: XCTestCase {

  override func tearDown() {
    super.tearDown()
    let delegateWindow:UIWindow! = UIApplication.shared.delegate!.window!
    var navController:UINavigationController?
    if ((delegateWindow.rootViewController?.isKind(of: UINavigationController.self)) != nil) {
      navController = delegateWindow.rootViewController as? UINavigationController
    } else {
      navController = delegateWindow.rootViewController!.navigationController
    }
    navController?.popToRootViewController(animated: true)
  }

  func testOpeningView() {
    self.openTestView("Typing Views")
  }

  func testTyping() {
    self.openTestView("Typing Views")
    EarlGrey().selectElement(with: grey_accessibilityID("TypingTextField"))
        .perform(grey_typeText("Sample Swift Test"))
        .assert(with: grey_text("Sample Swift Test"))
  }

  func testFastTyping() {
    self.openTestView("Typing Views")
    let textFieldEventsRecorder = TextFieldEventsRecorder()
    EarlGrey().selectElement(with: grey_accessibilityID("TypingTextField"))
        .perform(textFieldEventsRecorder.registerActionBlock())
        .perform(grey_replaceText("Sample Swift Test"))
        .assert(with: grey_text("Sample Swift Test"))
    GREYAssert(textFieldEventsRecorder.verify(), reason: "Text field events were not all received")
  }

  func testFastTypingOnWebView() {
    self.openTestView("Web Views")
    EarlGrey().selectElement(with: grey_accessibilityLabel("loadGoogle"))
        .perform(grey_tap())
    let searchButtonMatcher: GREYMatcher = grey_accessibilityHint("Search")

    self.waitForWebElementWithName("Search Button", elementMatcher: searchButtonMatcher)

    // grey_text() doesn't work on webviews, must use grey_accessibilityValue()
    EarlGrey().selectElement(with: searchButtonMatcher)
        .perform(grey_clearText())
        .perform(grey_typeText("zzz"))
        .perform(grey_replaceText("new_text_value"))
        .assert(with: grey_accessibilityValue("new_text_value"))
  }

  func testButtonPressWithGREYAllOf() {
    self.openTestView("Basic Views")
    EarlGrey().selectElement(with: grey_text("Tab 2")).perform(grey_tap())
    let matcher = grey_allOfMatchers(grey_text("Long Press"), grey_sufficientlyVisible())
    EarlGrey().selectElement(with: matcher).perform(grey_longPressWithDuration(1.0))
        .assert(with: grey_notVisible())
  }

  func testPossibleOpeningViews() {
    self.openTestView("Alert Views")
    let matcher = grey_anyOfMatchers(grey_text("FooText"),
                                     grey_text("Simple Alert"),
                                     grey_buttonTitle("BarTitle"))
    EarlGrey().selectElement(with: matcher).perform(grey_tap())
    EarlGrey().selectElement(with: grey_text("Flee"))
        .assert(with: grey_sufficientlyVisible())
        .perform(grey_tap())
  }

  func testSwiftCustomMatcher() {
    // Verify description in custom matcher isn't nil.
    // unexpectedly found nil while unwrapping an Optional value
    EarlGrey().selectElement(with: grey_allOfMatchers(grey_firstElement(),
                                                      grey_text("FooText")))
        .assert(with: grey_nil())
  }

  func testInteractionWithALabelWithParentHidden() {
    let checkHiddenBlock:GREYActionBlock =
        GREYActionBlock.action(withName: "checkHiddenBlock", perform: { element, errorOrNil in
                                       // Check if the found element is hidden or not.
                                       let superView:UIView! = element as! UIView
                                       return !superView.isHidden
        })

    self.openTestView("Basic Views")
    EarlGrey().selectElement(with: grey_text("Tab 2")).perform(grey_tap())
    EarlGrey().selectElement(with: grey_accessibilityLabel("tab2Container"))
        .perform(checkHiddenBlock).assert(with: grey_sufficientlyVisible())
    var error: NSError?
    EarlGrey().selectElement(with: grey_text("Non Existent Element"))
        .perform(grey_tap(), error:&error)
    if let errorVal = error {
      GREYAssertEqual(errorVal.domain as AnyObject?, kGREYInteractionErrorDomain as AnyObject?,
                      reason: "Element Not Found Error")
    }
  }

  func waitForWebElementWithName(_ name: String, elementMatcher matcher: GREYMatcher) {
    GREYCondition(name: name + " Condition", block: {_ in
      var errorOrNil: NSError?
      EarlGrey().selectElement(with: matcher)
          .assert(with: grey_sufficientlyVisible(), error: &errorOrNil)
      return errorOrNil == nil
    }).wait(withTimeout: 3.0)
  }

  func openTestView(_ name: String) {
    var errorOrNil : NSError?
    let cellMatcher = grey_accessibilityLabel(name)
    EarlGrey().selectElement(with: cellMatcher).perform(grey_tap(), error: &errorOrNil)
    if ((errorOrNil == nil)) {
      return
    }
    EarlGrey().selectElement(with: grey_kindOfClass(UITableView.self))
        .perform(grey_scrollToContentEdge(GREYContentEdge.top))
    EarlGrey().selectElement(with: GREYAllOf.init(matchers: [cellMatcher,grey_interactable()]))
        .usingSearch(grey_scrollInDirection(GREYDirection.down, 200),
                           onElementWith: grey_kindOfClass(UITableView.self))
        .perform(grey_tap())
  }

  func grey_firstElement() -> GREYMatcher {
    var firstMatch = true
    let matches: MatchesBlock = { (element: Any) -> Bool in
      if firstMatch {
        firstMatch = false
        return true
      }

      return false
    }

    let describe: DescribeToBlock = { (description: GREYDescription?) -> Void in
      description!.appendText("first match")
    }

    return GREYElementMatcherBlock.init(matchesBlock: matches, descriptionBlock: describe)
  }
}
