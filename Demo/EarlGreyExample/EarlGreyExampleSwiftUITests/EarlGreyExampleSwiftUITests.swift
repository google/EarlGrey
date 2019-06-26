//
// Copyright 2019 Google Inc.
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

class EarlGreyExampleSwiftUITests: XCTestCase {

  override func setUp() {
    // In UI tests it is usually best to stop immediately when a failure occurs.
    continueAfterFailure = false

    XCUIApplication().launch()
  }

  override func tearDown() { }

  func testBasicSelection() {
    // Select the button with Accessibility ID "clickMe".
    // This should throw a warning for "Result of Call Unused."
    EarlGrey.selectElement(with: grey_accessibilityID("ClickMe"))
  }

  func testBasicSelectionAndAction() {
    // Select and tap the button with Accessibility ID "clickMe".
    EarlGrey.selectElement(with: grey_accessibilityID("ClickMe"))
      .perform(grey_tap())
  }

  func testBasicSelectionAndAssert() {
    // Select the button with Accessibility ID "clickMe" and assert it's visible.
    EarlGrey.selectElement(with: grey_accessibilityID("ClickMe"))
      .assert(grey_sufficientlyVisible())
  }

  func testBasicSelectionActionAssert() {
    // Select and tap the button with Accessibility ID "clickMe", then assert it's visible.
    EarlGrey.selectElement(with: grey_accessibilityID("ClickMe"))
      .perform(grey_tap())
      .assert(grey_sufficientlyVisible())
  }

  func testSelectionOnMultipleElements() {
    // This test will fail because both buttons are visible and match the selection.
    // We add a custom error here to prevent the Test Suite failing.
    var error: NSError?
    EarlGrey.selectElement(with: grey_text("Non-Existent Element Text"))
      .perform(grey_tap(), error: &error)

    if let _ = error {
      print("Test Failed with Error : \(error.self!)")
    }
  }

  func testCollectionMatchers() {
    // First way to disambiguate: use collection matchers.
    let visibleSendButtonMatcher: GREYMatcher! =
      grey_allOf([grey_accessibilityID("ClickMe"), grey_sufficientlyVisible()])
    EarlGrey.selectElement(with: visibleSendButtonMatcher)
      .perform(grey_doubleTap())
  }

  func testCatchErrorOnFailure() {
    // TapMe doesn't exist, but the test doesn't fail because we are getting a pointer to the
    // error.
    var error: NSError?
    EarlGrey.selectElement(with: grey_accessibilityID("TapMe"))
      .perform(grey_tap(), error: &error)
    if let myError = error {
      print(myError)
    }
  }

  func testWithCondition() {
    let myCondition = GREYCondition.init(name: "Example condition", block: { () -> Bool in
      for j in 0...100000 {
        _ = j
      }
      return true
    })
    // Wait for my condition to be satisfied or timeout after 5 seconds.
    let success = myCondition!.wait(withTimeout: 5)
    if !success {
      // Just printing for the example.
      print("Condition not met")
    } else {
      EarlGrey.selectElement(with: grey_accessibilityID("ClickMe"))
        .perform(grey_tap())
    }
  }

  func testWithGreyAssertions() {
    GREYAssert(1 == 1)
    GREYAssertTrue(1 == 1)
    GREYAssertFalse(1 != 1)
    GREYAssertNotNil(1)
    GREYAssertNil(nil)
    // Uncomment one of the following lines to fail the test.
    //GREYFail("Failing with GREYFail")
  }
}

class SampleFailureHandler : NSObject, GREYFailureHandler {
  /**
   *  Called by the framework to raise an exception.
   *
   *  @param exception The exception to be handled.
   *  @param details   Extra information about the failure.
   */
  public func handle(_ exception: GREYFrameworkException!, details: String!) {
    print("Test Failed With Reason : \(exception.reason!) and details \(details)")
  }

}
