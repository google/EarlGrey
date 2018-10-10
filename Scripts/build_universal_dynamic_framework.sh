#!/bin/bash
#
#  Copyright 2018 Google Inc.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

# Build a Universal Dynamic Framework (i.e combines both simulator and device builds).
# This script is supposed to be run as a build phase in Xcode. Do not run it
# manually.
#
# This script comes from https://github.com/jverkoey/iOS-Framework

set -e
set +u

# Avoid recursively calling this script.
if [[ $SF_MASTER_SCRIPT_RUNNING ]]
then
  exit 0
fi
set -u
export SF_MASTER_SCRIPT_RUNNING=1

SF_TARGET_NAME=${PRODUCT_NAME}
SF_WRAPPER_NAME="${SF_TARGET_NAME}.framework"

if [ -d ${BUILT_PRODUCTS_DIR}/${SF_WRAPPER_NAME} ]
then
  FILE_OUTPUT=$(file "${BUILT_PRODUCTS_DIR}/${SF_WRAPPER_NAME}/${SF_TARGET_NAME}")
  if [[ ${FILE_OUTPUT} == *"4 architectures"* ]]
  then
    echo "Fat binary already up-to-date. Skipping build."
    exit 0
  fi
fi

# The following conditionals come from
# https://github.com/kstenerud/iOS-Universal-Framework

if [[ "$SDK_NAME" =~ ([A-Za-z]+) ]]
then
  SF_SDK_PLATFORM=${BASH_REMATCH[1]}
else
  echo "Could not find platform name from SDK_NAME: $SDK_NAME"
  exit 1
fi

if [[ "$SDK_NAME" =~ ([0-9]+.*$) ]]
then
  SF_SDK_VERSION=${BASH_REMATCH[1]}
else
  echo "Could not find sdk version from SDK_NAME: $SDK_NAME"
  exit 1
fi

if [[ "$SF_SDK_PLATFORM" = "iphoneos" ]]
then
  SF_OTHER_PLATFORM=iphonesimulator
else
  SF_OTHER_PLATFORM=iphoneos
fi

if [[ "$BUILT_PRODUCTS_DIR" =~ (.*)$SF_SDK_PLATFORM$ ]]
then
  SF_OTHER_BUILT_PRODUCTS_DIR="${BASH_REMATCH[1]}${SF_OTHER_PLATFORM}"
else
  echo "Could not find platform name from build products directory: "\
    "$BUILT_PRODUCTS_DIR"
  SF_OTHER_BUILT_PRODUCTS_DIR="${BUILT_PRODUCTS_DIR}-${SF_OTHER_PLATFORM}"
fi

if [ -d ${SF_OTHER_BUILT_PRODUCTS_DIR}/${SF_WRAPPER_NAME} ]
then
  echo "Removing ${SF_OTHER_BUILT_PRODUCTS_DIR}/${SF_WRAPPER_NAME}"
  rm -fr ${SF_OTHER_BUILT_PRODUCTS_DIR}/${SF_WRAPPER_NAME}
fi

# Build the other platform that hasn't been built.
xcrun xcodebuild build -project "${PROJECT_FILE_PATH}" -target \
  "${TARGET_NAME}" -configuration "${CONFIGURATION}" -sdk \
  ${SF_OTHER_PLATFORM}${SF_SDK_VERSION} BUILD_DIR="${BUILD_DIR}" \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO ENTITLEMENTS_REQUIRED=NO \
  ONLY_ACTIVE_ARCH=NO OBJROOT="${OBJROOT}" \ BUILD_ROOT="${BUILD_ROOT}" SYMROOT="${SYMROOT}" \
  $ACTION

# Smash the two framework binaries into one fat binary.
xcrun lipo -create "${BUILT_PRODUCTS_DIR}/${SF_WRAPPER_NAME}/${SF_TARGET_NAME}" \
  "${SF_OTHER_BUILT_PRODUCTS_DIR}/${SF_WRAPPER_NAME}/${SF_TARGET_NAME}" -output \
  "${BUILT_PRODUCTS_DIR}/${SF_WRAPPER_NAME}/${SF_TARGET_NAME}"

# Copy the framework to the other architecture folder to have a complete
# framework in both.
cp -a "${BUILT_PRODUCTS_DIR}/${SF_WRAPPER_NAME}" \
  "${SF_OTHER_BUILT_PRODUCTS_DIR}/${SF_WRAPPER_NAME}"

dsymutil "${BUILT_PRODUCTS_DIR}/${SF_WRAPPER_NAME}/${SF_TARGET_NAME}" \
	--out "${BUILT_PRODUCTS_DIR}/${SF_WRAPPER_NAME}.dSYM"

echo "Built framework is available at:"
echo "${BUILT_PRODUCTS_DIR}/${SF_WRAPPER_NAME}"
