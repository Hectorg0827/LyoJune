#!/usr/bin/env python3

import os
import uuid
import re
from pathlib import Path

def generate_uuid():
    """Generate a unique identifier in the format used by Xcode"""
    return str(uuid.uuid4()).replace('-', '').upper()[:24]

def add_file_to_xcode_project(project_path, file_path, target_group_path=None):
    """Add a Swift file to the Xcode project"""
    
    # Read the project file
    with open(project_path, 'r') as f:
        content = f.read()
    
    # Extract relative path from LyoApp directory
    relative_path = file_path.replace('/Users/republicalatuya/Desktop/LyoJune/LyoApp/', '')
    file_name = os.path.basename(file_path)
    
    # Generate UUIDs
    file_ref_uuid = generate_uuid()
    build_file_uuid = generate_uuid()
    
    print(f"Adding {file_name} with file ref UUID: {file_ref_uuid}, build UUID: {build_file_uuid}")
    
    # Add PBXBuildFile entry (near the top)
    build_file_entry = f'\t\t{build_file_uuid} /* {file_name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_uuid} /* {file_name} */; }};'
    
    # Find the first PBXBuildFile entry and add after it
    build_file_pattern = r'(\t\t\w+ /\* .+ in Sources \*/ = \{isa = PBXBuildFile; fileRef = \w+ /\* .+ \*/; \};)'
    match = re.search(build_file_pattern, content)
    if match:
        content = content[:match.end()] + '\n' + build_file_entry + content[match.end():]
    
    # Add PBXFileReference entry
    file_ref_entry = f'\t\t{file_ref_uuid} /* {file_name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {file_name}; sourceTree = "<group>"; }};'
    
    # Find the first PBXFileReference entry and add after it
    file_ref_pattern = r'(\t\t\w+ /\* .+\.swift \*/ = \{isa = PBXFileReference; lastKnownFileType = sourcecode\.swift; path = .+\.swift; sourceTree = "<group>"; \};)'
    match = re.search(file_ref_pattern, content)
    if match:
        content = content[:match.end()] + '\n' + file_ref_entry + content[match.end():]
    
    # Add to the appropriate group (Services, Networking, etc.)
    if 'Services' in file_path:
        group_pattern = r'(/* Services */ = \{[^}]+children = \([^)]+)'
        replacement = f'\\1\n\t\t\t\t{file_ref_uuid} /* {file_name} */,'
    elif 'Networking' in file_path:
        group_pattern = r'(/* Networking */ = \{[^}]+children = \([^)]+)'
        replacement = f'\\1\n\t\t\t\t{file_ref_uuid} /* {file_name} */,'
    elif 'Configuration' in file_path:
        group_pattern = r'(/* Configuration */ = \{[^}]+children = \([^)]+)'
        replacement = f'\\1\n\t\t\t\t{file_ref_uuid} /* {file_name} */,'
    elif 'Models' in file_path:
        group_pattern = r'(/* Models */ = \{[^}]+children = \([^)]+)'
        replacement = f'\\1\n\t\t\t\t{file_ref_uuid} /* {file_name} */,'
    elif 'Utilities' in file_path:
        group_pattern = r'(/* Utilities */ = \{[^}]+children = \([^)]+)'
        replacement = f'\\1\n\t\t\t\t{file_ref_uuid} /* {file_name} */,'
    else:
        # Default to Core group
        group_pattern = r'(/* Core */ = \{[^}]+children = \([^)]+)'
        replacement = f'\\1\n\t\t\t\t{file_ref_uuid} /* {file_name} */,'
    
    content = re.sub(group_pattern, replacement, content, flags=re.DOTALL)
    
    # Add to PBXSourcesBuildPhase (build sources)
    sources_pattern = r'(/* Sources */ = \{[^}]+files = \([^)]+)'
    sources_replacement = f'\\1\n\t\t\t\t{build_file_uuid} /* {file_name} in Sources */,'
    content = re.sub(sources_pattern, sources_replacement, content, flags=re.DOTALL)
    
    return content

def main():
    project_file = '/Users/republicalatuya/Desktop/LyoJune/LyoApp.xcodeproj/project.pbxproj'
    
    # Files that need to be added to the Xcode project
    files_to_add = [
        '/Users/republicalatuya/Desktop/LyoJune/LyoApp/Core/Services/APIService.swift',
        '/Users/republicalatuya/Desktop/LyoJune/LyoApp/Core/Networking/Protocols/APIProtocol.swift',
        '/Users/republicalatuya/Desktop/LyoJune/LyoApp/Core/Networking/APIClient.swift',
        '/Users/republicalatuya/Desktop/LyoJune/LyoApp/Core/Networking/MockAPIClient.swift',
        '/Users/republicalatuya/Desktop/LyoJune/LyoApp/Core/Configuration/DevelopmentConfig.swift',
        '/Users/republicalatuya/Desktop/LyoJune/LyoApp/Shared/Utilities/KeychainHelper.swift',
    ]
    
    # Check which files exist
    existing_files = []
    for file_path in files_to_add:
        if os.path.exists(file_path):
            existing_files.append(file_path)
            print(f"✓ Found: {os.path.basename(file_path)}")
        else:
            print(f"✗ Missing: {file_path}")
    
    if not existing_files:
        print("No files found to add!")
        return
    
    # Backup the project file
    backup_path = project_file + '.backup_before_adding_files'
    os.system(f'cp "{project_file}" "{backup_path}"')
    print(f"Created backup: {backup_path}")
    
    # Read current project content
    content = open(project_file, 'r').read()
    
    # Add each file
    for file_path in existing_files:
        content = add_file_to_xcode_project(project_file, file_path)
    
    # Write the updated project file
    with open(project_file, 'w') as f:
        f.write(content)
    
    print(f"Updated project file with {len(existing_files)} files")
    print("Files added:")
    for file_path in existing_files:
        print(f"  - {os.path.basename(file_path)}")

if __name__ == '__main__':
    main()
