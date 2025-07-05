#!/bin/bash
cd /Users/republicalatuya/Desktop/LyoJune
echo "Starting build test..."
xcodebuild -project LyoApp.xcodeproj -scheme LyoApp build > build_test_result.log 2>&1
BUILD_RESULT=$?
echo "Build completed with exit code: $BUILD_RESULT"
if [ $BUILD_RESULT -eq 0 ]; then
    echo "✅ BUILD SUCCESS!"
    echo "All 'Cannot find type' errors should be resolved!"
else
    echo "❌ BUILD FAILED"
    echo "Checking for remaining errors..."
    tail -50 build_test_result.log
fi
