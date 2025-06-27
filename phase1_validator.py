#!/usr/bin/env python3
"""
Phase 1 Completion Validator - Check that all duplicate types have been removed
and add necessary imports to files that use centralized types.
"""

import os
import re
import glob

# Files that need imports of centralized types
files_needing_imports = {
    # Files using NetworkError should import ErrorTypes
    "LyoApp/Core/Services/DataManager.swift": ["// Note: ErrorTypes should be imported"],
    "LyoApp/Core/Network/NetworkManager.swift": ["// Note: ErrorTypes should be imported"],
    "LyoApp/Core/Services/EnhancedAuthService.swift": ["// Note: AuthTypes and ErrorTypes should be imported"],
    "LyoApp/Core/Networking/APIClient.swift": ["// Note: ErrorTypes and APIModels should be imported"],
}

def check_duplicate_types():
    """Check for any remaining duplicate type definitions."""
    print("=== PHASE 1 DUPLICATE TYPE VALIDATION ===\n")
    
    # Types that should only exist in centralized locations
    centralized_types = {
        "enum NetworkError": "Core/Shared/ErrorTypes.swift",
        "enum AuthError": "Core/Shared/AuthTypes.swift", 
        "enum APIError": "Core/Shared/ErrorTypes.swift",
        "struct EmptyResponse": "Core/Shared/APIModels.swift",
        "struct SuccessResponse": "Core/Shared/APIModels.swift",
        "struct APIResponse": "Core/Shared/APIModels.swift",
        "extension Bundle": "Core/Shared/BundleExtensions.swift",
        "enum HTTPMethod": "Core/Shared/NetworkTypes.swift",
        "struct APIEndpoint": "Core/Shared/NetworkTypes.swift"
    }
    
    duplicate_found = False
    
    for type_definition, canonical_location in centralized_types.items():
        print(f"Checking {type_definition}...")
        
        # Find all Swift files
        swift_files = glob.glob("/Users/republicalatuya/Desktop/LyoJune/**/*.swift", recursive=True)
        matches = []
        
        for file_path in swift_files:
            try:
                with open(file_path, 'r') as f:
                    content = f.read()
                    if type_definition in content:
                        relative_path = file_path.replace("/Users/republicalatuya/Desktop/LyoJune/", "")
                        matches.append(relative_path)
            except:
                continue
        
        if len(matches) > 1:
            duplicate_found = True
            print(f"  ❌ DUPLICATE FOUND in {len(matches)} files:")
            for match in matches:
                status = "✅ CANONICAL" if canonical_location in match else "❌ DUPLICATE"
                print(f"    {status}: {match}")
        elif len(matches) == 1:
            if canonical_location in matches[0]:
                print(f"  ✅ Properly centralized in {matches[0]}")
            else:
                print(f"  ⚠️  Found in unexpected location: {matches[0]}")
        else:
            print(f"  ⚠️  Type not found - may need to be created")
        print()
    
    return not duplicate_found

def check_xcode_project_membership():
    """Check that centralized files are included in Xcode project."""
    print("=== XCODE PROJECT MEMBERSHIP VALIDATION ===\n")
    
    project_file = "/Users/republicalatuya/Desktop/LyoJune/LyoApp.xcodeproj/project.pbxproj"
    
    with open(project_file, 'r') as f:
        project_content = f.read()
    
    centralized_files = [
        "ErrorTypes.swift",
        "AuthTypes.swift", 
        "APIModels.swift",
        "BundleExtensions.swift",
        "NetworkTypes.swift"
    ]
    
    all_included = True
    
    for file_name in centralized_files:
        if file_name in project_content:
            print(f"  ✅ {file_name} is included in Xcode project")
        else:
            print(f"  ❌ {file_name} is NOT included in Xcode project")
            all_included = False
    
    print()
    return all_included

def add_import_comments():
    """Add comments to files that need imports."""
    print("=== ADDING IMPORT GUIDANCE ===\n")
    
    for file_path, comments in files_needing_imports.items():
        full_path = f"/Users/republicalatuya/Desktop/LyoJune/{file_path}"
        if os.path.exists(full_path):
            try:
                with open(full_path, 'r') as f:
                    content = f.read()
                
                # Check if import guidance already exists
                if "Note:" not in content:
                    # Add import guidance after existing imports
                    lines = content.split('\n')
                    import_end = 0
                    for i, line in enumerate(lines):
                        if line.startswith('import '):
                            import_end = i
                    
                    # Insert comments after imports
                    for comment in reversed(comments):
                        lines.insert(import_end + 1, comment)
                    
                    with open(full_path, 'w') as f:
                        f.write('\n'.join(lines))
                    
                    print(f"  ✅ Added import guidance to {file_path}")
                else:
                    print(f"  ℹ️  Import guidance already exists in {file_path}")
            except Exception as e:
                print(f"  ❌ Error updating {file_path}: {e}")
        else:
            print(f"  ⚠️  File not found: {file_path}")
    
    print()

def main():
    """Run Phase 1 validation."""
    print("PHASE 1 COMPLETION VALIDATOR")
    print("============================")
    print("Checking that all duplicate types have been removed and")
    print("centralized files are properly configured.\n")
    
    # Check for duplicate types
    duplicates_removed = check_duplicate_types()
    
    # Check Xcode project membership
    xcode_configured = check_xcode_project_membership()
    
    # Add import guidance
    add_import_comments()
    
    # Summary
    print("=== PHASE 1 COMPLETION SUMMARY ===")
    print(f"Duplicate types removed: {'✅ YES' if duplicates_removed else '❌ NO'}")
    print(f"Xcode project configured: {'✅ YES' if xcode_configured else '❌ NO'}")
    
    if duplicates_removed and xcode_configured:
        print("\n🎉 PHASE 1 COMPLETE!")
        print("✅ All duplicate types have been centralized")
        print("✅ Centralized files are included in Xcode project")
        print("✅ Ready to proceed to Phase 2 (Build testing)")
    else:
        print("\n⚠️  PHASE 1 INCOMPLETE")
        print("Some issues remain that need to be addressed before proceeding.")
    
    print()

if __name__ == "__main__":
    main()
