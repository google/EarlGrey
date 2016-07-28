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

set -euxo pipefail

xcodebuild -version
xcodebuild -showsdks

# Runs xcodebuild retrying up to 3 times on failure to start testing (exit code 65).
# The following arguments specified in the order below:
#  $1 : .xcodeproj file
#  $2 : scheme to run
#
# The output is prettified using xcpretty and redirected to xcodebuild.log for failure analysis.
execute_xcodebuild() {
  if [ -z ${1+x} ]; then
    echo "first argument must be a valid .xcodeproj file"
    exit 1
  elif [ -z ${2+x} ]; then
    echo "second argument must be a valid scheme"
    exit 1
  fi

  for retry_attempts in {1..3}; do
    # To retry on failure, disable exiting if command below fails.
    set +e
    env NSUnbufferedIO=YES xcodebuild -project ${1} -scheme ${2} -sdk "$SDK" -destination "$DESTINATION" -configuration Debug ONLY_ACTIVE_ARCH=NO test | tee xcodebuild.log | xcpretty -s;
    retval=$?
    # Re-enable exiting for command failures.
    set -e
    # Even failed tests exit with code 65. Add a check to query xcodebuild.log that tests haven't
    # started.
    if [ ${retval} -ne 65 ] || [ grep -q "Test Suite" xcodebuild.log ]; then
      break
    fi
  done
}

if [ "${TYPE}" == "RUBY" ]; then
  rvm use 2.2.2;
  cd gem;
  bundle install --retry=3;
  rake;
elif [ "${TYPE}" == "UNIT" ]; then
  execute_xcodebuild Tests/UnitTests/UnitTests.xcodeproj EarlGreyUnitTests
elif [ "${TYPE}" == "FUNCTIONAL_SWIFT" ]; then
  execute_xcodebuild Tests/FunctionalTests/FunctionalTests.xcodeproj EarlGreyFunctionalSwiftTests
elif [ "${TYPE}" == "FUNCTIONAL" ]; then
  execute_xcodebuild Tests/FunctionalTests/FunctionalTests.xcodeproj EarlGreyFunctionalTests
elif [ "${TYPE}" == "CONTRIB" ]; then
  execute_xcodebuild Demo/EarlGreyContribs/EarlGreyContribs.xcodeproj EarlGreyContribsTests
elif [ "${TYPE}" == "CONTRIB_SWIFT" ]; then
  execute_xcodebuild Demo/EarlGreyContribs/EarlGreyContribs.xcodeproj EarlGreyContribsSwiftTests
else
  echo "Unrecognized Type: ${TYPE}"
  exit 1
fi
