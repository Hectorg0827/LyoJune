#!/bin/bash

# Quick Build Test
echo "🔨 QUICK BUILD TEST"
echo "=================="

cd /Users/republicalatuya/Desktop/LyoJune

# Test build with timeout
timeout 180 xcodebuild -project LyoApp.xcodeproj -scheme LyoApp -destination "platform=iOS Simulator,name=iPhone 16,OS=18.5" build 2>&1 | tee quick_build_test.txt

# Check result
if grep -q "BUILD SUCCEEDED" quick_build_test.txt; then
    echo ""
    echo "🎉 BUILD SUCCEEDED!"
    echo "✅ All compilation errors have been resolved"
elif grep -q "BUILD FAILED" quick_build_test.txt; then
    echo ""
    echo "❌ BUILD FAILED - Extracting errors..."
    grep "error:" quick_build_test.txt | head -10
else
    echo ""
    echo "⏰ Build may have timed out or is still running"
fi
