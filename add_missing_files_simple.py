#!/usr/bin/env python3

import os
import uuid
import re

def generate_uuid():
    """Generate a UUID in the format used by Xcode project files."""
    return str(uuid.uuid4()).upper().replace('-', '')[:24]

def add_files_to_xcode_project():
    """Add missing files to the Xcode project with correct paths and groups."""
    
    # Read the current project file
    project_file = "/Users/republicalatuya/Desktop/LyoJune/LyoApp.xcodeproj/project.pbxproj"
    with open(project_file, 'r') as f:
        content = f.read()
    
    # Create backup
    backup_file = f"{project_file}.backup_simple"
    with open(backup_file, 'w') as f:
        f.write(content)
    print(f"Created backup: {backup_file}")
    
    # Files and their target groups - manually specified
    files_to_add = [
        # Core/Models group files
        ("LyoApp/Core/Models/AppModels.swift", "4993D84E2E9471A87A6702DB"),
        ("LyoApp/Core/Models/AuthModels.swift", "4993D84E2E9471A87A6702DB"),
        ("LyoApp/Core/Models/AIModels.swift", "4993D84E2E9471A87A6702DB"),
        ("LyoApp/Core/Models/CommunityModels.swift", "4993D84E2E9471A87A6702DB"),
        ("LyoApp/Core/Models/CourseModels.swift", "4993D84E2E9471A87A6702DB"),
        
        # DesignSystem group files  
        ("LyoApp/DesignSystem/DesignTokens.swift", "1EDE9C732A326B470F4A35F9"),
        ("LyoApp/DesignSystem/HapticManager.swift", "1EDE9C732A326B470F4A35F9"),
        ("LyoApp/DesignSystem/ModernViews.swift", "1EDE9C732A326B470F4A35F9"),
    ]
    
    # New groups to create under Core
    new_groups = [
        ("Services", "49A7E77EA5B345E8B3FDB84E", [
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
        ]),
        ("Networking", "49A7E77EA5B345E8B3FDB84E", [
            "LyoApp/Core/Networking/EnhancedNetworkManager.swift",
            "LyoApp/Core/Networking/APIClient.swift",
        ]),
        ("Configuration", "49A7E77EA5B345E8B3FDB84E", [
            "LyoApp/Core/Configuration/ConfigurationManager.swift",
        ]),
        ("Shared", "49A7E77EA5B345E8B3FDB84E", [
            "LyoApp/Core/Shared/ErrorTypes.swift",
        ])
    ]
    
    # Check which files actually exist
    all_file_paths = [path for path, _ in files_to_add]
    for _, _, group_files in new_groups:
        all_file_paths.extend(group_files)
    
    existing_files = []
    for file_path in all_file_paths:
        absolute_path = f"/Users/republicalatuya/Desktop/LyoJune/{file_path}"
        if os.path.exists(absolute_path):
            existing_files.append(file_path)
            print(f"✓ Found: {file_path}")
        else:
            print(f"✗ Missing: {file_path}")
    
    print(f"\nFound {len(existing_files)} files to add to project")
    
    # Generate UUIDs for files and build entries
    file_uuids = {}
    build_uuids = {}
    for file_path in existing_files:
        file_name = os.path.basename(file_path)
        file_uuids[file_path] = generate_uuid()
        build_uuids[file_path] = generate_uuid()
    
    # Generate UUIDs for new groups
    group_uuids = {}
    for group_name, _, _ in new_groups:
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
    for group_name, parent_group_id, group_files in new_groups:
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
    for file_path, target_group_id in files_to_add:
        if file_path in existing_files:
            file_name = os.path.basename(file_path)
            file_uuid = file_uuids[file_path]
            
            # Find the target group and add the file to its children
            group_pattern = rf'({target_group_id} /\* [^*]+ \*/ = \{{\s+isa = PBXGroup;\s+children = \([^)]+)'
            match = re.search(group_pattern, content, re.DOTALL)
            if match:
                insertion_point = match.end()
                file_entry = f'\n\t\t\t\t{file_uuid} /* {file_name} */,'
                content = content[:insertion_point] + file_entry + content[insertion_point:]
    
    # 5. Add new group references to Core group
    core_group_pattern = rf'(49A7E77EA5B345E8B3FDB84E /\* Core \*/ = \{{\s+isa = PBXGroup;\s+children = \([^)]+)'
    match = re.search(core_group_pattern, content, re.DOTALL)
    if match:
        insertion_point = match.end()
        for group_name, _, _ in new_groups:
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
