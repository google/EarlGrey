#!/bin/bash
#
#  Copyright 2016 Google Inc.
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

# Download Fishhook in the EarlGrey directory in the fishhook/ directory.
obtain_fishhook() {
  # Set the current branch, commit or tag of Fishhook to use.
  readonly FISHHOOK_VERSION="0.2"
  # URL for Fishhook to be downloaded from.
  readonly FISHHOOK_URL="https://github.com/facebook/fishhook/archive/${FISHHOOK_VERSION}.zip"
  echo "Obtaining the fishhook dependency."

  # Git Clone Fishhook. Make sure the destination folder is called “fishhook”.
  if [ -d "${EARLGREY_DIR}/fishhook" ]; then
    echo "The fishhook directory is already present at ${EARLGREY_DIR}/fishhook."`
      `" If you experience issues with running EarlGrey then please remove"`
      `" this directory and run this script again."
  else
    # Download the required fishhook version.
    run_command "There was an error downloading fishhook."`
      `" Please check if you are having problems with your connection."`
      ` curl -LOk --fail ${FISHHOOK_URL}

    if [ ! -f "${FISHHOOK_VERSION}.zip" ]; then
      echo "The fishhook zip file downloaded seems to have the incorrect"`
        `" version. Please download directly from ${FISHHOOK_URL} and check"`
        `" if there are any issues." >&2
      exit 1
    fi

    # Unzip the downloaded .zip file and rename the directory to fishhook/
    run_command "There was an issue while unzipping the Fishhook zip file. "`
      `"Please ensure if it unzips manually since it might be corrupt."`
      ` unzip ${FISHHOOK_VERSION}.zip > /dev/null

    if [ ! -d "fishhook-${FISHHOOK_VERSION}" ]; then
      echo "The correct fishhook version was not unzipped. Please check if"`
        `" fishhook-${FISHHOOK_VERSION} exists in the EarlGrey Directory."
      exit 1
    fi

    mv fishhook-${FISHHOOK_VERSION} "${EARLGREY_DIR}/fishhook/"
    if [[ $? != 0 ]]; then
      echo "There was an issue moving Fishhook as per"`
        `" the EarlGrey specification." >&2
      exit 1
    fi

    rm ${FISHHOOK_VERSION}.zip

    echo "Fishhook downloaded at ${EARLGREY_DIR}/fishhook"
  fi
}

# Download OCMock for the EarlGrey Unit Tests in the EarlGrey
# Unit Tests directory as ocmock/.
obtain_ocmock() {
  # Path for OCMock to be installed at.
  readonly OCMOCK_PATH="${EARLGREY_DIR}/Tests/UnitTests/ocmock"
  # Set the current branch, commit or tag of OCMock to use.
  readonly OCMOCK_VERSION="master"
  # URL for OCMock to be downloaded from.
  readonly OCMOCK_URL="https://github.com/erikdoe/ocmock/archive/${OCMOCK_VERSION}.zip"
  echo "Obtaining the OCMock dependency."

  # Git Clone OCMock. Make sure the destination folder is called “ocmock”.
if [ -d "${OCMOCK_PATH}" ]; then
    echo "The ocmock directory is already present at ${PWD}/${OCMOCK_PATH}."`
      `" If you experience issues with running EarlGrey then please remove"`
      `" this directory and run this script again."
  else
    # Download the required OCMock version.
    run_command "There was an error downloading OCMock."`
      `" Please check if you are having problems with your connection."`
      ` curl -LOk --fail ${OCMOCK_URL}

    if [ ! -f "${OCMOCK_VERSION}.zip" ]; then
      echo "The OCMock zip file downloaded seems to have the incorrect"`
        `" version. Please download directly from ${OCMOCK_URL} and check"`
        `" if there are any issues." >&2
      exit 1
    fi

    # Unzip the downloaded .zip file and rename the directory to ocmock/
    run_command "There was an issue while unzipping the OCMock zip file. "`
        `"Please ensure if it unzips manually since it might be corrupt."`
        ` unzip ${OCMOCK_VERSION}.zip > /dev/null

    if [ ! -d "ocmock-${OCMOCK_VERSION}" ]; then
      echo "The correct OCMock version was not unzipped. Please check if"`
        `" ocmock-${OCMOCK_VERSION} exists in the EarlGrey Directory."
      exit 1
    fi

    mv ocmock-${OCMOCK_VERSION} "${OCMOCK_PATH}"
    rm ${ocmock-${OCMOCK_VERSION}}.zip

    echo "OCMock downloaded at ${OCMOCK_PATH}"
  fi
}

# A method to run a command and in case of any execution error
# echo a user provided error.
run_command() {
  ERROR="$1"
  shift
  "$@"
  if [[ $? != 0 ]]; then
     echo ${ERROR} >&2
     exit 1
  fi
}

# Turn on Debug Settings.
set -u

# Path of the script.
readonly EARLGREY_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Path of EarlGrey from the script.
readonly EARLGREY_DIR="${EARLGREY_SCRIPT_DIR}/.."

echo "Changing into EarlGrey Directory"
# Change Directory to the directory that contains EarlGrey.
pushd "${EARLGREY_SCRIPT_DIR}" >> /dev/null

obtain_fishhook
obtain_ocmock

echo "The EarlGrey Project and the Test Projects are ready to be run."
# Return back to the calling folder since the script ran successfully.
popd >> /dev/null
