# EarlGrey 2 + Carthage

# Installing

Install carthage via [brew install carthage](https://github.com/Carthage/Carthage#installing-carthage) or one of the other supported [installation methods.](https://github.com/Carthage/Carthage#installing-carthage)

# Cartfile

Create a file called [Cartfile.private](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md) and add the EarlGrey dependency.

`github "google/EarlGrey" "earlgrey2"`

`Cartfile.private` is used to include the dependency without forcing parent projects to take on that dependency. This is a good fit for test frameworks
that are only used during development.

Run `carthage update` to update and build the dependencies. The build products will be stored in `./Carthage/Build/iOS/` 

`Cartfile.resolved` contains the version of EarlGrey used in the build.

# Known Issues

Currently only `AppFramework.framework` is built when building via Carthage.

Missing:

 - libChannelLib.a
 - libCommonLib.a
 - libTestLib.a
 - libUILib.a
 - libeDistantObject.a

# Debugging EarlGrey build failures

- `carthage build --no-skip-current` Run from repo root. Otherwise you'll see the error `has no shared framework schemes`
- `xcodebuild -scheme SCHEME -workspace WORKSPACE build or xcodebuild -scheme SCHEME -project PROJECT build`

