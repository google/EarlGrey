# Change Log

Details changes in each release of EarlGrey. EarlGrey follows
[semantic versioning](http://semver.org/).

## [1.7.2](https://github.com/google/EarlGrey/tree/1.7.2) (02/17/2017)

```
Baseline: [6d55af5]
   + [6d55af5]: 1.7.2 Release
```

### Bug Fixes
* Fixed Swizzler to properly reset swizzled selectors.
* Fixed typing by blacklisting UICompatibilityInputViewController in UIViewController tracking.

### Compatibility
* Requires iOS 8 as the minimum deployment target.
* Supports Xcode 8.2.1 and iOS 10.2.1 on devices and simulators.
* The EarlGrey gem runs out of the box for Swift 3.0 and Swift 2.3.

### Enhancements
* Updated analytics to use an client ID instead of user ID.

### Contributors
[mbaxley](https://github.com/mbaxley), thank you!

## [1.7.1](https://github.com/google/EarlGrey/tree/1.7.1) (02/03/2017)

```
Baseline: [e026773]
+ [e026773]: Change version numbers for EarlGrey 1.7.1
```

### Bug Fixes
* Fixed an issue with constraint failure details not being logged in the error trace.
* Updated nullability for GREYMatchers to improve Swift support.
* Minor changes to logging strings and docs.

### Compatibility
* Requires iOS 8 as the minimum deployment target.
* Supports Xcode 8.2.1 and iOS 10.2.1 on devices and simulators.
* The EarlGrey gem runs out of the box for Swift 3.0 and Swift 2.3.

### Enhancements
* Updated analytics to use an md5 hashed uid.

## [1.7.0](https://github.com/google/EarlGrey/tree/1.7.0) (01/25/2017)

```
Baseline: [f823ff2]
+ [f823ff2]: Removing JSON escape in reported errors.
```

### Bug Fixes
* Fixed a flake in testTrackingZombieQueue.
* Fixed CGRectIntegralInside to handle negative rectangles.
* Improved memory handling by moving autorelease pool inside loops.
* Fixed the bundle id to be consistent across all the test projects.
* Minor CI and other bug fixes.

### Compatibility
* Requires iOS 8 as the minimum deployment target.
* Supports Xcode 8.2.1 and iOS 10.2.1 on devices and simulators.

### New Features
* Updated analytics to include *hash* of test class name and *hash* of test case names to better estimate the volume of EarlGrey usage.
* Updated the readme to explain these changes.
* Updated tests for analytics to test new features.

### Enhancements
* Improved EarlGrey error logging for better post processing [Issue #392](https://github.com/google/EarlGrey/issues/392).
* Removed the deprecated methods and cleaned up private headers.
* The EarlGrey gem runs out of the box for Swift 3.0 and Swift 2.3.

### Deprecations
* Removed deprecated methods `grey_pinchFastInDirection` and `grey_pinchSlowInDirection` in favor of `grey_pinchFastInDirectionAndAngle` and `grey_pinchSlowInDirectionAndAngle` respectively.

### Contributors
[bootstraponline](https://github.com/bootstraponline), [stkhapugin](https://github.com/stkhapugin) and [kebernet](https://github.com/kebernet)

## [1.6.2](https://github.com/google/EarlGrey/tree/1.6.2) (01/06/2017)

```
Baseline: [0cdda9c]
+ [0cdda9c]: EarlGrey Sync for 1.6.2
```

### Bug Fixes
* Updated the EarlGrey API for Swift 3.0 as per the latest guidelines.
* Improved web tests to work with current google.com UI.
* Fixed a bug in the visibility checker for 32bit platform.
* Fixed flakiness caused by NSDate issues in EarlGreyExampleSwiftTests.

### Enhancements
* Added a travis hook to stop CI runs for docs-only changes.

### Contributors
Thanks to [bootstraponline](https://github.com/bootstraponline)
and the rest of the contributors!

## [1.6.1](https://github.com/google/EarlGrey/tree/1.6.1) (12/20/2016)

```
Baseline: [9e04024]
   + [9e04024]: Release 1.6.1
```

### Bug Fixes
* Add a test for long pressing the link in the UI webview.
* Fix issue with xcodeproj gem in travis runs.

### Enhancements
* Update travis run to use Xcode 8.2

## [1.6.0](https://github.com/google/EarlGrey/tree/1.6.0) (12/06/2016)

```
Baseline: [5080a21]
   + [5080a21]: Updated changelog info.plist pod spec and gem version for 1.6.0 release.
```

### Compatibility
* Requires iOS 8 as the minimum deployment target.
* The EarlGrey gem runs out of the box for Swift 3.0 and Swift 2.3.
* Has been tested for support till iOS 10.1 on devices and simulator.

### Bug Fixes
* Fixed CocoaPods issue with using EarlGrey as a module in Swift projects.
* Fixed issue with Accessibility service not enabled for simulators and devices.
* Minor documentation and syntax fixes.

### Enhancements
* Moved failure handler from a global variable to a thread local storage, like NSAssertionHandlers.
* Exposed the angle for pinch action in GREYPinchAction.
* Added EarlGreyExample CocoaPods project to travis.

### Deprecations
* Deprecated `grey_pinchSlowInDirection` and `grey_pinchFastInDirection` in favor of
  `grey_pinchFastInDirectionAndAngle` and `grey_pinchSlowInDirectionAndAngle`.

## [1.5.3](https://github.com/google/EarlGrey/tree/1.5.3) (11/14/2016)

```
Baseline: [690eaa2]
   + [690eaa2]: Updated ChangeLog and pod spec for 1.5.3 release
```

### Enhancements
* Resolve CocoaPods rating [Github issue](https://github.com/CocoaPods/CocoaPods/issues/6175)

## [1.5.2](https://github.com/google/EarlGrey/tree/1.5.2) (11/11/2016)

```
Baseline: [f3ee931]
   + [f3ee931]: Updated ChangeLog and pod spec for 1.5.2 release
```

### Compatibility
* Requires iOS 8 as the minimum deployment target.
* The EarlGrey gem runs out of the box for Swift 3.0 and Swift 2.3.
* Has been tested for support till iOS 10.1 on devices and simulator.

### Enhancements
* Enhance precision of timer used for touch injection
* Removed requirement for bridging header for Swift and EarlGrey

## [1.5.1](https://github.com/google/EarlGrey/tree/1.5.1) (11/07/2016)

```
Baseline: [d9eb1bc]
   + [d9eb1bc]: Updated ChangeLog and pod spec for 1.5.1 release
```

### Compatibility
* Requires iOS 8 as the minimum deployment target.
* The EarlGrey gem runs out of the box for Swift 3.0 and Swift 2.3.
* Has been tested for support till iOS 10.01 on devices and simulator.

### Bug Fixes
* Fixed CI Ruby test for Carthage.

### Enhancements
* Improved touch injection speed by making it work independent of the screen refresh rate.
* Added synchronization for `NSURLConnection::sendSynchronousRequest`.
* Exclude URLs that start with `data` scheme from being synchronized.
* Updated `grey_clearText` action to accept elements conforming to UITextInput protocol.

## [1.5.0](https://github.com/google/EarlGrey/tree/1.5.0) (10/31/2016)

```
Baseline: [55d42a4]
   + [55d42a4]: Updated ChangeLog and pod spec for 1.5 release
```

### Compatibility
* Requires iOS 8 as the minimum deployment target.
* The EarlGrey gem runs out of the box for [Swift 3.0](https://docs.google.com/document/d/1AeleXccp35EUX4ILa6CT3CwlxLSZq1YLrco9JF27p9k/edit) and Swift 2.3.
* Has been tested for support till iOS 10.01 on devices and simulator.

### Bug Fixes
* Failing analytics tests fixes.
* Fixed flaky Travis Stopwatch Test.
* Fixed rspec tests broken by ruby update and changing the directory.

### Enhancements
* Improved UIAppStateTracker APIs to allow for ignoring states.
* Improved failure handlers for multiple invocations within context of a valid test case.

### Deprecations
* Swift 2.2 is no longer supported.

## [1.4.0](https://github.com/google/EarlGrey/tree/1.4.0) (10/07/2016)

```
Baseline: [b5e34db]
   + [b5e34db]: Update Info.plist / Podspec / Cheatsheet for EarlGrey 1.4.0
```

### Compatibility
* Requires iOS 8 as the minimum deployment target.
* EarlGrey.gem runs out of the box for Swift 2.2.x. For Swift 3.0, please
  use the [Swift Migration Guide](https://swift.org/migration-guide/) to
  add the `Use Legacy Swift` build setting to your test target until we
  provide support.
* Has been tested for support till iOS 10.01 on devices and simulator.

### Enhancements
* A better way to blacklist URL's in GREYConfiguration by adding them to an NSArray.
* A verbose logger to provide more descriptive EarlGrey logs that can be enabled by
  setting the `kGREYAllowVerboseLogging` key in NSUserDefaults to `YES`. Verbose
  logging also measures the performance of interactions and the thread executor by
  using a stopwatch class.
* Improvements to `-[XCTestCase greyStatus]` to better reflect the status of a test.

### Bug Fixes
* Corrected selection of `UIPickerView`s even when they were disabled.
* Minor documentation and syntax fixes.

### Deprecations
* Deprecated `GREYFail` in favor of `GREYFailWithDetails`.

## [1.3.1](https://github.com/google/EarlGrey/tree/1.3.1) (09/19/2016)

```
Baseline: [c4913b]
   + [c4913b]: Update compatibility doc to include iOS 10.
```

### Compatibility
* Requires iOS 8 as the minimum deployment target.
* Has been tested for support till iOS 10.01 on devices and simulator.

### Enhancements
* Add autolayout to `FTRTypingViewController`

### Bug Fixes
* Minor documentation and syntax fixes.
* Fixed Functional Test Project scheme preventing it to be run on devices.
* Add a temporary hold on the xcodeproj gem dependency to unblock tests.

## [1.3.0](https://github.com/google/EarlGrey/tree/1.3.0) (09/09/2016)

```
Baseline: [6b2f329]
   + [6b2f329]: Add fixes for documentation.
```

### Compatibility
* Requires iOS 8 as the minimum deployment target.
* Has been tested for support till iOS 10 beta 4.

### New Features

* The following new matchers were added EarlGrey:
  * `grey_selected`: Checks if a UIControl is selected.
  * `grey_accessibilityFocused`: Checks if a UI element is focused by accessibility technologies
  like Voiceover or Switch Control.

### Enhancements
* Added an API to find the `XCTestCase` status through an EarlGrey test run.
* Improved the failure description in the failure handler.
* Made the `EarlGrey.swift` file syntax swiftier.
* Improved Unit and Functional test coverage.

### Bug Fixes
* Fixed Travis issue with the Ruby version.
* Minor documentation and syntax fixes.

### Deprecations
* `grey_elementAtIndex` has been removed in favor of the `atIndex:` interaction API. For migrating
  your tests, please follow the announcement
  [here](https://groups.google.com/forum/#!topic/earlgrey-discuss/Q6RhxRhtRvo).

### Contributors
Special thanks to [axi0mX](https://github.com/axi0mX),
[bootstraponline](https://github.com/bootstraponline),
[KazuCocoa](https://github.com/KazuCocoa) and the rest of our contributors.

## [1.2.0](https://github.com/google/EarlGrey/tree/1.2.0) (08/31/2016)

```
Baseline: [7070e1a]
   + [7070e1a]: Updated cheatsheet and podspec for 1.2.0 release
```

### New Features

* EarlGrey now supports multi-touch gestures! Following pinch actions have been added:
  * `grey_pinchFastInDirection`
  * `grey_pinchSlowInDirection`
* Added `atIndex:` interaction API to select from multiple element matches.

### Enhancements
* Updated Swift Macros in EarlGrey gem.
* Implemented matcher for UIScrollView scrolled to content edge.

### Bug Fixes
* Fixed several typos and cleaned up many project files with proper error messages.
* Added carthage `xcodebuild` command to Travis CI.
* Fixed issue with action{Did,Will}PerformAction notification and its userInfo.
* Updated protocol signatures.

### Contributors
Special thanks to [axi0mX](https://github.com/axi0mX) and the rest of our contributors.

## [1.1.0](https://github.com/google/EarlGrey/tree/1.1.0) (08/18/2016)

```
Baseline: [107dba5]
   + [107dba5]: Update podspec for 1.1.0 release [ci skip]
```

### New Features

* API reference documentation generated via [Jazzy](https://rubygems.org/gems/jazzy/)
* Cheatsheet for EarlGrey
* Carthage support
* Easier CocoaPods setup using [EarlGrey gem](https://rubygems.org/gems/earlgrey)
which replaces manually copying over `configure_earlgrey_pods.rb` and `EarlGrey.swift` file.

### Enhancements

* For demonstration purposes added Swift demo app and tests
* Update documentation for Swift usage
* Update contribution guidelines
* Added `grey_allOfMatchers` and `grey_anyOfMatchers` to EarlGrey.swift
* Use XCTest's mechanism of halting test execution instead of throwing arbitrary exception
* Helper method to speed up animation
* Added `grey_replaceText` action to directly replace text (without using keyboard) on a field
* Created `grey_atIndex` matcher for matching a single element from a list of matched elements
* Updated FAQs with questions and examples
* Update install guide with Cocoapods 0.39 support
* Added Badge for License, Cocoapod, and Travis
* Efficiency improvement in `GREYAppStateTracker` reducing O(n) to constant amortized time
* Improved webview synchronization
* Added tracking for `dispatch_async_f` and `dispatch_sync_f` methods
* Reduce throttling of CPU by allowing runloops to sleep when idle
* Removed unnecessary runloop drains improving overall speed and reliability
* Introduced trackers for `NSManagedObjectContext`
* Signal handlers and uncaught exception handler invoke previously installed handlers
* Improved accessibility logic to support beta versions of iOS 10

### Bug Fixes

* Race conditions in `GREYOperationQueueIdlingResourceTest`
* Race conditions in `GREYDispatchQueueIdlingResourceTest`
* Addressed Swift 3 related warnings in `EarlGrey.swift`
* Resigning first responder for autocorrect-enabled fields causes keyboard track to mistrack
keyboard disappearance events
* EarlGrey.xcodeproj fails to build for device because code signing identities aren't set
correctly
* Assertion failure in `-[GREYElementProvider dataEnumerator]` due to nil accessibility element
* Rubocop warnings in configure_earlgrey_pods.rb script and Podfile
* EarlGreyFunctionalTests `testSwipeOnWindow` always fails on iPhone 4S
* If parent directory has spaces, `setup-earlgrey.sh` will fail and exit
* Retain cycle in `GREYElementInteraction`
* Retain cycle in `UIApplication` mock in test suite
* Changed CFBundlePackageType in EarlGrey-Info.plist to FMWK

### Contributors
Special thanks to [bootstraponline](https://github.com/bootstraponline),
[axi0mX](https://github.com/axi0mX), and the rest of our contributors.

## [1.0.0](https://github.com/google/EarlGrey/tree/1.0.0) (02/16/2016)

First cup of EarlGrey.

```
Baseline: [7099484]
   + [7099484]: First version of EarlGrey.
```

Initial release.
