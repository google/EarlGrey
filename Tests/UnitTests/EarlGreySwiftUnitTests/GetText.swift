// Must use wrapper class to force pass by reference in block.
// inout params won't work. http://stackoverflow.com/a/28252105
public class Element {
  var text = ""
}

/*
 *  Example Usage:
 *
 *  let element = Element()
 *
 *  domainField.performAction(grey_typeText("hello.there"))
 *             .performAction(grey_getText(element))
 *
 *  GREYAssertTrue(element.text != "", reason: "get text failed")
 */
func grey_getText(elementCopy: Element) -> GREYActionBlock {
  return GREYActionBlock.actionWithName("get text",
    constraints: grey_respondsToSelector(Selector("text")),
    performBlock: { element, errorOrNil -> Bool in
      // Fix error: ambiguous use of 'text'
      // http://stackoverflow.com/a/25620623
      elementCopy.text = String(element.text ?? "")
      return true
  })
}
