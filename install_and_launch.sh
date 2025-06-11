#!/bin/bash

# Mileager Install and Launch Script
# Simple build and install without Flutter attach

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

echo "🚀 Launching app..."
~/Library/Android/sdk/platform-tools/adb -s $DEVICE_ID shell am start -n com.echoseofnumenor.mileager/.MainActivity

echo "✅ App installed and launched successfully!"
echo "💡 The app is running on your device. You can now test it manually."
echo "🔧 For debugging, use Android Studio or check device logs with:"
echo "   adb -s $DEVICE_ID logcat | grep mileager" 