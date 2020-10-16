## [2.2.0](https://github.com/google/EarlGrey/tree/2.2.0) (10/16/2019)
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
