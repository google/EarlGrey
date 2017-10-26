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

class TextFieldEventsRecorder {
  private var textDidBeginEditing = false
  private var textDidChange = false
  private var textDidEndEditing = false
  private var editingDidBegin = false
  private var editingChanged = false
  private var editingDidEndOnExit = false
  private var editingDidEnd = false

  func registerActionBlock() -> GREYAction {
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(textDidBeginEditingHandler),
                                           name: .UITextFieldTextDidBeginEditing,
                                           object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(textDidChangeHandler),
                                           name: .UITextFieldTextDidChange,
                                           object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(textDidEndEditingHandler),
                                           name: .UITextFieldTextDidEndEditing,
                                           object: nil)
    return GREYActionBlock.action(withName: "Register to editing events") {
      (element, errorOrNil) in
      let element = element as! UIControl
      element.addTarget(self,
                        action: #selector(self.editingDidBeginHandler),
                        for: .editingDidBegin)
      element.addTarget(self,
                        action: #selector(self.editingChangedHandler),
                        for: .editingChanged)
      element.addTarget(self,
                        action: #selector(self.editingDidEndOnExitHandler),
                        for: .editingDidEndOnExit)
      element.addTarget(self,
                        action: #selector(self.editingDidEndHandler),
                        for: .editingDidEnd)
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

class FTRSwiftTests: XCTestCase {

  var navigationController: UINavigationController? {
    let rootVC = UIApplication.shared.delegate?.window??.rootViewController
    return (rootVC as? UINavigationController) ?? (rootVC?.navigationController)
  }

  override func tearDown() {
    super.tearDown()
    _ = navigationController?.popToRootViewController(animated: true)
  }

  func testOpeningView() {
    openTestView("Typing Views")
  }

  func testRotation() {
    EarlGrey.rotateDeviceTo(orientation: .landscapeLeft, errorOrNil: nil)
    EarlGrey.rotateDeviceTo(orientation: .portrait, errorOrNil: nil)
  }

  func testTyping() {
    openTestView("Typing Views")
    let matcher = grey_accessibilityID("TypingTextField")
    let action = grey_typeText("Sample Swift Test")
    let assertionMatcher = grey_text("Sample Swift Test")
    EarlGrey.select(elementWithMatcher: matcher)
      .perform(action)
      .assert(assertionMatcher)
  }

  func testTypingWithError() {
    openTestView("Typing Views")
    EarlGrey.select(elementWithMatcher: grey_accessibilityID("TypingTextField"))
      .perform(grey_typeText("Sample Swift Test"))
      .assert(grey_text("Sample Swift Test"))

    var error: NSError?
    EarlGrey.select(elementWithMatcher: grey_accessibilityID("TypingTextField"))
      .perform(grey_typeText(""), error: &error)
      .assert(grey_text("Sample Swift Test"), error: nil)
    GREYAssertNotNil(error, reason: "Performance should have errored")
    error = nil
    EarlGrey.select(elementWithMatcher: grey_accessibilityID("TypingTextField"))
      .perform(grey_clearText())
      .perform(grey_typeText("Sample Swift Test"), error: nil)
      .assert(grey_text("Garbage Value"), error: &error)
    GREYAssertNotNil(error, reason: "Performance should have errored")
  }

  func testFastTyping() {
    openTestView("Typing Views")
    let textFieldEventsRecorder = TextFieldEventsRecorder()
    EarlGrey.select(elementWithMatcher: grey_accessibilityID("TypingTextField"))
      .perform(textFieldEventsRecorder.registerActionBlock())
      .perform(grey_replaceText("Sample Swift Test"))
      .assert(grey_text("Sample Swift Test"))
    GREYAssert(textFieldEventsRecorder.verify(), reason: "Text field events were not all received")
  }

  func testTypingWithDeletion() {
    openTestView("Typing Views")
    EarlGrey.select(elementWithMatcher: grey_accessibilityID("TypingTextField"))
      .perform(grey_typeText("Fooo\u{8}B\u{8}Bar"))
      .assert(grey_text("FooBar"))
  }

  func testButtonPressWithGREYAllOf() {
    openTestView("Basic Views")
    EarlGrey.select(elementWithMatcher: grey_text("Tab 2")).perform(grey_tap())
    let matcher = grey_allOf([grey_text("Long Press"), grey_sufficientlyVisible()])
    EarlGrey.select(elementWithMatcher: matcher).perform(grey_longPressWithDuration(1.1))
      .assert(grey_notVisible())
  }

  func testPossibleOpeningViews() {
    openTestView("Alert Views")
    let matcher = grey_anyOf([grey_text("FooText"),
                              grey_text("Simple Alert"),
                              grey_buttonTitle("BarTitle")])
    EarlGrey.select(elementWithMatcher: matcher).perform(grey_tap())
    EarlGrey.select(elementWithMatcher: grey_text("Flee"))
      .assert(grey_sufficientlyVisible())
      .perform(grey_tap())
  }

  func testSwiftCustomMatcher() {
    // Verify description in custom matcher isn't nil.
    // unexpectedly found nil while unwrapping an Optional value
    EarlGrey.select(elementWithMatcher: grey_allOf([grey_firstElement(), grey_text("FooText")]))
      .assert(grey_nil())
  }

  func testInteractionWithALabelWithParentHidden() {
    let checkHiddenBlock =
      GREYActionBlock.action(withName: "checkHiddenBlock", perform: { element, errorOrNil in
        // Check if the found element is hidden or not.
        let superView = element as! UIView
        return !superView.isHidden
      })

    openTestView("Basic Views")
    EarlGrey.select(elementWithMatcher: grey_text("Tab 2")).perform(grey_tap())
    EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("tab2Container"))
      .perform(checkHiddenBlock).assert(grey_sufficientlyVisible())
    var error: NSError?
    EarlGrey.select(elementWithMatcher: grey_text("Non Existent Element"))
      .perform(grey_tap(), error: &error)
    if let errorVal = error {
      GREYAssertEqualObjects(errorVal.domain,
                             kGREYInteractionErrorDomain,
                             reason: "Element Not Found Error")
    }
  }

  func testChangingDatePickerToAFutureDate() {
    openTestView("Picker Views")
    // Have an arbitrary date created
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    let date = Date(timeIntervalSinceReferenceDate: 118800)
    dateFormatter.locale = Locale(identifier: "en_US")
    EarlGrey.select(elementWithMatcher: grey_text("Date")).perform(grey_tap())
    EarlGrey.select(elementWithMatcher: grey_accessibilityID("DatePickerId"))
      .perform(grey_setDate(date))
    EarlGrey.select(elementWithMatcher: grey_accessibilityID("DatePickerId"))
      .assert(grey_datePickerValue(date))
  }

  func testStepperActionWithCondition() {
    openTestView("Basic Views")
    var stepperValue = 51.0
    // Without the parameter using the value of the wait action, a warning should be seen.
    _ = GREYCondition(name: "conditionWithAction") {
      stepperValue += 1
      EarlGrey.select(elementWithMatcher: grey_kindOfClass(UIStepper.self))
        .perform(grey_setStepperValue(stepperValue))
      return stepperValue == 55
    }.waitWithTimeout(seconds: 10.0)
    EarlGrey.select(elementWithMatcher: grey_kindOfClass(UIStepper.self))
      .assert(with: grey_stepperValue(55))
  }

  func openTestView(_ name: String) {
    var errorOrNil: NSError?
    EarlGrey.select(elementWithMatcher: grey_accessibilityLabel(name))
      .perform(grey_tap(), error: &errorOrNil)
    if errorOrNil == nil {
      return
    }
    EarlGrey.select(elementWithMatcher: grey_kindOfClass(UITableView.self))
      .perform(grey_scrollToContentEdge(GREYContentEdge.top))
    EarlGrey.select(elementWithMatcher: grey_allOf([grey_accessibilityLabel(name),
                                                    grey_interactable()]))
      .using(searchAction: grey_scrollInDirection(GREYDirection.down, 200),
             onElementWithMatcher: grey_kindOfClass(UITableView.self))
      .perform(grey_tap())
  }

  func grey_firstElement() -> GREYMatcher {
    var firstMatch = true
    return GREYElementMatcherBlock(matchesBlock: { element in
      if firstMatch {
        firstMatch = false
        return true
      }
      return false
    }, descriptionBlock: { description in
      _ = description?.appendText("first match")
    })
  }
}
