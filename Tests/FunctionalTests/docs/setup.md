# Running the Functional Tests

Ensure that the EarlGrey Xcode Project has been built as per the [Setup
Guide](../../../docs/setup.md). Once the EarlGrey targets are building,
you should be able to open the Functional Tests Project and then **Test**
the following targets:

The Project contains three main test schemes:

<img src="images/testSchemes.png">

1.  FunctionalTestRig

    Related Targets:

    *   Functional Tests: The XCUITest target which contains the canonical
        EarlGrey test sources (to be run in the test process).
    *   FunctionalTestRig: The Application under test with all its resources (to
        be run in the app process).
    *   HostDOCategories: Distant Object Categories (to be run in the app
        process, with headers exposed to the test process).

2.  FunctionalOutOfProcessTests

    Targets:

    *   Functional Out-Of-Process Tests: The XCUITest target which contains
        tests that interact with System Alerts and backgrounding /
        foregrounding.
    *   FunctionalTestRig: The Application under test with all its resources (to
        be run in the app process).

3.  FunctionalTestRigSwift

    Targets:

    *   Functional Swift Tests: The Swift XCUITest target which contains the
        Swift test sources (to be run in the test process).
    *   FunctionalTestRigSwift: The Application under test with all its
        resources (to be run in the app process) for running Swift Tests.
    *   HostDOCategoriesSwift: Distant Object Extensions in Swift (to be run in
        the app process, with headers exposed to the test process).
