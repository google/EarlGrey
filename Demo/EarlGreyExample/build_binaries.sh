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
DD_PATH="$DIR/xctestrun"
DD_PRODUCTS="$DD_PATH/Build/Products"
mkdir -p "$DD_PATH"
rm -rf "$DD_PATH"

echo "open $DIR/Demo/EarlGreyExample/EarlGreyExample.xcworkspace"
echo "Manually update with a valid Apple id."
echo "[Press Enter to continue]"
read

build() {
  xcodebuild build-for-testing \
    -workspace EarlGreyExample.xcworkspace \
    -scheme $1 \
    -destination "generic/platform=iOS" \
    -derivedDataPath "$DD_PATH"
}

move() {
  DEST_PATH="$DD_PRODUCTS/$2"
  mkdir -p $DEST_PATH
  cp "$DD_PRODUCTS/Debug-iphoneos/EarlGreyExampleSwift.app/PlugIns/$1.xctest/$1" \
  $DEST_PATH
}

# $1 Test Target Name
# $2 Destination Path
execute() {
  build $1
  move $1 $2
}

execute "EarlGreyExampleSwiftTests" "swift"
execute "EarlGreyExampleMixedTests" "mixed"
execute "EarlGreyExampleTests" "objc"

ZIP_PATH="$DD_PRODUCTS/EarlGreyExampleTests.zip"
cd $DD_PRODUCTS
zip -r $ZIP_PATH *
