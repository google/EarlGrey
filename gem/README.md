# EarlGrey

[![Gem Version](https://badge.fury.io/rb/earlgrey.svg)](https://rubygems.org/gems/earlgrey)

Automatically installs EarlGrey. Supports carthage, cocoapods, and Swift.

```
$ earlgrey help install
Usage:
  earlgrey install -t, --target=TARGET

Options:
  -p, [--project=PROJECT]            # Project
  -t, --target=TARGET                # EarlGrey
  -s, [--scheme=SCHEME]              # EarlGrey.xcscheme
      [--swift], [--no-swift]
                                     # Default: true
      [--carthage], [--no-carthage]
                                     # Default: true

Installs EarlGrey into an Xcode unit test target
```

## Usage

Create new Target `iOS Unit Testing Bundle` then add a new scheme
`Product → Scheme → Manage Schemes` and mark it as shared.
See [EarlGrey docs for screenshots](https://github.com/google/EarlGrey/blob/master/docs/install-and-run.md)

Now run the install command with the test target name:

- `earlgrey install -t AutoEarlGrey`

See [the example project](https://github.com/bootstraponline/swift_xcuitest_example/tree/earlgrey/Example)
which defines `AutoEarlGrey`.

## Notes

The install command does the following by default:

- Adds BridgingHeader.h and EarlGrey.swift to test target
- FRAMEWORK_SEARCH_PATHS = "$(SRCROOT)/Carthage/Build/iOS";
- HEADER_SEARCH_PATHS = "$(SRCROOT)/Carthage/Build/iOS/**";
- SWIFT_OBJC_BRIDGING_HEADER = "$(TARGET_NAME)/BridgingHeader.h";
- Add EarlGrey.swift to compile sources (PBXSourcesBuildPhase)
- Link binary with libraries. EarlGrey.framework
- Use carthage copy-files to ensure frameworks are signed, dSYMs/BCSymbolMaps copied.
  Carthage doesn't sign when building.
- Updates scheme DYLD_INSERT_LIBRARIES so it can find EarlGrey.framework