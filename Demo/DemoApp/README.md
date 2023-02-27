# EarlGrey 2 + Carthage

# Installing

Install carthage via [brew install carthage](https://github.com/Carthage/Carthage#installing-carthage) or one of the other supported [installation methods.](https://github.com/Carthage/Carthage#installing-carthage)

# Usage

- `carthage update --no-build` Download EarlGrey source via Carthage
- Follow the setup guide https://github.com/google/EarlGrey/blob/earlgrey2/docs/setup.md
  - Drag `Carthage/Checkouts/EarlGrey/EarlGrey.xcodeproj` into the `CarthageExample` project in Xcode.
  - In the `Build Phases` of your test target, add `libTestLib.a` to `Link Binary With Libraries`
  - In `Build Settings` of your test target, add `-ObjC`to `Other Linker Flags`
  - Update `User Header Search Paths` to include:
    - `$(SRCROOT)/Carthage/Checkouts/EarlGrey` with `recursive` selected
  - In the `Build Phases` of your test target, add `New Copy Files Phase`
    - Destination: `Absolute Path`
    - Path: `$(TARGET_BUILD_DIR)/../../<YOUR_APPLICATION_TARGET_NAME.app>/Frameworks`
    - Uncheck `Copy only when installing`
    - Click on the (+) in the bottom and add `AppFramework.framework`. Select `Code Sign On Copy`
  - For Swift support, add [EarlGrey.swift](https://github.com/google/EarlGrey/blob/earlgrey2/TestLib/Swift/EarlGrey.swift) to the project
    - Add `bridge.h` to your test target. Update `Build Settings` `Objective-C Bridging Header` to `$(TARGET_NAME)/bridge.h`
```objc
// bridge.h
#import "AppFramework/Action/GREYAction.h"
#import "AppFramework/Action/GREYActionBlock.h"
#import "AppFramework/Action/GREYActions.h"
#import "CommonLib/Matcher/GREYElementMatcherBlock.h"
#import "CommonLib/DistantObject/GREYHostApplicationDistantObject.h"
#import "CommonLib/Matcher/GREYMatcher.h"
#import "TestLib/AlertHandling/XCTestCase+GREYSystemAlertHandler.h"
#import "TestLib/EarlGrey.h"
```
  -  Add `@loader_path/Frameworks` to your `Runpath Search Paths` for both the App and Test Component.

# First test

Write your first test in Swift.

```swift
class MyFirstEarlGreyTest: XCTestCase {

  func testExample() {
    let application: XCUIApplication = XCUIApplication()
    application.launch()
    EarlGrey.selectElement(with: grey_keyWindow())
      .perform(grey_tap())
  }
}
```

# Cartfile

Create a file called [Cartfile.private](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md)
and add the EarlGrey dependency.

`github "google/EarlGrey" "earlgrey2"`

`Cartfile.private` is used to include the dependency without forcing parent
projects to take on that dependency. This is a good fit for test frameworks
that are only used during development.

Run `carthage update` to update and build the dependencies. The build
products will be stored in `./Carthage/Build/iOS/`

`Cartfile.resolved` contains the version of EarlGrey used in the build.

# Known Issues

Currently only `AppFramework.framework` is built when building via Carthage.
As a work around, EarlGrey is included from source. In the future when
EarlGrey 2.0 is shipped as a framework, Carthage will support building EarlGrey.

Missing:

 - libChannelLib.a
 - libCommonLib.a
 - libTestLib.a
 - libUILib.a
 - libeDistantObject.a

# Debugging EarlGrey build failures

- `carthage build --no-skip-current` Run from repo root. Otherwise you'll see the error `has no shared framework schemes`
- `xcodebuild -scheme SCHEME -workspace WORKSPACE build or xcodebuild -scheme SCHEME -project PROJECT build`
