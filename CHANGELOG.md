## [2.2.1](https://github.com/google/EarlGrey/tree/2.2.0) (12/9/2020)
```
Baseline: [91dc49f]
+ [91dc49f]: Move test-side screenshot to XCUIScreen.
```

### Enhancements
* Improved synchronization by performing most of the GREYActions on the main thread right after matching.
* Improved synchronization by tracking all NSTimers added in the main thread.
* Added EarlGrey API so that users can choose the root matcher for subsequent interactions.
* Verbose logging can be added through NSUserDefaults.
* iOS 14 support has been added for location alert strings.
* Dedupe superview/subview pair if accessibility attributes are the same as this is a valid case.

### Bug fixes
* Fix scrolling synchronization issue where tapping was failing at the end of scroll action.
* Fix crash when GREYConfiguration methods were called before relaunching the application.
* Fix crash when error screenshot was taken on the test side.

### Compatibility
* EarlGrey has been tested for working till Xcode version 12.2 and Swift 5.

### Known Issues
* There are animation issues with Context Menu’s and multi-window animations.
* ASAN, UBSAN and TSAN do not work with EarlGrey at the moment.

## [2.2.0](https://github.com/google/EarlGrey/tree/2.2.0) (10/9/2020)
```
Baseline: [ddf2911]
+ [ddf2911]: GREYCAAnimationDelegate optimization.
```

### Enhancements
* Support has been added for Xcode 11, 12 and iOS 13.x, iOS 14.
* Performance improvement for visibility checker that is used for grey_tap(), grey_sufficientlyVisible(), etc.
* Error logs are now more concise and clear.
* Miscellaneous synchronization improvements related to scroll views, timers and network tracking.
* All EarlGrey interactions from the test side now work on a separate background queue.
* Added app-under-test crash handler API to bring back crashed app and continue remaining test cases properly.
* Added dispatch policy API and the new background execution policy, which is more resistant to remote call related deadlock.

### Bug Fixes
* UIView and UIViewController owned by test can no longer be sent to app-under-test by remote invocation, which is considered a common mistake.

### Compatibility
* EarlGrey has been tested for working till Xcode version 12.2 and Swift 5.

### Known Issues
* There are animation issues with Context Menu’s and multi-window animations.
* ASAN, UBSAN and TSAN do not work with EarlGrey at the moment.

## [2.1.0](https://github.com/google/EarlGrey/tree/2.0.0) (11/05/2019)
```
Baseline: [ff674b6]
+ [ff674b6]: Experiment for draining before shifted view after-screenshot.
```

### Enhancements
* Support for iOS 13.
* Deadlock prevention fixes such as adding remote execution of all queries from the test framework.
* XCUITest support for rotation.

### Compatibility
* Xcode 11 / iOS 13 support present.

### Known Issues
* Swipe to go back support with iOS 13 does not work.


## [2.0.0](https://github.com/google/EarlGrey/tree/2.0.0) (08/05/2019)
```
Baseline: [13e6676]
+ [13e6676]: GREYTestDO modular imports
```

### Enhancements
* Fixed total animation duration miscalculation.
* Created a separate proxy queue class.

### Compatibility
* Release for EarlGreyV2
