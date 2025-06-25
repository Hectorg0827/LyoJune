#!/bin/bash

# Script to identify missing Swift files that need to be added to Xcode project

echo "=== Missing Swift Files Analysis ==="
echo ""

echo "Files that exist on filesystem but are NOT included in Xcode project:"
echo "================================================================="

# Get list of Swift files on filesystem
find LyoApp -name "*.swift" -exec basename {} \; | sort > /tmp/fs_files.txt

# Get list of Swift files in project
grep -o '[A-Za-z]*\.swift' LyoApp.xcodeproj/project.pbxproj | sort | uniq | grep -v sourcecode.swift > /tmp/project_files.txt

# Find missing files
echo "Core Services (CRITICAL):"
for file in AuthService.swift NetworkManager.swift ErrorManager.swift OfflineManager.swift DataManager.swift; do
    if ! grep -q "$file" /tmp/project_files.txt; then
        echo "  ❌ $file"
    else
        echo "  ✅ $file"
    fi
done

echo ""
echo "API Services:"
for file in APIServices.swift LearningAPIService.swift GamificationAPIService.swift; do
    if ! grep -q "$file" /tmp/project_files.txt; then
        echo "  ❌ $file"
    else
        echo "  ✅ $file"
    fi
done

echo ""
echo "AI Services:"
for file in AIService.swift EnhancedAIService.swift; do
    if ! grep -q "$file" /tmp/project_files.txt; then
        echo "  ❌ $file"
    else
        echo "  ✅ $file"
    fi
done

echo ""
echo "Additional Support Files:"
for file in ErrorHandler.swift ErrorHandlingViews.swift ConfigurationManager.swift; do
    if ! grep -q "$file" /tmp/project_files.txt; then
        echo "  ❌ $file"
    else
        echo "  ✅ $file"
    fi
done

echo ""
echo "=== SOLUTION ==="
echo "You need to add the missing files (marked with ❌) to your Xcode project:"
echo "1. Open Xcode"
echo "2. Right-click on the appropriate group in the Project Navigator"
echo "3. Choose 'Add Files to LyoApp'"
echo "4. Navigate to the file locations and add them"
echo ""
echo "OR use Xcode's 'Add Files to Project' feature to bulk-add missing files."

# Cleanup
rm -f /tmp/fs_files.txt /tmp/project_files.txt
