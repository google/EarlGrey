# EarlGrey Usage Examples
Add any example of custom matchers, asserts etc. that you have found very useful in your EarlGrey tests.

Example 1: **Selecting the first match via a custom Swift matcher**

When an application has exact duplicate elements (every attribute is the same,
including their hierarchy), then the correct fix is to update the app to avoid
duplicating the UI. When that's not possible, a workaround is to match on
the first element.

```swift
/// Example Usage:
///
///     EarlGrey.select(elementWithMatcher: grey_allOf([
///       grey_accessibilityID("some_id"),
///       grey_interactable(),
///       grey_firstElement(),
///     ])).assert(grey_notNil())
///
/// Note: Only intended to be used with `select(elementWithMatcher:)`.
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
```
