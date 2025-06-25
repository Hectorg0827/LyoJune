#!/usr/bin/env python3

import re
import uuid
import os

def generate_uuid():
    """Generate a 24-character hex string like Xcode uses"""
    return uuid.uuid4().hex.upper()[:24]

def add_file_to_xcode_project(project_path, file_path, file_name):
    """Add a Swift file to Xcode project"""
    
    with open(project_path, 'r') as f:
        content = f.read()
    
    # Generate UUIDs for the file
    file_ref_uuid = generate_uuid()
    build_file_uuid = generate_uuid()
    
    # Add PBXBuildFile entry
    build_file_pattern = r'(/* End PBXBuildFile section */)'
    build_file_entry = f'\t\t{build_file_uuid} /* {file_name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_uuid} /* {file_name} */; }};\n\t{{}}'
    content = re.sub(build_file_pattern, f'{build_file_entry}\n\\1', content)
    
    # Add PBXFileReference entry
    file_ref_pattern = r'(/* End PBXFileReference section */)'
    file_ref_entry = f'\t\t{file_ref_uuid} /* {file_name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {file_name}; sourceTree = "<group>"; }};\n\t{{}}'
    content = re.sub(file_ref_pattern, f'{file_ref_entry}\n\\1', content)
    
    # Add to Sources build phase (find the Sources section and add the file)
    sources_pattern = r'(/* Sources \*/ = \{[\s\S]*?files = \([\s\S]*?)(\s*\);[\s\S]*?};)'
    def sources_replacement(match):
        before = match.group(1)
        after = match.group(2)
        new_entry = f'\t\t\t\t{build_file_uuid} /* {file_name} in Sources */,\n'
        return before + new_entry + after
    
    content = re.sub(sources_pattern, sources_replacement, content)
    
    # Write back to file
    with open(project_path, 'w') as f:
        f.write(content)

# List of files to add
files_to_add = [
    ('LyoApp/Core/Services/AuthService.swift', 'AuthService.swift'),
    ('LyoApp/Core/Network/NetworkManager.swift', 'NetworkManager.swift'),
    ('LyoApp/Core/Services/ErrorManager.swift', 'ErrorManager.swift'),
    ('LyoApp/Core/Services/OfflineManager.swift', 'OfflineManager.swift'),
    ('LyoApp/Core/Services/DataManager.swift', 'DataManager.swift'),
    ('LyoApp/Core/Services/APIServices.swift', 'APIServices.swift'),
    ('LyoApp/Core/Services/LearningAPIService.swift', 'LearningAPIService.swift'),
    ('LyoApp/Core/Services/GamificationAPIService.swift', 'GamificationAPIService.swift'),
    ('LyoApp/Core/Services/AIService.swift', 'AIService.swift'),
    ('LyoApp/Core/Services/EnhancedAIService.swift', 'EnhancedAIService.swift'),
]

project_file = 'LyoApp.xcodeproj/project.pbxproj'

print("Adding missing files to Xcode project...")

# Create backup first
os.system(f'cp {project_file} {project_file}.backup')

try:
    for file_path, file_name in files_to_add:
        if os.path.exists(file_path):
            print(f"Adding {file_name}...")
            add_file_to_xcode_project(project_file, file_path, file_name)
        else:
            print(f"Warning: {file_path} does not exist!")
    
    print("\nFiles added successfully!")
    print("Backup created at: LyoApp.xcodeproj/project.pbxproj.backup")
    print("\nTry building the project now.")
    
except Exception as e:
    print(f"Error: {e}")
    print("Restoring backup...")
    os.system(f'cp {project_file}.backup {project_file}')
