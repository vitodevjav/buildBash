#############################################################
# build.bash
#############################################################
#!/bin/bash
# Exit this script immediately if any of the commands fails
set -e
PROJECT_NAME=TestBuild
BUNDLE_DIR=${PROJECT_NAME}.app
TEMP_DIR=_BuildTemp

if [ "$1" = "--device" ]; then
BUILDING_FOR_DEVICE=true;
fi

# Print the current target architecture
if [ "${BUILDING_FOR_DEVICE}" = true ]; then
echo 👍 Building ${PROJECT_NAME} for device
else
echo 👍 Building ${PROJECT_NAME} for simulator
fi

#############################################################
echo → Step 1: Prepare Working Folders
#############################################################
rm -rf ${BUNDLE_DIR}
rm -rf ${TEMP_DIR}
mkdir ${BUNDLE_DIR}
echo ✅ Create ${BUNDLE_DIR} folder
mkdir ${TEMP_DIR}
echo ✅ Create ${TEMP_DIR} folder

#############################################################
echo → Step 2: Compile Swift Files
#############################################################
SOURCE_DIR=TestBuild
SWIFT_SOURCE_FILES=${SOURCE_DIR}/*.swift
TARGET=""
SDK_PATH=""
if [ "${BUILDING_FOR_DEVICE}" = true ]; then
TARGET=arm64-apple-ios12.0
SDK_PATH=$(xcrun --show-sdk-path --sdk iphoneos)
FRAMEWORKS_DIR=Frameworks
OTHER_FLAGS="-Xlinker -rpath -Xlinker @executable_path/${FRAMEWORKS_DIR}"
else
TARGET=x86_64-apple-ios12.0-simulator
SDK_PATH=$(xcrun --show-sdk-path --sdk iphonesimulator)
fi

swiftc ${SWIFT_SOURCE_FILES} \
-sdk ${SDK_PATH} \
-target ${TARGET} \
-emit-executable \
${OTHER_FLAGS} \
-o ${BUNDLE_DIR}/${PROJECT_NAME}
echo ✅ Compile Swift source files ${SWIFT_SOURCE_FILES}

#############################################################
echo → Step 3: Compile Storyboards
#############################################################
STORYBOARDS=${SOURCE_DIR}/Base.lproj/*.storyboard
STORYBOARD_OUT_DIR=${BUNDLE_DIR}/Base.lproj
mkdir -p ${STORYBOARD_OUT_DIR}
echo ✅ Create ${STORYBOARD_OUT_DIR} folder
for storyboard_path in ${STORYBOARDS}; do
ibtool $storyboard_path \
--compilation-directory ${STORYBOARD_OUT_DIR}
echo ✅ Compile $storyboard_path
done

#############################################################
echo → Step 4: Process and Copy Info.plist
#############################################################
ORIGINAL_INFO_PLIST=${SOURCE_DIR}/Info.plist
TEMP_INFO_PLIST=${TEMP_DIR}/Info.plist
PROCESSED_INFO_PLIST=${BUNDLE_DIR}/Info.plist
APP_BUNDLE_IDENTIFIER=qulix.${PROJECT_NAME}
cp ${ORIGINAL_INFO_PLIST} ${TEMP_INFO_PLIST}
echo ✅ Copy ${ORIGINAL_INFO_PLIST} to ${TEMP_INFO_PLIST}

PLIST_BUDDY=/usr/libexec/PlistBuddy
${PLIST_BUDDY} -c "Set :CFBundleExecutable ${PROJECT_NAME}" ${TEMP_INFO_PLIST}
echo ✅ Set CFBundleExecutable to ${PROJECT_NAME}
${PLIST_BUDDY} -c "Set :CFBundleIdentifier ${APP_BUNDLE_IDENTIFIER}" ${TEMP_INFO_PLIST}
echo ✅ Set CFBundleIdentifier to ${APP_BUNDLE_IDENTIFIER}
${PLIST_BUDDY} -c "Set :CFBundleName ${PROJECT_NAME}" ${TEMP_INFO_PLIST}
echo ✅ Set CFBundleName to ${PROJECT_NAME}
cp ${TEMP_INFO_PLIST} ${PROCESSED_INFO_PLIST}
echo ✅ Copy ${TEMP_INFO_PLIST} to ${PROCESSED_INFO_PLIST}

if [ "${BUILDING_FOR_DEVICE}" != true ]; then
echo 🎉 Building ${PROJECT_NAME} for simulator successfully finished! 🎉
exit 0
fi

#############################################################
echo → Step 5: Copy Swift Runtime Libraries
#############################################################

SWIFT_LIBS_SRC_DIR=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/iphoneos
SWIFT_LIBS_DEST_DIR=${BUNDLE_DIR}/${FRAMEWORKS_DIR}
SWIFT_RUNTIME_LIBS=( libswiftCore.dylib libswiftCoreFoundation.dylib libswiftCoreGraphics.dylib libswiftCoreImage.dylib libswiftDarwin.dylib libswiftDispatch.dylib libswiftFoundation.dylib libswiftMetal.dylib libswiftObjectiveC.dylib libswiftQuartzCore.dylib libswiftSwiftOnoneSupport.dylib libswiftUIKit.dylib libswiftos.dylib )
mkdir -p ${BUNDLE_DIR}/${FRAMEWORKS_DIR}
echo ✅ Create ${SWIFT_LIBS_DEST_DIR} folder
for library_name in "${SWIFT_RUNTIME_LIBS[@]}"; do
cp ${SWIFT_LIBS_SRC_DIR}/$library_name ${SWIFT_LIBS_DEST_DIR}/
echo ✅ Copy $library_name to ${SWIFT_LIBS_DEST_DIR}
done
