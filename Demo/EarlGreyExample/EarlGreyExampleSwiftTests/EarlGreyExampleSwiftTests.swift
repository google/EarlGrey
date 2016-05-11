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
@testable import EarlGreyExampleSwift

class EarlGreyExampleSwiftTests: XCTestCase {

  func testBasicSelection() {
    // Select the button with Accessibility ID "clickMe".
    EarlGrey().selectElementWithMatcher(grey_accessibilityID("ClickMe"))
  }

  func testBasicSelectionAndAction() {
    // Select and tap the button with Accessibility ID "clickMe".
    EarlGrey().selectElementWithMatcher(grey_accessibilityID("ClickMe"))
        .performAction(grey_tap())
  }

  func testBasicSelectionAndAssert() {
    // Select the button with Accessibility ID "clickMe" and assert it's visible.
    EarlGrey().selectElementWithMatcher(grey_accessibilityID("ClickMe"))
        .assertWithMatcher(grey_sufficientlyVisible())
  }

  func testBasicSelectionActionAssert() {
    // Select and tap the button with Accessibility ID "clickMe", then assert it's visible.
    EarlGrey().selectElementWithMatcher(grey_accessibilityID("ClickMe"))
        .performAction(grey_tap())
        .assertWithMatcher(grey_sufficientlyVisible())
  }

  func testSelectionOnMultipleElements() {
    // This test will fail because both buttons are visible and match the selection.
    // We add a custom error here to prevent the Test Suite failing.
    var error: NSError?
    EarlGrey().selectElementWithMatcher(grey_sufficientlyVisible())
        .performAction(grey_tap(), error: &error)

    if let _ = error {
      print("Test Failed with Error : \(error?.description)")
    }
  }

  func testCollectionMatchers() {
    // First way to disambiguate: use collection matchers.
    let visibleSendButtonMatcher =
        grey_allOfMatchers(grey_accessibilityID("ClickMe"), grey_sufficientlyVisible())
    EarlGrey().selectElementWithMatcher(visibleSendButtonMatcher)
        .performAction(grey_doubleTap())
  }

  func testWithInRoot() {
    // Second way to disambiguate: use inRoot to focus on a specific window or container.
    // There are two buttons with accessibility id "Send", but only one is inside SendMessageView.
    EarlGrey().selectElementWithMatcher(grey_accessibilityID("Send"))
        .inRoot(grey_kindOfClass(SendMessageView))
        .performAction(grey_doubleTap())
  }

  func testWithCustomMatcher() {
    // Define the match condition: matches table cells that contains a date for a Thursday.
    let matches: MatchesBlock = { (element: AnyObject!) -> Bool in
      if let cell = element as? UITableViewCell {
        let formatter = NSDateFormatter()
        formatter.dateStyle = NSDateFormatterStyle.LongStyle
        if let date = formatter.dateFromString(cell.textLabel!.text!) {
          let calendar = NSCalendar.currentCalendar()
          let weekday = calendar.component(NSCalendarUnit.Weekday, fromDate: date)
          return weekday == 5
        } else {
          return false
        }
      } else {
        return false
      }
    }
    // Create a description for the matcher.
    let describe: DescribeToBlock = { (description: GREYDescription!) -> Void in
      description.appendText("Date for a Thursday")
    };
    // Create an EarlGrey custom matcher.
    let matcherForThursday = GREYElementMatcherBlock.init(matchesBlock: matches,
        descriptionBlock: describe)
    // Profit
    EarlGrey().selectElementWithMatcher(matcherForThursday)
        .performAction(grey_doubleTap())
  }

  func testTableCellOutOfScreen() {
    // Go find one cell out of the screen.
    EarlGrey().selectElementWithMatcher(grey_accessibilityID("Cell30"))
        .usingSearchAction(grey_scrollInDirection(GREYDirection.Down, 50),
            onElementWithMatcher: grey_accessibilityID("table"))
        .performAction(grey_tap())
    // Move back to top of the table.
    EarlGrey().selectElementWithMatcher(grey_accessibilityID("Cell1"))
        .usingSearchAction(grey_scrollInDirection(GREYDirection.Up, 500),
            onElementWithMatcher: grey_accessibilityID("table"))
        .performAction(grey_doubleTap())
  }

  func testCatchErrorOnFailure() {
    // TapMe doesn't exist, but the test doesn't fail because we are getting a pointer to the error.
    var error: NSError?
    EarlGrey().selectElementWithMatcher(grey_accessibilityID("TapMe"))
        .performAction(grey_tap(), error: &error)
    if let myError = error {
      print(myError)
    }
  }

  func testCustomAction() {
    // Fade in and out an element.
    let fadeInAndOut = { (element: UIView) -> Void in
      UIView.animateWithDuration(1.0, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut,
          animations: { element.alpha = 0.0 }, completion: {
            (finished: Bool) -> Void in

            UIView.animateWithDuration(1.0, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn,
                animations: { element.alpha = 1.0 }, completion: nil)
      })
    }
    // Define a custom action that applies fadeInAndOut to the selected element.
    let tapClickMe: GREYAction = {
      return GREYActionBlock.actionWithName("Fade In And Out",
                                            constraints: nil,
                                            performBlock: {
          (element: AnyObject!, errorOrNil: UnsafeMutablePointer<NSError?>) -> Bool in
            // First make sure element is attached to a window.
            guard let window = element.window! as UIView! else {
              let errorInfo = [NSLocalizedDescriptionKey:
                  NSLocalizedString("Element is not attached to a window", comment: "")]
              errorOrNil.memory = NSError(domain: kGREYInteractionErrorDomain, code: 1,
                  userInfo: errorInfo)
              return false
            }
            fadeInAndOut(window)
            return true
          })
    }()
    EarlGrey().selectElementWithMatcher(grey_accessibilityID("ClickMe"))
        .performAction(tapClickMe)
  }

  func testWithCustomAssertion() {
    // Write a custom assertion that checks if the alpha of an element is equal to the expected value.
    let alphaEqual = { (expectedAlpha: CGFloat) -> GREYAssertionBlock in
      return GREYAssertionBlock.assertionWithName("Assert Alpha Equal", assertionBlockWithError: {
          (element: AnyObject!, errorOrNil: UnsafeMutablePointer<NSError?>) -> Bool in
            guard let view = element! as! UIView as UIView! else {
              let errorInfo = [NSLocalizedDescriptionKey:
                NSLocalizedString("Element is not a UIView", comment: "")]
              errorOrNil.memory = NSError(domain: kGREYInteractionErrorDomain, code: 2,
                  userInfo: errorInfo)
              return false
            }
            return view.alpha == expectedAlpha
      })
    }
    EarlGrey().selectElementWithMatcher(grey_accessibilityID("ClickMe"))
        .assert(alphaEqual(1.0))
  }

  func testWithCustomFailureHandler() {
    // This test will fail and use our custom handler to handle the failure.
    // The custom handler is defined at the end of this file.
    let myHandler = PrintOnlyHandler()
    EarlGrey().setFailureHandler(myHandler)
    EarlGrey().selectElementWithMatcher(grey_accessibilityID("TapMe"))
        .performAction(grey_tap())
  }

  func testLayout() {
    // Define a layout constraint.
    let onTheRight = GREYLayoutConstraint(attribute: GREYLayoutAttribute.Left,
        relatedBy: GREYLayoutRelation.GreaterThanOrEqual,
        toReferenceAttribute: GREYLayoutAttribute.Right, multiplier: 1.0, constant: 0.0)
    EarlGrey().selectElementWithMatcher(grey_accessibilityLabel("SendForLayoutTest"))
        .assertWithMatcher(grey_layout([onTheRight], grey_accessibilityID("ClickMe")))
  }

  func testWithCondition() {
    let myCondition = GREYCondition.init(name: "Example condition", block: { () -> Bool in
      for j in 0...100000 {
        _ = j
      }
      return true
    })
    // Wait for my condition to be satisfied or timeout after 5 seconds.
    let success = myCondition.waitWithTimeout(5)
    if !success {
      // Just printing for the example.
      print("Condition not met")
    } else {
      EarlGrey().selectElementWithMatcher(grey_accessibilityID("ClickMe"))
        .performAction(grey_tap())
    }
  }

  func testWithGreyAssertions() {
    GREYAssert(1 == 1, reason: "Assert with GREYAssert")
    GREYAssertTrue(1 == 1, reason: "Assert with GREYAssertTrue")
    GREYAssertFalse(1 != 1, reason: "Assert with GREYAssertFalse")
    GREYAssertNotNil(1, reason: "Assert with GREYAssertNotNil")
    GREYAssertNil(nil, reason: "Assert with GREYAssertNil")
    GREYAssertEqual(1, 1, reason: "Assert with GREYAssertEqual")
    // Uncomment one of the following lines to fail the test.
    //GREYFail("Failing with GREYFail")
    //GREYFail("Failing with GREYFail", details: "Details of the failure")
  }

}

class PrintOnlyHandler : NSObject, GREYFailureHandler {

  func handleException(exception: GREYFrameworkException!, details: String!) {
    print("Test Failed With Reason : \(exception.reason) and details : \(details)")
  }

}
