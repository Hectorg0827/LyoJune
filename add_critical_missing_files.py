#!/usr/bin/env python3

import os
import re
import uuid

def main():
    project_path = "/Users/republicalatuya/Desktop/LyoJune/LyoApp.xcodeproj/project.pbxproj"
    
    # Files that were reported missing in the build error but not found in project file
    missing_files = [
        ("ModernViews.swift", "LyoApp/DesignSystem/ModernViews.swift"),
        ("HapticManager.swift", "LyoApp/DesignSystem/HapticManager.swift"),
        ("DesignTokens.swift", "LyoApp/DesignSystem/DesignTokens.swift"),
        ("ErrorTypes.swift", "LyoApp/Core/Shared/ErrorTypes.swift"),
        ("ConfigurationManager.swift", "LyoApp/Core/Configuration/ConfigurationManager.swift"),
        ("APIClient.swift", "LyoApp/Core/Networking/APIClient.swift"),
        ("EnhancedNetworkManager.swift", "LyoApp/Core/Networking/EnhancedNetworkManager.swift"),
        ("WebSocketManager.swift", "LyoApp/Core/Services/WebSocketManager.swift"),
        ("GamificationAPIService.swift", "LyoApp/Core/Services/GamificationAPIService.swift"),
        ("CommunityAPIService.swift", "LyoApp/Core/Services/CommunityAPIService.swift"),
        ("UserAPIService.swift", "LyoApp/Core/Services/UserAPIService.swift"),
        ("EnhancedAIService.swift", "LyoApp/Core/Services/EnhancedAIService.swift"),
        ("AIService.swift", "LyoApp/Core/Services/AIService.swift"),
        ("OfflineManager.swift", "LyoApp/Core/Services/OfflineManager.swift"),
        ("ErrorManager.swift", "LyoApp/Core/Services/ErrorManager.swift"),
        ("AnalyticsAPIService.swift", "LyoApp/Core/Services/AnalyticsAPIService.swift"),
        ("DataManager.swift", "LyoApp/Core/Services/DataManager.swift"),
        ("EnhancedServiceFactory.swift", "LyoApp/Core/Services/EnhancedServiceFactory.swift"),
        ("APIServices.swift", "LyoApp/Core/Services/APIServices.swift"),
        ("EnhancedAuthService.swift", "LyoApp/Core/Services/EnhancedAuthService.swift"),
        ("CourseModels.swift", "LyoApp/Core/Models/CourseModels.swift"),
        ("CommunityModels.swift", "LyoApp/Core/Models/CommunityModels.swift"),
        ("AIModels.swift", "LyoApp/Core/Models/AIModels.swift"),
        ("AuthModels.swift", "LyoApp/Core/Models/AuthModels.swift"),
        ("AppModels.swift", "LyoApp/Core/Models/AppModels.swift")
    ]
    
    # Verify files exist
    existing_files = []
    for filename, filepath in missing_files:
        full_path = "/Users/republicalatuya/Desktop/LyoJune/" + filepath
        if os.path.exists(full_path):
            existing_files.append((filename, filepath))
        else:
            print(f"Warning: File not found: {full_path}")
    
    print(f"Found {len(existing_files)} files to add to project")
    
    # Read current project file
    with open(project_path, 'r') as f:
        content = f.read()
    
    # Backup
    with open(project_path + ".backup_before_adding_missing", 'w') as f:
        f.write(content)
    
    # Find section markers
    build_files_start = content.find("/* Begin PBXBuildFile section */")
    build_files_end = content.find("/* End PBXBuildFile section */")
    
    file_refs_start = content.find("/* Begin PBXFileReference section */")
    file_refs_end = content.find("/* End PBXFileReference section */")
    
    sources_build_phase_pattern = r'(/\* Sources \*/ = \{[^}]*?files = \([^)]*?)(\);[^}]*?\};)'
    sources_match = re.search(sources_build_phase_pattern, content, re.DOTALL)
    
    if not all([build_files_start != -1, build_files_end != -1, file_refs_start != -1, file_refs_end != -1, sources_match]):
        print("Error: Could not find required sections in project file")
        return
    
    # Generate entries for missing files
    new_build_entries = []
    new_file_ref_entries = []
    new_sources_entries = []
    
    for filename, filepath in existing_files:
        # Check if already exists in project
        if filename in content:
            print(f"Skipping {filename} - already in project")
            continue
            
        # Generate UUIDs
        build_uuid = ''.join(f'{ord(c):02X}' for c in os.urandom(12))[:24]
        file_ref_uuid = ''.join(f'{ord(c):02X}' for c in os.urandom(12))[:24]
        
        # Create entries
        build_entry = f"\t\t{build_uuid} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_uuid} /* {filename} */; }};"
        file_ref_entry = f"\t\t{file_ref_uuid} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {filename}; sourceTree = \"<group>\"; }};"
        sources_entry = f"\t\t\t\t{build_uuid} /* {filename} in Sources */,"
        
        new_build_entries.append(build_entry)
        new_file_ref_entries.append(file_ref_entry)
        new_sources_entries.append(sources_entry)
        
        print(f"Adding {filename}")
    
    # Insert new entries
    if new_build_entries:
        insert_pos = build_files_end
        new_content = content[:insert_pos] + '\n' + '\n'.join(new_build_entries) + '\n' + content[insert_pos:]
        content = new_content
        
        # Update positions for subsequent insertions
        file_refs_start = content.find("/* Begin PBXFileReference section */")
        file_refs_end = content.find("/* End PBXFileReference section */")
        
        # Insert file references
        insert_pos = file_refs_end
        content = content[:insert_pos] + '\n' + '\n'.join(new_file_ref_entries) + '\n' + content[insert_pos:]
        
        # Update sources build phase
        sources_match = re.search(sources_build_phase_pattern, content, re.DOTALL)
        if sources_match:
            new_sources_section = sources_match.group(1) + '\n' + '\n'.join(new_sources_entries) + '\n' + sources_match.group(2)
            content = content.replace(sources_match.group(0), new_sources_section)
    
    # Write updated content
    with open(project_path, 'w') as f:
        f.write(content)
    
    print(f"Successfully added {len(new_build_entries)} files to the project")

if __name__ == "__main__":
    main()
