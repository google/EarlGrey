[![Apache License](https://img.shields.io/badge/license-Apache%202-lightgrey.svg?style=flat)](https://github.com/google/EarlGrey/blob/earlgrey2/LICENSE)
![Build Status](https://app.bitrise.io/app/0b4975da22d56e16/status.svg?token=5TrWUStkI51GjdO7PgEueQ)

**Note:** EarlGrey 2.0 is currently in Alpha and doesn't support all forms of integration. In the
coming quarters we'll add support for Xcode Projects and CocoaPods as well. Please peruse the code
and do bring forward any issues or concerns you might have with migrating your EarlGrey 1.0 tests
to 2.0.

To use, please clone the `earlgrey2` branch with its submodules:

    // Clone EarlGrey 2.0
    git clone -b earlgrey2 https://github.com/google/EarlGrey.git

# EarlGrey 2.0

EarlGrey 2.0 is a native iOS UI automation test framework that combines
[EarlGrey](https://github.com/google/EarlGrey) with [XCUITest](https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/testing_with_xcode/chapters/09-ui_testing.html), Apple's official
UI Testing Framework.

EarlGrey 2.0 allows you to write clear, concise tests in Objective-C / Swift and
enables out of process interactions with XCUITest. It has the following
chief advantages:

* **Synchronization:** From run to run, EarlGrey 2.0 ensures that you will get the same result
  in your tests, by making sure that the application is idle. It does so by automatically
  tracking UI changes, network requests and various queues. EarlGrey 2.0 also allows
  you to manually implement custom timings.
* **White-box:** EarlGrey 2.0 allows you to query the application under test from your tests.
* **Native Development:** As with EarlGrey 1.0, you can use EarlGrey 2.0 natively with Xcode.
  You can run tests directly from Xcode or xcodebuild. Please note that EarlGrey 2.0 uses a UI
  Testing Target and not a Unit Testing Target like EarlGrey 1.0.

EarlGrey 1.0 is a white-box testing tool that allows you to interact with the application under test.
Since XCUITest is a black-box testing framework, this is not directly possible with EarlGrey 2.0.
To fix this, we use [eDistantObject
(eDO)](https://github.com/google/eDistantObject)
to allow these white-box interactions.

# Using EarlGrey 2.0

Currently, only the source code is available, with Xcode Project integration. To integrate with
EarlGrey 2.0, please take a look at our [Setup Guide](docs/setup.md).

For a quick sample project, take a look at our
[FunctionalTests](Tests/FunctionalTests/FunctionalTests.xcodeproj)
project.

# Getting Help

You can use the same channels as with EarlGrey 1.0 for communicating with us. Please use the
`earlgrey-2` tag to differentiate the projects.

*   [Known Issues](https://github.com/google/EarlGrey/issues)
*   [Stack Overflow](http://stackoverflow.com/questions/tagged/earlgrey2)
*   [Slack](https://googleoss.slack.com/messages/earlgrey)
*   [Google Group](https://groups.google.com/forum/#!forum/earlgrey-discuss)

# Analytics

Unlike [EarlGrey 1.0](https://github.com/google/EarlGrey#analytics),
EarlGrey 2.0 does not collect or upload any analytics for its usage.

# EarlGrey 2.0 Advantages over XCUITest

*   Automatic synchronization with Animations, Dispatch Queues, Network Requests as enumerated [here](https://github.com/google/EarlGrey/blob/master/docs/features.md#synchronization).
*   In-built White-Box Testing Support with RMI.
*   Better Support for Flakiness Issues.
*   Better Control of tests. EarlGrey has a much larger set of matchers.
*   EarlGrey performs a pixel-by-pixel check for the visibility of an element.

# EarlGrey 2.0 Advantages over EarlGrey 1.0

*   Out of Process Testing using XCUITest. So System Alerts, Inter-app
    interactions etc. are supported
*   Lesser throttling of the application under test's main thread.
*   Better support since accessibility is provided out of the box with XCUITest.

# Caveats

*   You cannot directly access the application under test as with EarlGrey 1.0.
    You need to use [eDistantObject (eDO)](https://github.com/google/eDistantObject)
    to do so.
*   XCUITest application launches can add a 6+ second delay. Please use
    [XCUIApplication
    launch](https://developer.apple.com/documentation/xctest/xcuiapplication/1500467-launch?language=objc)
    judiciously.
