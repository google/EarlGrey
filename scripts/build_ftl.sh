#!/bin/bash
set -euxo pipefail
DD="dd_tmp"
ZIP="ftl_earlgrey.zip"
PROJ="./Tests/FunctionalTests/FunctionalTests.xcodeproj"
rm -rf "$DD"

xcodebuild build-for-testing \
  -project "$PROJ" \
  -scheme "FunctionalSwiftTests" \
  -derivedDataPath "$DD" \
  -sdk iphoneos

pushd "$DD/Build/Products"
zip -r "$ZIP" *-iphoneos *.xctestrun
popd

mv "$DD/Build/Products/$ZIP" .
