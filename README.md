# EarlGrey

EarlGrey is a native iOS UI automation test framework that enables you to write
clear, concise tests.

With the EarlGrey framework, you have access to enhanced synchronization
features. EarlGrey automatically synchronizes with the UI, network requests,
and various queues; but still allows you to manually implement customized
timings, if needed.

EarlGrey’s synchronization features help to ensure that the UI is in a steady
state before actions are performed. This greatly increases test stability and
makes tests highly repeatable.

EarlGrey works in conjunction with the XCTest framework and integrates with
Xcode’s Test Navigator so you can run tests directly from Xcode or the command
line (using xcodebuild).

## Getting Started

The EarlGrey documentation for users is located in the
[EarlGrey/docs](https://github.com/google/EarlGrey/tree/master/docs) folder.
To get started, review the EarlGrey features, check for backward compatibility,
and then install/run EarlGrey with your test target. After everything is
configured, take a look at the EarlGrey API and start writing your own tests.

  * [Features](https://github.com/google/EarlGrey/tree/master/docs/features.md)
  * [Backward Compatibility](https://github.com/google/EarlGrey/tree/master/docs/backward-compatibility.md)
  * [Install and Run](https://github.com/google/EarlGrey/tree/master/docs/install-and-run.md)
  * [API](https://github.com/google/EarlGrey/tree/master/docs/api.md)

## Getting Help

If you need help, several resources are available. First check the [FAQ](https://github.com/google/EarlGrey/tree/master/docs/faq.md).
If you have more questions after reading the FAQ, see [Known Issues](https://github.com/google/EarlGrey/tree/master/docs/known-issues.md).
If you still have questions, you can bring them to our attention by asking them on
[stackoverflow.com](http://stackoverflow.com/) using the [#earlgrey tag](http://stackoverflow.com/questions/tagged/earlgrey).
You can also start new discussions with us on our [Google group](https://groups.google.com/forum/#!forum/earlgrey-discuss).

  * [FAQ](https://github.com/google/EarlGrey/tree/master/docs/faq.md)
  * [Known Issues](https://github.com/google/EarlGrey/tree/master/docs/known-issues.md)
  * [Stack Overflow](http://stackoverflow.com/questions/tagged/earlgrey)
  * [Google Group](https://groups.google.com/forum/#!forum/earlgrey-discuss)

## Analytics

To prioritize and improve EarlGrey, the framework collects usage data and
uploads it to Google Analytics. More specifically, the framework collects the
App’s *Bundle ID* (as a MD5 hash) and the total number of test cases. This
information allows us to measure the volume of usage. If they wish, users can
choose to opt out by disabling the Analytics config setting in their test’s
setUp method:

```objc
// Disable analytics.
[[GREYConfiguration sharedInstance] setValue:@(NO)
                                forConfigKey:kGREYConfigKeyAnalyticsEnabled];
```

## For Contributors

Please make sure you’ve followed the guidelines in
[CONTRIBUTING.md](./CONTRIBUTING.md) before making any contributions.

### Setup an EarlGrey Project

  1. Clone the EarlGrey repository from GitHub:

    ```
    git clone https://github.com/google/EarlGrey.git
    ```

  2. After you have cloned the EarlGrey repository, download all the dependencies using the
  `setup-earlgrey.sh` script (run the script from the cloned repo).
  3. After the script completes successfully, open `EarlGrey.xcodeproj` and ensure that all
the targets build.
  4. You can now use `EarlGrey.xcodeproj` to make changes to the framework.

### Add and Run Tests

#### Unit Tests

To add unit tests for EarlGrey, use `UnitTests.xcodeproj` located at
`Tests/UnitTests`. To run all unit tests, select the **UnitTests** Scheme and press Cmd+U.

#### Functional Tests

To add functional tests for EarlGrey, use the `FunctionalTests.xcodeproj` located
at `Tests/FunctionalTests`. To run all functional tests, select the **FunctionalTests** Scheme and press Cmd+U.