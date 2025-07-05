#!/usr/bin/env python3

import os
import uuid
import re

def generate_uuid():
    """Generate a UUID in the format used by Xcode project files."""
    return str(uuid.uuid4()).upper().replace('-', '')[:24]

def add_files_to_xcode_project():
    """Add missing files to the Xcode project with correct group structure."""
    
    # Group IDs from the project file
    CORE_GROUP_ID = "49A7E77EA5B345E8B3FDB84E"
    CORE_MODELS_GROUP_ID = "4993D84E2E9471A87A6702DB"
    DESIGN_SYSTEM_GROUP_ID = "1EDE9C732A326B470F4A35F9"
    
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
        "LyoApp/DesignSystem/AnimationSystem.swift",
        "LyoApp/DesignSystem/EnhancedViews.swift",
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
            "LyoApp/Core/Networking/NetworkingProtocols.swift",
            "LyoApp/Core/Networking/Endpoint.swift",
        ],
        "Configuration": [
            "LyoApp/Core/Configuration/ConfigurationManager.swift",
        ],
        "Shared": [
            "LyoApp/Core/Shared/ErrorTypes.swift",
            "LyoApp/Core/Shared/KeychainHelper.swift",
            "LyoApp/Core/Shared/BundleExtensions.swift",
            "LyoApp/Core/Shared/NetworkTypes.swift",
        ]
    }
    
    # Check which files actually exist
    all_files = core_models_files + design_system_files
    for group_files in new_groups.values():
        all_files.extend(group_files)
    
    existing_files = []
    for file_path in all_files:
        full_path = f"/Users/republicalatuya/Desktop/LyoJune/{file_path}"
        if os.path.exists(full_path):
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
    backup_file = f"{project_file}.backup_final"
    with open(backup_file, 'w') as f:
        f.write(content)
    print(f"Created backup: {backup_file}")
    
    # Generate UUIDs for files and build entries
    file_uuids = {}
    build_uuids = {}
    for file_path in existing_files:
        file_uuids[file_path] = generate_uuid()
        build_uuids[file_path] = generate_uuid()
    
    # Generate UUIDs for new groups
    group_uuids = {}
    for group_name in new_groups.keys():
        group_uuids[group_name] = generate_uuid()
    
    # 1. Add file references
    file_references = []
    for file_path in existing_files:
        file_name = os.path.basename(file_path)
        file_uuid = file_uuids[file_path]
        file_ref = f'\t\t{file_uuid} /* {file_name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {file_name}; sourceTree = "<group>"; }};'
        file_references.append(file_ref)
    
    # Insert file references
    pbx_file_ref_end = content.find('/* End PBXFileReference section */')
    if pbx_file_ref_end != -1:
        insertion_point = content.rfind('\n', 0, pbx_file_ref_end)
        content = content[:insertion_point] + '\n' + '\n'.join(file_references) + content[insertion_point:]
    
    # 2. Add build files
    build_files = []
    for file_path in existing_files:
        file_name = os.path.basename(file_path)
        file_uuid = file_uuids[file_path]
        build_uuid = build_uuids[file_path]
        build_file = f'\t\t{build_uuid} /* {file_name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_uuid} /* {file_name} */; }};'
        build_files.append(build_file)
    
    # Insert build files
    pbx_build_file_end = content.find('/* End PBXBuildFile section */')
    if pbx_build_file_end != -1:
        insertion_point = content.rfind('\n', 0, pbx_build_file_end)
        content = content[:insertion_point] + '\n' + '\n'.join(build_files) + content[insertion_point:]
    
    # 3. Create new groups
    new_group_entries = []
    for group_name, group_files in new_groups.items():
        group_uuid = group_uuids[group_name]
        # Only include files that exist
        group_file_refs = []
        for file_path in group_files:
            if file_path in existing_files:
                file_name = os.path.basename(file_path)
                file_uuid = file_uuids[file_path]
                group_file_refs.append(f'\t\t\t\t{file_uuid} /* {file_name} */,')
        
        group_entry = f'\t\t{group_uuid} /* {group_name} */ = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n' + '\n'.join(group_file_refs) + '\n\t\t\t);\n\t\t\tpath = {group_name};\n\t\t\tsourceTree = "<group>";\n\t\t}};'
        new_group_entries.append(group_entry)
    
    # Insert new groups
    pbx_group_end = content.find('/* End PBXGroup section */')
    if pbx_group_end != -1:
        insertion_point = content.rfind('\n', 0, pbx_group_end)
        content = content[:insertion_point] + '\n' + '\n'.join(new_group_entries) + content[insertion_point:]
    
    # 4. Add files to existing groups (Core/Models and DesignSystem)
    for file_path in core_models_files:
        if file_path in existing_files:
            file_name = os.path.basename(file_path)
            file_uuid = file_uuids[file_path]
            
            # Find Core/Models group and add the file
            group_pattern = rf'({CORE_MODELS_GROUP_ID} /\* Models \*/ = \{{\s+isa = PBXGroup;\s+children = \([^)]+)'
            match = re.search(group_pattern, content, re.DOTALL)
            if match:
                insertion_point = match.end()
                file_entry = f'\n\t\t\t\t{file_uuid} /* {file_name} */,'
                content = content[:insertion_point] + file_entry + content[insertion_point:]
    
    for file_path in design_system_files:
        if file_path in existing_files:
            file_name = os.path.basename(file_path)
            file_uuid = file_uuids[file_path]
            
            # Find DesignSystem group and add the file
            group_pattern = rf'({DESIGN_SYSTEM_GROUP_ID} /\* DesignSystem \*/ = \{{\s+isa = PBXGroup;\s+children = \([^)]+)'
            match = re.search(group_pattern, content, re.DOTALL)
            if match:
                insertion_point = match.end()
                file_entry = f'\n\t\t\t\t{file_uuid} /* {file_name} */,'
                content = content[:insertion_point] + file_entry + content[insertion_point:]
    
    # 5. Add new group references to Core group
    core_group_pattern = rf'({CORE_GROUP_ID} /\* Core \*/ = \{{\s+isa = PBXGroup;\s+children = \([^)]+)'
    match = re.search(core_group_pattern, content, re.DOTALL)
    if match:
        insertion_point = match.end()
        for group_name in new_groups.keys():
            group_uuid = group_uuids[group_name]
            group_ref = f'\n\t\t\t\t{group_uuid} /* {group_name} */,'
            content = content[:insertion_point] + group_ref + content[insertion_point:]
            insertion_point += len(group_ref)
    
    # 6. Add build file entries to Sources phase
    build_file_entries = []
    for file_path in existing_files:
        file_name = os.path.basename(file_path)
        build_uuid = build_uuids[file_path]
        build_entry = f'\t\t\t\t{build_uuid} /* {file_name} in Sources */,'
        build_file_entries.append(build_entry)
    
    
    # Insert build file entries in Sources phase
    sources_phase_pattern = r'(92A5145C75D5A57ABAFEE26F /\* Sources \*/ = \{[^}]+files = \([^)]+)'
    match = re.search(sources_phase_pattern, content, re.DOTALL)
    if match:
        insertion_point = match.end()
        content = content[:insertion_point] + '\n' + '\n'.join(build_file_entries) + content[insertion_point:]
    
    # Write the updated project file
    with open(project_file, 'w') as f:
        f.write(content)
    
    print(f"Added {len(existing_files)} files to Xcode project")
    print(f"Created {len(new_groups)} new groups under Core")
    print("Updated project.pbxproj file")

if __name__ == "__main__":
    add_files_to_xcode_project()
