# FAQ

**How does EarlGrey compare to Xcode 7’s UI Testing?**

EarlGrey is more of a [grey-box testing](https://en.wikipedia.org/wiki/Gray_box_testing) solution
whereas Xcode’s UI Testing is completely [black-box](https://en.wikipedia.org/wiki/Black-box_testing).
EarlGrey runs in the same process as the app under test, so it has access to the same memory as the
app. This allows for better synchronization, such as ability to wait for network requests, and
allows for custom synchronization mechanisms (using idling resources and conditions) that aren’t
possible when using Xcode’s UI Testing feature.

However, EarlGrey is unable to launch or terminate the app under test from within the test case,
something that Xcode UI Testing is capable of. While EarlGrey supports many interactions, it makes
use of private APIs to create and inject touches, whereas Xcode’s UI Testing feature uses public
APIs.

Nonetheless, EarlGrey’s APIs are highly extensible and provide a way to write custom UI actions and
assertions. The ability to search for elements (using search actions) makes test cases resilient to
UI changes. For example, EarlGrey provides APIs that allow searching for elements in scrollable
containers, regardless of the amount of scrolling required.

**I get a crash with “Could not swizzle …”**

This usually means that EarlGrey is trying to swizzle the method that it has swizzled before. This
can happen if EarlGrey is being linked to more than once. Ensure that only the app under test is
linking to EarlGrey and that the app has no dependencies on EarlGrey.

**I see lots of “XXX is implemented in both YYY and ZZZ. One of the two will be used. Which one is
undefined.” in the logs**

This usually means that EarlGrey is being linked to more than once. Ensure that the app under test
is linking to EarlGrey and that the app has no dependencies on EarlGrey.

**Is there a way to return a specific element?**

No, but there is a better alternative. Use [GREYActionBlock](../EarlGrey/Action/GREYActionBlock.h)
to create a custom GREYAction and access any fields or invoke any selector on the element. For
example, if you want to invoke a selector on an element, you can use syntax similar to the
following:


```
- (void)testInvokeCustomSelectorOnElement {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"id_of_element")]
      performAction:[GREYActionBlock actionWithName:@"Invoke clearStateForTest selector"
       performBlock:^(id element, NSError *__strong *errorOrNil) {
           [element doSomething];
           return YES; // Return YES for success, NO for failure.
       }
  ]];
}
```

**How do I perform conditional actions on elements that may or may not exist in the UI hierarchy?**

If you are unsure whether the element exists in the UI hierarchy, pass an `NSError` to the
interaction and check if the error domain and code indicate that the element wasn’t found:

```
NSError *error;
[[EarlGrey selectElementWithMatcher:grey_accessibilityID(‘Foo")]
    performAction:grey_tap() error:&error];
if ([error.domain isEqual:kGREYInteractionErrorDomain] &&
    error.code == kGREYInteractionElementNotFoundErrorCode) {
  // Element doesn’t exist.
}
```

**My app shows a splash screen. How can I make my test wait for the main screen?**

Use [GREYCondition](../EarlGrey/Synchronization/GREYCondition.h) in your test's setup method to
wait for the main screen’s view controller. Here’s an example:


```
 (void)setUp {
  [super setUp];

  // Wait for the main view controller to become the root view controller.
  BOOL success = [[GREYCondition conditionWithName:@"Wait for main root view controller" block:^{
    id<UIApplicationDelegate> appDelegate = [UIApplication sharedApplication].delegate;
    UIViewController *rootViewController = appDelegate.window.rootViewController;
    return [rootViewController isKindOfClass:[MainViewController class]];
  }] waitWithTimeout:5];

  GREYAssertTrue(success, @"Main view controller should appear within 5 seconds.");
}
```

**Will my test fail if I have other modal dialogs showing on top of my app?**

Yes, if these dialogs belong to the app process running the test and are obscuring UI elements with
which tests are interacting.

**Can I use Xcode Test Navigator?**

Yes. EarlGrey supports **Test Navigator** out-of-the-box.

**Can I set debug breakpoints in the middle of a test?**

Yes. You can set a breakpoint on any interaction. The breakpoint will be hit before that
interaction is executed, but after all prior interactions have been executed.
