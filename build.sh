#!/bin/sh

BASE_DIR=$(pwd)
BUILD_DIR=$BASE_DIR/out
WORKSPACE=$BASE_DIR/CodeReady\ Containers.xcworkspace
ARCHIVE_PATH=$BUILD_DIR/CodeReady_Containers.xcarchive
EXPORT_OPTIONS=$BASE_DIR/CodeReady\ Containers/ExportOptions.plist
SCHEME=CodeReady\ Containers

if [ ! -f "$BUILD_DIR" ]; then
	mkdir -p "$BUILD_DIR"
fi

# Build xcarchive
xcodebuild -workspace "$WORKSPACE" -config Release -scheme "$SCHEME" -archivePath "$ARCHIVE_PATH" archive

# Build .app archive
xcodebuild -exportArchive -archivePath "$ARCHIVE_PATH" -exportPath "$BUILD_DIR" -exportOptionsPlist "$EXPORT_OPTIONS"
