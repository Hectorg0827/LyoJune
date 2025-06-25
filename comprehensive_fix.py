#!/usr/bin/env python3

import re
import uuid
import os
import shutil

def generate_xcode_uuid():
    """Generate a 24-character hex string like Xcode uses"""
    return ''.join([hex(x)[2:].upper() for x in uuid.uuid4().bytes])[:24]

def backup_project():
    """Create a backup of the project file"""
    project_file = 'LyoApp.xcodeproj/project.pbxproj'
    backup_file = f'{project_file}.backup_final'
    shutil.copy2(project_file, backup_file)
    print(f"✅ Backup created: {backup_file}")
    return backup_file

def add_files_to_xcode_project(file_mappings):
    """Add multiple Swift files to Xcode project"""
    
    project_file = 'LyoApp.xcodeproj/project.pbxproj'
    
    with open(project_file, 'r') as f:
        content = f.read()
    
    # Store all new entries to add at once
    build_file_entries = []
    file_ref_entries = []
    source_entries = []
    
    for file_path, file_name in file_mappings:
        if not os.path.exists(file_path):
            print(f"❌ File not found: {file_path}")
            continue
            
        if file_name in content:
            print(f"✅ {file_name} already in project")
            continue
        
        # Generate UUIDs
        file_ref_uuid = generate_xcode_uuid()
        build_file_uuid = generate_xcode_uuid()
        
        # Prepare entries
        build_file_entries.append(
            f'\t\t{build_file_uuid} /* {file_name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_uuid} /* {file_name} */; }};'
        )
        
        file_ref_entries.append(
            f'\t\t{file_ref_uuid} /* {file_name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {file_name}; sourceTree = "<group>"; }};'
        )
        
        source_entries.append(
            f'\t\t\t\t{build_file_uuid} /* {file_name} in Sources */,'
        )
        
        print(f"🔄 Prepared {file_name}")
    
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
    
    print(f"✅ Added {len(build_file_entries)} files to project")

def main():
    print("🚀 LyoApp Project File Repair")
    print("=" * 50)
    
    # Create backup
    backup_file = backup_project()
    
    # Define all files that need to be added
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
        ('LyoApp/Core/UI/ErrorHandlingViews.swift', 'ErrorHandlingViews.swift'),
        ('LyoApp/Core/Services/ErrorHandler.swift', 'ErrorHandler.swift'),
        ('LyoApp/Core/Configuration/ConfigurationManager.swift', 'ConfigurationManager.swift'),
    ]
    
    try:
        # Add files to project
        add_files_to_xcode_project(files_to_add)
        
        # Verify
        project_file = 'LyoApp.xcodeproj/project.pbxproj'
        with open(project_file, 'r') as f:
            content = f.read()
        
        print("\n📊 Verification:")
        all_good = True
        for _, file_name in files_to_add:
            if os.path.exists(f"LyoApp/{file_name}") or any(os.path.exists(f"LyoApp/{path}/{file_name}") for path in ['Core/Services', 'Core/Network', 'Core/UI', 'Core/Configuration']):
                count = content.count(file_name)
                if count >= 2:
                    print(f"  ✅ {file_name} - {count} references")
                else:
                    print(f"  ❌ {file_name} - {count} references")
                    all_good = False
        
        if all_good:
            print("\n🎉 All files successfully added to project!")
            print("\n🔨 Next steps:")
            print("1. Try building: xcodebuild -project LyoApp.xcodeproj -scheme LyoApp build")
            print("2. If errors persist, manually add files in Xcode")
        else:
            print("\n⚠️  Some files may not have been added correctly")
            print(f"Restore backup if needed: cp {backup_file} LyoApp.xcodeproj/project.pbxproj")
        
    except Exception as e:
        print(f"\n❌ Error: {e}")
        print(f"Restoring backup: cp {backup_file} LyoApp.xcodeproj/project.pbxproj")
        os.system(f'cp {backup_file} LyoApp.xcodeproj/project.pbxproj')

if __name__ == "__main__":
    main()
