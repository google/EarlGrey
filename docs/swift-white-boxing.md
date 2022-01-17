# How to Query / Modify the Application Under Test (White-Boxing) in Swift

Since Swift does not have Header files like Objective-C, the process for using
EarlGrey's distant objects is a bit different.

For Swift, we utilize an extension of EarlGrey 2.0's Distant Objects -
GREYHostApplicationDistantObject and GREYHostBackgroundDistantObject, however
since we need to provide the test with the function declarations, we need to
create a protocol that will help expose them.

Since the Helper Bundle defined in
the [White-Boxing Setup Guide](white-boxing-setup-guide.md) is initially empty,
add a Swift file into it. The file can be blank for now.
This should automatically enable you to add a Bridging Header as described in
the Setup Guide's [Bridging Header](setup.md#bridging_header) section.
Add a Bridging Header with imports for any EarlGrey files that you need.
Refer to the [EarlGrey TestRig Bridging Header](../Tests/TestRig/Sources/Swift/SwiftTestRigBridgingHeader.h)
for an example. The Helper Bundle runs in the app side, so **do not add any
TestLib or any test-specific dependencies**.

### GREYHostApplicationDistantObject (Main Thread)

Say we wish to check the host application's `UIInterfaceOrientation`. For this,
we can use the main thread distant object - `GREYHostApplicationDistantObject`
for this purpose. The first step is to setup a protocol. Let's define the method
that we want to create by creating a base file - `SwiftTestsHost.swift`.

```swift
@objc
protocol SwiftTestsHost {

  /// Obtain the host application's interface orientation.
  func interfaceOrientation() -> UIInterfaceOrientation
}
```

Add this protocol file to **both the Helper Bundle and the Test Target**.

Now, let's create an extension file in the Helper Bundle. Let's add the method
body in an extension file, `GREYHostApplicationDistantObject+SwiftTestsHost`, as below:

```swift
extension GREYHostApplicationDistantObject: SwiftTestsHost {

  func interfaceOrientation() -> UIInterfaceOrientation {
    return UIApplication.shared.statusBarOrientation
  }
}
```

The distant object can now be readily referred to in your test. Instead of using
the object directly however, you would need to cast it to ensure that the
protocol methods are available. Use an extension on `XCTestCase` to accomplish
this within your testcase file:

```swift
private extension XCTestCase {
  /// A variable to point to the GREYHostApplicationDistantObject since casts in Swift fail on
  /// proxy types. Hence we have to perform an unsafeBitCast.
  var host: SwiftTestsHost {
    return unsafeBitCast(
      GREYHostApplicationDistantObject.sharedInstance,
      to: SwiftTestsHost.self)
  }
}
```

The distant object can now be used in your tests directly to access the
application.

For the case of getting the `interfaceOrientation` -

```swift
func testInterfaceOrientation() {
  XCTAssertEqual(host.interfaceOrientation(), UIInterfaceOrientation.portrait)
}

```

### GREYHostBackgroundDistantObject (Background Thread)

You can follow the same pattern to create extensions on
`GREYHostBackgroundDistantObject`, to make calls on a non-main thread.
