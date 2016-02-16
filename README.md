# EarlGrey

EarlGrey is a native iOS UI automation test framework that enables you to write
clear, concise tests.

With the EarlGrey framework, you have access to enhanced synchronization
features. EarlGrey automatically synchronizes with the UI, network requests,
and various queues, but still allows you to manually implement customized
timings, if needed.

EarlGrey’s synchronization features help ensure that the UI is in a steady
state before actions are performed. This greatly increases test stability and
makes tests highly repeatable.

EarlGrey works in conjunction with the XCTest framework and integrates with
Xcode’s Test Navigator so you can run tests directly from Xcode or the command
line (using xcodebuild).

## Getting Started

The EarlGrey documentation for users is located in the `EarlGrey/docs` folder.
To get started, review the EarlGrey features, check for backward compatibility,
and then install/run EarlGrey with your test target. Once everything is
configured, take a look at the EarlGrey API and start writing your own tests.

  * [Features](./docs/features.md)
  * [Backward Compatibility](./docs/backward-compatibility.md)
  * [Install and Run](./docs/install-and-run.md)
  * [API](./docs/api.md)

## Getting Help

If you need help, several resources are available. First check the FAQ. If the
answers you need are not there, read through the Known Issues. If you still have
questions, contact us using our [Google group](https://groups.google.com/forum/#!forum/earlgrey-discuss).

  * [FAQ](./docs/faq.md)
  * [Known Issues](./docs/known-issues.md)

## Analytics

To prioritize and improve EarlGrey, the framework collects usage data and
uploads it to Google Analytics. More specifically, the framework collects the
App’s *Bundle ID* (as a MD5 hash) and the total number of test cases. This
information allows us to measure the volume of usage. If they wish, users can
choose to opt out by disabling the Analytics config setting in their test’s
setUp method:

```
// Disable analytics.
[[GREYConfiguration sharedInstance] setValue:@(NO) forConfigKey:kGREYConfigKeyAnalyticsEnabled];
```

## For Contributors

Please make sure you’ve followed the guidelines in 
[CONTRIBUTING.md](./CONTRIBUTING.md) before making any contributions.

### Setup EarlGrey Project

  1. Clone the EarlGrey repository from Github:

      ```
      git clone https://github.com/google/EarlGrey.git
      ```

  2. Once you have the EarlGrey repository, download all the dependencies using the
  `setup-earlgrey.sh` script (run the script from the cloned repo).
  3. Once the script completes successfully, open `EarlGrey.xcodeproj` and ensure all
the targets build.
  4. You can now use `EarlGrey.xcodeproj` to make changes to the framework.

### Add and Run Tests

#### Unit Tests

To add unit tests for EarlGrey use `UnitTests.xcodeproj` located at
`Tests/UnitTests`. To run all unit tests, select the **UnitTests** Scheme and press Cmd+U.

#### Functional Tests

To add functional tests for EarlGrey use the `FunctionalTests.xcodeproj` located
at `Tests/FunctionalTests`. To run all functional tests, select the **FunctionalTests** Scheme and press Cmd+U.
