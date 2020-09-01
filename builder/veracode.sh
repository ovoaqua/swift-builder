#!/bin/bash

#######################################################
# veracode packager script for tealium-swift
#######################################################

# variable declarations
XCODE_PROJECT="tealium-swift"
SCHEME="SwiftTestbed"
BUILD_PATH="build"
IOS_ARCHIVE="tealium-swift.xcarchive"
IOS_DESTINATION="generic/platform=iOS"
BACKUP_CONFIGURATION="Distribution"
BACKUP_ARCHIVENAME="${XCODE_PROJECT}Archive"
OLD_ARCHIVENAME="${BACKUP_ARCHIVENAME}"
NEW_ARCHIVENAME="${SCHEME}_${NEW_CONFIGURATION}"

# scheme path
SCHEME_DIR="${XCODE_PROJECT}.xcodeproj/xcshareddata/xcschemes"
SCHEME_PATH="${SCHEME_DIR}/${SCHEME}.xcscheme"

# function definitions

function clean_build_folder {
    if [[ -d "${BUILD_PATH}" ]]; then
        rm -rf "${BUILD_PATH}"
        mkdir "${BUILD_PATH}"
    fi
}

function update_configuration {
	xcodebuild \
	-project "${XCODE_PROJECT}.xcodeproj" \
	-sdk iphoneos \
	-scheme ${SCHEME} \
	-configuration "Debug" clean \
    -allowProvisioningUpdates \
    ENABLE_BITCODE=YES
	sed -i .bak "/<ArchiveAction/,/<\/ArchiveAction>/{s/\"Distribution\"/\"Debug\"/;s/\"${OLD_ARCHIVENAME}\"/\"${NEW_ARCHIVENAME}\"/;}" ${SCHEME_PATH} 
}

function restore_archive_configuration {
	sed -i .bak "/<ArchiveAction/,/<\/ArchiveAction>/{s/\"Debug\"/\"Distribution\"/;s/\"${NEW_ARCHIVENAME}\"/\"${BACKUP_ARCHIVENAME}\"/;}" ${SCHEME_PATH}
	rm "${SCHEME_DIR}/${XCODE_PROJECT}.xcscheme.bak"
}

function create_archives {
    archive "${SCHEME}" "${IOS_DESTINATION}" "${BUILD_PATH}/${IOS_ARCHIVE}" #"iphonesimulator"
}

function archive {
	update_configuration
    xcodebuild archive \
    -project "${XCODE_PROJECT}.xcodeproj" \
    -scheme "${1}" \
    -destination "${2}" \
    -archivePath "${3}" \
    -sdk iphoneos \
    -allowProvisioningUpdates \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    DEBUG_INFORMATION_FORMAT=dwarf-with-dsym \
    ENABLE_BITCODE=YES
    echo "Archiving ${1} ${2} ${3}"
    restore_archive_configuration   
}

function prepare_archive {
	mkdir "${BUILD_PATH}/${IOS_ARCHIVE}/Payload"
	mv "${BUILD_PATH}/${IOS_ARCHIVE}/Products/Applications" "${BUILD_PATH}/${IOS_ARCHIVE}/Payload"
	rm -rf "Products"
}

function zip_archive {
	if [[ -d "${BUILD_PATH}/${IOS_ARCHIVE}/" ]]; then
		mkdir "${BUILD_PATH}/${XCODE_PROJECT}"
	    cp -R "${BUILD_PATH}/${IOS_ARCHIVE}/BCSymbolMaps" "build/${XCODE_PROJECT}" \
	    && cp -R "${BUILD_PATH}/${IOS_ARCHIVE}/dSYMs" "build/${XCODE_PROJECT}" \
	    && cp "${BUILD_PATH}/${IOS_ARCHIVE}/Info.plist" "build/${XCODE_PROJECT}" \
	    && cp -R "${BUILD_PATH}/${IOS_ARCHIVE}/Payload" "build/${XCODE_PROJECT}" \
	    && cp -R "${BUILD_PATH}/${IOS_ARCHIVE}/Products" "build/${XCODE_PROJECT}"
        zip -r "${XCODE_PROJECT}.zip" "${BUILD_PATH}/${XCODE_PROJECT}"
        for file in *.zip; do mv "$file" "${file%.zip}.bca"; done
        rm -rf "${BUILD_PATH}"
    fi
}

#### start ####
clean_build_folder

# do the work
create_archives
prepare_archive
zip_archive

echo ""
echo "Done! Upload ${XCODE_PROJECT}.bca to Veracode."