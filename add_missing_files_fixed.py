#!/usr/bin/env python3

import os
import uuid
import re

def generate_uuid():
    """Generate a UUID in the format used by Xcode project files."""
    return str(uuid.uuid4()).upper().replace('-', '')[:24]

def add_files_to_xcode_project():
    """Add missing files to the Xcode project with correct paths."""
    
    # List of files that need to be added to the project with their correct relative paths
    missing_files = [
        # Core/Models
        ("LyoApp/Core/Models/AppModels.swift", "Core/Models/AppModels.swift"),
        ("LyoApp/Core/Models/AuthModels.swift", "Core/Models/AuthModels.swift"), 
        ("LyoApp/Core/Models/AIModels.swift", "Core/Models/AIModels.swift"),
        ("LyoApp/Core/Models/CommunityModels.swift", "Core/Models/CommunityModels.swift"),
        ("LyoApp/Core/Models/CourseModels.swift", "Core/Models/CourseModels.swift"),
        
        # Core/Services
        ("LyoApp/Core/Services/EnhancedAuthService.swift", "Core/Services/EnhancedAuthService.swift"),
        ("LyoApp/Core/Services/APIServices.swift", "Core/Services/APIServices.swift"),
        ("LyoApp/Core/Services/EnhancedServiceFactory.swift", "Core/Services/EnhancedServiceFactory.swift"),
        ("LyoApp/Core/Services/DataManager.swift", "Core/Services/DataManager.swift"),
        ("LyoApp/Core/Services/AnalyticsAPIService.swift", "Core/Services/AnalyticsAPIService.swift"),
        ("LyoApp/Core/Services/ErrorManager.swift", "Core/Services/ErrorManager.swift"),
        ("LyoApp/Core/Services/OfflineManager.swift", "Core/Services/OfflineManager.swift"),
        ("LyoApp/Core/Services/AIService.swift", "Core/Services/AIService.swift"),
        ("LyoApp/Core/Services/EnhancedAIService.swift", "Core/Services/EnhancedAIService.swift"),
        ("LyoApp/Core/Services/UserAPIService.swift", "Core/Services/UserAPIService.swift"),
        ("LyoApp/Core/Services/CommunityAPIService.swift", "Core/Services/CommunityAPIService.swift"),
        ("LyoApp/Core/Services/GamificationAPIService.swift", "Core/Services/GamificationAPIService.swift"),
        ("LyoApp/Core/Services/WebSocketManager.swift", "Core/Services/WebSocketManager.swift"),
        
        # Core/Networking
        ("LyoApp/Core/Networking/EnhancedNetworkManager.swift", "Core/Networking/EnhancedNetworkManager.swift"),
        ("LyoApp/Core/Networking/APIClient.swift", "Core/Networking/APIClient.swift"),
        
        # Core/Configuration
        ("LyoApp/Core/Configuration/ConfigurationManager.swift", "Core/Configuration/ConfigurationManager.swift"),
        
        # Core/Shared
        ("LyoApp/Core/Shared/ErrorTypes.swift", "Core/Shared/ErrorTypes.swift"),
        
        # DesignSystem
        ("LyoApp/DesignSystem/DesignTokens.swift", "DesignSystem/DesignTokens.swift"),
        ("LyoApp/DesignSystem/HapticManager.swift", "DesignSystem/HapticManager.swift"),
        ("LyoApp/DesignSystem/ModernViews.swift", "DesignSystem/ModernViews.swift"),
    ]
    
    # Check which files actually exist
    existing_files = []
    for full_path, relative_path in missing_files:
        absolute_path = f"/Users/republicalatuya/Desktop/LyoJune/{full_path}"
        if os.path.exists(absolute_path):
            existing_files.append((full_path, relative_path))
            print(f"✓ Found: {full_path}")
        else:
            print(f"✗ Missing: {full_path}")
    
    print(f"\nFound {len(existing_files)} files to add to project")
    
    # Read the current project file
    project_file = "/Users/republicalatuya/Desktop/LyoJune/LyoApp.xcodeproj/project.pbxproj"
    with open(project_file, 'r') as f:
        content = f.read()
    
    # Create backup
    backup_file = f"{project_file}.backup_correct_paths"
    with open(backup_file, 'w') as f:
        f.write(content)
    print(f"Created backup: {backup_file}")
    
    # Generate entries for each file
    file_references = []
    build_files = []
    build_file_entries = []
    
    for full_path, relative_path in existing_files:
        file_name = os.path.basename(full_path)
        file_uuid = generate_uuid()
        build_uuid = generate_uuid()
        
        # Create file reference entry with correct path
        file_ref = f'\t\t{file_uuid} /* {file_name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{relative_path}"; sourceTree = "<group>"; }};'
        file_references.append(file_ref)
        
        # Create build file entry  
        build_file = f'\t\t{build_uuid} /* {file_name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_uuid} /* {file_name} */; }};'
        build_files.append(build_file)
        
        # Create build file list entry
        build_entry = f'\t\t\t\t{build_uuid} /* {file_name} in Sources */,'
        build_file_entries.append(build_entry)
    
    # Insert file references
    pbx_file_ref_end = content.find('/* End PBXFileReference section */')
    if pbx_file_ref_end != -1:
        insertion_point = content.rfind('\n', 0, pbx_file_ref_end)
        new_content = content[:insertion_point] + '\n' + '\n'.join(file_references) + content[insertion_point:]
        content = new_content
    
    # Insert build files
    pbx_build_file_end = content.find('/* End PBXBuildFile section */')
    if pbx_build_file_end != -1:
        insertion_point = content.rfind('\n', 0, pbx_build_file_end)
        new_content = content[:insertion_point] + '\n' + '\n'.join(build_files) + content[insertion_point:]
        content = new_content
    
    # Insert build file entries in Sources phase
    sources_phase_pattern = r'(92A5145C75D5A57ABAFEE26F /\* Sources \*/ = \{[^}]+files = \([^)]+)'
    match = re.search(sources_phase_pattern, content, re.DOTALL)
    if match:
        insertion_point = match.end()
        new_content = content[:insertion_point] + '\n' + '\n'.join(build_file_entries) + content[insertion_point:]
        content = new_content
    
    # Write the updated project file
    with open(project_file, 'w') as f:
        f.write(content)
    
    print(f"Added {len(existing_files)} files to Xcode project")
    print("Updated project.pbxproj file")

if __name__ == "__main__":
    add_files_to_xcode_project()
