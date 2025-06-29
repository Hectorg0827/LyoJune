#!/bin/bash

echo "=== LyoApp Build Status Check ==="
echo "Date: $(date)"
echo

cd /Users/republicalatuya/Desktop/LyoJune

echo "1. Checking for Swift compilation errors..."
xcodebuild -project LyoApp.xcodeproj -scheme LyoApp -destination "platform=iOS Simulator,name=iPhone 16,OS=18.5" build > build_validation.log 2>&1

if [ $? -eq 0 ]; then
    echo "✅ BUILD SUCCESSFUL"
    echo "🎉 All Swift compilation errors have been resolved!"
    echo
    echo "=== BUILD SUMMARY ==="
    echo "✅ No compilation errors found"
    echo "✅ All files compile successfully"
    echo "✅ App is ready for deployment"
else
    echo "❌ BUILD FAILED"
    echo "🔍 Checking specific errors..."
    echo
    echo "=== COMPILATION ERRORS ==="
    grep -i "error:" build_validation.log | head -n 10
    echo
    echo "=== FAILED FILES ==="
    grep "SwiftCompile.*failed" build_validation.log | head -n 5
fi

echo
echo "=== Recent Build Log (last 20 lines) ==="
tail -n 20 build_validation.log

echo
echo "Build validation complete."
