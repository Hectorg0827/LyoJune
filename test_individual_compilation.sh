#!/bin/bash

cd /Users/republicalatuya/Desktop/LyoJune

echo "Testing compilation of ErrorTypes.swift..."
xcrun swiftc -typecheck LyoApp/Core/Shared/ErrorTypes.swift

echo "Testing compilation of KeychainHelper.swift..."
xcrun swiftc -typecheck LyoApp/Core/Shared/KeychainHelper.swift

echo "Testing compilation of NetworkingProtocols.swift..."
xcrun swiftc -typecheck LyoApp/Core/Networking/NetworkingProtocols.swift

echo "Done testing individual files"
