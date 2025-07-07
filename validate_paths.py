#!/usr/bin/env python3

import os

def validate_file_paths():
    # List of files with their expected paths
    files_to_check = [
        'LyoApp/Core/Models/AppModels.swift',
        'LyoApp/Core/Models/AuthModels.swift',
        'LyoApp/Core/Models/AIModels.swift',
        'LyoApp/Core/Models/CommunityModels.swift',
        'LyoApp/Core/Models/CourseModels.swift',
        'LyoApp/Core/Services/EnhancedAuthService.swift',
        'LyoApp/Core/Services/APIServices.swift',
        'LyoApp/Core/Services/DataManager.swift',
        'LyoApp/Core/Networking/APIClient.swift',
        'LyoApp/Core/Networking/EnhancedNetworkManager.swift',
        'LyoApp/Core/Configuration/ConfigurationManager.swift',
        'LyoApp/Core/Shared/ErrorTypes.swift',
        'LyoApp/DesignSystem/ModernViews.swift',
        'LyoApp/DesignSystem/HapticManager.swift',
        'LyoApp/DesignSystem/DesignTokens.swift',
    ]
    
    base_path = '/Users/republicalatuya/Desktop/LyoJune'
    
    print("Validating file paths...")
    missing_files = []
    existing_files = []
    
    for file_path in files_to_check:
        full_path = os.path.join(base_path, file_path)
        if os.path.exists(full_path):
            existing_files.append(file_path)
            print(f"✅ {file_path}")
        else:
            missing_files.append(file_path)
            print(f"❌ {file_path}")
    
    print(f"\nSummary:")
    print(f"Existing files: {len(existing_files)}")
    print(f"Missing files: {len(missing_files)}")
    
    if missing_files:
        print(f"\nMissing files:")
        for file in missing_files:
            print(f"  - {file}")
    
    return len(missing_files) == 0

if __name__ == "__main__":
    all_exist = validate_file_paths()
    if all_exist:
        print("\n🎉 All files exist at their specified paths!")
    else:
        print("\n⚠️  Some files are missing and need to be located or created.")
