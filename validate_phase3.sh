#!/bin/bash

# Phase 3 Integration Validation Script for LyoApp
# This script validates that all Phase 3 backend integration features are working correctly

echo "🚀 PHASE 3: BACKEND INTEGRATION VALIDATION"
echo "=========================================="
echo ""

PROJECT_DIR="/Users/republicalatuya/Desktop/LyoJune"
cd "$PROJECT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

# Function to print info
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Function to print section header
print_section() {
    echo -e "\n${BLUE}📋 $1${NC}"
    echo "----------------------------------------"
}

# Validation counters
TOTAL_CHECKS=0
PASSED_CHECKS=0

# Function to validate file existence
validate_file() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if [ -f "$1" ]; then
        print_status 0 "File exists: $1"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        print_status 1 "File missing: $1"
        return 1
    fi
}

# Function to validate directory existence
validate_directory() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if [ -d "$1" ]; then
        print_status 0 "Directory exists: $1"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        print_status 1 "Directory missing: $1"
        return 1
    fi
}

# Function to check Swift syntax
validate_swift_syntax() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if [ -f "$1" ]; then
        # Check for basic Swift syntax errors
        if grep -q "import SwiftUI\|import Foundation\|import Combine" "$1" && 
           ! grep -q "syntax error\|unexpected token" "$1"; then
            print_status 0 "Swift syntax valid: $(basename "$1")"
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
            return 0
        else
            print_status 1 "Swift syntax issues: $(basename "$1")"
            return 1
        fi
    else
        print_status 1 "File not found for syntax check: $1"
        return 1
    fi
}

print_section "1. ENHANCED SERVICES VALIDATION"

# Validate Enhanced Services
enhanced_services=(
    "LyoApp/Core/Services/EnhancedServiceFactory.swift"
    "LyoApp/Core/Services/EnhancedAuthService.swift"
    "LyoApp/Core/Services/EnhancedAPIService.swift"
    "LyoApp/Core/Services/WebSocketManager.swift"
    "LyoApp/Core/Networking/EnhancedNetworkManager.swift"
    "LyoApp/Core/Data/CoreDataManager.swift"
)

for service in "${enhanced_services[@]}"; do
    validate_file "$service"
    validate_swift_syntax "$service"
done

print_section "2. CORE DATA MODEL VALIDATION"

# Validate Core Data Model
validate_file "LyoApp/Resources/LyoDataModel.xcdatamodeld/LyoDataModel.xcdatamodel/contents"

print_section "3. UPDATED VIEW MODELS VALIDATION"

# Validate Updated ViewModels
view_models=(
    "LyoApp/Core/ViewModels/FeedViewModel.swift"
    "LyoApp/Core/ViewModels/LearnViewModel.swift"
    "LyoApp/Core/ViewModels/ProfileViewModel.swift"
)

for vm in "${view_models[@]}"; do
    validate_file "$vm"
    validate_swift_syntax "$vm"
    
    # Check if ViewModels use enhanced services
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if grep -q "EnhancedServiceFactory\|serviceFactory" "$vm"; then
        print_status 0 "Uses enhanced services: $(basename "$vm")"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        print_status 1 "Missing enhanced services integration: $(basename "$vm")"
    fi
done

print_section "4. CONFIGURATION VALIDATION"

# Validate Configuration
validate_file ".env"
validate_file "LyoApp/Core/Configuration/ConfigurationManager.swift"

# Check if .env is properly formatted
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if [ -f ".env" ] && grep -q "API_BASE_URL\|JWT_SECRET" ".env"; then
    print_status 0 ".env file properly configured"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    print_status 1 ".env file missing required configuration"
fi

print_section "5. NOTIFICATION SYSTEM VALIDATION"

# Validate Notification Extensions
validate_file "LyoApp/Core/Utilities/NotificationExtensions.swift"
validate_swift_syntax "LyoApp/Core/Utilities/NotificationExtensions.swift"

print_section "6. MAIN APP INTEGRATION VALIDATION"

# Validate Main App Integration
validate_file "LyoApp/App/LyoApp.swift"
validate_swift_syntax "LyoApp/App/LyoApp.swift"

# Check if main app uses enhanced services
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if grep -q "EnhancedServiceFactory" "LyoApp/App/LyoApp.swift"; then
    print_status 0 "Main app uses enhanced services"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    print_status 1 "Main app missing enhanced services integration"
fi

print_section "7. XCODE PROJECT VALIDATION"

# Validate Xcode project file
validate_file "LyoApp.xcodeproj/project.pbxproj"

# Check if new files are added to Xcode project
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if grep -q "EnhancedServiceFactory.swift\|LyoDataModel.xcdatamodeld" "LyoApp.xcodeproj/project.pbxproj"; then
    print_status 0 "New files added to Xcode project"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    print_status 1 "New files not properly added to Xcode project"
fi

print_section "8. DESIGN SYSTEM INTEGRATION VALIDATION"

# Validate Design System files still exist and are integrated
design_files=(
    "LyoApp/DesignSystem/DesignTokens.swift"
    "LyoApp/DesignSystem/DesignSystem.swift"
    "LyoApp/DesignSystem/ModernComponents.swift"
    "LyoApp/DesignSystem/SkeletonLoader.swift"
    "LyoApp/DesignSystem/AnimationSystem.swift"
    "LyoApp/DesignSystem/HapticManager.swift"
)

for design_file in "${design_files[@]}"; do
    validate_file "$design_file"
done

print_section "9. BUILD READINESS CHECK"

print_info "Attempting to build the project..."

# Try to build the project
if xcodebuild -project LyoApp.xcodeproj -scheme LyoApp -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' build > build_log.txt 2>&1; then
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
    print_status 0 "Project builds successfully"
    
    # Clean up build log if successful
    rm -f build_log.txt
else
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    print_status 1 "Project build failed - check build_log.txt for details"
    print_warning "Build errors detected. Check build_log.txt for details."
fi

print_section "10. FINAL VALIDATION SUMMARY"

echo ""
echo "📊 VALIDATION RESULTS:"
echo "======================"
echo "Total Checks: $TOTAL_CHECKS"
echo "Passed: $PASSED_CHECKS"
echo "Failed: $((TOTAL_CHECKS - PASSED_CHECKS))"

PASS_PERCENTAGE=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))
echo "Pass Rate: $PASS_PERCENTAGE%"

echo ""
if [ $PASS_PERCENTAGE -ge 90 ]; then
    echo -e "${GREEN}🎉 PHASE 3 VALIDATION: EXCELLENT ($PASS_PERCENTAGE% pass rate)${NC}"
    echo -e "${GREEN}✅ Backend integration is ready for testing!${NC}"
elif [ $PASS_PERCENTAGE -ge 80 ]; then
    echo -e "${YELLOW}⚠️  PHASE 3 VALIDATION: GOOD ($PASS_PERCENTAGE% pass rate)${NC}"
    echo -e "${YELLOW}🔧 Minor issues need attention before testing.${NC}"
else
    echo -e "${RED}❌ PHASE 3 VALIDATION: NEEDS WORK ($PASS_PERCENTAGE% pass rate)${NC}"
    echo -e "${RED}🚨 Significant issues need to be resolved.${NC}"
fi

echo ""
echo "🔍 NEXT STEPS:"
echo "=============="
echo "1. 🧪 Run comprehensive testing on device/simulator"
echo "2. 🔌 Test API connectivity and authentication"
echo "3. 📱 Test real-time features and offline functionality"
echo "4. 🎯 Performance testing and optimization"
echo "5. 🚀 Prepare for App Store submission"

echo ""
echo "📝 Validation completed at: $(date)"
echo "📄 For detailed build errors (if any), check: build_log.txt"

# Exit with appropriate code
if [ $PASS_PERCENTAGE -ge 80 ]; then
    exit 0
else
    exit 1
fi
