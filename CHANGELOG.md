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
