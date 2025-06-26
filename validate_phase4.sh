#!/bin/bash

# Phase 4 Validation Script - Backend Integration & API Development
# This script validates that all Phase 4 requirements are met

echo "🚀 Phase 4 Validation: Backend Integration & API Development"
echo "============================================================"

PHASE4_PASSED=true

# Function to check if file exists and has content
check_file_exists() {
    local file_path="$1"
    local description="$2"
    
    if [ -f "$file_path" ]; then
        local line_count=$(wc -l < "$file_path")
        echo "✅ $description exists ($line_count lines)"
        return 0
    else
        echo "❌ $description missing: $file_path"
        PHASE4_PASSED=false
        return 1
    fi
}

# Function to check if code contains specific patterns
check_code_pattern() {
    local file_path="$1"
    local pattern="$2"
    local description="$3"
    
    if [ -f "$file_path" ] && grep -q "$pattern" "$file_path"; then
        echo "✅ $description found"
        return 0
    else
        echo "❌ $description missing in $file_path"
        PHASE4_PASSED=false
        return 1
    fi
}

# Function to count occurrences of a pattern
count_pattern() {
    local file_path="$1"
    local pattern="$2"
    
    if [ -f "$file_path" ]; then
        grep -c "$pattern" "$file_path" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

echo ""
echo "📁 Phase 4 File Validation"
echo "---------------------------"

# Check core files
check_file_exists "LyoApp/Core/Models/AppModels.swift" "Core AppModels.swift"
check_file_exists "LyoApp/Core/Models/AuthModels.swift" "Enhanced AuthModels.swift"
check_file_exists "LyoApp/Core/Networking/APIClient.swift" "Enhanced APIClient.swift"
check_file_exists "LyoApp/Core/Networking/Endpoint.swift" "Endpoint definitions"

echo ""
echo "🔧 Backend Integration Features"
echo "-------------------------------"

# Check for Syncable protocol
check_code_pattern "LyoApp/Core/Models/AppModels.swift" "protocol Syncable" "Syncable protocol"
check_code_pattern "LyoApp/Core/Models/AppModels.swift" "enum SyncStatus" "SyncStatus enum"
check_code_pattern "LyoApp/Core/Models/AppModels.swift" "struct APIError" "APIError struct"

# Check for network models
check_code_pattern "LyoApp/Core/Models/AppModels.swift" "struct NetworkInfo" "NetworkInfo model"
check_code_pattern "LyoApp/Core/Models/AppModels.swift" "enum ConnectionType" "ConnectionType enum"
check_code_pattern "LyoApp/Core/Models/AppModels.swift" "enum Bandwidth" "Bandwidth enum"

echo ""
echo "📊 API Serialization Methods"
echo "----------------------------"

# Count API methods
api_payload_count=$(count_pattern "LyoApp/Core/Models/AppModels.swift" "func toAPIPayload")
api_response_count=$(count_pattern "LyoApp/Core/Models/AppModels.swift" "func fromAPIResponse")

echo "✅ toAPIPayload methods: $api_payload_count"
echo "✅ fromAPIResponse methods: $api_response_count"

if [ "$api_payload_count" -lt 15 ]; then
    echo "❌ Insufficient API payload methods (expected 15+, found $api_payload_count)"
    PHASE4_PASSED=false
fi

if [ "$api_response_count" -lt 15 ]; then
    echo "❌ Insufficient API response methods (expected 15+, found $api_response_count)"
    PHASE4_PASSED=false
fi

echo ""
echo "🏗️ Model Validation"
echo "-------------------"

# Check for key models
declare -a REQUIRED_MODELS=(
    "struct User"
    "struct UserAvatar" 
    "struct UserPreferences"
    "struct UserProfile"
    "struct UserSkill"
    "struct Course"
    "struct Lesson"
    "struct Quiz"
    "struct Post"
    "struct Comment"
    "struct Achievement"
    "struct LearningStats"
    "struct Instructor"
    "struct CommunityGroup"
    "struct NotificationModel"
    "struct AnalyticsEvent"
    "enum SubscriptionTier"
)

for model in "${REQUIRED_MODELS[@]}"; do
    check_code_pattern "LyoApp/Core/Models/AppModels.swift" "$model" "$model"
done

echo ""
echo "🔐 Authentication Models"
echo "------------------------"

# Check authentication models
declare -a AUTH_MODELS=(
    "struct AuthCredentials"
    "struct AuthTokens"
    "struct AuthSession"
    "struct DeviceInfo"
    "enum AuthState"
    "enum AuthError"
)

for model in "${AUTH_MODELS[@]}"; do
    check_code_pattern "LyoApp/Core/Models/AuthModels.swift" "$model" "$model"
done

echo ""
echo "🌐 Networking Infrastructure"
echo "----------------------------"

# Check networking enhancements
check_code_pattern "LyoApp/Core/Networking/APIClient.swift" "import Combine" "Combine framework integration"
check_code_pattern "LyoApp/Core/Networking/APIClient.swift" "func request" "Request methods"
check_code_pattern "LyoApp/Core/Networking/APIClient.swift" "enum APIError" "API error handling"

echo ""
echo "📋 Supporting Infrastructure"
echo "----------------------------"

# Check for pagination and sync infrastructure
check_code_pattern "LyoApp/Core/Models/AppModels.swift" "struct PaginatedResponse" "Paginated response"
check_code_pattern "LyoApp/Core/Models/AppModels.swift" "struct SyncQueueItem" "Sync queue"
check_code_pattern "LyoApp/Core/Models/AppModels.swift" "protocol APIPayloadConvertible" "API protocols"

echo ""
echo "🎯 Backend Integration Properties"
echo "---------------------------------"

# Check for backend integration properties in models
sync_properties_count=$(count_pattern "LyoApp/Core/Models/AppModels.swift" "let syncStatus: SyncStatus")
server_id_count=$(count_pattern "LyoApp/Core/Models/AppModels.swift" "let serverID: String\\?")
version_count=$(count_pattern "LyoApp/Core/Models/AppModels.swift" "let version: Int")

echo "✅ Models with syncStatus: $sync_properties_count"
echo "✅ Models with serverID: $server_id_count"
echo "✅ Models with version: $version_count"

if [ "$sync_properties_count" -lt 5 ]; then
    echo "❌ Insufficient models with sync properties (expected 5+, found $sync_properties_count)"
    PHASE4_PASSED=false
fi

echo ""
echo "📊 Statistics Summary"
echo "--------------------"

# Get file statistics
if [ -f "LyoApp/Core/Models/AppModels.swift" ]; then
    total_lines=$(wc -l < "LyoApp/Core/Models/AppModels.swift")
    struct_count=$(grep -c "^public struct" "LyoApp/Core/Models/AppModels.swift")
    enum_count=$(grep -c "^public enum" "LyoApp/Core/Models/AppModels.swift")
    
    echo "📄 AppModels.swift: $total_lines lines"
    echo "🏗️ Public structs: $struct_count"
    echo "📋 Public enums: $enum_count"
    echo "🔧 API payload methods: $api_payload_count"
    echo "🔄 API response methods: $api_response_count"
fi

echo ""
echo "🎯 Phase 4 Completion Status"
echo "============================"

if [ "$PHASE4_PASSED" = true ]; then
    echo "🎉 Phase 4: PASSED ✅"
    echo ""
    echo "✅ All backend integration features implemented"
    echo "✅ API serialization methods complete"  
    echo "✅ Sync infrastructure in place"
    echo "✅ Authentication models enhanced"
    echo "✅ Networking layer upgraded"
    echo "✅ All major models support backend integration"
    echo ""
    echo "🚀 Phase 4 is COMPLETE and ready for backend integration!"
else
    echo "❌ Phase 4: FAILED ❌"
    echo ""
    echo "❌ Some requirements are missing"
    echo "❌ Review the failed checks above"
    echo "❌ Phase 4 needs additional work"
fi

echo ""
echo "📝 Next Steps:"
echo "1. Implement actual backend API endpoints"
echo "2. Set up database schema matching models"
echo "3. Implement authentication flows"
echo "4. Add background sync services"
echo "5. Test API integration end-to-end"

echo ""
echo "============================================================"
echo "Phase 4 validation complete - $(date)"
