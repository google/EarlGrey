# Change Log

Details changes in each release of EarlGrey. EarlGrey follows
[semantic versioning](http://semver.org/).

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
