# Install and run

This document shows you how to install EarlGrey and then how to set up and run your first
test.

## Install EarlGrey

You can add EarlGrey to Xcode projects in three ways: using CocoaPods, Carthage or manually through the Xcode Project.

For EarlGrey, we highly recommend [CocoaPods](http://cocoapods.org/pods/EarlGrey) as the best way to get started.

### CocoaPods installation

#### Step 1: Set up a Unit target

1. To create a new Unit Test (XCTest) target, select your project in the Xcode Project Navigator,
and then click **Editor → Add Target...** from the menu.
2. In the **Add Target** window, select **iOS** → **Test** → **iOS Unit Testing Bundle**:

<img src="images/image00.png" width="500">

Click **Next** → **"Add a Test Target Name"** → **Finish**.

3. The test target must have a Scheme associated with it. To add one, go to **Product** →
**Scheme** → **Manage Schemes**, press the plus **(+)** sign, and then select the target from
the dropdown menu. Ensure the **Container** is set to the app under test.

<img src="images/image01.png" width="500">

And click on **Close**.

#### Step 2: Add EarlGrey as a framework dependency

1. In the test target's section in your `Podfile`, add EarlGrey as a dependency.

```ruby
target TEST_TARGET do
  project PROJECT_NAME

  use_frameworks! # Required for Swift Test Targets only
  inherit! :search_paths # Required for not double-linking libraries in the app and test targets.
  pod 'EarlGrey'
end
```

2. Use the `configure_for_earlgrey` method from the [EarlGrey gem](https://rubygems.org/gems/earlgrey)
in your Podfile's `post_install` section as in below.

```ruby
post_install do |installer|
  require 'earlgrey' # Imports the EarlGrey gem for usage in your Podfile
  configure_for_earlgrey(installer, PROJECT_NAME, TEST_TARGET, SCHEME_FILE) # EarlGrey Gem Call
end
```

3. Your complete Podfile when using EarlGrey with the latest CocoaPods should look like:

```ruby
PROJECT_NAME = 'SampleApp'
TEST_TARGET = 'SampleAppTests'
SCHEME_FILE = 'SampleAppTests.xcscheme'

target TEST_TARGET do
  project PROJECT_NAME

  use_frameworks! # Required for Swift Test Targets only
  inherit! :search_paths # Required for not double-linking libraries in the app and test targets.
  pod 'EarlGrey'
end

post_install do |installer|
  require 'earlgrey' # Imports the EarlGrey gem for usage in your Podfile
  configure_for_earlgrey(installer, PROJECT_NAME, TEST_TARGET, SCHEME_FILE) # EarlGrey Gem Call
end
```

4. Install the EarlGrey gem by doing `gem install earlgrey` and then do the `pod install`.

Notes:
* Call the `configure_for_earlgrey` method for each target / Scheme.
* For compatibility between different versions, please see [this doc](https://github.com/google/EarlGrey/tree/master/docs/versions.md).
To download a particular version of the gem, use `gem install earlgrey -v x.y.z`.

#### Step 3: Run the pod install command

After you successfully run the `pod install` command, open the generated workspace and find EarlGrey
installed in the `Pods/` directory. The generated `Pods/` project should look similar to:

<img src="images/image02.png" width="250">

### Carthage Installation

#### Step 1: Set up a test target for Carthage

See [Step 1 from the `CocoaPods installation`](#step-1:-set-up-a-unit-target) detailed above.

#### Step 2: Configure carthage

1. Install Carthage

`brew update; brew install carthage`

2. Specify the version of EarlGrey to use in Cartfile.private.

Note that you can also use "master" instead of a release tag.

`echo 'github "google/EarlGrey" "1.2.0"' >> Cartfile.private`

3. Update to latest EarlGrey revision and create Cartfile.resolved.

`carthage update EarlGrey --platform ios`

#### Step 3: Use the EarlGrey gem

1. Install the EarlGrey gem.

`gem install earlgrey`

2. Use the gem to install EarlGrey into the testing target.

`earlgrey install -t EarlGreyExampleSwiftTests`

Now you're ready to start testing with EarlGrey!
If you need more control, review the available installation options in the `earlgrey gem`:

`earlgrey help install`

### GitHub Installation

In cases where CocoaPods is not compatible with your project, you can add EarlGrey manually to your Xcode project.

#### Step 1: Generate EarlGrey.framework

1. Download the source for EarlGrey and its dependencies.
  * Download EarlGrey's source code from the [Latest Release](https://github.com/google/EarlGrey/releases/latest)

  * Unzip and go to the `EarlGrey-x.y.z/EarlGrey` directory that contains **EarlGrey.xcodeproj**.

  * Open the **EarlGrey.xcodeproj** file and build the EarlGrey scheme.

Your EarlGrey folder structure should now look like this:

<img src="images/image03.png" width="200">

And your EarlGrey Project should look like this:

<img src="images/image04.png" width="200">

2. As part of the initial build step, a script [**setup-earlgrey.sh**](https://github.com/google/EarlGrey/tree/master/Scripts/setup-earlgrey.sh)
   will be run to download all the required dependencies. Without it, you might find dependencies
   like `fishhook` and `OCHamcrest` shown as missing in the folder structure.

#### Step 2: Add EarlGrey as a dependency of the project which contains your app under test

1. Close **EarlGrey.xcodeproj** so that it is no longer open in any Xcode window. Once closed, drag **EarlGrey.xcodeproj** from its directory into your App’s project or workspace in Xcode. To verify this, you should find `EarlGrey` in the list of targets of your app in Xcode:

<img src="images/image05.png" width="350">

2. Add **EarlGrey.framework** as a dependency of your project’s Test Target:

```
**Project** → **Test Target** → **Build Phases** → **Link Binary With Libraries** → **+ (Add Sign)** → **EarlGrey.framework**
```

3. Add EarlGrey as a Target Dependency to the Test Target:

```
**Project** → **Test Target** → **Build Phases** → **Target Dependencies** → **+ (Add Sign)** → **EarlGrey**
```

The Test Target’s Build Phases should now look similar to this:

<img src="images/image06.png" width="450">

4. Turn off Bitcode as it is not supported by EarlGrey (yet) by setting **Enable Bitcode** to **NO** in the Build Settings of the Test Target.

5. You must add environment variables in the Test Target's Scheme to inject the EarlGrey framework. To do so, go to **The Test Target → Edit Scheme → Test Action** and then deselect **Use the Run action's arguments and environment variables**. Add the following details in the `Environment Variables`:

Key: `DYLD_INSERT_LIBRARIES`
Value:`@executable_path/EarlGrey.framework/EarlGrey`

Make sure the `Expand Variables Based On` value points to the app under test. The Scheme should now look like this:<a name="scheme-changes"></a>

<img src="images/image07.png" width="500">

#### Step 3: Attempt to build the app under test

In Xcode, attempt to build the app under test. It should build without any errors. After EarlGrey is built, see the [Final Test Configuration](#final-test-configuration) section for additional customizations that you may need to get your tests to run.

#### Step 4: Final Test Configuration <a name="final-test-configuration"></a>

The EarlGrey tests are hosted from the application being tested. Make sure the test target is setup
correctly to launch the app under test:

1. Under the **General** tab:
  * **Host Application** is set to the app under test.

2. Under the **Build Settings** tab:
  * **Test Host** points to your application, for example:
     *$(BUILT_PRODUCTS_DIR)/<PRODUCT_NAME>.app/<PRODUCT_NAME>* where
     *<PRODUCT_NAME>* must be replaced by the name of the app under test.
  * **Bundle Loader** is set to *$(TEST_HOST)*.
  * **Wrapper Extension** is set to *xctest*.
3. Add a **Copy Files** Build Phase to the Test Target to copy the EarlGrey framework to your app under test.
To do this, choose **Project → Test Target → Build Phases → + (Add Sign) → New Copy Files Phase**, and then
add the following details in the **Copy Files** phase:

Destination: `Absolute Path`
Path: `$(TEST_HOST)/..`
Copy files only when installing: Deselect
Name: `Path to EarlGrey.Framework` with `Code Sign on Copy` selected.

The Build Phases should now include:<a name="build-phase-changes"></a>

<img src="images/image08.png" width="450">

After the app under test is set up, you can use the Xcode **Test Navigator** to add new test classes and run them selectively, or together.

## Set Up and run your first test

Because EarlGrey is based on XCTest, creating your first test in Xcode is as easy as creating a new
**Unit Test Case Class**. Be careful not to confuse **Unit Test Case Class** with **UI Test Case
Class**. **UI Test Case Class** uses the new UI Testing feature added to XCTest and isn’t yet
compatible with EarlGrey.

1. **Ctrl+Click** the folder for your app's source files, and then select **New file...**. The
following dialog will appear:

<img src="images/image09.png" width="422">

2. Select **Unit Test Case Class**, and then click **Next**. On the following screen, type the name
of your test case. For this example, let’s leave it as *MyFirstEarlGreyTest*:

<img src="images/image10.png" width="422">

3. On the next screen, make sure that the test is associated with the Unit Test target. In this
case, our target is *SimpleAppTests*:

<img src="images/image11.png" width="422">

4. Xcode will create a new test case for us but we won’t need much of it. Let’s change the code to
leave just a single test method and include the EarlGrey framework, like this:

```objc
@import EarlGrey;
#import <XCTest/XCTest.h>

@interface MyFirstEarlGreyTest : XCTestCase
@end

@implementation MyFirstEarlGreyTest

- (void)testExample {
// Your test actions and assertions will go here.
}

@end
```

5. Now let’s add a simple EarlGrey assertion that checks for the presence of a key window and
asserts that it is displayed. Here’s what the resulting test would look like:

```objc
- (void)testPresenceOfKeyWindow {
[[EarlGrey selectElementWithMatcher:grey_keyWindow()]
assertWithMatcher:grey_sufficientlyVisible()];
}

```

6. And that’s it! As with any other unit test, this test will show up in the test navigator, so you
can run it by just clicking on the **run** icon or by Ctrl+clicking the test name and then selecting
**Test "testPresenceOfKeyWindow"**. Because this is a regular unit test, you can place breakpoints in
your test and in your application code and use the built-in tools seamlessly.

### Swift

To use EarlGrey with Swift, include the `EarlGrey.swift` file in your Swift Test Project. The file
contains functions that implement C preprocessor macros that aren't available in Swift. There are
two ways to do so:

#### Using the [earlgrey gem](https://rubygems.org/gems/earlgrey): 
* We recommend uisng the EarlGrey gem to use EarlGrey with Swift.

The EarlGrey gem also copies the `EarlGrey.swift` file to your project directory if you're
passing the `{swift: true}` parameter to the args for the `configure_for_earlgrey()` method as
in the below snippet. This is compiled into the tests along with EarlGrey.

```ruby
configure_for_earlgrey(installer, PROJECT_NAME, test_target, test_target + '.xcscheme', {swift: true})
```

EarlGrey currently supports Swift 3.0 and 2.3. While 3.0 is the default, you can also use 2.3
by adding `{swift: true, swift_version: 2.3}`.

* Manual installation:

In this case you need to download the correct
[`EarlGrey.swift`](https://github.com/google/EarlGrey/tree/master/gem/lib/earlgrey/files/)
file for your Swift version and include it in to your test bundle.

Here is an example of a very basic EarlGrey test written in Swift:

```swift
import EarlGrey // This adds EarlGrey.swift and the EarlGrey framework.

// Select the button with Accessibility ID "clickMe" and assert it's visible.
EarlGrey.select(elementWithMatcher: grey_accessibilityID("ClickMe"))
.assert(grey_sufficientlyVisible())
```

> For compatibility with Swift, we use `grey_allOfMatchers()` and `grey_anyOfMatchers()` instead
of `grey_allOf()` and `grey_anyOf()` respectively.
