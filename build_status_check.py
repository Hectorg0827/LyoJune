#!/usr/bin/env python3

import os
import subprocess
import sys

def main():
    print("=== LyoApp Build Status Check ===")
    
    project_dir = "/Users/republicalatuya/Desktop/LyoJune"
    os.chdir(project_dir)
    
    print("Checking project file validity...")
    
    # Try to run a simple xcodebuild command to validate project
    try:
        result = subprocess.run([
            "xcodebuild", 
            "-project", "LyoApp.xcodeproj",
            "-list"
        ], capture_output=True, text=True, timeout=30)
        
        if result.returncode == 0:
            print("✅ Project file is valid")
            print("Available schemes:")
            print(result.stdout)
        else:
            print("❌ Project file has issues:")
            print(result.stderr)
            
    except subprocess.TimeoutExpired:
        print("⏰ Command timed out")
    except Exception as e:
        print(f"❌ Error running xcodebuild: {e}")
    
    print("\nChecking for missing Swift files...")
    
    # Files that were reported missing in build error
    missing_files = [
        "LyoApp/DesignSystem/ModernViews.swift",
        "LyoApp/DesignSystem/HapticManager.swift", 
        "LyoApp/DesignSystem/DesignTokens.swift",
        "LyoApp/Core/Shared/ErrorTypes.swift",
        "LyoApp/Core/Configuration/ConfigurationManager.swift",
        "LyoApp/Core/Networking/APIClient.swift",
        "LyoApp/Core/Networking/EnhancedNetworkManager.swift",
        "LyoApp/Core/Services/WebSocketManager.swift",
        "LyoApp/Core/Models/AppModels.swift",
        "LyoApp/Core/Models/AuthModels.swift",
        "LyoApp/Core/Models/AIModels.swift",
        "LyoApp/Core/Models/CommunityModels.swift",
        "LyoApp/Core/Models/CourseModels.swift"
    ]
    
    found_count = 0
    for file_path in missing_files:
        if os.path.exists(file_path):
            print(f"✅ {file_path}")
            found_count += 1
        else:
            print(f"❌ {file_path}")
    
    print(f"\nSummary: {found_count}/{len(missing_files)} files found")
    
    if found_count == len(missing_files):
        print("🎉 All previously missing files are now present!")
        print("The project should now build successfully.")
    else:
        missing_count = len(missing_files) - found_count
        print(f"⚠️  {missing_count} files are still missing.")

if __name__ == "__main__":
    main()
