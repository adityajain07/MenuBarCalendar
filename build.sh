#!/bin/bash
set -e

APP="MenuBarCalendar"
BUILD_DIR="build"
APP_BUNDLE="$BUILD_DIR/$APP.app"

echo "Building $APP..."

rm -rf "$BUILD_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

swiftc \
    -parse-as-library \
    -target arm64-apple-macosx13.0 \
    -framework SwiftUI \
    -framework AppKit \
    -framework EventKit \
    -framework UserNotifications \
    -O \
    Sources/*.swift \
    -o "$APP_BUNDLE/Contents/MacOS/$APP"

cp Info.plist "$APP_BUNDLE/Contents/"

echo "Signing app..."
codesign --force --sign - --entitlements "$APP.entitlements" "$APP_BUNDLE"

echo "Build complete: $APP_BUNDLE"
echo ""
echo "To run:  open $APP_BUNDLE"
echo "To install: cp -r $APP_BUNDLE /Applications/"
