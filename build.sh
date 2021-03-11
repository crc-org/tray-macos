#!/bin/sh

BASE_DIR=$(pwd)
BUILD_DIR=$BASE_DIR/out
PROJECT=$BASE_DIR/CodeReady\ Containers.xcodeproj
SCHEME=CodeReady\ Containers

if [ ! -f "$BUILD_DIR" ]; then
	mkdir -p "$BUILD_DIR"
fi

swiftlint

# Build xcarchive
xcodebuild -project "$PROJECT" -config Release -scheme "$SCHEME" -derivedDataPath "$BUILD_DIR"

