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

import XCTest

/// An extension of XCTestCase to set up the test host.
private extension XCTestCase {
  /// A variable to point to the GREYHostApplicationDistantObject since casts in Swift fail on
  /// proxy types. Hence we have to perform an unsafeBitCast.
  var host: FTRSwiftTestsHost {
    return unsafeBitCast(
      GREYHostApplicationDistantObject.sharedInstance,
      to: FTRSwiftTestsHost.self)
  }
}

// Singleton to launch the app only once.
class Application: NSObject {
  static let sharedApplication = {
    return Application()
  }()
  override init() {
    XCUIApplication().launch()
  }
}

class FTRSwiftTests: XCTestCase {

  override func setUp() {
    super.setUp()
    _ = Application.sharedApplication
  }

  override func tearDown() {
    host.resetNavigationStack()
    super.tearDown()
  }

  func testOpeningView() {
    EarlGrey.selectElement(with: grey_text("Basic Views"))
      .perform(grey_tap())
    EarlGrey.selectElement(with: grey_text("Tab 2"))
      .assert(grey_sufficientlyVisible())
  }

  func testRotation() {
    XCTAssertNoThrow(try EarlGrey.rotateDevice(to: .landscapeLeft))
    XCTAssertNoThrow(try EarlGrey.rotateDevice(to: .portrait))
  }

  func testTyping() {
    EarlGrey.selectElement(with: grey_text("Basic Views"))
      .perform(grey_tap())
    EarlGrey.selectElement(with: grey_text("Tab 2"))
      .perform(grey_tap())
    let matcher: GREYMatcher! = grey_accessibilityID("foo")
    let action: GREYAction! = grey_typeText("Sample Swift Test")
    let assertionMatcher = grey_text("Sample Swift Test")
    EarlGrey.selectElement(with: matcher)
      .perform(action)
      .assert(assertionMatcher)
  }

  func testFastTyping() {
    openTestView(named: "Typing Views")
#if swift(>=4.2)
    let beginEditingRecorder = host.makeTextFieldNotificationRecorder(
      for: UITextField.textDidBeginEditingNotification)
    let didChangeRecorder = host.makeTextFieldNotificationRecorder(
      for: UITextField.textDidChangeNotification)
    let didEndEditingRecorder = host.makeTextFieldNotificationRecorder(
      for: UITextField.textDidEndEditingNotification)
#else
    let beginEditingRecorder = host.makeTextFieldNotificationRecorder(
      for: .UITextFieldTextDidBeginEditing)
    let didChangeRecorder = host.makeTextFieldNotificationRecorder(
      for: .UITextFieldTextDidChange)
    let didEndEditingRecorder = host.makeTextFieldNotificationRecorder(
      for: .UITextFieldTextDidEndEditing)
#endif
    let editingDidBeginRecorderAction =
      host.makeTextFieldEditingEventRecorder(for: .editingDidBegin)
    let editingChangedRecorderAction =
      host.makeTextFieldEditingEventRecorder(for: .editingChanged)
    let editingDidEndOnExitRecorderAction =
      host.makeTextFieldEditingEventRecorder(for: .editingDidEndOnExit)
    let editingDidEndRecorderAction =
      host.makeTextFieldEditingEventRecorder(for: .editingDidEnd)
    EarlGrey.selectElement(with: grey_accessibilityID("TypingTextField"))
      .perform(editingDidBeginRecorderAction)
      .perform(editingChangedRecorderAction)
      .perform(editingDidEndOnExitRecorderAction)
      .perform(editingDidEndRecorderAction)
      .perform(grey_replaceText("Sample Swift Test"))
      .assert(grey_text("Sample Swift Test"))
    GREYAssertTrue(
      beginEditingRecorder.wasNotificationReceived,
      "Text field begin editing notification was not received.")
    GREYAssertTrue(
      didChangeRecorder.wasNotificationReceived,
      "Text field did change notification was not received.")
    GREYAssertTrue(
      didEndEditingRecorder.wasNotificationReceived,
      "Text field did end editing notification was not received.")
    GREYAssertTrue(
      editingDidBeginRecorderAction.wasEventReceived,
      "Text field did begin editing event was not received.")
    GREYAssertTrue(
      editingChangedRecorderAction.wasEventReceived,
      "Text field editing changed event was not received.")
    GREYAssertTrue(
      editingDidEndOnExitRecorderAction.wasEventReceived,
      "Text field editing did end on exit event was not received.")
    GREYAssertTrue(
      editingDidEndRecorderAction.wasEventReceived,
      "Text field editing did end event was not received.")
  }

  func testTypingWithDeletion() {
    openTestView(named: "Typing Views")
    EarlGrey.selectElement(with: grey_accessibilityID("TypingTextField"))
      .perform(grey_typeText("Fooo\u{8}B\u{8}Bar"))
      .assert(grey_text("FooBar"))
  }

  func testButtonPressWithGREYAllOf() {
    openTestView(named: "Basic Views")
    EarlGrey.selectElement(with: grey_text("Tab 2")).perform(grey_tap())
    let matcher = grey_allOf([grey_text("Long Press"), grey_sufficientlyVisible()])
    EarlGrey.selectElement(with: matcher).perform(grey_longPressWithDuration(1.1))
      .assert(grey_notVisible())
  }

  func testPossibleOpeningViews() {
    openTestView(named: "Alert Views")
    let matcher = grey_anyOf([
      grey_text("FooText"),
      grey_text("Simple Alert"),
      grey_buttonTitle("BarTitle"),
    ])
    EarlGrey.selectElement(with: matcher).perform(grey_tap())
    EarlGrey.selectElement(with: grey_text("Flee"))
      .assert(grey_sufficientlyVisible())
      .perform(grey_tap())
  }

  func testtestSwiftCustomMatcher() {
    // Verify description in custom matcher isn't nil.
    // unexpectedly found nil while unwrapping an Optional value
    EarlGrey.selectElement(with: grey_allOf([
      host.makeFirstElementMatcher(),
      grey_text("FooText"),
    ])).assert(grey_nil())
  }

  func testInteractionWithALabelWithParentHidden() {
    openTestView(named: "Basic Views")
    let checkHiddenAction = host.makeCheckHiddenAction()
    EarlGrey.selectElement(with: grey_text("Tab 2")).perform(grey_tap())
    EarlGrey.selectElement(with: grey_accessibilityLabel("tab2Container"))
      .perform(checkHiddenAction).assert(grey_sufficientlyVisible())
    var error: NSError?
    EarlGrey.selectElement(with: grey_text("Non Existent Element"))
      .perform(grey_tap(), error: &error)
    if let errorVal = error {
      GREYAssertEqual(errorVal.domain, kGREYInteractionErrorDomain, "Element Not Found Error")
    }
  }

  func testChangingDatePickerToAFutureDate() {
    openTestView(named: "Picker Views")
    // Have an arbitrary date created
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    let date = Date(timeIntervalSinceReferenceDate: 118800)
    dateFormatter.locale = Locale(identifier: "en_US")
    EarlGrey.selectElement(with: grey_text("Date")).perform(grey_tap())
    EarlGrey.selectElement(with: grey_accessibilityID("DatePickerId"))
      .perform(grey_setDate(date))
    EarlGrey.selectElement(with: grey_accessibilityID("DatePickerId"))
      .assert(grey_datePickerValue(date))
  }

  func testStepperActionWithCondition() {
    openTestView(named: "Basic Views")
    var stepperValue = 51.0
    // Without the parameter using the value of the wait action, a warning should be seen.
    _ = GREYCondition(name: "conditionWithAction") {
      stepperValue += 1
      EarlGrey.selectElement(with: grey_kindOfClass(UIStepper.self))
        .perform(grey_setStepperValue(stepperValue))
      return stepperValue == 55
    }.wait(withTimeout: 10.0)
    EarlGrey.selectElement(with: grey_kindOfClass(UIStepper.self))
      .assert(grey_stepperValue(55))
  }

  func testSystemAlertTappingAPI() {
    EarlGrey.selectElement(with: grey_text("Basic Views"))
      .perform(grey_tap())
    var denyError: NSError?
    XCTAssertFalse(grey_denySystemDialogWithError(&denyError))
    XCTAssertNotNil(denyError)

    var acceptError: NSError?
    XCTAssertFalse(grey_acceptSystemDialogWithError(&acceptError))
    XCTAssertNotNil(acceptError)

    XCTAssertFalse(
      grey_typeSystemAlertText(
        "foo",
        forPlaceholderText: "bar",
        error: nil))
    var typingError: NSError?
    XCTAssertFalse(
      grey_typeSystemAlertText(
        "foo",
        forPlaceholderText: "bar",
        error: &typingError))
    XCTAssertNotNil(acceptError)
  }

  func openTestView(named name: String) {
    var error: NSError?
    EarlGrey.selectElement(with: grey_accessibilityLabel(name))
      .perform(grey_tap(), error: &error)
    if error == nil {
      return
    }
    EarlGrey.selectElement(with: grey_kindOfClass(UITableView.self))
      .perform(grey_scrollToContentEdge(GREYContentEdge.top))
    let nameMatcher = grey_allOf([
      grey_accessibilityLabel(name),
      grey_interactable(),
    ])
    EarlGrey.selectElement(with: nameMatcher)
      .usingSearch(
        action: grey_scrollInDirection(GREYDirection.down, 200),
        onElementWith:grey_kindOfClass(UITableView.self))
      .perform(grey_tap())
  }
}
