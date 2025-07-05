#!/bin/bash

# Quick compilation test for key files
cd /Users/republicalatuya/Desktop/LyoJune

echo "Testing Swift file compilation..."
echo "================================="

# Test if we can compile individual files without linking
echo "Testing ErrorTypes.swift..."
xcrun swiftc -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) -target x86_64-apple-ios18.0-simulator -parse -primary-file LyoApp/Core/Shared/ErrorTypes.swift 2>&1 | head -10

echo ""
echo "Testing EnhancedAuthService.swift..."
xcrun swiftc -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) -target x86_64-apple-ios18.0-simulator -parse -primary-file LyoApp/Core/Services/EnhancedAuthService.swift -I . 2>&1 | head -10

echo ""
echo "Testing CourseModels.swift..."
xcrun swiftc -sdk $(xcrun --sdk iphonesimulator --show-sdk-path) -target x86_64-apple-ios18.0-simulator -parse -primary-file LyoApp/Core/Models/CourseModels.swift 2>&1 | head -10
