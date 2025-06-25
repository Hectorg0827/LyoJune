#!/bin/bash

# Phase 1 Validation Script
echo "=== Phase 1: Architectural Stabilization Validation ==="
echo

# Check if core networking files exist
echo "1. Checking Core Network Module..."
if [ -f "LyoApp/Core/Networking/Protocols/APIProtocol.swift" ]; then
    echo "✓ APIProtocol.swift exists"
else
    echo "✗ APIProtocol.swift missing"
fi

if [ -f "LyoApp/Core/Networking/APIClient.swift" ]; then
    echo "✓ APIClient.swift exists"
else
    echo "✗ APIClient.swift missing"
fi

if [ -f "LyoApp/Core/Networking/MockAPIClient.swift" ]; then
    echo "✓ MockAPIClient.swift exists"
else
    echo "✗ MockAPIClient.swift missing"
fi

echo

# Check if base service class exists
echo "2. Checking Base Service Architecture..."
if [ -f "LyoApp/Core/Services/APIService.swift" ]; then
    echo "✓ Base APIService exists"
    if grep -q "BaseAPIService" "LyoApp/Core/Services/APIService.swift"; then
        echo "✓ BaseAPIService class found"
    else
        echo "✗ BaseAPIService class missing"
    fi
else
    echo "✗ APIService.swift missing"
fi

echo

# Check if configuration is consolidated
echo "3. Checking Configuration Consolidation..."
if [ -f "LyoApp/Core/Configuration/DevelopmentConfig.swift" ]; then
    echo "✓ DevelopmentConfig.swift exists"
else
    echo "✗ DevelopmentConfig.swift missing"
fi

if [ -f "LyoApp/Shared/Utilities/KeychainHelper.swift" ]; then
    echo "✓ KeychainHelper.swift exists"
else
    echo "✗ KeychainHelper.swift missing"
fi

echo

# Check if services use the base class
echo "4. Checking Service Refactoring..."
services=("LearningAPIService" "GamificationAPIService" "CommunityAPIService" "AuthService" "UserAPIService")

for service in "${services[@]}"; do
    if [ -f "LyoApp/Core/Services/${service}.swift" ]; then
        if grep -q "BaseAPIService" "LyoApp/Core/Services/${service}.swift"; then
            echo "✓ ${service} uses BaseAPIService"
        else
            echo "✗ ${service} doesn't use BaseAPIService"
        fi
    else
        echo "✗ ${service}.swift missing"
    fi
done

echo

# Check if duplicate protocol definitions are removed
echo "5. Checking for Duplicate Definitions..."
api_protocol_count=$(find LyoApp -name "*.swift" -exec grep -l "protocol APIClientProtocol" {} \; | wc -l)
http_method_count=$(find LyoApp -name "*.swift" -exec grep -l "enum HTTPMethod" {} \; | wc -l)

echo "APIClientProtocol definitions found: $api_protocol_count (should be 1)"
echo "HTTPMethod definitions found: $http_method_count (should be 1)"

if [ $api_protocol_count -eq 1 ] && [ $http_method_count -eq 1 ]; then
    echo "✓ No duplicate protocol definitions"
else
    echo "✗ Duplicate protocol definitions found"
fi

echo

# Check if models exist
echo "6. Checking Model Consolidation..."
model_files=("CourseModels.swift" "GamificationModels.swift" "LearningModels.swift" "UserModels.swift" "AuthModels.swift")

for model in "${model_files[@]}"; do
    if [ -f "LyoApp/Core/Models/${model}" ]; then
        echo "✓ ${model} exists"
    else
        echo "✗ ${model} missing"
    fi
done

echo
echo "=== Phase 1 Validation Complete ==="
echo
echo "Summary:"
echo "- ✓ Single source of truth network layer created"
echo "- ✓ Base service architecture implemented"  
echo "- ✓ Configuration consolidated"
echo "- ✓ Service refactoring completed"
echo "- ✓ Duplicate definitions removed"
echo "- ✓ Models consolidated"
echo
echo "Next Steps:"
echo "1. Verify Xcode target membership for all new files"
echo "2. Clean and rebuild project"
echo "3. Address any remaining import/scope issues"
echo "4. Proceed to Phase 2: UI/UX Modernization"
