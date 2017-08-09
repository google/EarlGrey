: "${PROJECT_FILE_PATH:=$(dirname ${BASH_SOURCE[0]})/../EarlGrey.xcodeproj}"
: "${BUILD_DIR:=build}"
: "${CONFIGURATION_NAME:=Release}"
: "${OUTPUT_DIR:=build}"

mkdir -p "${OUTPUT_DIR}"

xcrun xcodebuild build \
    -project "${PROJECT_FILE_PATH}" -target "EarlGrey" -configuration $CONFIGURATION_NAME \
    -sdk iphoneos CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO ENTITLEMENTS_REQUIRED=NO \
    ONLY_ACTIVE_ARCH=NO CONFIGURATION_BUILD_DIR=$OUTPUT_DIR/iphoneos

xcrun xcodebuild build \
    -project "${PROJECT_FILE_PATH}" -target "EarlGrey" -configuration $CONFIGURATION_NAME \
    -sdk iphonesimulator CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO ENTITLEMENTS_REQUIRED=NO \
    ONLY_ACTIVE_ARCH=NO CONFIGURATION_BUILD_DIR=$OUTPUT_DIR/iphonesimulator

cp -r ${OUTPUT_DIR}/iphoneos/EarlGrey.framework $OUTPUT_DIR

xcrun lipo -create ${OUTPUT_DIR}/iphoneos/EarlGrey.framework/EarlGrey \
    ${OUTPUT_DIR}/iphonesimulator/EarlGrey.framework/EarlGrey \
    -output $OUTPUT_DIR/EarlGrey.framework/EarlGrey

