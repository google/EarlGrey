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

if [ "${TYPE}" == "RUBY" ]; then
  rvm use 2.2.2;
  cd gem;
  bundle install --retry=3;
  rake;
elif [ "${TYPE}" == "UNIT" ]; then
  env NSUnbufferedIO=YES xcodebuild -project Tests/UnitTests/UnitTests.xcodeproj -scheme EarlGreyUnitTests -sdk "$SDK" -destination "$DESTINATION" -configuration Debug ONLY_ACTIVE_ARCH=NO test | tee xcodebuild.log | xcpretty -s;
elif [ "${TYPE}" == "FUNCTIONAL_SWIFT" ]; then
  env NSUnbufferedIO=YES xcodebuild -project Tests/FunctionalTests/FunctionalTests.xcodeproj -scheme EarlGreyFunctionalSwiftTests -sdk "$SDK" -destination "$DESTINATION" -configuration Debug ONLY_ACTIVE_ARCH=NO test | tee xcodebuild.log | xcpretty -s;
elif [ "${TYPE}" == "FUNCTIONAL" ]; then
  env NSUnbufferedIO=YES xcodebuild -project Tests/FunctionalTests/FunctionalTests.xcodeproj -scheme EarlGreyFunctionalTests -sdk "$SDK" -destination "$DESTINATION" -configuration Debug ONLY_ACTIVE_ARCH=NO test | tee xcodebuild.log | xcpretty -s;
elif [ "${TYPE}" == "CONTRIB" ]; then
  env NSUnbufferedIO=YES xcodebuild -project Demo/EarlGreyContribs/EarlGreyContribs.xcodeproj -scheme EarlGreyContribsTests -sdk "$SDK" -destination "$DESTINATION" -configuration Debug ONLY_ACTIVE_ARCH=NO test | tee xcodebuild.log | xcpretty -s;
  env NSUnbufferedIO=YES xcodebuild -project Demo/EarlGreyContribs/EarlGreyContribs.xcodeproj -scheme EarlGreyContribsSwiftTests -sdk "$SDK" -destination "$DESTINATION" -configuration Debug ONLY_ACTIVE_ARCH=NO test | tee xcodebuild.log | xcpretty -s;
else
  echo "Unrecognized Type: ${TYPE}"
  exit 1
fi
