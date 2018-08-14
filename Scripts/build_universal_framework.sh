#!/bin/bash

rm -rf tmp/ universal/

set -euo pipefail

if ! [ -x "$(command -v xcpretty)" ]; then
  gem install xcpretty
fi

SCHEME="EarlGrey"
PROJECT="../$SCHEME.xcodeproj"
TMP="$PWD/tmp"

# Build for device
xcodebuild build \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -sdk iphoneos \
  SYMROOT=$TMP \
  | xcpretty

# Build for simulator
xcodebuild build \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -sdk iphonesimulator \
  SYMROOT=$TMP \
  | xcpretty

DEVICE_FRAMEWORK="$TMP/Release-iphoneos/EarlGrey.framework/EarlGrey"
SIM_FRAMEWORK="$TMP/Release-iphonesimulator/EarlGrey.framework/EarlGrey"

UNI_DIR="$TMP/../universal"
mkdir "$UNI_DIR"
cp -RL "$TMP/Release-iphoneos/EarlGrey.framework" "$UNI_DIR"
UNI_FRAMEWORK="$UNI_DIR/EarlGrey.framework/EarlGrey"

# Create universal framework with correct dSYM
set -x
lipo -create \
  "$DEVICE_FRAMEWORK" \
  "$SIM_FRAMEWORK" \
  -output "$UNI_FRAMEWORK"

dsymutil "$UNI_FRAMEWORK" \
  --out "$UNI_DIR/EarlGrey.framework.dSYM"
