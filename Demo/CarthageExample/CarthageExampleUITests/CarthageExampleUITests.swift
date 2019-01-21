import XCTest

class CarthageExampleUITests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false

        XCUIApplication().launch()
    }

    func testExample() {
        let application: XCUIApplication = XCUIApplication()
        application.launch()
        EarlGrey.selectElement(with: grey_keyWindow())
            .perform(grey_tap())
    }
}
