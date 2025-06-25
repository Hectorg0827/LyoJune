#!/usr/bin/env python3

import re
import uuid
import os
import shutil

def generate_xcode_uuid():
    """Generate a 24-character hex string like Xcode uses"""
    return ''.join([hex(x)[2:].upper() for x in uuid.uuid4().bytes])[:24]

def add_files_to_xcode_project_correct_paths():
    """Add Swift files to Xcode project with correct relative paths"""
    
    project_file = 'LyoApp.xcodeproj/project.pbxproj'
    
    with open(project_file, 'r') as f:
        content = f.read()
    
    # Define files with their correct relative paths within the LyoApp folder
    files_to_add = [
        ('Core/Services/AuthService.swift', 'AuthService.swift'),
        ('Core/Network/NetworkManager.swift', 'NetworkManager.swift'),
        ('Core/Services/ErrorManager.swift', 'ErrorManager.swift'),
        ('Core/Services/OfflineManager.swift', 'OfflineManager.swift'),
        ('Core/Services/DataManager.swift', 'DataManager.swift'),
        ('Core/Services/APIServices.swift', 'APIServices.swift'),
        ('Core/Services/LearningAPIService.swift', 'LearningAPIService.swift'),
        ('Core/Services/GamificationAPIService.swift', 'GamificationAPIService.swift'),
        ('Core/Services/AIService.swift', 'AIService.swift'),
        ('Core/Services/EnhancedAIService.swift', 'EnhancedAIService.swift'),
        ('Core/UI/ErrorHandlingViews.swift', 'ErrorHandlingViews.swift'),
        ('Core/Services/ErrorHandler.swift', 'ErrorHandler.swift'),
        ('Core/Configuration/ConfigurationManager.swift', 'ConfigurationManager.swift'),
    ]
    
    # Store all new entries to add at once
    build_file_entries = []
    file_ref_entries = []
    source_entries = []
    
    for relative_path, file_name in files_to_add:
        full_path = f'LyoApp/{relative_path}'
        
        if not os.path.exists(full_path):
            print(f"❌ File not found: {full_path}")
            continue
            
        if file_name in content:
            print(f"✅ {file_name} already in project")
            continue
        
        # Generate UUIDs
        file_ref_uuid = generate_xcode_uuid()
        build_file_uuid = generate_xcode_uuid()
        
        # Prepare entries with correct relative paths
        build_file_entries.append(
            f'\t\t{build_file_uuid} /* {file_name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_uuid} /* {file_name} */; }};'
        )
        
        # Use the relative path within LyoApp
        file_ref_entries.append(
            f'\t\t{file_ref_uuid} /* {file_name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {file_name}; sourceTree = "<group>"; }};'
        )
        
        source_entries.append(
            f'\t\t\t\t{build_file_uuid} /* {file_name} in Sources */,'
        )
        
        print(f"🔄 Prepared {file_name} with path: {relative_path}")
    
    if not build_file_entries:
        print("ℹ️  No new files to add")
        return
    
    # Add PBXBuildFile entries
    build_section_pattern = r'(/\* End PBXBuildFile section \*/)'
    build_entries_text = '\n' + '\n'.join(build_file_entries) + '\n\t\t'
    content = re.sub(build_section_pattern, build_entries_text + r'\1', content)
    
    # Add PBXFileReference entries  
    file_ref_pattern = r'(/\* End PBXFileReference section \*/)'
    file_ref_entries_text = '\n' + '\n'.join(file_ref_entries) + '\n\t\t'
    content = re.sub(file_ref_pattern, file_ref_entries_text + r'\1', content)
    
    # Add to Sources build phase
    sources_pattern = r'(/\* Sources \*/ = \{[^}]*?files = \([^)]*?)(\s*\);)'
    sources_entries_text = '\n' + '\n'.join(source_entries) + '\n\t\t\t'
    content = re.sub(sources_pattern, r'\1' + sources_entries_text + r'\2', content, flags=re.DOTALL)
    
    # Write back to file
    with open(project_file, 'w') as f:
        f.write(content)
    
    print(f"✅ Added {len(build_file_entries)} files to project with correct paths")

def main():
    print("🚀 LyoApp Project File Repair - Correct Paths")
    print("=" * 60)
    
    # Create backup
    project_file = 'LyoApp.xcodeproj/project.pbxproj'
    backup_file = f'{project_file}.backup_correct_paths'
    shutil.copy2(project_file, backup_file)
    print(f"✅ Backup created: {backup_file}")
    
    try:
        # Add files to project with correct paths
        add_files_to_xcode_project_correct_paths()
        
        # Verify
        with open(project_file, 'r') as f:
            content = f.read()
        
        print("\n📊 Verification:")
        files_to_check = [
            'AuthService.swift', 'NetworkManager.swift', 'ErrorManager.swift',
            'OfflineManager.swift', 'DataManager.swift', 'APIServices.swift',
            'LearningAPIService.swift', 'GamificationAPIService.swift',
            'AIService.swift', 'EnhancedAIService.swift', 'ErrorHandlingViews.swift',
            'ErrorHandler.swift', 'ConfigurationManager.swift'
        ]
        
        all_good = True
        for file_name in files_to_check:
            count = content.count(file_name)
            if count >= 2:
                print(f"  ✅ {file_name} - {count} references")
            else:
                print(f"  ❌ {file_name} - {count} references")
                all_good = False
        
        if all_good:
            print("\n🎉 All files successfully added with correct paths!")
            print("\n🔨 Try building now:")
            print("xcodebuild -project LyoApp.xcodeproj -scheme LyoApp build")
        else:
            print("\n⚠️  Some files may not have been added correctly")
            print(f"Restore backup if needed: cp {backup_file} {project_file}")
        
    except Exception as e:
        print(f"\n❌ Error: {e}")
        print(f"Restoring backup: cp {backup_file} {project_file}")
        os.system(f'cp {backup_file} {project_file}')

if __name__ == "__main__":
    main()
