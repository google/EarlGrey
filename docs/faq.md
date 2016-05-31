# FAQ

**How does EarlGrey compare to Xcode’s UI Testing?**

EarlGrey is more of a [gray-box testing](https://en.wikipedia.org/wiki/Gray_box_testing) solution
whereas Xcode’s UI Testing is completely [black-box](https://en.wikipedia.org/wiki/Black-box_testing).
EarlGrey runs in the same process as the app under test, so it has access to the same memory as the
app. This allows for better synchronization, such as ability to wait for network requests, and
allows for custom synchronization mechanisms that aren’t possible when using Xcode’s UI Testing feature.

However, EarlGrey is unable to launch or terminate the app under test from within the test case,
something that Xcode UI Testing is capable of. While EarlGrey supports many interactions, it makes
use of private APIs to create and inject touches, whereas Xcode’s UI Testing feature uses public
APIs.

Nonetheless, EarlGrey’s APIs are highly extensible and provide a way to write custom UI actions and
assertions. The ability to search for elements (using search actions) makes test cases resilient to
UI changes. For example, EarlGrey provides APIs that allow searching for elements in scrollable
containers, regardless of the amount of scrolling required.

**I get a crash with “Could not swizzle …”**

This usually means that EarlGrey is trying to swizzle a method that it has swizzled before. This
can happen if EarlGrey is being linked to more than once. Ensure that only the test target
depends on EarlGrey.framework and EarlGrey.framework is embedded in the app under test (`$TEST_HOST`) from the
test target's build phase.

**I see lots of “XXX is implemented in both YYY and ZZZ. One of the two will be used. Which one is
undefined.” in the logs**

This usually means that EarlGrey is being linked to more than once. Ensure that only the test target
depends on EarlGrey.framework and EarlGrey.framework is embedded in the app under test (`$TEST_HOST`) from the
test target's build phase.

**Is there a way to return a specific element?**

No, but there is a better alternative. Use [GREYActionBlock](../EarlGrey/Action/GREYActionBlock.h)
to create a custom GREYAction and access any fields or invoke any selector on the element. For
example, if you want to invoke a selector on an element, you can use syntax similar to the
following:


```objc
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

```objc
NSError *error;
[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"Foo")]
    performAction:grey_tap()
            error:&error];

if ([error.domain isEqual:kGREYInteractionErrorDomain] &&
    error.code == kGREYInteractionElementNotFoundErrorCode) {
  // Element doesn’t exist.
}
```

**My app shows a splash screen. How can I make my test wait for the main screen?**

Use [GREYCondition](../EarlGrey/Synchronization/GREYCondition.h) in your test's setup method to
wait for the main screen’s view controller. Here’s an example:


```objc
- (void)setUp {
  [super setUp];

  // Wait for the main view controller to become the root view controller.
  BOOL success = [[GREYCondition conditionWithName:@"Wait for main root view controller"
                                             block:^{
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

**Where do I find the xctest bundle?**

For the Example project, run the `EarlGreyExampleSwiftTests` target once then find the bundle:

> cd ~/Library/Developer/Xcode/DerivedData/EarlGreyExample-*/Build/Products/Debug-iphonesimulator/EarlGreyExampleSwift.app/PlugIns/EarlGreyExampleSwiftTests.xctest/

For physical device builds, replace `Debug-iphonesimulator` with `Debug-iphoneos`.

You can verify the `EarlGrey.framework` is included in the bundle at `EarlGreyExampleSwiftTests.xctest/Frameworks/EarlGrey.framework`

**How should I handle animations?**

By default, [EarlGrey truncates CALayer based animations](../EarlGrey/Common/GREYConfiguration.h#L108) that exceed a threshold. The max animation duration setting is configurable:

```swift
// swift
let kMaxAnimationInterval:CFTimeInterval = 5.0
GREYConfiguration.sharedInstance().setValue(kMaxAnimationInterval, forConfigKey: kGREYConfigKeyCALayerMaxAnimationDuration)
```

```objc
// objc
[[GREYConfiguration sharedInstance] setValue:@(kMaxAnimationInterval)
                                forConfigKey:kGREYConfigKeyCALayerMaxAnimationDuration];
```

In addition to truncating, animation speed can be increased. UIKit
completion blocks and async calls execute as they normally would, just faster. This matches the
real conditions the iOS app is run under and will catch more bugs than simply disabling animations.
Note that the speedup doesn't work on `UIScrollView` because it animates via `CADisplayLink` internally.
Refer to the [PSPDFKit blog post for more details.](https://pspdfkit.com/blog/2016/running-ui-tests-with-ludicrous-speed/)

```swift
UIApplication.sharedApplication().keyWindow?.layer.speed = 100
```
