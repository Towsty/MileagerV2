#!/bin/bash

# Mileager Debug Script
# Workaround for Flutter APK detection issue

set -e

# Get the first available Android device
DEVICE_ID=$(flutter devices --machine | jq -r '.[] | select(.targetPlatform | startswith("android")) | .id' | head -n1)

if [ -z "$DEVICE_ID" ]; then
    echo "❌ No Android devices found. Please connect a device or start an emulator."
    exit 1
fi

echo "📱 Using device: $DEVICE_ID"

echo "🔨 Building debug APK..."
cd android
./gradlew assembleDebug
cd ..

echo "📱 Installing APK to device..."
~/Library/Android/sdk/platform-tools/adb -s $DEVICE_ID install -r android/app/build/outputs/apk/debug/app-debug.apk

echo "🚀 Starting Flutter debugging session..."
# Copy APK to expected location for Flutter
mkdir -p build/app/outputs/flutter-apk
cp android/app/build/outputs/apk/debug/app-debug.apk build/app/outputs/flutter-apk/app-debug.apk

# Start Flutter with attach mode
flutter attach -d $DEVICE_ID

echo "✅ Debug session started. You can now debug in Cursor!" 