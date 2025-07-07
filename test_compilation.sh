#!/bin/bash

echo "Testing Swift compilation for LyoApp..."
cd /Users/republicalatuya/Desktop/LyoJune

# Test individual file compilation
echo "Testing KeychainHelper..."
swiftc -parse LyoApp/Core/Shared/KeychainHelper.swift -framework Foundation -framework Security 2>&1

echo ""
echo "Testing ConfigurationManager..."
swiftc -parse LyoApp/Core/Configuration/ConfigurationManager.swift -framework Foundation -framework Security 2>&1

echo ""
echo "Testing EnhancedNetworkManager..."
swiftc -parse LyoApp/Core/Networking/EnhancedNetworkManager.swift -framework Foundation -framework Network -framework Combine -framework UIKit -framework Security 2>&1

echo ""
echo "Testing complete."
