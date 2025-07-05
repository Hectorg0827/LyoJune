#!/usr/bin/env python3

import os
import uuid
import re

def generate_uuid():
    """Generate a UUID in the format used by Xcode project files."""
    return str(uuid.uuid4()).upper().replace('-', '')[:24]

def add_files_to_xcode_project():
    """Add missing files to the Xcode project with correct paths and groups."""
    
    # Files to add to existing Core/Models group
    core_models_files = [
        "LyoApp/Core/Models/AppModels.swift",
        "LyoApp/Core/Models/AuthModels.swift", 
        "LyoApp/Core/Models/AIModels.swift",
        "LyoApp/Core/Models/CommunityModels.swift",
        "LyoApp/Core/Models/CourseModels.swift",
    ]
    
    # Files to add to existing DesignSystem group
    design_system_files = [
        "LyoApp/DesignSystem/DesignTokens.swift",
        "LyoApp/DesignSystem/HapticManager.swift",
        "LyoApp/DesignSystem/ModernViews.swift",
    ]
    
    # New groups to create under Core and their files
    new_groups = {
        "Services": [
            "LyoApp/Core/Services/EnhancedAuthService.swift",
            "LyoApp/Core/Services/APIServices.swift",
            "LyoApp/Core/Services/EnhancedServiceFactory.swift",
            "LyoApp/Core/Services/DataManager.swift",
            "LyoApp/Core/Services/AnalyticsAPIService.swift",
            "LyoApp/Core/Services/ErrorManager.swift",
            "LyoApp/Core/Services/OfflineManager.swift",
            "LyoApp/Core/Services/AIService.swift",
            "LyoApp/Core/Services/EnhancedAIService.swift",
            "LyoApp/Core/Services/UserAPIService.swift",
            "LyoApp/Core/Services/CommunityAPIService.swift",
            "LyoApp/Core/Services/GamificationAPIService.swift",
            "LyoApp/Core/Services/WebSocketManager.swift",
        ],
        "Networking": [
            "LyoApp/Core/Networking/EnhancedNetworkManager.swift",
            "LyoApp/Core/Networking/APIClient.swift",
        ],
        "Configuration": [
            "LyoApp/Core/Configuration/ConfigurationManager.swift",
        ],
        "Shared": [
            "LyoApp/Core/Shared/ErrorTypes.swift",
        ]
    }
    
    # Check which files actually exist
    all_files = core_models_files + design_system_files
    for group_files in new_groups.values():
        all_files.extend(group_files)
    
    existing_files = []
    for file_path in all_files:
        absolute_path = f"/Users/republicalatuya/Desktop/LyoJune/{file_path}"
        if os.path.exists(absolute_path):
            existing_files.append(file_path)
            print(f"✓ Found: {file_path}")
        else:
            print(f"✗ Missing: {file_path}")
    
    print(f"\nFound {len(existing_files)} files to add to project")
    
    # Read the current project file
    project_file = "/Users/republicalatuya/Desktop/LyoJune/LyoApp.xcodeproj/project.pbxproj"
    with open(project_file, 'r') as f:
        content = f.read()
    
    # Create backup
    backup_file = f"{project_file}.backup_advanced"
    with open(backup_file, 'w') as f:
        f.write(content)
    print(f"Created backup: {backup_file}")
    
    # Group IDs from the project file
    CORE_GROUP_ID = "49A7E77EA5B345E8B3FDB84E"
    CORE_MODELS_GROUP_ID = "4993D84E2E9471A87A6702DB"
    DESIGN_SYSTEM_GROUP_ID = "1EDE9C732A326B470F4A35F9"
    
    # Collections for generated entries
    file_references = []
    build_files = []
    build_file_entries = []
    new_group_entries = []
    group_updates = {}
    
    # Create new groups first
    for group_name in new_groups.keys():
        group_uuid = generate_uuid()
        group_entry = f'\t\t{group_uuid} /* {group_name} */ = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t);\n\t\t\tpath = {group_name};\n\t\t\tsourceTree = "<group>";\n\t\t}};'
        new_group_entries.append(group_entry)
        group_updates[group_name] = group_uuid
    
    # Process files and categorize them
    for file_path in existing_files:
        file_name = os.path.basename(file_path)
        file_uuid = generate_uuid()
        build_uuid = generate_uuid()
        
        # Create file reference entry
        file_ref = f'\t\t{file_uuid} /* {file_name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {file_name}; sourceTree = "<group>"; }};'
        file_references.append(file_ref)
        
        # Create build file entry  
        build_file = f'\t\t{build_uuid} /* {file_name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_uuid} /* {file_name} */; }};'
        build_files.append(build_file)
        
        # Create build file list entry
        build_entry = f'\t\t\t\t{build_uuid} /* {file_name} in Sources */,'
        build_file_entries.append(build_entry)
        
        # Determine which group this file belongs to
        if file_path in core_models_files:
            target_group = CORE_MODELS_GROUP_ID
        elif file_path in design_system_files:
            target_group = DESIGN_SYSTEM_GROUP_ID
        else:
            # Find which new group this file belongs to
            for group_name, group_files in new_groups.items():
                if file_path in group_files:
                    target_group = group_updates[group_name]
                    break
        
        # Add file to the appropriate group
        if target_group not in group_updates.values():
            # Existing group - need to add to the children list
            group_pattern = rf'({target_group} /\* .+ \*/ = \{{\s+isa = PBXGroup;\s+children = \([^)]+)'
            match = re.search(group_pattern, content, re.DOTALL)
            if match:
                insertion_point = match.end()
                file_entry = f'\n\t\t\t\t{file_uuid} /* {file_name} */,'
                content = content[:insertion_point] + file_entry + content[insertion_point:]
        else:
            # New group - add to the children list
            group_uuid = target_group
            group_pattern = rf'({group_uuid} /\* .+ \*/ = \{{\s+isa = PBXGroup;\s+children = \(\s+)'
            file_entry = f'\t\t\t\t{file_uuid} /* {file_name} */,\n'
            # We'll update this after adding the groups
            if group_uuid not in [g for g in group_updates.values()]:
                continue
    
    # Insert new groups into PBXGroup section
    if new_group_entries:
        pbx_group_end = content.find('/* End PBXGroup section */')
        if pbx_group_end != -1:
            insertion_point = content.rfind('\n', 0, pbx_group_end)
            new_content = content[:insertion_point] + '\n' + '\n'.join(new_group_entries) + content[insertion_point:]
            content = new_content
    
    # Add new groups to Core group
    if group_updates:
        core_group_pattern = rf'({CORE_GROUP_ID} /\* Core \*/ = \{{\s+isa = PBXGroup;\s+children = \([^)]+)'
        match = re.search(core_group_pattern, content, re.DOTALL)
        if match:
            insertion_point = match.end()
            for group_name, group_uuid in group_updates.items():
                group_ref = f'\n\t\t\t\t{group_uuid} /* {group_name} */,'
                content = content[:insertion_point] + group_ref + content[insertion_point:]
                insertion_point += len(group_ref)
    
    # Now add files to new groups
    for file_path in existing_files:
        file_name = os.path.basename(file_path)
        file_uuid = None
        
        # Find the file UUID we created
        for ref in file_references:
            if file_name in ref:
                file_uuid = ref.split()[0]
                break
        
        if not file_uuid:
            continue
        
        # Determine which new group this file belongs to
        for group_name, group_files in new_groups.items():
            if file_path in group_files:
                group_uuid = group_updates[group_name]
                group_pattern = rf'({group_uuid} /\* {group_name} \*/ = \{{\s+isa = PBXGroup;\s+children = \(\s+)'
                match = re.search(group_pattern, content, re.DOTALL)
                if match:
                    insertion_point = match.end()
                    file_entry = f'\t\t\t\t{file_uuid} /* {file_name} */,\n'
                    content = content[:insertion_point] + file_entry + content[insertion_point:]
                break
    
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
    print(f"Created {len(new_groups)} new groups under Core")
    print("Updated project.pbxproj file")

if __name__ == "__main__":
    add_files_to_xcode_project()
