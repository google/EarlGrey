import EarlGrey
import XCTest

@testable import EarlGreyExampleSwift

class SwiftTests: XCTestCase {
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
}
