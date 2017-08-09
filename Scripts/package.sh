SOURCE_DIR=$(dirname ${BASH_SOURCE[0]})
CURRENT_DIR=$PWD
: "${PROJECT_FILE_PATH:=${SOURCE_DIR}/../EarlGrey.xcodeproj}"
: "${OUTPUT_DIR:=${SOURCE_DIR}/build}"

readonly PACKAGE_NAME="EarlGrey"
readonly OUTPUT_TMP_DIR=$(mktemp -d)
readonly OUTPUT_PACKAGE_DIR=$OUTPUT_TMP_DIR/$PACKAGE_NAME
readonly PACKAGE_FILES="README.md CHANGELOG.md LICENSE"

# Make a universal dynamic framework build.
export OUTPUT_DIR=$OUTPUT_TMP_DIR/build
(cd $SOURCE_DIR/.. && xcrun xcodebuild build -project "${PROJECT_FILE_PATH}" -target "Release")

# Copy files to the temp dir and zip.
mkdir -p $OUTPUT_PACKAGE_DIR
(cd $SOURCE_DIR/.. && cp $PACKAGE_FILES $OUTPUT_PACKAGE_DIR)

# Symlink the framework so we don't need to copy.
ln -s "$OUTPUT_DIR/EarlGrey.framework" $OUTPUT_PACKAGE_DIR/EarlGrey.framework

(cd $OUTPUT_DIR/.. && \
    zip -r -X "$CURRENT_DIR/${PACKAGE_NAME}.zip" "${PACKAGE_NAME}")

rm -rf $OUTPUT_TMP_DIR
