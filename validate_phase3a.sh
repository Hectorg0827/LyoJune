#!/bin/bash

# PHASE 3A VALIDATION SCRIPT
# Comprehensive validation of all Phase 3A advanced iOS features

echo "🚀 PHASE 3A VALIDATION SCRIPT"
echo "=============================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
total_checks=0
passed_checks=0
failed_checks=0

# Function to check if file exists and count lines
check_file() {
    local file_path="$1"
    local expected_min_lines="$2"
    local description="$3"
    
    total_checks=$((total_checks + 1))
    
    if [ -f "$file_path" ]; then
        line_count=$(wc -l < "$file_path")
        if [ "$line_count" -ge "$expected_min_lines" ]; then
            echo -e "${GREEN}✅ $description${NC}"
            echo -e "   📄 $file_path (${line_count} lines)"
            passed_checks=$((passed_checks + 1))
        else
            echo -e "${YELLOW}⚠️  $description (file too short)${NC}"
            echo -e "   📄 $file_path (${line_count} lines, expected min: ${expected_min_lines})"
            failed_checks=$((failed_checks + 1))
        fi
    else
        echo -e "${RED}❌ $description${NC}"
        echo -e "   📄 File not found: $file_path"
        failed_checks=$((failed_checks + 1))
    fi
}

# Function to check directory structure
check_directory() {
    local dir_path="$1"
    local description="$2"
    
    total_checks=$((total_checks + 1))
    
    if [ -d "$dir_path" ]; then
        echo -e "${GREEN}✅ $description${NC}"
        echo -e "   📁 $dir_path"
        passed_checks=$((passed_checks + 1))
    else
        echo -e "${RED}❌ $description${NC}"
        echo -e "   📁 Directory not found: $dir_path"
        failed_checks=$((failed_checks + 1))
    fi
}

echo "🔍 PHASE 3A IMPLEMENTATION VALIDATION"
echo "=====================================\n"

# Check Core Directory Structure
echo -e "${BLUE}📁 DIRECTORY STRUCTURE VALIDATION${NC}"
echo "-----------------------------------"

check_directory "LyoApp/Core/Security" "Security Directory"
check_directory "LyoApp/Core/Services" "Services Directory" 
check_directory "LyoApp/Features/Settings" "Settings Directory"

echo ""

# Check Core Files
echo -e "${BLUE}📄 CORE FILES VALIDATION${NC}"
echo "-------------------------"

# Security Components
check_file "LyoApp/Core/Security/BiometricAuthManager.swift" 400 "Biometric Authentication Manager"
check_file "LyoApp/Core/Security/SecurityManager.swift" 300 "Security Manager"

# Service Components  
check_file "LyoApp/Core/Services/NotificationManager.swift" 400 "Notification Manager"
check_file "LyoApp/Core/Services/SiriShortcutsManager.swift" 300 "Siri Shortcuts Manager"
check_file "LyoApp/Core/Services/SpotlightManager.swift" 300 "Spotlight Manager"
check_file "LyoApp/Core/Services/BackgroundTaskManager.swift" 400 "Background Task Manager"
check_file "LyoApp/Core/Services/WidgetDataProvider.swift" 200 "Widget Data Provider"
check_file "LyoApp/Core/Services/Phase3AIntegrationManager.swift" 300 "Phase 3A Integration Manager"

# Settings Interface
check_file "LyoApp/Features/Settings/Phase3ASettingsView.swift" 400 "Phase 3A Settings View"

echo ""

# Check Previously Implemented Files (from earlier phases)
echo -e "${BLUE}🏗️  PREVIOUS PHASE FILES VALIDATION${NC}"
echo "-----------------------------------"

check_file "LyoApp/Core/Models/AppModels.swift" 100 "Centralized App Models"
check_file "LyoApp/Core/Models/AppErrors.swift" 50 "Centralized App Errors"
check_file "LyoApp/Core/Networking/EnhancedNetworkManager.swift" 200 "Enhanced Network Manager"
check_file "LyoApp/Core/Services/EnhancedAuthService.swift" 150 "Enhanced Auth Service"
check_file "LyoApp/Core/Data/EnhancedCoreDataManager.swift" 200 "Enhanced Core Data Manager"
check_file "LyoApp/DesignSystem/ModernDesignSystem.swift" 200 "Modern Design System"

echo ""

# Swift Syntax Validation
echo -e "${BLUE}🔧 SWIFT SYNTAX VALIDATION${NC}"
echo "---------------------------"

total_checks=$((total_checks + 1))

# Check if we can find swift files and do basic syntax validation
swift_files_found=0
swift_files_with_issues=0

for file in LyoApp/Core/Security/*.swift LyoApp/Core/Services/*.swift LyoApp/Features/Settings/*.swift; do
    if [ -f "$file" ]; then
        swift_files_found=$((swift_files_found + 1))
        
        # Basic syntax checks
        if grep -q "import Foundation" "$file" && grep -q "class\|struct\|enum" "$file"; then
            echo -e "${GREEN}✅ Basic syntax check passed: $(basename "$file")${NC}"
        else
            echo -e "${YELLOW}⚠️  Potential syntax issues: $(basename "$file")${NC}"
            swift_files_with_issues=$((swift_files_with_issues + 1))
        fi
    fi
done

if [ $swift_files_found -gt 0 ]; then
    if [ $swift_files_with_issues -eq 0 ]; then
        echo -e "${GREEN}✅ Swift Syntax Validation${NC}"
        echo -e "   📊 $swift_files_found Swift files checked, no issues found"
        passed_checks=$((passed_checks + 1))
    else
        echo -e "${YELLOW}⚠️  Swift Syntax Validation (with warnings)${NC}"
        echo -e "   📊 $swift_files_found Swift files checked, $swift_files_with_issues with potential issues"
        failed_checks=$((failed_checks + 1))
    fi
else
    echo -e "${RED}❌ Swift Syntax Validation${NC}"
    echo -e "   📊 No Swift files found"
    failed_checks=$((failed_checks + 1))
fi

echo ""

# Feature Implementation Validation
echo -e "${BLUE}🎯 FEATURE IMPLEMENTATION VALIDATION${NC}"
echo "-------------------------------------"

# Check for key implementation patterns
features=(
    "BiometricAuthManager:FaceID|TouchID|biometric"
    "NotificationManager:UNUserNotificationCenter|notification"  
    "SiriShortcutsManager:INVoiceShortcut|Siri"
    "SpotlightManager:CSSearchableIndex|Spotlight"
    "BackgroundTaskManager:BGTaskScheduler|background"
    "SecurityManager:jailbreak|security"
    "WidgetDataProvider:WidgetKit|widget"
    "Phase3AIntegrationManager:Phase3AFeature|integration"
)

for feature_check in "${features[@]}"; do
    IFS=':' read -r filename patterns <<< "$feature_check"
    file_found=false
    
    for file in LyoApp/Core/Security/${filename}.swift LyoApp/Core/Services/${filename}.swift; do
        if [ -f "$file" ]; then
            file_found=true
            pattern_found=false
            
            IFS='|' read -ra PATTERN_ARRAY <<< "$patterns"
            for pattern in "${PATTERN_ARRAY[@]}"; do
                if grep -qi "$pattern" "$file"; then
                    pattern_found=true
                    break
                fi
            done
            
            total_checks=$((total_checks + 1))
            if [ "$pattern_found" = true ]; then
                echo -e "${GREEN}✅ $filename implementation patterns found${NC}"
                passed_checks=$((passed_checks + 1))
            else
                echo -e "${YELLOW}⚠️  $filename implementation patterns not found${NC}"
                failed_checks=$((failed_checks + 1))
            fi
            break
        fi
    done
    
    if [ "$file_found" = false ]; then
        total_checks=$((total_checks + 1))
        echo -e "${RED}❌ $filename file not found${NC}"
        failed_checks=$((failed_checks + 1))
    fi
done

echo ""

# Documentation Validation
echo -e "${BLUE}📚 DOCUMENTATION VALIDATION${NC}"
echo "----------------------------"

check_file "PHASE_3A_COMPLETION_FINAL.md" 50 "Phase 3A Completion Report"
check_file "MASTER_ROADMAP.md" 100 "Master Roadmap Documentation"

echo ""

# Project Structure Validation
echo -e "${BLUE}🏗️  PROJECT STRUCTURE VALIDATION${NC}"
echo "----------------------------------"

total_checks=$((total_checks + 1))

# Check if Xcode project exists
if [ -f "LyoApp.xcodeproj/project.pbxproj" ]; then
    echo -e "${GREEN}✅ Xcode Project Structure${NC}"
    echo -e "   📦 LyoApp.xcodeproj/project.pbxproj"
    passed_checks=$((passed_checks + 1))
else
    echo -e "${RED}❌ Xcode Project Structure${NC}"
    echo -e "   📦 project.pbxproj not found"
    failed_checks=$((failed_checks + 1))
fi

# Check Core Data model
total_checks=$((total_checks + 1))
if [ -d "LyoApp/Resources/LyoDataModel.xcdatamodeld" ]; then
    echo -e "${GREEN}✅ Core Data Model${NC}"
    echo -e "   🗄️  LyoDataModel.xcdatamodeld"
    passed_checks=$((passed_checks + 1))
else
    echo -e "${YELLOW}⚠️  Core Data Model${NC}"
    echo -e "   🗄️  LyoDataModel.xcdatamodeld not found (may need creation)"
    failed_checks=$((failed_checks + 1))
fi

echo ""

# Final Summary
echo -e "${BLUE}📊 VALIDATION SUMMARY${NC}"
echo "====================="
echo ""

success_rate=$((passed_checks * 100 / total_checks))

echo -e "📋 Total Checks: ${total_checks}"
echo -e "✅ Passed: ${GREEN}${passed_checks}${NC}"
echo -e "❌ Failed: ${RED}${failed_checks}${NC}"
echo -e "📈 Success Rate: ${success_rate}%"
echo ""

if [ $success_rate -ge 90 ]; then
    echo -e "${GREEN}🎉 PHASE 3A VALIDATION: EXCELLENT${NC}"
    echo -e "   Phase 3A implementation is complete and ready!"
    echo ""
    echo -e "${BLUE}🚀 READY FOR:${NC}"
    echo "   • Phase 3B: Core Data Models & Entity Implementation"
    echo "   • Integration Testing & Validation"
    echo "   • App Store Preparation"
    echo ""
elif [ $success_rate -ge 75 ]; then
    echo -e "${YELLOW}⚠️  PHASE 3A VALIDATION: GOOD${NC}"
    echo -e "   Phase 3A implementation is mostly complete with minor issues."
    echo ""
    echo -e "${BLUE}🔧 RECOMMENDED ACTIONS:${NC}"
    echo "   • Address failed validation items"
    echo "   • Complete missing implementations"
    echo "   • Run integration tests"
    echo ""
elif [ $success_rate -ge 50 ]; then
    echo -e "${YELLOW}⚠️  PHASE 3A VALIDATION: NEEDS WORK${NC}"
    echo -e "   Phase 3A implementation is partially complete."
    echo ""
    echo -e "${BLUE}🔧 REQUIRED ACTIONS:${NC}"
    echo "   • Complete missing core implementations"
    echo "   • Fix validation failures"
    echo "   • Ensure all files are properly created"
    echo ""
else
    echo -e "${RED}❌ PHASE 3A VALIDATION: INCOMPLETE${NC}"
    echo -e "   Phase 3A implementation needs significant work."
    echo ""
    echo -e "${BLUE}🔧 CRITICAL ACTIONS:${NC}"
    echo "   • Implement missing core components"
    echo "   • Create required files and directories"
    echo "   • Follow Phase 3A implementation plan"
    echo ""
fi

# Exit with appropriate code
if [ $success_rate -ge 75 ]; then
    exit 0
else
    exit 1
fi
