import XCTest

class GetTextTest: XCTestCase {

  func testGetText() {
    let expected = "hello!"
    let textfield = UITextField()
    textfield.text = expected

    var errorOrNil: NSError?
    let element = Element()
    grey_getText(element).perform(textfield, error: &errorOrNil)
    let actual = element.text

    GREYAssertNil(errorOrNil, reason: "Error: \(errorOrNil)")
    GREYAssertEqual(actual, expected,
                    reason: "GetText failed. expected: '\(expected)' got: '\(actual)'")
  }
}
