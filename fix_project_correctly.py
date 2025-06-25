#!/usr/bin/env python3

import re
import uuid
import os

def generate_uuid():
    """Generate a 24-character hex string like Xcode uses"""
    return uuid.uuid4().hex.upper()[:24]

def add_file_to_xcode_project_correct(project_path, file_name):
    """Add a Swift file to Xcode project correctly"""
    
    with open(project_path, 'r') as f:
        content = f.read()
    
    # Check if file is already in project
    if file_name in content:
        print(f"  {file_name} already in project")
        return
    
    # Generate UUIDs for the file
    file_ref_uuid = generate_uuid()
    build_file_uuid = generate_uuid()
    
    # Add PBXBuildFile entry (for Sources only)
    build_file_pattern = r'(/* End PBXBuildFile section */)'
    build_file_entry = f'\t\t{build_file_uuid} /* {file_name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_uuid} /* {file_name} */; }};\n\t{{}}'
    content = re.sub(build_file_pattern, f'{build_file_entry}\\1', content)
    
    # Add PBXFileReference entry
    file_ref_pattern = r'(/* End PBXFileReference section */)'
    file_ref_entry = f'\t\t{file_ref_uuid} /* {file_name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {file_name}; sourceTree = "<group>"; }};\n\t{{}}'
    content = re.sub(file_ref_pattern, f'{file_ref_entry}\\1', content)
    
    # Add to Sources build phase ONLY (not Resources)
    # Find the Sources section and add the file
    sources_build_phase_pattern = r'(/\* Sources \*/ = \{[^}]*files = \([^}]*?)(\);[^}]*\};)'
    
    def sources_replacement(match):
        before = match.group(1)
        after = match.group(2)
        new_entry = f'\n\t\t\t\t{build_file_uuid} /* {file_name} in Sources */,'
        return before + new_entry + '\n\t\t\t' + after
    
    content = re.sub(sources_build_phase_pattern, sources_replacement, content, flags=re.DOTALL)
    
    # Write back to file
    with open(project_path, 'w') as f:
        f.write(content)
    
    print(f"  ✅ Added {file_name}")

# List of all missing files
all_files_to_add = [
    'AuthService.swift',
    'NetworkManager.swift',
    'ErrorManager.swift', 
    'OfflineManager.swift',
    'DataManager.swift',
    'APIServices.swift',
    'LearningAPIService.swift',
    'GamificationAPIService.swift',
    'AIService.swift',
    'EnhancedAIService.swift',
    'ErrorHandlingViews.swift',
    'ErrorHandler.swift',
    'ConfigurationManager.swift'
]

project_file = 'LyoApp.xcodeproj/project.pbxproj'

print("Correctly adding missing files to Xcode project...")
print("=" * 50)

# Create backup
os.system(f'cp {project_file} {project_file}.backup2')

try:
    for file_name in all_files_to_add:
        add_file_to_xcode_project_correct(project_file, file_name)
    
    print("\n✅ All files added successfully!")
    print("Backup created at: LyoApp.xcodeproj/project.pbxproj.backup2")
    
    # Verify the additions
    with open(project_file, 'r') as f:
        content = f.read()
    
    print("\n📊 Verification:")
    for file_name in all_files_to_add:
        count = content.count(file_name)
        if count >= 2:  # Should appear at least twice (PBXBuildFile and PBXFileReference)
            print(f"  ✅ {file_name} - {count} references")
        else:
            print(f"  ❌ {file_name} - {count} references (should be >= 2)")
    
    print("\nTry building the project now!")
    
except Exception as e:
    print(f"Error: {e}")
    print("Restoring backup...")
    os.system(f'cp {project_file}.backup2 {project_file}')
