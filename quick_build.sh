#!/bin/bash

# Simple build script to capture compilation errors
cd /Users/republicalatuya/Desktop/LyoJune

echo "Building LyoApp project..."
echo "=========================="

xcodebuild -project LyoApp.xcodeproj -scheme LyoApp -destination "platform=iOS Simulator,name=iPhone 16,OS=18.5" clean build 2>&1 | tee build_current_attempt.log

echo ""
echo "Build completed. Check build_current_attempt.log for details."
echo "Summary of errors:"
echo "=================="

# Extract error and warning lines
grep -E "(error:|warning:)" build_current_attempt.log | head -20
