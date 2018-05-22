#!/usr/bin/env bash

# Requires:
#  - Xcode 9.3
#  - Ruby 2.5
#  - Cocoapods 1.5.2
#  - EarlGrey gem 1.13.0
#
# See getting started guide:
#  - https://github.com/google/EarlGrey/tree/master/Demo/EarlGreyExample

DIR=$(pwd)
DD_PATH="$DIR/xctestrun/"
mkdir -p "$DD_PATH"
rm -rf "$DD_PATH"

echo "open $DIR/$REPO_NAME/Demo/EarlGreyExample/EarlGreyExample.xcworkspace"
echo "Manually update with a valid Apple id."
echo "[Press Enter to continue]"
read

xcodebuild build-for-testing \
  -workspace EarlGreyExample.xcworkspace \
  -scheme "EarlGreyExampleSwiftTests" \
  -destination "generic/platform=iOS" \
  -derivedDataPath "$DD_PATH"

FIXTURES_PATH="fixtures/swift"
mkdir -p "$FIXTURES_PATH"
cp "$DIR/xctestrun/Build/Products/Debug-iphoneos/EarlGreyExampleSwift.app/PlugIns/EarlGreyExampleSwiftTests.xctest/EarlGreyExampleSwiftTests" \
 "$FIXTURES_PATH"


xcodebuild build-for-testing \
  -workspace EarlGreyExample.xcworkspace \
  -scheme "EarlGreyExampleMixedTests" \
  -destination "generic/platform=iOS" \
  -derivedDataPath "$DD_PATH"

FIXTURES_PATH="fixtures/mixed"
mkdir -p "$FIXTURES_PATH"
cp "$DIR/xctestrun/Build/Products/Debug-iphoneos/EarlGreyExampleSwift.app/PlugIns/EarlGreyExampleMixedTests.xctest/EarlGreyExampleMixedTests" \
 "$FIXTURES_PATH"

xcodebuild build-for-testing \
  -workspace EarlGreyExample.xcworkspace \
  -scheme "EarlGreyExampleTests" \
  -destination "generic/platform=iOS" \
  -derivedDataPath "$DD_PATH"

FIXTURES_PATH="fixtures/objc"
mkdir -p "$FIXTURES_PATH"
cp "$DIR/xctestrun/Build/Products/Debug-iphoneos/EarlGreyExampleSwift.app/PlugIns/EarlGreyExampleTests.xctest/EarlGreyExampleTests" \
 "$FIXTURES_PATH"