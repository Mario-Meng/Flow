#!/bin/bash

set -e

echo "Setting up native libraries for Flow app..."
echo ""

# Source directory
CDC_SYNC_DIR="packages/dart_cdc_sync"
NATIVE_SRC="$CDC_SYNC_DIR/lib/native"

# Target directories
MAIN_NATIVE="lib/native"
MACOS_FRAMEWORKS="$CDC_SYNC_DIR/macos/Frameworks"
ANDROID_JNI="$CDC_SYNC_DIR/android/src/main/jniLibs"

# Create target directories
mkdir -p "$MAIN_NATIVE"
mkdir -p "$MACOS_FRAMEWORKS"
mkdir -p "$ANDROID_JNI/arm64-v8a"
mkdir -p "$ANDROID_JNI/x86_64"

echo "Copying libraries..."

# macOS
if [ -f "$NATIVE_SRC/libchunker.dylib" ]; then
    cp "$NATIVE_SRC/libchunker.dylib" "$MAIN_NATIVE/"
    cp "$NATIVE_SRC/libchunker.dylib" "$MACOS_FRAMEWORKS/"
    echo "✓ macOS: libchunker.dylib"
else
    echo "⚠️  macOS library not found, run: cd packages/dart_cdc_sync/chunker-ffi && ./build.sh"
fi

# Android
if [ -f "$NATIVE_SRC/libchunker_android_arm64.so" ]; then
    cp "$NATIVE_SRC/libchunker_android_arm64.so" "$ANDROID_JNI/arm64-v8a/libchunker.so"
    echo "✓ Android ARM64: libchunker.so"
else
    echo "⚠️  Android ARM64 library not found"
fi

if [ -f "$NATIVE_SRC/libchunker_android_amd64.so" ]; then
    cp "$NATIVE_SRC/libchunker_android_amd64.so" "$ANDROID_JNI/x86_64/libchunker.so"
    echo "✓ Android x86_64: libchunker.so"
else
    echo "⚠️  Android x86_64 library not found"
fi

echo ""
echo "Done! Native libraries are ready."
echo ""
echo "Now run:"
echo "  flutter clean"
echo "  flutter run"

