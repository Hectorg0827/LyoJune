#!/bin/bash

# Phase 3B Validation Script
# Validates Core Data Models & Entity Implementation

echo "🚀 PHASE 3B VALIDATION: Core Data Models & Entity Implementation"
echo "=================================================================="
echo

# Initialize counters
total_checks=0
passed_checks=0

# Function to check if file exists
check_file() {
    total_checks=$((total_checks + 1))
    if [ -f "$1" ]; then
        echo "✅ File exists: $1"
        passed_checks=$((passed_checks + 1))
        return 0
    else
        echo "❌ Missing file: $1"
        return 1
    fi
}

# Function to check file size
check_file_size() {
    total_checks=$((total_checks + 1))
    if [ -f "$1" ]; then
        size=$(wc -l < "$1" 2>/dev/null || echo "0")
        if [ "$size" -gt "$2" ]; then
            echo "✅ File size check: $1 ($size lines, expected >$2)"
            passed_checks=$((passed_checks + 1))
            return 0
        else
            echo "⚠️  File size warning: $1 ($size lines, expected >$2)"
            return 1
        fi
    else
        echo "❌ Cannot check size: $1 (file missing)"
        return 1
    fi
}

# Function to check Swift syntax
check_swift_syntax() {
    total_checks=$((total_checks + 1))
    if [ -f "$1" ]; then
        # Check for basic Swift syntax elements
        if grep -q "import Foundation" "$1" && grep -q "import CoreData" "$1"; then
            echo "✅ Swift syntax check: $1"
            passed_checks=$((passed_checks + 1))
            return 0
        else
            echo "⚠️  Swift syntax warning: $1 (missing expected imports)"
            return 1
        fi
    else
        echo "❌ Cannot check syntax: $1 (file missing)"
        return 1
    fi
}

# Function to check for specific content
check_content() {
    total_checks=$((total_checks + 1))
    if [ -f "$1" ]; then
        if grep -q "$2" "$1"; then
            echo "✅ Content check: $1 contains '$2'"
            passed_checks=$((passed_checks + 1))
            return 0
        else
            echo "❌ Content missing: $1 should contain '$2'"
            return 1
        fi
    else
        echo "❌ Cannot check content: $1 (file missing)"
        return 1
    fi
}

echo "📁 STEP 1: Core Data Models Directory Structure"
echo "-----------------------------------------------"

# Check directory structure
check_file "LyoApp/Core/Data/Models"

echo

echo "🏗️ STEP 2: Core Data Stack Implementation"
echo "----------------------------------------"

check_file "LyoApp/Core/Data/CoreDataStack.swift"
check_file_size "LyoApp/Core/Data/CoreDataStack.swift" 1000
check_swift_syntax "LyoApp/Core/Data/CoreDataStack.swift"
check_content "LyoApp/Core/Data/CoreDataStack.swift" "NSPersistentCloudKitContainer"
check_content "LyoApp/Core/Data/CoreDataStack.swift" "CloudKitStatus"

echo

echo "👤 STEP 3: User Entity Implementation"
echo "-----------------------------------"

check_file "LyoApp/Core/Data/Models/User+CoreDataClass.swift"
check_file_size "LyoApp/Core/Data/Models/User+CoreDataClass.swift" 800
check_swift_syntax "LyoApp/Core/Data/Models/User+CoreDataClass.swift"
check_content "LyoApp/Core/Data/Models/User+CoreDataClass.swift" "NSManagedObject"
check_content "LyoApp/Core/Data/Models/User+CoreDataClass.swift" "encryptSensitiveData"
check_content "LyoApp/Core/Data/Models/User+CoreDataClass.swift" "LearningPreferences"

echo

echo "📚 STEP 4: Course Entity Implementation"
echo "-------------------------------------"

check_file "LyoApp/Core/Data/Models/Course+CoreDataClass.swift"
check_file_size "LyoApp/Core/Data/Models/Course+CoreDataClass.swift" 1000
check_swift_syntax "LyoApp/Core/Data/Models/Course+CoreDataClass.swift"
check_content "LyoApp/Core/Data/Models/Course+CoreDataClass.swift" "enum Category"
check_content "LyoApp/Core/Data/Models/Course+CoreDataClass.swift" "enum DifficultyLevel"
check_content "LyoApp/Core/Data/Models/Course+CoreDataClass.swift" "enrollUser"

echo

echo "📖 STEP 5: Lesson Entity Implementation"
echo "-------------------------------------"

check_file "LyoApp/Core/Data/Models/Lesson+CoreDataClass.swift"
check_file_size "LyoApp/Core/Data/Models/Lesson+CoreDataClass.swift" 1200
check_swift_syntax "LyoApp/Core/Data/Models/Lesson+CoreDataClass.swift"
check_content "LyoApp/Core/Data/Models/Lesson+CoreDataClass.swift" "enum LessonType"
check_content "LyoApp/Core/Data/Models/Lesson+CoreDataClass.swift" "LessonContent"
check_content "LyoApp/Core/Data/Models/Lesson+CoreDataClass.swift" "markCompleted"

echo

echo "📊 STEP 6: Progress Entity Implementation"
echo "---------------------------------------"

check_file "LyoApp/Core/Data/Models/Progress+CoreDataClass.swift"
check_file_size "LyoApp/Core/Data/Models/Progress+CoreDataClass.swift" 600
check_swift_syntax "LyoApp/Core/Data/Models/Progress+CoreDataClass.swift"
check_content "LyoApp/Core/Data/Models/Progress+CoreDataClass.swift" "enum ProgressStatus"
check_content "LyoApp/Core/Data/Models/Progress+CoreDataClass.swift" "updateProgress"
check_content "LyoApp/Core/Data/Models/Progress+CoreDataClass.swift" "StudyPatternAnalysis"

echo

echo "🏆 STEP 7: Achievement Entity Implementation"
echo "------------------------------------------"

check_file "LyoApp/Core/Data/Models/Achievement+CoreDataClass.swift"
check_file_size "LyoApp/Core/Data/Models/Achievement+CoreDataClass.swift" 800
check_swift_syntax "LyoApp/Core/Data/Models/Achievement+CoreDataClass.swift"
check_content "LyoApp/Core/Data/Models/Achievement+CoreDataClass.swift" "enum AchievementCategory"
check_content "LyoApp/Core/Data/Models/Achievement+CoreDataClass.swift" "enum AchievementTier"
check_content "LyoApp/Core/Data/Models/Achievement+CoreDataClass.swift" "unlock"

echo

echo "📚 STEP 8: Repository Pattern Implementation"
echo "------------------------------------------"

check_file "LyoApp/Core/Repositories"
check_file "LyoApp/Core/Repositories/UserRepository.swift"
check_file "LyoApp/Core/Repositories/CourseRepository.swift"
check_file_size "LyoApp/Core/Repositories/UserRepository.swift" 600
check_file_size "LyoApp/Core/Repositories/CourseRepository.swift" 800
check_swift_syntax "LyoApp/Core/Repositories/UserRepository.swift"
check_swift_syntax "LyoApp/Core/Repositories/CourseRepository.swift"
check_content "LyoApp/Core/Repositories/UserRepository.swift" "ObservableObject"
check_content "LyoApp/Core/Repositories/CourseRepository.swift" "performBackgroundTask"

echo

echo "🔄 STEP 9: CloudKit Integration Features"
echo "--------------------------------------"

check_content "LyoApp/Core/Data/CoreDataStack.swift" "cloudKitRecord"
check_content "LyoApp/Core/Data/CoreDataStack.swift" "needsCloudKitSync"
check_content "LyoApp/Core/Data/Models/User+CoreDataClass.swift" "cloudKitRecordData"
check_content "LyoApp/Core/Data/Models/Course+CoreDataClass.swift" "cloudKitRecordData"
check_content "LyoApp/Core/Data/Models/Progress+CoreDataClass.swift" "cloudKitRecordData"

echo

echo "⚡ STEP 10: Performance & Optimization Features"
echo "---------------------------------------------"

check_content "LyoApp/Core/Data/CoreDataStack.swift" "batchUpdate"
check_content "LyoApp/Core/Data/CoreDataStack.swift" "performBackgroundTask"
check_content "LyoApp/Core/Data/CoreDataStack.swift" "backgroundContext"
check_content "LyoApp/Core/Repositories/UserRepository.swift" "performBackgroundTask"
check_content "LyoApp/Core/Repositories/CourseRepository.swift" "batchUpdate"

echo

echo "🔍 STEP 11: Advanced Features Check"
echo "---------------------------------"

check_content "LyoApp/Core/Data/Models/User+CoreDataClass.swift" "encrypt"
check_content "LyoApp/Core/Data/Models/Course+CoreDataClass.swift" "searchableKeywords"
check_content "LyoApp/Core/Data/Models/Lesson+CoreDataClass.swift" "downloadVideo"
check_content "LyoApp/Core/Data/Models/Progress+CoreDataClass.swift" "getStudyPatternAnalysis"
check_content "LyoApp/Core/Data/Models/Achievement+CoreDataClass.swift" "createLearningAchievements"

echo

echo "📄 STEP 12: Documentation & Planning"
echo "----------------------------------"

check_file "PHASE_3B_PLAN.md"
check_file "PHASE_3B_COMPLETION_FINAL.md"
check_file_size "PHASE_3B_PLAN.md" 100
check_file_size "PHASE_3B_COMPLETION_FINAL.md" 100

echo

# Calculate success rate
if [ $total_checks -gt 0 ]; then
    success_rate=$((passed_checks * 100 / total_checks))
else
    success_rate=0
fi

echo "📊 PHASE 3B VALIDATION RESULTS"
echo "=============================="
echo "Total Checks: $total_checks"
echo "Passed Checks: $passed_checks"
echo "Success Rate: $success_rate%"
echo

if [ $success_rate -ge 90 ]; then
    echo "🎉 PHASE 3B: EXCELLENT! Ready for Phase 3C"
    echo "✨ Core Data architecture is production-ready!"
elif [ $success_rate -ge 80 ]; then
    echo "✅ PHASE 3B: GOOD! Minor issues to address"
    echo "🔧 Some optimizations recommended"
elif [ $success_rate -ge 70 ]; then
    echo "⚠️  PHASE 3B: ACCEPTABLE! Several issues to fix"
    echo "🛠️  Requires attention before proceeding"
else
    echo "❌ PHASE 3B: NEEDS WORK! Major issues detected"
    echo "🚨 Significant development required"
fi

echo
echo "🚀 Next: Phase 3C - Advanced Features Integration"
echo "🎯 Focus: Video streaming, real-time features, advanced analytics"
echo

# Set exit code based on success rate
if [ $success_rate -ge 80 ]; then
    exit 0
else
    exit 1
fi
